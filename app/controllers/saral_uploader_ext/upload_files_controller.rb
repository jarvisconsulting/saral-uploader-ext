require 'mime/types'
require 'google/cloud/storage'

module SaralUploaderExt
  class UploadFilesController < ApplicationController
    def generate_upload_signed_url
      bucket_name = @app_config[:gcloud_bucket]
      unless bucket_name.present?
        raise SaralUploaderExt::CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' is not found in .env file in main rails application")
      end

      gcloud_project_id = @app_config[:gcloud_project_id]
      unless gcloud_project_id.present?
        raise SaralUploaderExt::CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' is not found in .env file in main rails application")
      end

      gcloud_keyfile = @app_config[:gcloud_keyfile]
      unless gcloud_keyfile.present?
        raise SaralUploaderExt::CustomError.new('Gcloud keyfile must be present', "'G_CLOUD_KEYFILE' is not found in .env file in main rails application")
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

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id, credentials: gcloud_keyfile)
      bucket = storage.bucket(bucket_name)

      expiration_time = @app_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60) # default expiration time is 15 minutes

      url = bucket&.signed_url(file_path,
                               method: "PUT",
                               expires: expiration_time,
                               version: :v4,
                               headers: { "Content-Type" => file_type })

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

      gcloud_keyfile = @app_config[:gcloud_keyfile]
      unless gcloud_keyfile.present?
        raise SaralUploaderExt::CustomError.new('Gcloud keyfile must be present', "'G_CLOUD_KEYFILE' is not found in .env file in main rails application")
      end

      file_path = params[:file_path]
      unless file_path.present?
        raise SaralUploaderExt::CustomError.new('File path must be present', "File path must be present in 'file_path' key")
      end

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id, credentials: gcloud_keyfile)
      bucket = storage.bucket(bucket_name)

      raise 'Bucket not found' if bucket.nil?

      expiration_time = @app_config[:signed_url_expiration_time_in_seconds].presence&.to_i || (15 * 60) # default expiration time is 15 minutes

      url = bucket.signed_url(file_path.to_s, expires: expiration_time, version: :v4)
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

      gcloud_keyfile = @app_config[:gcloud_keyfile]
      unless gcloud_keyfile.present?
        raise SaralUploaderExt::CustomError.new('Gcloud keyfile must be present', "'G_CLOUD_KEYFILE' is not found in .env file in main rails application")
      end

      file_path = params[:file_path]
      unless file_path.present?
        raise SaralUploaderExt::CustomError.new('File path must be present', "File path must be present in 'file_path' key")
      end

      storage = Google::Cloud::Storage.new(project_id: gcloud_project_id, credentials: gcloud_keyfile)
      bucket = storage.bucket(bucket_name)

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

  end
end