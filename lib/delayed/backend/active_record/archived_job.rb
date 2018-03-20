class Delayed::Backend::ActiveRecord::ArchivedJob < ::ActiveRecord::Base
  attr_accessible :priority, :run_at, :queue, :payload_object, :failed_at, :locked_at, :locked_by,
                  :delayed_object_type, :delayed_object_id, :method_name, :args, :args_digest
end
