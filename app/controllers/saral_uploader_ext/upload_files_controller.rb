require 'mime/types'
require 'google/cloud/storage'
require 'google/apis/iamcredentials_v1'

module SaralUploaderExt
  class UploadFilesController < ApplicationController
    IAM_SIGN_BLOB_SCOPE = 'https://www.googleapis.com/auth/iam'
    def generate_upload_signed_url
      bucket_name = @app_config[:gcloud_bucket]
      unless bucket_name.present?
        raise SaralUploaderExt::CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' is not found in .env file in main rails application")
      end

      gcloud_project_id = @app_config[:gcloud_project_id]
      unless gcloud_project_id.present?
        raise SaralUploaderExt::CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' is not found in .env file in main rails application")
      end

      uuid = SecureRandom.uuid
      file_name = params[:file_name]
      unless file_name.present?
        raise SaralUploaderExt::CustomError.new('File name must be present', "File name must be present in 'file_name' key")
      end
      modified_filename = file_name.gsub(/\s+/, "_") # replace all whitespaces into '_' in filename

      file_type = MIME::Types.type_for(modified_filename).first.to_s

      bucket_path = params[:bucket_path]
      unless bucket_path.present?
        raise SaralUploaderExt::CustomError.new('Bucket path must be present', "Bucket path must be present in 'bucket_path' key")
      end

      file_path = "#{bucket_path}-#{uuid}-#{modified_filename}"

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id)
      bucket = storage.bucket(bucket_name, skip_lookup: true)

      expiration_time = @app_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60) # default expiration time is 15 minutes

      url = bucket&.signed_url(file_path,
                               method: "PUT",
                               expires: expiration_time,
                               version: :v4,
                               headers: { "Content-Type" => file_type },
                               **signer_options(storage))

      host_name = 'https://storage.googleapis.com'
      render json: { success: true, message: 'Signed URL generated', url: url, file_path: file_path, file_url: "#{host_name}/#{bucket_name}/#{file_path}", content_type: file_type }, status: :ok
    rescue SaralUploaderExt::CustomError => e
      render json: { success: false, message: e.message, description: e.description }, status: :bad_request
    rescue => e
      render json: { success: false, message: e.message }, status: :bad_request
    end

    def get_signed_url_using_file_path
      bucket_name = @app_config[:gcloud_bucket]
      unless bucket_name.present?
        raise SaralUploaderExt::CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' is not found in .env file in main rails application")
      end

      gcloud_project_id = @app_config[:gcloud_project_id]
      unless gcloud_project_id.present?
        raise SaralUploaderExt::CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' is not found in .env file in main rails application")
      end

      file_path = params[:file_path]
      unless file_path.present?
        raise SaralUploaderExt::CustomError.new('File path must be present', "File path must be present in 'file_path' key")
      end

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id)
      bucket = storage.bucket(bucket_name, skip_lookup: true)

      raise 'Bucket not found' if bucket.nil?

      expiration_time = @app_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60) # default expiration time is 15 minutes

      url = bucket.signed_url(file_path.to_s, expires: expiration_time, version: :v4,  **signer_options(storage))
      raise 'File not found in this file_path' if url.nil?

      render json: { success: true, message: 'Signed URL generated', url: url }, status: :ok
    rescue SaralUploaderExt::CustomError => e
      render json: { success: false, message: e.message, description: e.description }, status: :bad_request
    rescue => e
      render json: { success: false, message: e.message }, status: :bad_request
    end

    def delete_file_from_bucket
      bucket_name = @app_config[:gcloud_bucket]
      unless bucket_name.present?
        raise SaralUploaderExt::CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' is not found in .env file in main rails application")
      end

      gcloud_project_id = @app_config[:gcloud_project_id]
      unless gcloud_project_id.present?
        raise SaralUploaderExt::CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' is not found in .env file in main rails application")
      end

      file_path = params[:file_path]
      unless file_path.present?
        raise SaralUploaderExt::CustomError.new('File path must be present', "File path must be present in 'file_path' key")
      end

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id)
      bucket = storage.bucket(bucket_name, skip_lookup: true)

      raise 'Bucket not found' if bucket.nil?

      file = bucket.file(file_path)
      raise 'File not found' if file.nil?

      file.delete
      render json: { success: true, message: 'File deleted successfully', file_path: file_path }, status: :ok

    rescue SaralUploaderExt::CustomError => e
      render json: { success: false, message: e.message, description: e.description }, status: :bad_request
    rescue => e
      render json: { success: false, message: e.message }, status: :bad_request
    end

    private

    # When credentials come from a JSON keyfile, google-cloud-storage can sign
    # locally using the private key embedded in that keyfile, so no override is
    # needed. When running on GCE/GKE via Application Default Credentials
    # (Workload Identity), there is no private key available, so we resolve the
    # attached service account's email and sign via the IAM Credentials API
    # (self-impersonation) instead.
    def signer_options(storage)
      @signer_options ||= begin
                            credentials = storage.service.credentials
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