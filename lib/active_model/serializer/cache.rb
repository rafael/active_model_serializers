module ActiveModel
  class Serializer
    # Caching for serializers.
    #
    module Cache
      extend ActiveSupport::Concern

      included do |base|
        with_options instance_accessor: false do
          base.class_attribute :_cache         # @api private : the cache object
          base.class_attribute :_fragmented    # @api private : @see ::fragmented
          base.class_attribute :_cache_key     # @api private : when present, is first item in cache_key
          base.class_attribute :_cache_only    # @api private : when fragment caching, whitelists cached_attributes. Cannot combine with except
          base.class_attribute :_cache_except  # @api private : when fragment caching, blacklists cached_attributes. Cannot combine with only
          base.class_attribute :_cache_options # @api private : used by CachedSerializer, passed to _cache.fetch
          #  _cache_options include:
          #    expires_in
          #    compress
          #    force
          #    race_condition_ttl
          #  Passed to ::_cache as
          #    serializer._cache.fetch(cache_key, @klass._cache_options)
          base.class_attribute :_cache_digest # @api private : Generated
        end
      end

      # Matches
      #  "c:/git/emberjs/ember-crm-backend/app/serializers/lead_serializer.rb:1:in `<top (required)>'"
      #  AND
      #  "/c/git/emberjs/ember-crm-backend/app/serializers/lead_serializer.rb:1:in `<top (required)>'"
      #  AS
      #  c/git/emberjs/ember-crm-backend/app/serializers/lead_serializer.rb
      CALLER_FILE = /
        \A       # start of string
        \S+      # one or more non-spaces
        (?=      # stop previous match when
          :\d+     # a colon is followed by one or more digits
          :in      # followed by a colon followed by in
        )
      /x

      module ClassMethods
        # Generates a unique digest for each serializer at load.
        def inherited(base)
          super
          caller_line = caller.first
          base._cache_digest = digest_caller_file(caller_line)
        end

        # Hashes contents of file for +_cache_digest+
        def digest_caller_file(caller_line)
          serializer_file_path = caller_line[CALLER_FILE]
          serializer_file_contents = IO.read(serializer_file_path)
          Digest::MD5.hexdigest(serializer_file_contents)
        rescue TypeError, Errno::ENOENT
          warn <<-EOF.strip_heredoc
           Cannot digest non-existent file: '#{caller_line}'.
           Please set `::_cache_digest` of the serializer
           if you'd like to cache it.
           EOF
          ''.freeze
        end

        # @api private
        # Used by FragmentCache on the CachedSerializer
        #  to call attribute methods on the fragmented cached serializer.
        def fragmented(serializer)
          self._fragmented = serializer
        end

        # Enables a serializer to be automatically cached
        #
        # Sets +::_cache+ object to <tt>ActionController::Base.cache_store</tt>
        #   when Rails.configuration.action_controller.perform_caching
        #
        # @params options [Hash] with valid keys:
        #   key            : @see ::_cache_key
        #   only           : @see ::_cache_only
        #   except         : @see ::_cache_except
        #   skip_digest    : does not include digest in cache_key
        #   all else       : @see ::_cache_options
        #
        # @example
        #   class PostSerializer < ActiveModel::Serializer
        #     cache key: 'post', expires_in: 3.hours
        #     attributes :title, :body
        #
        #     has_many :comments
        #   end
        #
        # @todo require less code comments. See
        # https://github.com/rails-api/active_model_serializers/pull/1249#issuecomment-146567837
        def cache(options = {})
          self._cache = ActionController::Base.cache_store if Rails.configuration.action_controller.perform_caching
          self._cache_key = options.delete(:key)
          self._cache_only = options.delete(:only)
          self._cache_except = options.delete(:except)
          self._cache_options = (options.empty?) ? nil : options
        end

        # Used to cache serializer name => serializer class
        # when looked up by Serializer.get_serializer_for.
        def serializers_cache
          @serializers_cache ||= ThreadSafe::Cache.new
        end
      end
    end
  end
end
