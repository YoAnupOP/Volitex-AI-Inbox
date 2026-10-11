class VolitexProductionConfiguration
  ENCRYPTION_KEYS = %w[
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  ].freeze

  def self.validate_encryption!(environment:, assets_precompile: false)
    return unless environment.to_s == 'production'
    return if assets_precompile

    missing = ENCRYPTION_KEYS.select { |key| ENV[key].blank? }
    return if missing.empty?

    raise ArgumentError, "Missing required production encryption configuration: #{missing.join(', ')}"
  end
end
