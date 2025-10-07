require 'google/cloud/storage'
require 'mime/types'
require 'securerandom'

module SaralUploaderExt
  class UploadService
    def initialize(gcloud_bucket: nil)
    default_config = SaralUploaderExt.config
      @bucket_name = gcloud_bucket || default_config[:gcloud_bucket]
      @gcloud_project_id = default_config[:gcloud_project_id]
      @gcloud_keyfile = default_config[:gcloud_keyfile]
      @expiration_time = default_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60)

      raise CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' missing") unless @bucket_name.present?
      raise CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' missing") unless @gcloud_project_id.present?
      raise CustomError.new('Gcloud keyfile must be present', "'G_CLOUD_KEYFILE' missing") unless @gcloud_keyfile.present?

      @storage = Google::Cloud::Storage.new(project_id: @gcloud_project_id, credentials: @gcloud_keyfile)
      @bucket = @storage.bucket(@bucket_name)
      raise 'Bucket not found' if @bucket.nil?
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
        headers: headers
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

      url = @bucket.signed_url(file_path, expires: expiration_time, version: :v4)
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
  end
end
