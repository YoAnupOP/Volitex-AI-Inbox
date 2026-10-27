const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

test('n8n audit gate resolves only the exact verified backport and fails closed', () => {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'volitex-n8n-audit-'));
  const source = 'a'.repeat(40);
  const image = 'volitex-n8n:' + source;
  const directory =
    '/usr/local/lib/node_modules/n8n/node_modules/.pnpm/braces@3.0.3/node_modules/braces';
  const verification = {
    status: 'PASS',
    source_sha: source,
    backports: [{ advisory: 'CVE-2026-93687', directory }],
  };
  const finding = {
    VulnerabilityID: 'CVE-2026-93687',
    PkgName: 'braces',
    InstalledVersion: '3.0.3',
    Severity: 'HIGH',
    PkgPath: directory.slice(1) + '/package.json',
  };
  const zodDirectory =
    '/usr/local/lib/node_modules/n8n/node_modules/.pnpm/zod@3.25.76/node_modules/zod';
  const zodFinding = {
    ...finding,
    VulnerabilityID: 'CVE-2023-54404',
    PkgName: 'zod',
    InstalledVersion: '3.25.76',
    PkgPath: zodDirectory.slice(1) + '/package.json',
  };
  const zodVerification = {
    ...verification,
    backports: [
      {
        advisory: 'CVE-2023-54404',
        directory: zodDirectory,
        scope: 'constrained-container-early-exit-v3-v4-cjs-esm',
      },
    ],
  };
  const cases = [
    { label: 'verified patch', finding, expected: 0 },
    {
      label: 'unknown advisory',
      finding: { ...finding, VulnerabilityID: 'CVE-UNKNOWN' },
      expected: 1,
    },
    {
      label: 'critical is never waived',
      finding: { ...finding, Severity: 'CRITICAL' },
      expected: 1,
    },
    {
      label: 'unverified duplicate',
      finding: { ...finding, PkgPath: 'other/braces/package.json' },
      expected: 1,
    },
    {
      label: 'changed package',
      finding: { ...finding, PkgName: 'other' },
      expected: 1,
    },
    {
      label: 'changed version',
      finding: { ...finding, InstalledVersion: '3.0.2' },
      expected: 1,
    },
    { label: 'wrong source', finding, source: 'b'.repeat(40), expected: 1 },
    { label: 'wrong image', finding, image: 'other-image', expected: 1 },
    { label: 'failed verifier', finding, status: 'FAIL', expected: 1 },
    {
      label: 'verified constrained Zod patch',
      finding: zodFinding,
      verification: zodVerification,
      expected: 0,
    },
    {
      label: 'Zod without the verified scope',
      finding: zodFinding,
      expected: 1,
    },
    {
      label: 'unverified Zod duplicate',
      finding: { ...zodFinding, PkgPath: 'other/zod/package.json' },
      verification: zodVerification,
      expected: 1,
    },
    {
      label: 'Zod critical is never waived',
      finding: { ...zodFinding, Severity: 'CRITICAL' },
      verification: zodVerification,
      expected: 1,
    },
    {
      label: 'other Zod advisory remains blocked',
      finding: { ...zodFinding, VulnerabilityID: 'CVE-UNKNOWN' },
      verification: zodVerification,
      expected: 1,
    },
  ];
  try {
    for (const entry of cases) {
      fs.writeFileSync(
        path.join(scratch, 'report.json'),
        JSON.stringify({
          ArtifactName: image,
          Results: [{ Type: 'node-pkg', Vulnerabilities: [entry.finding] }],
        })
      );
      fs.writeFileSync(
        path.join(scratch, 'verification.json'),
        JSON.stringify({
          ...(entry.verification || verification),
          status: entry.status || 'PASS',
        })
      );
      const result = spawnSync(
        process.execPath,
        [
          path.resolve('script/production/audit_n8n_runtime.mjs'),
          path.join(scratch, 'report.json'),
          path.join(scratch, 'verification.json'),
          path.join(scratch, 'summary.json'),
          entry.source || source,
          entry.image || image,
        ],
        { encoding: 'utf8' }
      );
      assert.equal(
        result.status,
        entry.expected,
        entry.label + ': ' + result.stderr
      );
    }
  } finally {
    assert.equal(path.dirname(scratch), os.tmpdir());
    for (const file of fs.readdirSync(scratch))
      fs.unlinkSync(path.join(scratch, file));
    fs.rmdirSync(scratch);
  }
});
