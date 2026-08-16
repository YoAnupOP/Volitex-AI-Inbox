require 'rails_helper'

RSpec.describe Instagram::CommentsService do
  let(:channel) { create(:channel_instagram) }
  let(:inbox) { channel.inbox }
  let(:comment_id) { '1234567890' }
  let(:comment) do
    {
      id: comment_id,
      text: 'A customer comment',
      from: { id: 'customer-id', username: 'customer' },
      media: { id: 'media-id', media_product_type: 'FEED' }
    }.with_indifferent_access
  end

  before do
    stub_request(:get, %r{https://graph\.instagram\.com/v22\.0/customer-id})
      .to_return(
        status: 200,
        body: { id: 'customer-id', name: 'Customer', username: 'customer' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  it 'does not create an inbound message for a self-authored comment webhook' do
    comment[:from][:id] = channel.instagram_id

    expect { described_class.new(comment, channel).perform }.not_to change(Message, :count)
  end

  it 'creates one inbound message for repeated delivery of the same customer comment ID' do
    service = described_class.new(comment, channel)

    expect do
      service.perform
      service.perform
    end.to change { inbox.messages.where(source_id: comment_id).count }.from(0).to(1)
  end
end
