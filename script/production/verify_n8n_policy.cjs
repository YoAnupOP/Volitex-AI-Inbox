// Run inside the exact candidate image with runtime-policy.env and no network.
// Exercises n8n's real node loader; this is not a dependency scan or core-mailer clearance.
const assert = require('node:assert/strict');
const { createRequire } = require('node:module');

const fromN8n = createRequire('/usr/local/lib/node_modules/n8n/package.json');
const { Container } = fromN8n('@n8n/di');
const { ModuleRegistry } = fromN8n('@n8n/backend-common');
const { LoadNodesAndCredentials } = fromN8n(
  './dist/load-nodes-and-credentials'
);
const { NodeTypes } = fromN8n('./dist/node-types');
const {
  ForgotPasswordRequestDto,
  InviteUsersRequestDto,
  OwnerSetupRequestDto,
} = fromN8n('@n8n/api-types');

async function verify() {
  const email = 'operator@example.invalid';
  const owner = {
    email,
    firstName: 'Synthetic',
    lastName: 'Operator',
    password: 'Synthetic_Private1!',
  };
  assert.equal(ForgotPasswordRequestDto.safeParse({ email }).success, true);
  assert.equal(InviteUsersRequestDto.safeParse([{ email }]).success, true);
  assert.equal(OwnerSetupRequestDto.safeParse(owner).success, true);
  for (const address of [email + ',' + email, 'free text '.repeat(64)]) {
    assert.equal(
      ForgotPasswordRequestDto.safeParse({ email: address }).success,
      false
    );
    assert.equal(
      InviteUsersRequestDto.safeParse([{ email: address }]).success,
      false
    );
    assert.equal(
      OwnerSetupRequestDto.safeParse({ ...owner, email: address }).success,
      false
    );
  }
  assert.equal(
    ForgotPasswordRequestDto.safeParse({
      email: 'a'.repeat(256) + '@example.invalid',
    }).success,
    false
  );
  const allowed = JSON.parse(process.env.NODES_INCLUDE);
  assert.ok(Array.isArray(allowed) && allowed.length > 0);
  const modules = Container.get(ModuleRegistry);
  for (const name of ['source-control', 'promotions', 'community-packages']) {
    assert.ok(!modules.eligibleModules.includes(name), `${name} is enabled`);
  }

  const loader = Container.get(LoadNodesAndCredentials);
  await loader.init();
  const nodeTypes = Container.get(NodeTypes);
  const unexpected = Object.keys(loader.known.nodes).filter(
    type => !allowed.includes(type)
  );
  assert.deepEqual(
    unexpected,
    [],
    `Unexpected nodes loaded: ${unexpected.join(', ')}`
  );
  for (const type of allowed) {
    assert.ok(loader.isKnownNode(type), `Required node missing: ${type}`);
    assert.ok(
      nodeTypes.getByNameAndVersion(type),
      `Required node cannot load: ${type}`
    );
  }
  const gateway = nodeTypes.getByNameAndVersion(
    'CUSTOM.volitexReply'
  ).description;
  assert.equal(gateway.outputs.length, 2);
  const operation = gateway.properties.find(
    property => property.name === 'operation'
  );
  assert.equal(operation.default, 'authorize');
  assert.ok(operation.options.some(option => option.value === 'sendReply'));
  assert.equal(
    gateway.properties.find(property => property.name === 'content').required,
    true
  );
  for (const type of [
    'n8n-nodes-base.git',
    'n8n-nodes-base.ssh',
    'n8n-nodes-base.code',
    'n8n-nodes-base.executeCommand',
    'n8n-nodes-base.emailSend',
    'n8n-nodes-base.readWriteFile',
    'n8n-nodes-base.xml',
    'n8n-nodes-base.compression',
    'n8n-nodes-base.gitTool',
    'n8n-nodes-base.sshTool',
    'n8n-nodes-base.codeTool',
    'n8n-nodes-base.editImage',
    'n8n-nodes-base.editImageTool',
    'n8n-nodes-base.snowflake',
    'n8n-nodes-base.snowflakeTool',
    'n8n-nodes-base.kafka',
    'n8n-nodes-base.kafkaTrigger',
  ]) {
    assert.equal(loader.isKnownNode(type), false, `${type} remains available`);
    assert.throws(
      () => nodeTypes.getByNameAndVersion(type),
      undefined,
      `${type} can execute`
    );
  }
  const forbiddenImports = Object.keys(require.cache).filter(filename =>
    /\/node_modules\/(?:simple-git|@simple-git\/argv-parser|toml|snowflake-sdk|gm|showdown|markdown-it|element-plus|@langchain\/(?:mongodb|redis)|@confluentinc\/kafka-javascript)\//.test(
      filename
    )
  );
  assert.deepEqual(
    forbiddenImports,
    [],
    'Restricted nodes imported an excluded SDK'
  );
  console.log(
    JSON.stringify({
      result: 'PASS',
      allowedNodes: allowed.length,
      coreAddressShapes: 'PASS',
    })
  );
}

verify().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
