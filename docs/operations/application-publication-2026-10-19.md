# Authorized application publication — 2026-10-19

## Decision and immutable deployment input

**PASS: publication and pull-back verification. Not authorization for deployment or client traffic.**

```dotenv
VOLITEX_IMAGE=ghcr.io/yoanupop/volitex-ai-inbox@sha256:a64c40f71683d2da9473bfed66d6531ff92e55539d29432ec75fc6950a89b5b4
```

Use this exact reference for migration, web, ordinary worker and campaign worker through the existing shared image variable. Campaign capability remains disabled pending its independent acceptance gates. No deployment, callback change, campaign enablement or live message was performed.

## Authorization, source and provenance

The founder explicitly authorized publication of source `66aa7305bf724823a7f9ac6a16488d81dcd583dd` to this GHCR repository, followed by pull/scan/boot verification. No source was substituted or modified.

- Delivery branch: `codex/integrated-release-candidate-reconcile-20261019`.
- Workflow dispatch ref: documentation HEAD `4a9dfa05fa1aaebbe6acb3574b5fceba16a22e0b`.
- Explicit checkout/build input and verified `/app/.git_sha`: **66aa7305bf724823a7f9ac6a16488d81dcd583dd**.
- [Publication workflow run39208999225](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39208999225): **success**. Exact SHA equality and three completed candidate gates checked before build. Existing full CE failures remain documented, not bypassed or described as green.
- Registry manifest digest: `sha256:a64c40f71683d2da9473bfed66d6531ff92e55539d29432ec75fc6950a89b5b4`.
- Manifest-referenced image configuration digest: `sha256:1cf264099259d2762e2581c5295e54f04ae8207b4f7cbac2001bfa4515a2542f`.
- Platform: linux/amd64. Source-SHA tag was used for publication; deployment must use digest above.
- This is a **new artifact**, different from prior ephemeral image configuration `sha256:eaa08f2941eeb40e346cdf7f4314df6eb235ebb44a6b7956aff44ac33e7b37d9`. It received full independent verification. No reproducible-byte claim is made: source fixes inputs, but base tags/package repositories are not fully frozen.
- Available provenance: guarded workflow log, explicit checkout/build argument, embedded source SHA, registry manifest/config association and matching pre-push/post-pull scans. **No signed source attestation was produced** by this workflow. Embedded SHA alone is not cryptographic source proof.
- Docker Desktop server29.8.0, WSL Ubuntu used for local pull-back testing. Docker containerd may display manifest digest as local image ID; configuration identity is taken from the registry manifest, not confused with manifest identity.

The workflow built once, booted/recovered and scanned it, then pushed that same local image without rebuilding. The local follow-up explicitly pulled and tested the immutable registry reference. No existing tag was deliberately promoted, no production image reference was changed, and no production service was touched.

## Executed checks

| Check | Result |
|---|---|
| Remote source/ancestry and clean task worktree | PASS before dispatch; documentation-only delta from authorized source |
| Required candidate/campaign/migration gates | PASS, checked by publishing workflow against source66 |
| Publication build + boot/recovery + scan + push | PASS in linked workflow; publication-evidence artifact contains pre-push scan and immutable-reference.txt |
| Registry manifest resolution and docker pull by digest | PASS locally; pull returned the exact expected digest |
| Embedded source SHA | PASS: exact authorized40-character SHA |
| Published-image scan | PASS: zero critical/high; details below |
| Published-image migration and web health | PASS in isolated disposable PostgreSQL/Redis environment |
| Ordinary worker and campaign worker | PASS, both from the same digest as web; correct queue heartbeat selectors verified |
| Database/Redis/schema/Sidekiq connectivity | PASS |
| Shared attachment persistence and PostgreSQL dump/restore | PASS |
| Restart and graceful shutdown | PASS for web and both workers |
| Production deployment / Coolify route / actual KVM reboot or alerts | NOT RUN, outside authorization |
| Live WhatsApp/Instagram / campaign | NOT RUN, outside authorization |

Commands (credentials are not required in their arguments):

```sh
gh workflow run publish_volitex_image.yml --repo YoAnupOP/Volitex-AI-Inbox --ref codex/integrated-release-candidate-reconcile-20261019 -f source_sha=66aa7305bf724823a7f9ac6a16488d81dcd583dd -f authorization=PUBLISH_CANDIDATE
docker pull ghcr.io/yoanupop/volitex-ai-inbox@sha256:a64c40f71683d2da9473bfed66d6531ff92e55539d29432ec75fc6950a89b5b4
docker buildx imagetools inspect "$VOLITEX_IMAGE" --raw
docker run --rm "$VOLITEX_IMAGE" cat /app/.git_sha
bash script/production/verify_candidate.sh "$VOLITEX_IMAGE" 66aa7305bf724823a7f9ac6a16488d81dcd583dd
```

Local execution supplied the digest directly and normalized CRLF in a temporary Bash stream; verifier source was unchanged from66. Unique disposable prefix `volitex-verify-publication39208999225local` isolated the test network, database and containers. Existing staging n8n services were preserved. The verifier retains its uniquely named test storage volume; no existing volumes were deleted. The local script exited0 with `PUBLISHED_DIGEST_VERIFICATION_PASS` after all checks.

## Actual published-artifact scan

Scanner: Trivy0.75.0, pinned image `aquasec/trivy@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa`, vulnerability scanner enabled; no severity suppression. Fresh vulnerability schema2 and Java schema1 databases downloaded locally. Database artifact fingerprints were not retained; comparisons below are advisory/component identities, not a frozen-DB claim.

- Pre-push scan timestamp: `2026-10-19T06:22:41.245645828Z`.
- Post-pull scan timestamp: `2026-10-19T06:35:26.069863867Z` (UTC; 12:05 IST).
- Both: **0 critical / 0 high / 2 medium / 1 low**.

| Advisory | Installed | Scanner fixed version | Severity | Disposition |
|---|---|---|---|---|
| CVE-2026-32700 | devise4.9.4 | >=5.0.3 | Medium | Existing backport/configuration disposition retained from candidate evidence; not claimed removed |
| CVE-2026-40295 | devise4.9.4 | >=5.0.4 | Medium | Existing unused-Timeoutable/configuration disposition retained; not claimed removed |
| CVE-2026-54696 | default json2.9.1 | >=2.19.9 | Low | Dormant default gem; active locked JSON2.21.2; not claimed removed |

No new finding identities between pre-push and pulled-image scans. n8n image and prior security dispositions were not changed by this application publication. Its mandatory identity ingress guard and trusted-operator restrictions remain deployment conditions, not a zero-finding claim.

Pre-push full scan is retained in the GitHub publication-evidence artifact. Local post-pull scan/logs/manifest are under the protected workstation temp evidence directory `volitex-publication-39208999225`; they are not a remote immutable evidence archive. Raw runtime logs are not committed. SHA256 checksums:

- pre-push image.json: `ba3421d505eb1271537d330954e6a62e4ff6d030c66aa8b88f768682f9cfe05e`
- pulled-image.json: `2ea09580cc81d880202e7a8fd194effa6d3847fd075329abc472c587c2b30717`
- pulled-verification.log: `5eebd540e2fc248c1b0863a1d8b2a46de8483a1e1d86d6c66ddb64336793fe0e`

## Remaining KVM acceptance before traffic

Follow the authoritative first-client runbook; publication does not certify the server:

1. Separate explicit deployment authorization. Configure protected application/encryption/n8n keys and operator credentials; retain recoverable off-server copies.
2. Set VOLITEX_IMAGE above for all application processes. Verify actual running digest and source marker. Configure private PostgreSQL/Valkey networking, persistent media/data, AOF/noeviction and bounded resources/logs.
3. Install the n8n Traefik identity middleware and verify every actual generated HTTPS router, TLS, trusted administration and no alternate public port/bypass. Main/worker use the same reviewed n8n digest and queue configuration.
4. Pre-migration backup, migration status and health checks; perform actual off-server database/media/n8n/key restore and server reboot recovery. Local disposable restore is not server acceptance.
5. Verify worker stopped/unhealthy alerts, external uptime and actual alert delivery. Verify tenant permissions/human ownership and each offered messaging channel with an explicitly approved smoke test.
6. Normal client traffic requires recorded server acceptance and authorization. Campaigns additionally require approved opted-in/template audience, actual delivery/status/opt-out reconciliation, unknown-outcome procedures and measured KVM load/recovery acceptance; keep the feature disabled until those pass.

No zero-downtime, exactly-once provider delivery or unmeasured production capacity promise is made.