// Explicit opt-in integration test: Docker required, no staging data or credentials.
// node --test script/production/specs/n8n_compression_ingress.test.cjs
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const http = require('node:http');
const net = require('node:net');

const n8n =
  'n8nio/n8n@sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392';
const traefik =
  'traefik@sha256:575fa15b135078fe5e50aa847987d96dbddd7b093c172429618404df73f3fa7c';
const docker = (...args) =>
  execFileSync('docker', args, { encoding: 'utf8', timeout: 120000 }).trim();
const delay = ms =>
  new Promise(resolve => {
    setTimeout(resolve, ms);
  });

function request(port, route, headers, abort, body) {
  const requestHeaders = headers || {};
  const shouldAbort = abort === true;
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port,
        path: route,
        method: body ? 'POST' : 'GET',
        headers: requestHeaders,
      },
      res => {
        let bytes = 0;
        res.on('data', chunk => {
          bytes += chunk.length;
          if (shouldAbort) {
            res.destroy();
            resolve({ status: res.statusCode, headers: res.headers, bytes });
          }
        });
        res.on('end', () =>
          resolve({ status: res.statusCode, headers: res.headers, bytes })
        );
        res.on('error', err => {
          if (!shouldAbort) reject(err);
        });
      }
    );
    req.setTimeout(5000, () => req.destroy(new Error('request timeout')));
    req.on('error', reject);
    req.end(body);
  });
}

async function availablePort() {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', resolve).on('error', reject);
  });
  const { port } = server.address();
  await new Promise(resolve => {
    server.close(resolve);
  });
  return port;
}

// Network probes must stay sequential so each disconnect is bounded and the
// compressor counter isolates only requests sent through the guarded proxy.
/* eslint-disable no-await-in-loop, no-restricted-syntax */
test(
  'Traefik identity guard prevents compressor allocation in the exact n8n image',
  { timeout: 180000 },
  async t => {
    const prefix = `volitex-compression-${process.pid}-${Date.now()}`;
    const backend = `${prefix}-backend`;
    const proxy = `${prefix}-proxy`;
    const edge = `${prefix}-edge`;
    const scratch = fs.mkdtempSync(
      path.join(os.tmpdir(), 'volitex-compression-')
    );
    const created = [];
    let network = false;
    let edgeNetwork = false;
    const count = () =>
      Number(docker('exec', backend, 'cat', '/tmp/volitex-compressor-count'));
    try {
      fs.copyFileSync(
        path.resolve('deployment/n8n/traefik-compression-guard.yaml'),
        path.join(scratch, 'guard.yaml')
      );
      fs.writeFileSync(
        path.join(scratch, 'routes.yaml'),
        `http:
  routers:
    n8n:
      rule: PathPrefix(\x60/\x60)
      entryPoints: [web]
      middlewares: [volitex-n8n-identity]
      service: n8n
  services:
    n8n:
      loadBalancer:
        servers:
          - url: http://${backend}:5678
`
      );
      docker('network', 'create', '--internal', prefix);
      network = true;
      docker('network', 'create', edge);
      edgeNetwork = true;
      const port = await availablePort();
      docker(
        'run',
        '-d',
        '--name',
        backend,
        '--network',
        prefix,
        '--memory',
        '768m',
        '--pids-limit',
        '256',
        '--tmpfs',
        '/home/node/.n8n:uid=1000,gid=1000,mode=0700',
        '--mount',
        `type=bind,src=${path.resolve('script/production/specs/n8n_compression_probe.cjs')},dst=/probe.cjs,readonly`,
        '-e',
        'NODE_OPTIONS=--require=/probe.cjs',
        '-e',
        'N8N_DIAGNOSTICS_ENABLED=false',
        '-e',
        'N8N_VERSION_NOTIFICATIONS_ENABLED=false',
        '-e',
        'N8N_TEMPLATES_ENABLED=false',
        '-e',
        'N8N_SECURE_COOKIE=false',
        n8n,
        'start'
      );
      created.push(backend);
      docker(
        'run',
        '-d',
        '--name',
        proxy,
        '--network',
        edge,
        '--memory',
        '128m',
        '--pids-limit',
        '128',
        '-p',
        `127.0.0.1:${port}:8080`,
        '--mount',
        `type=bind,src=${scratch},dst=/dynamic,readonly`,
        traefik,
        '--entrypoints.web.address=:8080',
        '--providers.file.directory=/dynamic',
        '--log.level=ERROR'
      );
      created.push(proxy);
      docker('network', 'connect', prefix, proxy);
      let ready = false;
      let readiness = 'no response';
      for (let attempt = 0; attempt < 60; attempt += 1) {
        try {
          const response = await request(port, '/healthz/readiness');
          readiness = `${response.status} ${response.headers['content-type'] || ''}`;
          ready = response.status === 200;
        } catch (error) {
          readiness = error.code || error.message;
        }
        if (ready) break;
        await delay(1000);
      }
      if (!ready) {
        t.diagnostic(`last proxied readiness response: ${readiness}`);
        t.diagnostic(
          `direct readiness response: ${docker(
            'exec',
            '-e',
            'NODE_OPTIONS=',
            backend,
            'node',
            '-e',
            `
        require('http').get('http://127.0.0.1:5678/healthz/readiness', r=>{r.resume();r.on('end',()=>console.log(r.statusCode))}).on('error',e=>{console.error(e.message);process.exit(1)});`
          )}`
        );
        t.diagnostic(
          `backend startup logs:\n${docker('logs', backend).slice(-6000)}`
        );
        t.diagnostic(
          `proxy startup logs:\n${docker('logs', proxy).slice(-3000)}`
        );
      }
      assert.ok(ready, 'isolated n8n boot/readiness');
      // Positive control from INSIDE the isolated backend. No published bypass port.
      const direct = JSON.parse(
        docker(
          'exec',
          '-e',
          'NODE_OPTIONS=',
          backend,
          'node',
          '-e',
          `
      require('http').get({host:'127.0.0.1',port:5678,path:'/',headers:{'Accept-Encoding':'gzip'}}, r=>{
        r.resume();r.on('end',()=>console.log(JSON.stringify({status:r.statusCode,encoding:r.headers['content-encoding']})));
      }).on('error',()=>process.exit(1));`
        )
      );
      assert.equal(direct.status, 200);
      assert.equal(direct.encoding, 'gzip');
      const baseline = count();
      assert.ok(
        baseline > 0,
        'instrumentation detects the unguarded compressor'
      );
      const encodings = [
        'gzip',
        'br',
        'deflate',
        '*',
        'gzip, deflate, br',
        'identity;q=0, *;q=1',
        ['gzip', 'br'],
      ];
      for (const encoding of encodings) {
        const response = await request(port, '/', {
          'Accept-Encoding': encoding,
        });
        assert.equal(response.status, 200);
        assert.equal(response.headers['content-encoding'], undefined);
        assert.ok(
          response.bytes > 1024,
          'response exceeds compression threshold'
        );
      }
      for (const route of [
        '/healthz/readiness',
        '/rest/settings',
        '/rest/workflows',
        '/webhook/missing-probe',
      ]) {
        const response = await request(port, route, {
          'aCcEpT-EnCoDiNg': 'gzip',
        });
        assert.ok(
          response.status < 500,
          `${route}: not a proxy/server failure`
        );
        assert.equal(response.headers['content-encoding'], undefined);
      }
      const denied = await request(port, '/rest/workflows', {
        'Accept-Encoding': 'gzip',
      });
      assert.equal(
        denied.status,
        401,
        'existing API authentication remains enforced'
      );
      const absentWebhook = await request(
        port,
        '/webhook/missing-probe',
        {
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json',
        },
        false,
        '{"synthetic":true}'
      );
      assert.equal(absentWebhook.status, 404);
      // Six bounded early closes, only against this disposable guarded instance.
      for (let i = 0; i < 6; i += 1) {
        await request(port, '/', { 'Accept-Encoding': 'gzip, br' }, true);
      }
      assert.equal(
        count(),
        baseline,
        'zero compressor allocations for all guarded requests'
      );
      docker('restart', proxy);
      await delay(2000);
      assert.equal(
        (await request(port, '/', { 'Accept-Encoding': 'gzip' })).headers[
          'content-encoding'
        ],
        undefined
      );
      assert.equal(count(), baseline, 'guard persists after proxy restart');
      const ports = JSON.parse(
        docker(
          'inspect',
          '--format',
          '{{json .HostConfig.PortBindings}}',
          backend
        )
      );
      assert.ok(
        !ports || Object.keys(ports).length === 0,
        'backend has no host port'
      );
      t.diagnostic(
        `PASS: exact image boot; positive gzip control=${baseline}; 7 encoding variants; 4 route classes; auth 401; webhook 404; 6 early closes; restart; zero guarded compressor allocations; no backend port`
      );
    } finally {
      // Only resources created by THIS invocation; no named volumes or staging data.
      for (const name of created.reverse()) docker('rm', '-f', name);
      if (network) docker('network', 'rm', prefix);
      if (edgeNetwork) docker('network', 'rm', edge);
      fs.rmSync(scratch, { recursive: true, force: true });
    }
  }
);
/* eslint-enable no-await-in-loop, no-restricted-syntax */
