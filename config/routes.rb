SaralUploaderExt::Engine.routes.draw do
  get 'upload_files/generate_upload_signed_url', to: 'upload_files#generate_upload_signed_url'
  get 'upload_files/delete_file_from_bucket', to: 'upload_files#delete_file_from_bucket'
end
