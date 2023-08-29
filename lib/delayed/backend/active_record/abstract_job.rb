class Delayed::Backend::ActiveRecord::AbstractJob < ::ActiveRecord::Base
  self.abstract_class = true
end
