// Preserve the raw scanner report. Only the independently verified source
// backport below can resolve a retained scanner finding; no severity overrides.
import fs from 'node:fs';
import assert from 'node:assert/strict';

const [reportFile, verificationFile, outputFile, sourceSha, image] =
  process.argv.slice(2);
const report = JSON.parse(fs.readFileSync(reportFile));
const verification = JSON.parse(fs.readFileSync(verificationFile));
assert.equal(verification.status, 'PASS');
assert.match(sourceSha, /^[a-f0-9]{40}$/);
assert.equal(verification.source_sha, sourceSha);
assert.equal(report.ArtifactName, image);
const resolved = [];
const unresolved = [];
const lowerSeverity = [];
for (const result of report.Results) {
  for (const finding of result.Vulnerabilities || []) {
    const backport = verification.backports.find(
      entry =>
        entry.advisory === finding.VulnerabilityID &&
        finding.PkgPath === entry.directory.slice(1) + '/package.json'
    );
    const knownBackport =
      (finding.PkgName === 'braces' &&
        finding.InstalledVersion === '3.0.3' &&
        finding.Severity === 'HIGH') ||
      (finding.PkgName === 'stream-json' &&
        finding.InstalledVersion === '1.9.1' &&
        finding.VulnerabilityID === 'CVE-2026-104183' &&
        finding.Severity === 'MEDIUM');
    if (result.Type === 'node-pkg' && knownBackport && backport) {
      resolved.push({
        ...finding,
        resolution: 'source-backport-verified',
        verification:
          'verify-runtime.mjs exact source hashes and CI regression tests',
      });
    } else if (['CRITICAL', 'HIGH'].includes(finding.Severity)) {
      unresolved.push(finding);
    } else {
      lowerSeverity.push(finding);
    }
  }
}
const summary = {
  image: report.ArtifactName,
  unresolved_critical_high: unresolved,
  verified_backports: resolved,
  retained_lower_severity: lowerSeverity,
  status: unresolved.length ? 'FAIL' : 'PASS',
};
fs.writeFileSync(outputFile, JSON.stringify(summary, null, 2) + '\n');
console.log(
  JSON.stringify({
    status: summary.status,
    unresolved: unresolved.length,
    verifiedBackports: resolved.length,
  })
);
assert.equal(
  unresolved.length,
  0,
  'Unresolved n8n critical/high findings block publication'
);
