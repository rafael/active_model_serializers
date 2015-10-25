require 'thread_safe'
require 'active_model/serializer/collection_serializer'
require 'active_model/serializer/array_serializer'
require 'active_model/serializer/include_tree'
require 'active_model/serializer/attributes'
require 'active_model/serializer/associations'
require 'active_model/serializer/cache'
require 'active_model/serializer/configuration'
require 'active_model/serializer/fieldset'
require 'active_model/serializer/lint'

# ActiveModel::Serializer is an abstract class that is
# reified when subclassed to decorate a resource.
module ActiveModel
  class Serializer
    include Configuration
    include Attributes
    include Associations
    include Cache

    require 'active_model/serializer/adapter'

    class_attribute :_type, instance_reader: true, instance_writer: false

    # @example
    #   class AdminAuthorSerializer < ActiveModel::Serializer
    #     type 'authors'
    def self.type(type)
      self._type = type
    end

    # @param resource [ActiveRecord::Base, ActiveModelSerializers::Model]
    # @return [ActiveModel::Serializer]
    #   Preferentially returns
    #   1. resource.serializer
    #   2. ArraySerializer when resource is a collection
    #   3. options[:serializer]
    #   4. lookup serializer when resource is a Class
    def self.serializer_for(resource, options = {})
      if resource.respond_to?(:serializer_class)
        resource.serializer_class
      elsif resource.respond_to?(:to_ary)
        config.collection_serializer
      else
        options.fetch(:serializer) { get_serializer_for(resource.class) }
      end
    end

    # @see ActiveModel::Serializer::Adapter.lookup
    def self.adapter
      ActiveModel::Serializer::Adapter.lookup(config.adapter)
    end

    # @api private
    def self.serializer_lookup_chain_for(klass)
      chain = []

      resource_class_name = klass.name.demodulize
      resource_namespace = klass.name.deconstantize
      serializer_class_name = "#{resource_class_name}Serializer"

      chain.push("#{name}::#{serializer_class_name}") if self != ActiveModel::Serializer
      chain.push("#{resource_namespace}::#{serializer_class_name}")

      chain
    end

    # @api private
    # Find a serializer from a class and caches the lookup.
    # Preferentially retuns:
    #   1. class name appended with "Serializer"
    #   2. try again with superclass, if present
    #   3. nil
    def self.get_serializer_for(klass)
      serializers_cache.fetch_or_store(klass) do
        # NOTE(beauby): When we drop 1.9.3 support we can lazify the map for perfs.
        serializer_class = serializer_lookup_chain_for(klass).map(&:safe_constantize).find { |x| x }

        if serializer_class
          serializer_class
        elsif klass.superclass
          get_serializer_for(klass.superclass)
        end
      end
    end

    attr_accessor :object, :root, :scope

    # `scope_name` is set as :current_user by default in the controller.
    # If the instance does not have a method named `scope_name`, it
    # defines the method so that it calls the +scope+.
    def initialize(object, options = {})
      self.object = object
      self.instance_options = options
      self.root = instance_options[:root]
      self.scope = instance_options[:scope]

      scope_name = instance_options[:scope_name]
      if scope_name && !respond_to?(scope_name)
        self.class.class_eval do
          define_method scope_name, lambda { scope }
        end
      end
    end

    # Used by adapter as resource root.
    def json_key
      root || object.class.model_name.to_s.underscore
    end

    protected

    attr_accessor :instance_options
  end
end
