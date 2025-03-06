Rails.application.config.gcloud_bucket = ENV['G_CLOUD_BUCKET']
Rails.application.config.gcloud_project_id = ENV['G_CLOUD_PROJECT_ID']
Rails.application.config.gcloud_keyfile = ENV['G_CLOUD_KEYFILE']
Rails.application.config.signed_url_expiration_time_in_seconds = ENV['SIGNED_URL_EXPIRATION_TIME_IN_SECONDS']