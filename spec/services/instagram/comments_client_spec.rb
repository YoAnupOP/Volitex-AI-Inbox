require 'rails_helper'

RSpec.describe Instagram::CommentsClient do
  let(:inbox) { instance_double(Inbox, name: 'volitexai') }
  let(:channel) do
    instance_double(Channel::Instagram, instagram_id: '9001', access_token: 'access-token', inbox: inbox)
  end
  let(:response) do
    {
      'data' => [
        {
          'id' => '1001',
          'from' => { 'id' => '9001', 'username' => 'meta_business_username' },
          'replies' => {
            'data' => [
              { 'id' => '1002', 'from' => { 'id' => '9001' } },
              { 'id' => '1003', 'from' => { 'id' => '9002', 'username' => 'customer' } }
            ]
          }
        }
      ]
    }
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('INSTAGRAM_API_VERSION', 'v22.0').and_return('v22.0')
    stub_request(:get, 'https://graph.instagram.com/v22.0/123/comments')
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'preserves Meta usernames and uses the connected inbox identity only for self-authored records without one' do
    result = described_class.new(channel).comments('123')

    expect(result.dig('data', 0, 'from', 'username')).to eq('meta_business_username')
    expect(result.dig('data', 0, 'replies', 'data', 0, 'username')).to eq('volitexai')
    expect(result.dig('data', 0, 'replies', 'data', 1, 'username')).to be_nil
  end

  it 'keeps a reply nested when Meta also includes the same ID as a top-level comment' do
    response['data'] << {
      'id' => '1002',
      'from' => { 'id' => '9001', 'username' => 'meta_business_username' },
      'text' => 'A duplicate top-level copy of the reply'
    }
    response.dig('data', 0, 'replies', 'data', 0)['from'] = {}

    result = described_class.new(channel).comments('123')

    expect(result['data'].pluck('id')).to eq(['1001'])
    expect(result.dig('data', 0, 'replies', 'data').pluck('id')).to include('1002')
    expect(result.dig('data', 0, 'replies', 'data', 0, 'from', 'username')).to eq('meta_business_username')
  end

  it 'uses parent IDs to preserve separate reply branches at every depth' do
    response['data'] = [
      {
        'id' => '1001',
        'replies' => {
          'data' => [
            { 'id' => '1002', 'parent_id' => '1001', 'text' => 'B replies to A' },
            { 'id' => '1003', 'parent_id' => '1002', 'text' => 'C replies to B' },
            { 'id' => '1004', 'parent_id' => '1001', 'text' => 'C replies to A' }
          ]
        }
      }
    ]

    result = described_class.new(channel).comments('123')

    expect(result['data'].pluck('id')).to eq(['1001'])
    expect(result.dig('data', 0, 'replies', 'data').pluck('id')).to eq(%w[1002 1004])
    expect(result.dig('data', 0, 'replies', 'data', 0, 'replies', 'data').pluck('id')).to eq(['1003'])
  end
end
