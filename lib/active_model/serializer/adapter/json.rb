class ActiveModel::Serializer::Adapter::Json < ActiveModel::Serializer::Adapter
        extend ActiveSupport::Autoload
        autoload :FragmentCache

        def serializable_hash(options = nil)
          options ||= {}
          if serializer.respond_to?(:each)
            result = serializer.map { |s| FlattenJson.new(s).serializable_hash(options) }
          else
            return nil unless serializer

            hash = {}

            core = cache_check(serializer) do
              serializer.attributes(options)
            end

            serializer.associations.each do |association|
              hash[association.key] =
                if association.options[:virtual_value]
                  association.options[:virtual_value]
                elsif association.serializer && association.serializer.object
                  FlattenJson.new(association.serializer).serializable_hash(association.options)
                end
            end
            result = core.merge hash
          end

          { root => result }
        end

        def fragment_cache(cached_hash, non_cached_hash)
          ActiveModel::Serializer::Adapter::Json::FragmentCache.new().fragment_cache(cached_hash, non_cached_hash)
        end
end
