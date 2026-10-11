class ApplicationJob < ActiveJob::Base
  # Jobs carry customer messages and webhook signing credentials. Keep job IDs
  # and execution metadata in logs, but never serialize their arguments there.
  self.log_arguments = false

  # https://api.rubyonrails.org/v5.2.1/classes/ActiveJob/Exceptions/ClassMethods.html
  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.info("Skipping #{job.class} because of #{error.class.name}")
  end
end
