module Delayed
  module Backend
    module HtExtension
      def self.included(base)
        base.extend ClassMethods

        base.switch_to_ht_table
        base.class_eval do
          attr_accessible :delayed_object_type, :delayed_object_id, :method_name, :args, :unique_digest
          before_validation :update_unique_digest
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
        if @payload_object.is_a?(Delayed::PerformableMethod)
          populate_method_attrs(@payload_object)
        elsif @payload_object.respond_to?(:klass) && @payload_object.respond_to?(:method_name) && @payload_object.respond_to?(:args)
          handle_generic_delayed_job(@payload_object)
        else
          self.handler = object.to_yaml
        end
      end

      def payload_object
        @payload_object ||= _payload_object
      rescue TypeError, LoadError, NameError, ArgumentError => e
        logger.error("Failed to load object for job id: #{self.id} - #{e.message}")
        raise DeserializationError,
              "Job failed to load: #{e.message}. Handler: #{handler.inspect}"
      end

      def _payload_object
        if self.handler.present?
          YAML.load(self.handler)
        else
          clazz = Object.const_get(self.delayed_object_type)
          object = if self.delayed_object_id.present?
                     clazz.find_by_id(self.delayed_object_id)
                   else
                     clazz
                   end
          raise ArgumentError.new("object not found for delayed job #{self.id}, type: #{self.delayed_object_type}, obj_id: #{self.delayed_object_id}") unless object.present?
          PerformableMethod.new(object, self.method_name, YAML.load(self.args))
        end
      end

      def handle_generic_delayed_job(generic_delayed_job)
        self.delayed_object_type = generic_delayed_job.klass.name
        self.method_name = generic_delayed_job.method_name
        self.args = generic_delayed_job.args.to_yaml
        self.handler = nil
      end

      def populate_method_attrs(performable_method)
        object = performable_method.object
        self.delayed_object_type, self.delayed_object_id, self.handler =
        if object.is_a?(::ActiveRecord::Base) && object.persisted?
          [object.class.name, object.id, nil]
        elsif object.is_a?(::Class)
          [object.name, nil, nil]
        else
          [nil, nil, performable_method.to_yaml]
        end

        unless self.handler.present?
          self.method_name = performable_method.method_name
          self.args = performable_method.args.to_yaml
        end
      end

      def update_unique_digest
        unique_fields = [self.delayed_object_type,
                         self.delayed_object_id,
                         self.method_name,
                         self.args,
                         self.failed_at,
                         self.handler,
                         !!self.locked_at,
                         self.run_at]
        unique_fields_str = unique_fields.join('#')
        self.unique_digest = Digest::SHA256.hexdigest unique_fields_str
      end

      def archive
        if Delayed::Backend::ActiveRecord::ArchivedJob.archive(self)
          self.destroy
        end
      end
    end
  end
end
