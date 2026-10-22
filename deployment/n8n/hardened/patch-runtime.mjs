import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

const root = '/usr/local/lib/node_modules/n8n';
const updates = '/opt/security-updates/node_modules';
const replacements = {
  '@modelcontextprotocol/sdk': ['1.31.0', '1.32.0'],
  '@modelcontextprotocol/server': ['2.0.0', '2.3.0'],
  'follow-redirects': ['1.16.0', '1.16.1'],
  'markdown-it': ['13.0.2', '14.3.3'],
  'sanitize-html': ['2.17.7', '2.18.0'],
  '@simple-git/argv-parser': ['1.1.1', '2.0.1'],
  handlebars: ['4.7.9', '4.7.10'],
  nodemailer: ['8.0.10', '10.0.9'],
  hono: ['4.12.34', '4.13.11'],
  'ip-address': ['10.3.1', '10.7.1'],
  moment: ['2.30.1', '2.31.0'],
  multer: ['2.3.0', '2.4.0'],
  qs: ['6.15.2', '6.16.0'],
  'simple-git': ['3.36.0', '4.0.1'],
  toml: ['3.0.0', '4.2.0'],
};
const pristine = {
  'lib/parse.js':
    'e572166565f15fa6ad9865ae49d678218e32aabfd1b3720f6d0d43d39800d310',
  'lib/compile.js':
    'dc98f22eee3d511785d92a00758d5f0d48efed5f5813bdecc2de430c529b5c9f',
  'lib/expand.js':
    '41ccc196ebfa7b7781a634e721eb744e4e7bcb54cba427a7e3d6806a1b9e58f7',
  'lib/stringify.js':
    '379f22d77bfa1478341ccd49c5e4267464aabcbba03558bab332aac23fc6f23a',
};
const sha256 = data => createHash('sha256').update(data).digest('hex');
const manifest = { schema: 1, n8n: '2.44.4', replacements: [], backports: [] };
const packages = [];

function collect(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) collect(file);
    else if (entry.isFile() && entry.name === 'package.json') {
      const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
      if (
        pkg.name in replacements ||
        ['braces', 'stream-json'].includes(pkg.name)
      ) {
        packages.push({ directory, ...pkg });
      }
    }
  }
}

function replaceOnce(source, before, after) {
  assert.equal(
    source.split(before).length,
    2,
    `Patch anchor changed: ${before}`
  );
  return source.replace(before, after);
}

collect(root);
for (const [name, [previous, version]] of Object.entries(replacements)) {
  const installed = packages.filter(pkg => pkg.name === name);
  assert.ok(installed.length > 0, `Missing upstream dependency: ${name}`);
  const target = path.join(updates, name);
  assert.equal(
    JSON.parse(fs.readFileSync(path.join(target, 'package.json'))).version,
    version
  );
  for (const pkg of installed) {
    assert.equal(
      pkg.version,
      previous,
      `Review changed upstream dependency: ${name}`
    );
    assert.ok(pkg.directory.startsWith(root + '/node_modules/'));
    fs.rmSync(pkg.directory, { recursive: true });
    fs.symlinkSync(target, pkg.directory, 'dir');
    manifest.replacements.push({
      name,
      previous,
      version,
      directory: pkg.directory,
      target,
    });
  }
}

// Retain the upstream package version. The scanner finding remains visible;
// the release gate independently verifies this exact source backport.
for (const pkg of packages.filter(pkg => pkg.name === 'braces')) {
  assert.equal(pkg.version, '3.0.3');
  const files = {};
  for (const [relative, expected] of Object.entries(pristine)) {
    const file = path.join(pkg.directory, relative);
    let source = fs.readFileSync(file, 'utf8');
    assert.equal(
      sha256(source),
      expected,
      `Review changed upstream source: ${relative}`
    );
    if (relative === 'lib/parse.js') {
      const anchor = '      stack.push(block);';
      assert.equal(source.split(anchor).length, 3);
      source = source.replaceAll(
        anchor,
        "      if (stack.length >= 128) throw new SyntaxError('Brace AST depth exceeds 128');\n" +
          anchor
      );
    } else {
      const walker = relative === 'lib/stringify.js' ? 'stringify' : 'walk';
      source = replaceOnce(
        source,
        `const ${walker} = (node, parent = {}) => {`,
        `const ${walker} = (node, parent = {}, depth = 0) => {\n` +
          "    if (depth >= 128) throw new SyntaxError('Brace AST depth exceeds 128');"
      );
      const before =
        walker === 'stringify' ? 'stringify(child)' : 'walk(child, node)';
      source = replaceOnce(source, before, `${walker}(child, node, depth + 1)`);
    }
    fs.writeFileSync(file, source);
    files[relative] = {
      original_sha256: expected,
      patched_sha256: sha256(source),
    };
  }
  manifest.backports.push({
    name: 'braces',
    version: pkg.version,
    advisory: 'CVE-2026-93687',
    directory: pkg.directory,
    maximum_ast_depth: 128,
    files,
  });
}
for (const pkg of packages.filter(pkg => pkg.name === 'stream-json')) {
  assert.equal(pkg.version, '1.9.1');
  const file = path.join(pkg.directory, 'Assembler.js');
  let source = fs.readFileSync(file, 'utf8');
  const original =
    'a341b21d86a9c005e5433eadb6c33d4708d611c8bc624ee383463c0fb6d2e32b';
  assert.equal(sha256(source), original);
  const anchor = 'this.current[this.key] = value;';
  assert.equal(source.split(anchor).length, 3);
  source = source.replaceAll(
    anchor,
    "if (this.key === '__proto__') {\n" +
      '          Object.defineProperty(this.current, this.key, {value, writable: true, enumerable: true, configurable: true});\n' +
      '        } else {\n          this.current[this.key] = value;\n        }'
  );
  fs.writeFileSync(file, source);
  manifest.backports.push({
    name: 'stream-json',
    version: pkg.version,
    advisory: 'CVE-2026-104183',
    directory: pkg.directory,
    files: {
      'Assembler.js': {
        original_sha256: original,
        patched_sha256: sha256(source),
      },
    },
  });
}
assert.ok(manifest.backports.some(entry => entry.name === 'braces'));
assert.ok(manifest.backports.some(entry => entry.name === 'stream-json'));
fs.writeFileSync(
  '/opt/volitex/security/manifest.json',
  JSON.stringify(manifest, null, 2) + '\n'
);
