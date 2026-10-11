require 'rails_helper'

RSpec.describe VolitexProductionConfiguration do
  let(:missing_keys) { described_class::ENCRYPTION_KEYS.index_with(nil) }
  let(:configured_keys) { described_class::ENCRYPTION_KEYS.index_with('disposable-test-key') }

  it 'rejects missing production encryption keys without exposing values' do
    with_modified_env missing_keys do
      expect { described_class.validate_encryption!(environment: 'production') }
        .to raise_error(ArgumentError, /Missing required production encryption configuration/)
    end
  end

  it 'rejects partial or blank production configuration' do
    with_modified_env configured_keys.merge('ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY' => ' ') do
      expect { described_class.validate_encryption!(environment: 'production') }
        .to raise_error(ArgumentError, /ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY/)
    end
  end

  it 'accepts a complete production key set' do
    with_modified_env configured_keys do
      expect { described_class.validate_encryption!(environment: 'production') }.not_to raise_error
    end
  end

  it 'does not require runtime secrets for asset compilation or non-production' do
    with_modified_env missing_keys do
      expect { described_class.validate_encryption!(environment: 'production', assets_precompile: true) }.not_to raise_error
      expect { described_class.validate_encryption!(environment: 'test') }.not_to raise_error
    end
  end
end
