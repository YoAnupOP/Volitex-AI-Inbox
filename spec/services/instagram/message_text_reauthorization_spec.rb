require 'rails_helper'

RSpec.describe Instagram::MessageText do
  let(:channel) { create(:channel_instagram) }
  let(:event) do
    { sender: { id: 'sender-123' }, recipient: { id: channel.instagram_id },
      timestamp: (Time.current.to_f * 1000).to_i, message: { mid: 'incoming-123', text: 'Please book a visit' } }.with_indifferent_access
  end

  it 'retains and deduplicates a new-contact message even after authorization expires' do
    channel.update!(expires_at: 1.hour.ago)
    channel.prompt_reauthorization!
    expect { 2.times { described_class.new(event, channel).perform } }.to change(channel.inbox.messages, :count).by(1)
    expect(channel.inbox.messages.last.content).to eq('Please book a visit')
    expect(channel.inbox.contacts.last.name).to include('sender-123')
    expect(WebMock).not_to have_requested(:get, /graph.instagram.com/)
  end

  it 'preserves original event time so delayed delivery does not reopen a DM window' do
    channel.update!(expires_at: 1.hour.ago)
    event[:timestamp] = (25.hours.ago.to_f * 1000).to_i
    described_class.new(event, channel).perform
    expect(channel.inbox.messages.last.created_at).to be_within(2.seconds).of(25.hours.ago)
    expect(Conversations::MessageWindowService.new(channel.inbox.conversations.last, human_agent: false).can_reply?).to be false
  end
end
