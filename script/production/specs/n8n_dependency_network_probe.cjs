// Isolated child process: an uncaught decoder error must fail this probe.
// Only loopback servers and synthetic payloads; no provider credentials.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const zlib = require('node:zlib');
const manifest = JSON.parse(
  fs.readFileSync('/opt/volitex/security/manifest.json')
);
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

async function probe() {
  for (const entry of manifest.replacements.filter(
    item => item.name === 'body-parser'
  )) {
    const parse = require(entry.directory).json();
    const server = http.createServer((req, res) => {
      parse(req, res, error => {
        res.statusCode = error ? 400 : 200;
        res.end('ok');
      });
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    try {
      await new Promise((resolve, reject) => {
        const request = http.request(
          {
            host: '127.0.0.1',
            port: server.address().port,
            method: 'POST',
            headers: {
              'content-type': 'application/json',
              'content-encoding': 'gzip',
            },
          },
          response => {
            response.resume();
            response.on('end', resolve);
          }
        );
        request.on('error', reject);
        request.write(zlib.gzipSync('{"ok":true}'));
        setTimeout(
          () => request.end(Buffer.from('invalid trailing frame')),
          20
        );
      });
      await delay(50);
      const response = await fetch(
        `http://127.0.0.1:${server.address().port}/healthy`
      );
      assert.equal(response.status, 200);
      await response.text();
    } finally {
      server.closeAllConnections();
      await new Promise(resolve => server.close(resolve));
    }
  }
  for (const entry of manifest.replacements.filter(
    item => item.name === 'undici'
  )) {
    const client = require(entry.directory);
    const server = http.createServer((req, res) => {
      if (req.url === '/malicious') {
        res.writeHead(200, {
          'content-encoding': Array(6).fill('gzip').join(', '),
          'content-length': '100',
        });
        res.flushHeaders();
        const socket = res.socket;
        setTimeout(() => socket.end(), 20);
      } else res.end('healthy');
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const url = `http://127.0.0.1:${server.address().port}`;
    try {
      await assert.rejects(client.fetch(url + '/malicious'), error => {
        assert.match(String(error.cause?.message), /encoding|coding/i);
        return true;
      });
      await delay(50);
      assert.equal(
        await (await client.fetch(url + '/healthy')).text(),
        'healthy'
      );
    } finally {
      server.closeAllConnections();
      await new Promise(resolve => server.close(resolve));
    }
  }
  const entry = manifest.replacements.find(item => item.name === 'multer');
  let removed = 0;
  const upload = require(entry.directory)({
    storage: {
      _handleFile(_req, file, callback) {
        file.stream.resume();
        callback(new Error('synthetic storage failure'));
      },
      _removeFile(_req, _file, callback) {
        removed += 1;
        callback();
      },
    },
  }).single('file');
  const server = http.createServer((req, res) => {
    upload(req, res, error => {
      res.statusCode = error ? 400 : 200;
      res.end('finished');
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const body =
      '--probe\r\nContent-Disposition: form-data; name="file"; filename="synthetic.txt"\r\nContent-Type: text/plain\r\n\r\nsynthetic\r\n--probe--\r\n';
    const response = await fetch(`http://127.0.0.1:${server.address().port}`, {
      method: 'POST',
      headers: { 'content-type': 'multipart/form-data; boundary=probe' },
      body,
    });
    assert.equal(response.status, 400);
    assert.equal(await response.text(), 'finished');
    assert.equal(removed, 0, 'failed uploads must not enter storage cleanup');
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
probe().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
