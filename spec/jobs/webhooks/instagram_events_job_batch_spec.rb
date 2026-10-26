require 'rails_helper'

RSpec.describe Webhooks::InstagramEventsJob do
  let(:channel) { create(:channel_instagram) }
  let(:job) { described_class.new }

  before do
    allow(job).to receive(:find_channel).and_return(channel)
  end

  it 'dispatches each event independently across a mixed batch' do
    message = { message: { mid: 'message-1', text: 'Hi' }, sender: { id: 'contact' }, recipient: { id: channel.instagram_id } }
    read = { read: { mid: 'message-1' }, sender: { id: 'contact' }, recipient: { id: channel.instagram_id } }
    expect(job).to receive(:message).with(message.with_indifferent_access, channel).ordered
    expect(job).to receive(:read).with(read.with_indifferent_access, channel).ordered
    job.process_entries([{ id: channel.instagram_id, messaging: [message, read] }])
  end

  it 'adapts postbacks into the normal idempotent incoming message path' do
    postback = { postback: { mid: 'postback-1', title: 'Book a visit' }, sender: { id: 'contact' }, recipient: { id: channel.instagram_id } }
    expect(job).to receive(:message).with(hash_including(message: { mid: 'postback-1', text: 'Book a visit' }), channel)
    job.process_entries([{ id: channel.instagram_id, messaging: [postback] }])
  end
end
