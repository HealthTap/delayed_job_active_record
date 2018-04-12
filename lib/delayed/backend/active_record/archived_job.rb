class Delayed::Backend::ActiveRecord::ArchivedJob < ::ActiveRecord::Base
  attr_accessible :priority, :run_at, :queue, :payload_object, :failed_at, :locked_at, :locked_by,
                  :delayed_object_type, :delayed_object_id, :method_name, :args, :unique_digest,
                  :attempts, :handler, :last_error

  def self.archive(delayed_job)
    failed_job = Delayed::Backend::ActiveRecord::ArchivedJob.new(
        delayed_job.attributes.select{|a| Delayed::Backend::ActiveRecord::ArchivedJob.accessible_attributes.include?(a)}
    )
    failed_job.failed_at = delayed_job.class.db_time_now
    failed_job.save
  end

  def retry
    retry_job = Delayed::Backend::ActiveRecord::HtDelayedJob.new(
      self.attributes.select{|a| Delayed::Backend::ActiveRecord::HtDelayedJob.accessible_attributes.include?(a)}
    )
    retry_job.handler = self.handler
    retry_job.failed_at = nil
    retry_job.attempts = 0
    if retry_job.save
      self.destroy
    end
  end

end
