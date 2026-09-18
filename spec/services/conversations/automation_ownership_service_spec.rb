require 'rails_helper'

RSpec.describe Conversations::AutomationOwnershipService do
  let(:account) { create(:account) }
  let(:human_agent) { create(:user, account: account, role: :agent) }
  let(:bot) { create(:agent_bot, account: account, bot_config: { 'volitex_control_plane' => 'n8n' }) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false,
                              validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before { create(:agent_bot_inbox, account: account, inbox: inbox, agent_bot: bot) }

  describe '#enable_n8n!' do
    it 'assigns the dedicated n8n AgentBot and makes n8n the sole owner' do
      described_class.new(conversation: conversation, actor: human_agent).enable_n8n!

      conversation.reload
      expect(conversation.assignee_agent_bot).to eq(bot)
      expect(conversation.assignee).to be_nil
      expect(conversation.custom_attributes).to include('ai_mode' => true, 'automation_owner' => 'n8n', 'automation_agent_bot_id' => bot.id)
    end

    it 'rejects a normal AgentBot that is not marked as the n8n control plane' do
      inbox.agent_bot_inbox.update!(agent_bot: create(:agent_bot, account: account))

      expect { described_class.new(conversation: conversation, actor: human_agent).enable_n8n! }
        .to raise_error(ArgumentError, /Volitex n8n AgentBot/)
    end
  end

  describe '#handoff_to_human!' do
    it 'revokes bot ownership before assigning the human agent' do
      service = described_class.new(conversation: conversation, actor: human_agent)
      service.enable_n8n!
      service.handoff_to_human!

      conversation.reload
      expect(conversation.assignee_agent_bot).to be_nil
      expect(conversation.assignee).to eq(human_agent)
      expect(conversation.custom_attributes).to include('ai_mode' => false, 'automation_owner' => 'human')
    end
  end
end
