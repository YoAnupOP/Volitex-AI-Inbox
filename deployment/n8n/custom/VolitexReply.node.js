const { createHmac, timingSafeEqual } = require('node:crypto');

const result = (statusCode, status, extra = {}) => ({
  statusCode,
  status,
  ...extra,
});
const positiveId = value => Number.isSafeInteger(value) && value > 0;

// Receives the unmodified raw bytes from Webhook's rawBody option. Credentials
// remain in n8n's encrypted credential store, never in exported node parameters.
function authenticate(raw, headers, secret, now = Date.now()) {
  const timestamp = headers['x-chatwoot-timestamp'];
  const signature = headers['x-chatwoot-signature'];
  const delivery = headers['x-chatwoot-delivery'];
  if (
    !/^\d{10}$/.test(timestamp || '') ||
    Math.abs(now / 1000 - Number(timestamp)) > 300 ||
    !/^sha256=[a-f0-9]{64}$/.test(signature || '') ||
    !/^[a-f0-9-]{36}$/i.test(delivery || '')
  )
    return false;
  const expected = createHmac('sha256', secret)
    .update(`${timestamp}.`)
    .update(raw)
    .digest();
  return timingSafeEqual(expected, Buffer.from(signature.slice(7), 'hex'));
}

function validateEvent(raw, headers, credentials, now) {
  if (!authenticate(raw, headers, credentials.signingSecret, now))
    return result(401, 'invalid_authentication');
  let event;
  try {
    event = JSON.parse(raw.toString('utf8'));
  } catch {
    return result(400, 'invalid_json');
  }
  if (
    event.event !== 'message_created' ||
    event.message_type !== 'incoming' ||
    event.private !== false
  )
    return result(200, 'ignored_event');
  const accountId = Number(credentials.accountId);
  const inboxId = Number(credentials.inboxId);
  const conversationId = event.conversation?.id;
  if (
    !positiveId(event.id) ||
    !positiveId(conversationId) ||
    event.account?.id !== accountId ||
    event.inbox?.id !== inboxId ||
    event.conversation?.inbox_id !== inboxId ||
    !positiveId(event.sender?.id)
  ) {
    return result(403, 'tenant_context_rejected');
  }
  if (event.content !== 'Volitex round trip')
    return result(200, 'ignored_test_phrase');
  return result(200, 'authenticated_event', { event });
}

async function processEvent(raw, headers, credentials, request, now) {
  const verified = validateEvent(raw, headers, credentials, now);
  if (!verified.event) return verified;
  const { event } = verified;
  const accountId = Number(credentials.accountId);
  const inboxId = Number(credentials.inboxId);
  const conversationId = event.conversation.id;
  const base = credentials.baseUrl.replace(/\/$/, '');
  const url = `${base}/api/v1/accounts/${accountId}/conversations/${conversationId}`;
  const options = {
    headers: { api_access_token: credentials.apiToken },
    json: true,
    timeout: 3000,
    disableFollowRedirect: true,
  };
  try {
    const conversation = await request({ ...options, method: 'GET', url });
    if (
      conversation.inbox_id !== inboxId ||
      conversation.meta?.sender?.id !== event.sender.id
    )
      return result(403, 'conversation_context_rejected');
    const attributes = conversation.custom_attributes || {};
    if (
      attributes.automation_owner !== 'n8n' ||
      Number(attributes.automation_agent_bot_id) !== Number(credentials.botId)
    ) {
      return result(200, 'human_owned');
    }
    if (conversation.can_reply === false) return result(200, 'window_closed');
    // Stable across new delivery headers, repeated events, worker retries and
    // provider source_id updates; Inbox locks and deduplicates the actual send.
    const deliveryId = `incoming:${accountId}:${inboxId}:${event.id}`;
    const message = await request({
      ...options,
      method: 'POST',
      url: `${url}/messages`,
      body: {
        content:
          'Volitex staging automation: your message reached Inbox and the n8n queue worker.',
        message_type: 'outgoing',
        private: false,
        automation_delivery_id: deliveryId,
      },
    });
    return result(200, 'reply_accepted', {
      incoming_message_id: event.id,
      reply_message_id: message.id,
    });
  } catch (error) {
    if (
      /SSRF|blocked IP|disallowed|not allowed|private.*address/i.test(
        error.message || ''
      )
    ) {
      return result(503, 'inbox_network_blocked');
    }
    const status = error.statusCode || error.response?.statusCode;
    if (status === 422) return result(200, 'reply_rejected');
    if (status)
      return result(200, 'inbox_api_rejected', { inbox_status: status });
    // Retry only an indeterminate transport outcome, with the same key and a
    // fresh ownership check. Definitive API rejections are never retried.
    return result(503, 'inbox_unavailable');
  }
}

class VolitexReply {
  constructor() {
    this.description = {
      displayName: 'Volitex authenticated reply',
      name: 'volitexReply',
      group: ['transform'],
      version: 1,
      description:
        'Verify Inbox HMAC and tenant context, then reply through its assigned AgentBot',
      defaults: { name: 'Volitex authenticated reply' },
      inputs: ['main'],
      outputs: ['main'],
      credentials: [{ name: 'volitexInbox', required: true }],
      properties: [
        {
          displayName: 'Operation',
          name: 'operation',
          type: 'options',
          options: [
            { name: 'Validate Webhook', value: 'validate' },
            { name: 'Reply', value: 'reply' },
          ],
          default: 'reply',
        },
      ],
    };
  }

  async execute() {
    const credentials = await this.getCredentials('volitexInbox');
    const items = this.getInputData();
    if (items.length !== 1) throw new Error('Expected one raw Inbox webhook');
    const raw = await this.helpers.getBinaryDataBuffer(0, 'data');
    if (this.getNodeParameter('operation', 0) === 'validate') {
      const { event, ...verification } = validateEvent(
        raw,
        items[0].json.headers || {},
        credentials
      );
      return [[{ ...items[0], json: { ...items[0].json, verification } }]];
    }
    const response = await processEvent(
      raw,
      items[0].json.headers || {},
      credentials,
      options => this.helpers.httpRequest(options)
    );
    const logLevel =
      response.statusCode >= 400 || response.status === 'inbox_api_rejected'
        ? 'warn'
        : 'info';
    this.logger[logLevel]('Volitex Inbox automation', {
      executionId: this.getExecutionId(),
      accountId: credentials.accountId,
      ...response,
    });
    if (response.statusCode >= 500)
      throw new Error(`Volitex reply failed: ${response.status}`);
    return [[{ json: response, pairedItem: { item: 0 } }]];
  }
}
module.exports = { VolitexReply, authenticate, validateEvent, processEvent };
