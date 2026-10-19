require 'rails_helper'
require 'yaml'

RSpec.describe 'Production deployment contracts' do # rubocop:disable RSpec/DescribeClass -- configuration, not a class
  let(:application) { YAML.load_file(Rails.root.join('docker-compose.production.yaml'), aliases: true).fetch('services') }
  let(:automation) { YAML.load_file(Rails.root.join('deployment/n8n-queue.compose.yaml'), aliases: true).fetch('services') }

  it 'requires the same explicit Volitex image for migration, web and both workers without an upstream fallback' do
    images = application.values.map { |service| service.fetch('image') }.uniq
    expect(images.size).to eq(1)
    expect(images.first).to start_with('${VOLITEX_IMAGE:?')
    expect(images.first).not_to include('latest', 'chatwoot/chatwoot', ':-')
  end

  it 'checks the ordinary and campaign workers independently and bounds the campaign connection pool' do
    expect(application.dig('sidekiq', 'environment', 'SIDEKIQ_HEALTH_QUEUE')).to eq('critical')
    expect(application.dig('campaign-worker', 'environment', 'SIDEKIQ_HEALTH_QUEUE')).to eq('campaigns')
    expect(application.dig('campaign-worker', 'environment', 'SIDEKIQ_DB_POOL')).to eq('2')
    expect(application.dig('campaign-worker', 'environment', 'SIDEKIQ_CONCURRENCY')).to eq('2')
    %w[sidekiq campaign-worker].each do |name|
      expect(application.fetch(name).fetch('healthcheck').fetch('test')).to include('script/production/campaign_worker_health.rb')
    end
  end

  it 'rotates logs for every application and n8n stack service' do
    (application.values + automation.values).each do |service|
      expect(service.fetch('logging')).to eq('driver' => 'local', 'options' => { 'max-size' => '10m', 'max-file' => '5' })
    end
  end

  it 'retains the shared attachment volume across web and both workers' do
    %w[rails sidekiq campaign-worker].each do |name|
      expect(application.fetch(name).fetch('volumes')).to include('volitex_storage:/app/storage')
    end
  end

  it 'keeps n8n dependencies and worker private with the main and worker on the same image' do
    automation.each_value { |service| expect(service.fetch('ports', [])).to be_empty }
    expect(automation.dig('n8n-main', 'image')).to eq(automation.dig('n8n-worker', 'image'))
    expect(automation.dig('n8n-main', 'labels')).to include('coolify.traefik.middlewares=volitex-n8n-identity@file')
    %w[n8n-worker n8n-postgres n8n-valkey].each do |name|
      expect(automation.fetch(name).fetch('labels', [])).to be_empty
    end
  end

  it 'persists n8n queue writes without evicting queued jobs' do
    command = automation.dig('n8n-valkey', 'command').join(' ')
    expect(command).to include('--appendonly yes', '--appendfsync everysec', '--maxmemory-policy noeviction')
    expect(automation.dig('n8n-valkey', 'volumes')).to include('n8n_valkey_data:/data')
  end

  it 'prevents the legacy upstream publisher from running in the Volitex repository' do
    workflow = YAML.load_file(Rails.root.join('.github/workflows/publish_ee_docker.yml'))
    workflow.fetch('jobs').each_value do |job|
      expect(job.fetch('if')).to eq("github.repository == 'chatwoot/chatwoot'")
    end
  end
end
