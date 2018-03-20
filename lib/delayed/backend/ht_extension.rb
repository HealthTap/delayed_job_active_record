module Delayed
  module Backend
    module HtExtension
      def self.included(base)
        base.extend ClassMethods

        base.switch_to_ht_table
        base.class_eval do
          attr_accessible :delayed_object_type, :delayed_object_id, :method_name, :args, :args_digest
          before_validation :update_unique_digest
          validates_uniqueness_of :unique_digest
        end
      end

      module ClassMethods
        def switch_to_ht_table
          delayed_job_table_name = "#{::ActiveRecord::Base.table_name_prefix}ht_delayed_jobs"
          self.table_name = delayed_job_table_name
        end
      end

      def payload_object=(object)
        @payload_object = object
        if @payload_object.is_a?(Delayed::PerformableMethod) &&
            @payload_object.object.is_a?(::ActiveRecord::Base) &&
            @payload_object.object.persisted?
          populate_method_attrs(@payload_object)
        else
          self.handler = object.to_yaml
        end
      end

      def payload_object
        @payload_object ||= _payload_object
      rescue TypeError, LoadError, NameError, ArgumentError => e
        raise DeserializationError,
              "Job failed to load: #{e.message}. Handler: #{handler.inspect}"
      end

      def _payload_object
        if self.handler.present?
          YAML.load(self.handler)
        else
          clazz = Object.const_get(self.delayed_object_type)
          object = clazz.find_by_id(self.delayed_object_id)
          PerformableMethod.new(object, self.method_name, YAML.load(self.args))
        end
      end

      def populate_method_attrs(performable_method)
        object = performable_method.object
        self.delayed_object_type = object.class.name
        self.delayed_object_id = object.id
        self.method_name = performable_method.method_name
        self.args = performable_method.args.to_yaml
        self.handler = nil
      end

      def update_unique_digest
        unique_fields_str = [self.delayed_object_type,
                             self.delayed_object_id,
                             self.method_name,
                             self.args,
                             self.failed_at,
                             self.handler,
                             !!self.locked_at].join('#')
        self.unique_digest = Digest::SHA256.hexdigest unique_fields_str
      end
    end
  end
end
