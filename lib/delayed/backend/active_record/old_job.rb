class Delayed::Backend::ActiveRecord::OldJob < Delayed::Backend::ActiveRecord::AbstractJob
  self.table_name = 'delayed_jobs'
end
