import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

const root = '/usr/local/lib/node_modules/n8n';
const custom = {
  'VolitexReply.node.js':
    'd2dc164a4f8a21fd2a6afbdb447ba5ea178d64b8b94557975051c46d290a6af3',
  'VolitexInbox.credentials.js':
    '71c10dfa6f679f59e04083bfb7f4709c614a53629d7e76e3f362e7594bf02119',
};
for (const [file, expected] of Object.entries(custom)) {
  const actual = createHash('sha256')
    .update(fs.readFileSync('/opt/volitex/n8n-custom/' + file))
    .digest('hex');
  assert.equal(actual, expected, `Unverified custom extension: ${file}`);
}
const manifest = JSON.parse(
  fs.readFileSync('/opt/volitex/security/manifest.json', 'utf8')
);
const versions = {
  '@modelcontextprotocol/sdk': '1.32.0',
  '@modelcontextprotocol/server': '2.3.0',
  'follow-redirects': '1.16.1',
  'markdown-it': '14.3.3',
  'sanitize-html': '2.18.0',
  '@simple-git/argv-parser': '2.0.1',
  handlebars: '4.7.10',
  nodemailer: '10.0.9',
  hono: '4.13.11',
  'ip-address': '10.7.1',
  moment: '2.31.0',
  multer: '2.4.0',
  qs: '6.16.0',
  'simple-git': '4.0.1',
  toml: '4.2.0',
};
const hashes = {
  'lib/parse.js':
    'd7413826544cb3220fe6b71c869e19389c7512f5f7ab88f0b7103a4181e186dc',
  'lib/compile.js':
    '241abdb96b50441861578406e2e013484dfe6dfe27d53c3339b79b421ff2e36a',
  'lib/expand.js':
    '961bc3e6de55fdfe2e4d8d520f33c2f50b27910a591a5438b684c800991deefa',
  'lib/stringify.js':
    'f63dbf849bc5eeda6548ca8eff788f211221dde68c395105f6422473893e4ecd',
};
assert.equal(manifest.schema, 1);
assert.equal(
  JSON.parse(fs.readFileSync(root + '/package.json')).version,
  '2.44.4'
);
for (const [name, version] of Object.entries(versions)) {
  const entries = manifest.replacements.filter(entry => entry.name === name);
  assert.ok(entries.length > 0);
  for (const entry of entries) {
    assert.ok(entry.directory.startsWith(root + '/node_modules/'));
    assert.equal(
      fs.realpathSync(entry.directory),
      '/opt/security-updates/node_modules/' + name
    );
    const pkg = JSON.parse(
      fs.readFileSync(path.join(entry.directory, 'package.json'))
    );
    assert.equal(pkg.name, name);
    assert.equal(pkg.version, version);
  }
}
assert.ok(manifest.backports.some(entry => entry.name === 'braces'));
assert.ok(manifest.backports.some(entry => entry.name === 'stream-json'));
const streamHashes = {
  'Assembler.js':
    '7de02a8bace37fdaf740263c3dc8c0497c114c1c9a5c1096f3998dfbc94bb744',
};
for (const entry of manifest.backports) {
  assert.ok(['braces', 'stream-json'].includes(entry.name));
  const isBraces = entry.name === 'braces';
  assert.equal(entry.version, isBraces ? '3.0.3' : '1.9.1');
  assert.equal(entry.advisory, isBraces ? 'CVE-2026-93687' : 'CVE-2026-104183');
  assert.ok(entry.directory.startsWith(root + '/node_modules/'));
  for (const [file, expected] of Object.entries(
    isBraces ? hashes : streamHashes
  )) {
    const actual = createHash('sha256')
      .update(fs.readFileSync(path.join(entry.directory, file)))
      .digest('hex');
    assert.equal(actual, expected, `Unverified backport: ${file}`);
    assert.equal(entry.files[file].patched_sha256, expected);
  }
}
console.log(
  JSON.stringify({
    status: 'PASS',
    source_sha: fs.readFileSync('/opt/volitex/security/source-sha', 'utf8'),
    replacements: versions,
    backports: manifest.backports.map(entry => ({
      advisory: entry.advisory,
      directory: entry.directory,
    })),
  })
);
