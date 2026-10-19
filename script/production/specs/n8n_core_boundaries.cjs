// Run inside the exact official n8n image with --network none.
// These caller-specific checks do not clear every bundled node or dependency.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

const root = '/usr/local/lib/node_modules/n8n';
const source = relative => fs.readFileSync(path.join(root, relative), 'utf8');

test('core email templates are read as UTF-8 strings, not caller-provided ASTs', () => {
  const mailer = source('dist/user-management/email/user-management-mailer.js');
  assert.match(mailer, /readFile\)\(templatePath, 'utf-8'\)/);
  assert.match(mailer, /handlebars_1\.default\.compile\(markup\)/);
  const engine = source('dist/utils/handlebars.util.js');
  assert.doesNotMatch(engine, /allowProtoMethodsByDefault/);
});

test('core mail sender does not forward caller raw or attachment options', async () => {
  const { NodeMailer } = require(
    path.join(root, 'dist/user-management/email/node-mailer.js')
  );
  let captured;
  const sender = Object.create(NodeMailer.prototype);
  sender.sender = 'synthetic@example.invalid';
  sender.transport = {
    sendMail: async options => {
      captured = options;
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
    subject: 'bounded synthetic probe',
    body: '<p>synthetic</p>',
    raw: { path: 'file:///must-not-be-read' },
    attachments: [{ path: 'file:///must-not-be-read' }],
  });
  assert.equal(captured.raw, undefined);
  assert.equal(captured.attachments.length, 1);
  assert.equal(captured.attachments[0].filename, 'n8n-logo.png');
  assert.equal(captured.to, 'recipient@example.invalid');
});

test('Git and SSH nodes remain installed: safe smoke workflow cannot clear them', () => {
  for (const node of ['Git/Git.node.js', 'Ssh/Ssh.node.js']) {
    assert.equal(
      fs.existsSync(
        path.join(root, 'node_modules/n8n-nodes-base/dist/nodes', node)
      ),
      true
    );
  }
});
