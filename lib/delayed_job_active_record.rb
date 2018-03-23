require 'active_record'
require 'delayed_job'
require 'delayed/backend/active_record'
require 'delayed/backend/active_record/archived_job'
require 'delayed/backend/active_record/old_job'
require 'delayed/backend/active_record/ht_delayed_job'

Delayed::Worker.backend = :active_record
