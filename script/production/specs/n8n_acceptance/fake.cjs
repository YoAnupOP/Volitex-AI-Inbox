// Loopback fake Meta and delayed Inbox response proxy. No external URL accepted.
const http = require('node:http');
const fs = require('node:fs');
let providerCalls = 0;
let apiPosts = 0;
let delayNextReply = false;
const respond = (res, status, body) => {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
};
http
  .createServer((req, res) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
    });
    req.on('end', () => {
      if (req.url === '/state')
        return respond(res, 200, { providerCalls, apiPosts });
      if (req.url === '/delay-next') {
        delayNextReply = true;
        return respond(res, 200, {});
      }
      if (req.url.startsWith('/meta/')) {
        if (req.url.includes('/phone_numbers'))
          return respond(res, 200, { data: [{ id: 'synthetic-phone' }] });
        if (
          req.url.includes('/messages') &&
          req.method === 'POST' &&
          JSON.parse(body).type === 'text'
        ) {
          providerCalls += 1;
          return respond(res, 200, {
            messages: [{ id: `synthetic-provider-${providerCalls}` }],
          });
        }
        return respond(res, 200, { data: [], success: true });
      }
      if (req.method === 'POST' && req.url.endsWith('/messages')) apiPosts += 1;
      // Fixed destination. Credentials are forwarded only to the disposable Inbox.
      const proxy = http.request(
        {
          hostname: 'probe-inbox',
          port: 3000,
          path: req.url,
          method: req.method,
          headers: { ...req.headers, host: 'probe-inbox:3000' },
        },
        upstream => {
          let result = '';
          upstream.on('data', chunk => {
            result += chunk;
          });
          upstream.on('end', () => {
            const delay =
              delayNextReply &&
              req.method === 'POST' &&
              req.url.endsWith('/messages') &&
              upstream.statusCode === 200;
            if (delay) {
              delayNextReply = false;
              fs.writeFileSync('/state/api-committed', 'yes');
            }
            setTimeout(
              () => {
                if (delay)
                  fs.writeFileSync('/state/api-response-released', 'yes');
                res.writeHead(upstream.statusCode, {
                  'Content-Type': 'application/json',
                });
                res.end(result);
              },
              delay ? 2500 : 0
            );
          });
        }
      );
      proxy.on('error', () =>
        respond(res, 502, { error: 'synthetic_upstream_unavailable' })
      );
      proxy.end(body);
    });
  })
  .listen(8080, '0.0.0.0');
