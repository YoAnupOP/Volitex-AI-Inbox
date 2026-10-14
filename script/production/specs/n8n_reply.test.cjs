const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createHmac } = require('node:crypto');
const {
  VolitexReply,
  processEvent,
} = require('../../../deployment/n8n/custom/VolitexReply.node.js');

const credentials = {
  signingSecret: 'synthetic-test-secret',
  apiToken: 'synthetic-test-token',
  accountId: 1,
  inboxId: 3,
  botId: 7,
  baseUrl: 'https://inbox.invalid',
};
const event = {
  event: 'message_created',
  message_type: 'incoming',
  private: false,
  content: 'Volitex round trip',
  id: 12,
  account: { id: 1 },
  inbox: { id: 3 },
  conversation: { id: 1, inbox_id: 3 },
  sender: { id: 9, type: 'contact' },
};
const raw = Buffer.from(JSON.stringify(event));
const timestamp = Math.floor(Date.now() / 1000).toString();
const headers = {
  'x-chatwoot-timestamp': timestamp,
  'x-chatwoot-delivery': 'a921d653-9185-4bdb-aa90-449fbbd9f071',
  'x-chatwoot-signature': `sha256=${createHmac('sha256', credentials.signingSecret).update(`${timestamp}.`).update(raw).digest('hex')}`,
};
const conversation = {
  inbox_id: 3,
  meta: { sender: { id: 9 } },
  custom_attributes: { automation_owner: 'n8n', automation_agent_bot_id: 7 },
};

test('missing and invalid HMAC, modified raw bytes, and stale timestamps reject before API access', async () => {
  await Promise.all(
    [
      [raw, {}, undefined],
      [
        raw,
        { ...headers, 'x-chatwoot-signature': `sha256=${'0'.repeat(64)}` },
        undefined,
      ],
      [Buffer.concat([raw, Buffer.from(' ')]), headers, undefined],
      [raw, headers, Date.now() + 301000],
    ].map(async ([body, incomingHeaders, now]) => {
      const response = await processEvent(
        body,
        incomingHeaders,
        credentials,
        () => {
          throw new Error('must not call API');
        },
        now
      );
      assert.equal(response.statusCode, 401);
    })
  );
});
test('credential account and inbox context rejects a foreign tenant', async () => {
  const response = await processEvent(
    raw,
    headers,
    { ...credentials, accountId: 2 },
    () => {
      throw new Error('must not call API');
    }
  );
  assert.equal(response.statusCode, 403);
});
test('validation stage preserves raw bytes for the reply but acknowledges without any API call', async () => {
  const input = {
    json: { headers },
    binary: { data: { data: raw.toString('base64') } },
  };
  const context = {
    getCredentials: async () => credentials,
    getInputData: () => [input],
    getNodeParameter: () => 'validate',
    helpers: {
      getBinaryDataBuffer: async () => raw,
      httpRequest: () => {
        throw new Error('must not call API');
      },
    },
  };
  const [[output]] = await VolitexReply.prototype.execute.call(context);
  assert.deepEqual(output.json.verification, {
    statusCode: 200,
    status: 'authenticated_event',
  });
  assert.equal(output.binary, input.binary);
});
test('human ownership and wrong contact prevent POST', async () => {
  await Promise.all(
    [
      { ...conversation, custom_attributes: { automation_owner: 'human' } },
      { ...conversation, meta: { sender: { id: 10 } } },
    ].map(async value => {
      const response = await processEvent(
        raw,
        headers,
        credentials,
        options => {
          assert.equal(options.method, 'GET');
          return value;
        }
      );
      assert.notEqual(response.status, 'reply_accepted');
    })
  );
});
test('closed service window skips the outgoing API call', async () => {
  const response = await processEvent(raw, headers, credentials, options => {
    assert.equal(options.method, 'GET');
    return { ...conversation, can_reply: false };
  });
  assert.equal(response.status, 'window_closed');
});
test('definitive API rejection is recorded without retrying a rejected reply', async () => {
  const response = await processEvent(raw, headers, credentials, options => {
    if (options.method === 'GET') return conversation;
    throw Object.assign(new Error('synthetic rejection'), { statusCode: 429 });
  });
  assert.equal(response.statusCode, 200);
  assert.equal(response.status, 'inbox_api_rejected');
  assert.equal(response.inbox_status, 429);
});
test('reply uses AgentBot credential, stable inbound idempotency key and original conversation', async () => {
  const posts = [];
  const request = options => {
    assert.equal(options.headers.api_access_token, credentials.apiToken);
    if (options.method === 'GET') return conversation;
    posts.push(options);
    return { id: 33 };
  };
  const first = await processEvent(raw, headers, credentials, request);
  const retry = await processEvent(raw, headers, credentials, request);
  assert.equal(first.reply_message_id, 33);
  assert.equal(retry.reply_message_id, 33);
  assert.equal(
    posts[0].url,
    'https://inbox.invalid/api/v1/accounts/1/conversations/1/messages'
  );
  assert.equal(
    posts[0].body.automation_delivery_id,
    posts[1].body.automation_delivery_id
  );
});
test('timeout returns retryable result without immediate duplicate POST; handoff rejection acknowledges safely', async () => {
  await Promise.all(
    [undefined, 422].map(async statusCode => {
      let calls = 0;
      const response = await processEvent(
        raw,
        headers,
        credentials,
        options => {
          if (options.method === 'GET') return conversation;
          calls += 1;
          throw Object.assign(new Error('synthetic'), { statusCode });
        }
      );
      assert.equal(calls, 1);
      assert.equal(response.statusCode, statusCode === 422 ? 200 : 503);
    })
  );
});
