class Delayed::Backend::ActiveRecord::OldJob < ::ActiveRecord::Base
  self.table_name = 'delayed_jobs'
end
