require 'google/cloud/storage'
require 'google/apis/iamcredentials_v1'
require 'mime/types'
require 'securerandom'

module SaralUploaderExt
  class UploadService
    IAM_SIGN_BLOB_SCOPE = 'https://www.googleapis.com/auth/iam'

    def initialize(gcloud_bucket: nil)
    default_config = SaralUploaderExt.config
      @bucket_name = gcloud_bucket || default_config[:gcloud_bucket]
      @gcloud_project_id = default_config[:gcloud_project_id]
      @expiration_time = default_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60)

      raise CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' missing") unless @bucket_name.present?
      raise CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' missing") unless @gcloud_project_id.present?

      @storage = Google::Cloud::Storage.new(project_id: @gcloud_project_id)
      # skip_lookup avoids an upfront `buckets.get` call. That call goes through
      # Google::Cloud::Storage::Service#get_bucket, which passes `generation:`/
      # `soft_deleted:` keywords that raise ArgumentError when the legacy
      # `google-api-client` gem's bundled (older) storage_v1 client shadows the
      # one this gem depends on. Bucket existence still gets verified implicitly
      # the first time an actual operation (signed_url, create_file, delete) hits
      # the API.
      @bucket = @storage.bucket(@bucket_name, skip_lookup: true)
    end

    def generate_upload_signed_url(file_name:, bucket_path:, expiration_time: nil, max_file_size_in_mb: nil)
      expiration_time =  expiration_time.presence&.to_i || @expiration_time
      raise CustomError.new('File name must be present', "Provide 'file_name'") unless file_name.present?
      raise CustomError.new('Bucket path must be present', "Provide 'bucket_path'") unless bucket_path.present?

      uuid = SecureRandom.uuid
      modified_filename = file_name.gsub(/\s+/, "_")
      file_type = MIME::Types.type_for(modified_filename).first.to_s
      file_path = "#{bucket_path}/#{uuid}-#{modified_filename}"

      headers = { "Content-Type" => file_type }

      if max_file_size_in_mb.present?
        max_file_size_in_bytes = max_file_size_in_mb.to_i * 1024 * 1024
        headers["x-goog-content-length-range"] = "0,#{max_file_size_in_bytes}"
      end

      url = @bucket.signed_url(
        file_path,
        method: "PUT",
        expires: expiration_time,
        version: :v4,
        headers: headers,
        **signer_options
      )

      host_name = 'https://storage.googleapis.com'
      {
        url: url,
        file_path: file_path,
        file_url: "#{host_name}/#{@bucket_name}/#{file_path}",
        content_type: file_type,
        headers: headers
      }
    end

    def get_signed_url_using_file_path(file_path:, expiration_time: nil)
      expiration_time =  expiration_time.presence&.to_i || @expiration_time
      raise CustomError.new('File path must be present', "Provide 'file_path'") unless file_path.present?

      url = @bucket.signed_url(file_path, expires: expiration_time, version: :v4, **signer_options)
      raise 'File not found in this file_path' if url.nil?

      { url: url }
    end

    def delete_file(file_path:)
      raise CustomError.new('File path must be present', "Provide 'file_path'") unless file_path.present?

      file = @bucket.file(file_path)
      raise 'File not found' if file.nil?

      file.delete
      { success: true, file_path: file_path }
    end

    private

    # When credentials come from a JSON keyfile, google-cloud-storage can sign
    # locally using the private key embedded in that keyfile, so no override is
    # needed. When running on GCE/GKE via Application Default Credentials
    # (Workload Identity), there is no private key available, so we resolve the
    # attached service account's email and sign via the IAM Credentials API
    # (self-impersonation) instead.
    def signer_options
      @signer_options ||= begin
        credentials = @storage.service.credentials
        if credentials.issuer.present? && credentials.signing_key.present?
          {}
        else
          service_account_email = fetch_service_account_email
          { issuer: service_account_email, signer: iam_sign_blob_proc(service_account_email) }
        end
      end
    end

    def fetch_service_account_email
      host = Google::Auth::GCECredentials.metadata_host
      connection = Faraday.new(url: "http://#{host}") do |conn|
        conn.options.timeout = 1.0
        conn.options.open_timeout = 0.1
        conn.adapter Faraday.default_adapter
      end

      response = connection.get(
        '/computeMetadata/v1/instance/service-accounts/default/email',
        nil,
        'Metadata-Flavor' => 'Google'
      )
      unless response.status == 200
        raise CustomError.new(
          'Unable to resolve signer identity',
          'Could not fetch the attached service account email from the GCE metadata server'
        )
      end

      response.body
    end

    def iam_sign_blob_proc(service_account_email)
      iam_client = Google::Apis::IamcredentialsV1::IAMCredentialsService.new
      iam_client.authorization = Google::Auth.get_application_default([IAM_SIGN_BLOB_SCOPE])

      lambda do |string_to_sign|
        request = Google::Apis::IamcredentialsV1::SignBlobRequest.new(payload: string_to_sign)
        response = iam_client.sign_service_account_blob(
          "projects/-/serviceAccounts/#{service_account_email}",
          request
        )
        response.signed_blob
      end
    end
  end
end
