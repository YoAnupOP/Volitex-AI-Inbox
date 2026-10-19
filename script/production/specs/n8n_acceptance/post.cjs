// Synthetic credential fixture is local to the disposable probe, never exported.
const fs = require('node:fs');
const http = require('node:http');
const { createHmac, randomUUID } = require('node:crypto');
const fixture = JSON.parse(
  fs.readFileSync('/fixtures/credentials-data.json', 'utf8')
);
const event = JSON.parse(fs.readFileSync('/fixtures/event.json', 'utf8'));
if (process.argv[2] === 'foreign') event.account.id += 1000;
const body = JSON.stringify(event);
const timestamp = Math.floor(Date.now() / 1000).toString();
const signature = createHmac('sha256', fixture.signingSecret)
  .update(`${timestamp}.${body}`)
  .digest('hex');
const request = http.request(
  {
    hostname: 'probe-n8n',
    port: 5678,
    path: '/webhook/volitex-staging-account-1',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Chatwoot-Timestamp': timestamp,
      'X-Chatwoot-Delivery': randomUUID(),
      'X-Chatwoot-Signature': `sha256=${process.argv[2] === 'invalid' ? '0'.repeat(64) : signature}`,
    },
  },
  response => {
    response.resume();
    response.on('end', () => console.log(response.statusCode));
  }
);
request.setTimeout(60000, () =>
  request.destroy(new Error('synthetic probe timeout'))
);
request.on('error', error => {
  console.error(`Synthetic request failed: ${error.code || error.name}`);
  process.exit(1);
});
request.end(body);
