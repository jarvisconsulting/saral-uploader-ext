# 📦 SaralUploaderExt
SaralUploaderExt is a Ruby on Rails engine that enables Google Cloud Storage file uploads via signed URLs, downloads, and deletions. It supports secure file management using V4 signed URLs, making it ideal for frontend direct uploads without exposing credentials.

## ✨ Features
- ✅ Generate signed upload URLs for Google Cloud Storage
- ✅ Fetch signed download URLs using the file path
- ✅ Delete files from the GCS bucket
- ✅ Configurable through environment variables and YAML
- ✅ Can be mounted in your main app with route-level authentication

## 🔧 Installation
- Add this line to your application’s Gemfile:
<pre lang="ruby">
   gem 'saral_uploader_ext', git: '[https://github.com/your-org/saral_uploader_ext.git](https://github.com/jarvisconsulting/saral-uploader-ext)'
</pre>
Then run
<pre lang="ruby"> bundle install </pre>

## 🛠️ Configuration
1. Add environment variables to your main app’s .env:
<pre lang="ruby">
  GCLOUD_BUCKET_NAME=your_bucket_name
  GCLOUD_PROJECT=your_gcloud_project_id
  SIGNED_URL_EXPIRATION_TIME_IN_SECONDS=900 # optional, defaults to 900 (15 minutes)
</pre>

2. Create config file: config/saral_uploader_ext.yml
 <pre lang="yaml">
defaults: &DEFAULTS
  gcloud_bucket: <%= ENV['GCLOUD_BUCKET_NAME'] %>
  gcloud_project_id: <%= ENV['GCLOUD_PROJECT'] %>
  signed_url_expiration_time_in_seconds: <%= ENV['SIGNED_URL_EXPIRATION_TIME_IN_SECONDS'] %>

development:
  <<: *DEFAULTS

test:
  <<: *DEFAULTS

production:
  <<: *DEFAULTS
</pre>

# Routes.rb
<pre lang="ruby"> mount SaralUploaderExt::Engine => '/saral_uploader' </pre>

To restrict access (e.g., only logged-in users), wrap it in an authentication constraint:
<pre lang="ruby">
   authenticate :user do
     mount SaralUploaderExt::Engine => '/saral_uploader'
   end
</pre>

## 📡 Available Endpoints

| Method | Endpoint                                                             | Description                          | Params                         |
|--------|----------------------------------------------------------------------|--------------------------------------|--------------------------------|
| GET    | /saral_uploader/upload_files/generate_upload_signed_url             | Generate a signed URL for uploading  | `file_name`, `bucket_path`     |
| GET    | /saral_uploader/upload_files/get_signed_url_using_file_path         | Generate signed URL for download     | `file_path`                    |
| GET    | /saral_uploader/upload_files/delete_file_from_bucket                | Delete file from GCS bucket          | `file_path`                    |

## 🧱 Dependencies
Ensure your Gemfile includes:

<pre lang="ruby"> 
gem 'google-cloud-storage'
gem 'mime-types'
gem 'dotenv-rails' # (optional, for .env file support)
</pre>

## 🛠 Maintained By

Maintained by **Chitranshoo Prakash**, **Rajnish Kumar Mishra** / **Jarvis Consulting**
