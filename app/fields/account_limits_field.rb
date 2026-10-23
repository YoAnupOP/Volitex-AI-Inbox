require 'administrate/field/base'

class AccountLimitsField < Administrate::Field::Base
  LIMIT_KEYS = %w[agents inboxes captain_responses captain_documents emails].freeze

  def to_s
    data
  end

  def limits
    LIMIT_KEYS.index_with { |key| data.to_h[key] }
  end
end
