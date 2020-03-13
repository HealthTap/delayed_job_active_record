module Delayed
  module Backend
    module ActiveRecord
      class HtDelayedJob < ::ActiveRecord::Base
        include Delayed::Backend::HtExtension

        #attr_accessible :priority, :run_at, :queue, :payload_object,
        #                :failed_at, :locked_at, :locked_by
      end
    end
  end
end
