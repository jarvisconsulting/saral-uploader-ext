module SaralUploaderExt
  class UploadFilesController < ApplicationController
    def generate_upload_signed_url
      bucket_name = Rails.application.config.gcloud_bucket
      unless bucket_name.present?
        raise SaralUploaderExt::CustomError.new('Bucket name must be present', "'G_CLOUD_BUCKET' is not found in .env file in main rails application")
      end

      gcloud_project_id = Rails.application.config.gcloud_project_id
      unless gcloud_project_id.present?
        raise SaralUploaderExt::CustomError.new('Gcloud project ID must be present', "'G_CLOUD_PROJECT_ID' is not found in .env file in main rails application")
      end

      gcloud_keyfile = Rails.application.config.gcloud_keyfile
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

      expiration_time = Rails.application.config.signed_url_expiration_time_in_seconds || (15 * 60) # default expiration time is 15 minutes

      url = bucket&.signed_url(file_path,
                               method: "PUT",
                               expires: expiration_time,
                               version: :v4,
                               headers: { "Content-Type" => file_type })

      host_name = 'https://storage.googleapis.com'
      render json: { success: true, message: 'Signed URL generated', url: url, file_path: "#{host_name}/#{bucket_name}/#{file_path}", content_type: file_type }, status: :ok
    rescue SaralUploaderExt::CustomError => e
      render json: { success: false, message: e.message, description: e.description }, status: :bad_request
    rescue => e
      render json: { success: false, message: e.message }, status: :bad_request
    end

  end
end