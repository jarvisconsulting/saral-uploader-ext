require_relative 'patches/google_storage_soft_deleted_patch'

module SaralUploaderExt
  class Engine < ::Rails::Engine
    isolate_namespace SaralUploaderExt

    config.after_initialize do
      if defined?(Google::Apis::StorageV1::StorageService)
        Google::Apis::StorageV1::StorageService.prepend(
          SaralUploaderExt::Patches::GoogleStorageSoftDeletedPatch
        )
      end
    end
  end
end
