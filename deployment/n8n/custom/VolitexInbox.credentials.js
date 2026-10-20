class VolitexInbox {
  constructor() {
    this.name = 'volitexInbox';
    this.displayName = 'Volitex AI Inbox account AgentBot';
    this.properties = [
      {
        displayName: 'Inbox URL',
        name: 'baseUrl',
        type: 'string',
        default: '',
        required: true,
      },
      {
        displayName: 'Account ID',
        name: 'accountId',
        type: 'number',
        default: 0,
        required: true,
      },
      {
        displayName: 'Inbox ID',
        name: 'inboxId',
        type: 'number',
        default: 0,
        required: true,
      },
      {
        displayName: 'AgentBot ID',
        name: 'botId',
        type: 'number',
        default: 0,
        required: true,
      },
      {
        displayName: 'AgentBot API Token',
        name: 'apiToken',
        type: 'string',
        typeOptions: { password: true },
        default: '',
        required: true,
      },
      {
        displayName: 'Webhook Signing Secret',
        name: 'signingSecret',
        type: 'string',
        typeOptions: { password: true },
        default: '',
        required: true,
      },
    ];
  }
}
module.exports = { VolitexInbox };
