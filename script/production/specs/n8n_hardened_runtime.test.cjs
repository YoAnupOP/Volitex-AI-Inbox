const assert = require('node:assert/strict');
const fs = require('node:fs');
const { createRequire } = require('node:module');
const { test } = require('node:test');
const { spawnSync } = require('node:child_process');

const root = '/usr/local/lib/node_modules/n8n';
const fromN8n = createRequire(root + '/package.json');
const manifest = JSON.parse(
  fs.readFileSync('/opt/volitex/security/manifest.json')
);

test('patched dependencies resolve from the actual n8n callers', () => {
  for (const [name, version] of Object.entries({
    handlebars: '4.7.10',
    nodemailer: '10.0.9',
    'simple-git': '4.0.1',
  })) {
    const directory = fs.realpathSync(root + '/node_modules/' + name);
    assert.ok(fromN8n.resolve(name).startsWith(directory + '/'));
    assert.equal(
      JSON.parse(fs.readFileSync(directory + '/package.json')).version,
      version
    );
  }
  const fromGit = createRequire(fromN8n.resolve('simple-git'));
  const parser = fromGit.resolve('@simple-git/argv-parser');
  assert.ok(parser.startsWith('/opt/security-updates/node_modules/'));
  assert.equal(
    require('/opt/security-updates/node_modules/@simple-git/argv-parser/package.json')
      .version,
    '2.0.1'
  );
});

test('patched Handlebars renders the core string-template contract', () => {
  const handlebars = fromN8n('handlebars');
  const render = handlebars.compile(
    '<p>{{name}} {{#if enabled}}ready{{/if}}</p>'
  );
  assert.equal(
    render({ name: '<operator>', enabled: true }),
    '<p>&lt;operator&gt; ready</p>'
  );
  assert.equal(handlebars.compile('{{value.constructor}}')({ value: {} }), '');
});

test('the actual core mailer composes email through patched Nodemailer', async () => {
  const { NodeMailer } = fromN8n('./dist/user-management/email/node-mailer.js');
  const nodemailer = fromN8n('nodemailer');
  const transport = nodemailer.createTransport({
    streamTransport: true,
    buffer: true,
  });
  const sender = Object.create(NodeMailer.prototype);
  let composed;
  sender.sender = 'operator@example.invalid';
  sender.transport = {
    sendMail: async options => {
      composed = await transport.sendMail(options);
      return composed;
    },
  };
  sender.logger = { debug() {}, error() {} };
  sender.errorReporter = {
    error(error) {
      throw error;
    },
  };
  await sender.sendMail({
    emailRecipients: 'recipient@example.invalid',
    subject: 'Synthetic core mail',
    body: '<p>Security update</p>',
  });
  assert.match(composed.message.toString(), /To: recipient@example.invalid/);
  assert.match(composed.message.toString(), /Subject: Synthetic core mail/);
  assert.match(composed.message.toString(), /Security update/);
});

test('updated Markdown handles ordinary text and adversarial reference definitions', () => {
  const result = spawnSync(
    process.execPath,
    [
      '-e',
      String.raw`const assert = require('node:assert/strict');
       const MarkdownIt = require('/opt/security-updates/node_modules/markdown-it');
       const md = new MarkdownIt({ typographer: true });
       assert.equal(md.render('[safe](https://example.invalid)'), '<p><a href="https://example.invalid">safe</a></p>\n');
       md.render('[a]: /u "' + 'x\n'.repeat(100000));
       md.render('"a '.repeat(32000) + "b' ".repeat(32000));`,
    ],
    { timeout: 5000, encoding: 'utf8' }
  );
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
});

test('patched TOML preserves the disabled SDK parser contract', () => {
  const toml = require('/opt/security-updates/node_modules/toml');
  assert.equal(toml.parse('[service]\nenabled = true\n').service.enabled, true);
});

for (const entry of manifest.backports.filter(item => item.name === 'braces')) {
  const braces = require(entry.directory);
  test('backported braces retains normal patterns and rejects deeply nested strings', () => {
    assert.deepEqual(braces.expand('client-{a,b}-{1..2}'), [
      'client-a-1',
      'client-a-2',
      'client-b-1',
      'client-b-2',
    ]);
    assert.equal(braces.compile('client-{a,b}'), 'client-(a|b)');
    assert.equal(
      braces.stringify(braces.parse('client-{a,b}')),
      'client-{a,b}'
    );
    const pattern = '{'.repeat(4000) + 'x' + '}'.repeat(4000);
    for (const method of ['parse', 'compile', 'expand', 'stringify']) {
      assert.throws(
        () => braces[method](pattern),
        error =>
          error instanceof SyntaxError &&
          /depth exceeds 128/.test(error.message)
      );
    }
    assert.throws(
      () => braces.compile('('.repeat(4000) + 'x' + ')'.repeat(4000)),
      error =>
        error instanceof SyntaxError && /depth exceeds 128/.test(error.message)
    );
  });
  test('direct AST calls cannot bypass the backported depth bound', () => {
    for (const method of ['compile', 'expand', 'stringify']) {
      let ast = { type: 'text', value: 'x' };
      for (let depth = 0; depth < 512; depth += 1) {
        ast = { type: 'brace', nodes: [ast] };
      }
      assert.throws(
        () => braces[method](ast),
        error =>
          error instanceof SyntaxError &&
          /depth exceeds 128/.test(error.message)
      );
    }
  });
}

test('streaming JSON assembler preserves __proto__ as data with and without a reviver', () => {
  const entry = manifest.backports.find(item => item.name === 'stream-json');
  const Assembler = require(entry.directory + '/Assembler');
  for (const options of [{}, { reviver: (_key, value) => value }]) {
    const assembler = new Assembler(options);
    assembler.startObject();
    assembler.keyValue('__proto__');
    assembler.startObject();
    assembler.keyValue('isAdmin');
    assembler.trueValue();
    assembler.endObject();
    assembler.endObject();
    assert.equal(Object.getPrototypeOf(assembler.current), Object.prototype);
    assert.equal(Object.hasOwn(assembler.current, '__proto__'), true);
    assert.equal(assembler.current.__proto__.isAdmin, true);
    assert.equal(assembler.current.isAdmin, undefined);
  }
});

test('the actual core flatted-data reader retains safe object prototypes', async () => {
  const path = require('node:path');
  const backend = path.dirname(
    fromN8n.resolve('@n8n/backend-common/package.json')
  );
  const { parseFlattedAsync } = require(
    backend + '/dist/utils/flatted-async.js'
  );
  const { stringify } = fromN8n('flatted');
  const input = JSON.parse('{"__proto__":{"isAdmin":true},"normal":"ok"}');
  const output = await parseFlattedAsync(stringify(input));
  assert.deepEqual(output, input);
  assert.equal(Object.getPrototypeOf(output), Object.prototype);
  assert.equal(output.isAdmin, undefined);
});
