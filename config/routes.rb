SaralUploaderExt::Engine.routes.draw do
  get 'upload_files/generate_upload_signed_url', to: 'upload_files#generate_upload_signed_url'
end
