require 'rails_helper'

RSpec.describe Instagram::SendOnInstagramService do
  let(:channel) { create(:channel_instagram) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: inbox.account) }
  let(:user) { create(:user, account: inbox.account, role: :agent) }
  let(:bot) { create(:agent_bot) }

  before do
    allow(GlobalConfig).to receive(:get).and_call_original
    allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT').and_return('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => true)
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT', nil).and_return(true)
  end

  it 'never tags a bot reply as HUMAN_AGENT' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 1.hour.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: bot)
    params = described_class.new(message: message).send(:merge_human_agent_tag, {})
    expect(params).not_to have_key(:tag)
  end

  it 'does not tag human replies inside the standard window' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 1.hour.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: user)
    expect(described_class.new(message: message).send(:merge_human_agent_tag, {})).not_to have_key(:tag)
  end

  it 'tags eligible human replies after 24 hours and within seven days' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 25.hours.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: user)
    expect(described_class.new(message: message).send(:merge_human_agent_tag, {})[:tag]).to eq('HUMAN_AGENT')
  end

  it 'blocks bots outside 24 hours at actual dispatch without calling Meta' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 25.hours.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: bot)
    expect(HTTParty).not_to receive(:post)
    described_class.new(message: message).perform
    expect(message.reload).to be_failed
  end

  it 'blocks automation rules even when a User is recorded as sender' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 25.hours.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: user,
                               content_attributes: { automation_rule_id: 123 })
    described_class.new(message: message).perform
    expect(message.reload).to be_failed
  end

  it 'blocks human replies after seven days' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 8.days.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: user)
    described_class.new(message: message).perform
    expect(message.reload).to be_failed
  end

  it 'does not let an incoming public comment open the private DM window' do
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, content_attributes: { instagram_comment: true })
    expect(Conversations::MessageWindowService.new(conversation).can_reply?).to be false
  end

  it 'does not interpret a false string setting as Human Agent approval' do
    allow(GlobalConfigService).to receive(:load).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT', nil).and_return('false')
    create(:message, account: inbox.account, message_type: :incoming, conversation: conversation, created_at: 25.hours.ago)
    message = create(:message, account: inbox.account, message_type: :outgoing, conversation: conversation, sender: user)
    described_class.new(message: message).perform
    expect(message.reload).to be_failed
  end
end
