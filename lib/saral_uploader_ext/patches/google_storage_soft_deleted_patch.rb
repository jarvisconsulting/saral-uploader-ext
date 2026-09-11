# google-api-client 0.53.0 ships its own bundled Google::Apis::StorageV1::StorageService
# that shadows the standalone google-apis-storage_v1 gem. The bundled version predates
# the `soft_deleted:`, `match_glob:`, `include_folders_as_prefixes:`, `filter:`,
# `generation:`, and `return_partial_success:` keywords that google-cloud-storage 1.44+
# passes to these methods. Ruby 3.x strict keyword checking raises:
#   ArgumentError: unknown keyword: :soft_deleted
# This patch intercepts the affected methods, strips the unknown keywords, and forwards
# the rest to the old client's method.
module SaralUploaderExt
  module Patches
    module GoogleStorageSoftDeletedPatch
      def get_object(bucket, object, soft_deleted: nil, **kwargs, &block)
        super(bucket, object, **kwargs, &block)
      end

      def list_objects(bucket, soft_deleted: nil, match_glob: nil,
                       include_folders_as_prefixes: nil, filter: nil, **kwargs, &block)
        super(bucket, **kwargs, &block)
      end

      def get_bucket(bucket, soft_deleted: nil, generation: nil, **kwargs, &block)
        super(bucket, **kwargs, &block)
      end

      def list_buckets(project, soft_deleted: nil, return_partial_success: nil, **kwargs, &block)
        super(project, **kwargs, &block)
      end
    end
  end
end
