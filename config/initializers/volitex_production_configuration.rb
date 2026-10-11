require Rails.root.join('lib/volitex_production_configuration')

assets_precompile = defined?(Rake) && Rake.respond_to?(:application) && Rake.application.top_level_tasks.include?('assets:precompile')
VolitexProductionConfiguration.validate_encryption!(environment: Rails.env, assets_precompile: assets_precompile)
