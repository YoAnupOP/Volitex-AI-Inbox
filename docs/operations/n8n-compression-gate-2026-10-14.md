# n8n compression denial-of-service release gate — 2026-10-14

## Decision

**PASS with a required ingress mitigation; the vulnerable dependency remains in the official n8n image.** Do not expose n8n except through the guarded Coolify Traefik route. This closes the identified unauthenticated compression path for the intended deployment; it does not patch the image or clear its other security findings.

## Evidence and upstream check

- Repository branch: `codex/whatsapp-interactive-quick-menus`.
- Source before this gate: `22ccdd1275c4d7f0e787dff8ec8d1e3794e65604`.
- Official latest stable release at verification: n8n `2.43.5`; the official stable branch CLI manifest also declares `compression: 1.8.1`. The exact stable image remains `n8nio/n8n@sha256:4fc4c67bf5fb990201a71d94c7070abf8dd0619cb8af1d059877a447f3640392`.
- The official n8n CLI setup installs `compression()` as common middleware before route authentication. A direct unauthenticated request with `Accept-Encoding: gzip` to the image returned HTTP 200 with gzip encoding.
- [GHSA-vc2v-76pw-4v95](https://github.com/advisories/GHSA-vc2v-76pw-4v95) / CVE-2026-87776 affects compression 1.8.1; 1.8.2 is the fixed release. No supported stable n8n release or official immutable image with the patched dependency was found during this check. Do not infer that the latest tag is fixed.

## Implemented mitigation

Traefik's documented Headers middleware overwrites the request `Accept-Encoding` header before proxying it to n8n. The request header is set to `identity`, causing n8n's `compression` middleware not to create a zlib response stream. This targets the vulnerable allocation path itself; it is not an authentication or rate-limit substitute.

- `deployment/n8n/traefik-compression-guard.yaml` defines `volitex-n8n-identity`.
- `deployment/n8n-queue.compose.yaml` attaches `volitex-n8n-identity@file` to the Coolify-generated routers for `n8n-main` using Coolify's documented Compose middleware shorthand.
- `n8n-main` exposes only its container port; it has no host `ports` mapping. Keep it that way. The worker is private and is not routed publicly. Do not add another route or listener that bypasses Traefik.

The file-provider middleware must be installed in Coolify at **Servers → server → Proxy → Dynamic Configurations** using the contents of `deployment/n8n/traefik-compression-guard.yaml`. Verify it appears without provider errors. Deploy the Compose service and inspect the generated n8n routers to confirm the identity middleware is attached to every router. This configuration has not been applied to a production Coolify server, which does not yet exist.

## Isolated regression test

Command:

```sh
node --test script/production/specs/n8n_compression_ingress.test.cjs
```

Result: **1 test passed, 0 failed**, against the exact official n8n 2.43.5 image digest above and Traefik `sha256:575fa15b135078fe5e50aa847987d96dbddd7b093c172429618404df73f3fa7c`.

The isolated test used disposable containers and a private backend network; only the proxy had a loopback-bound test port. It confirmed:

1. Direct backend positive control: HTTP 200 gzip response and one observed native compressor allocation.
2. Through Traefik: seven `Accept-Encoding` variants were overwritten; root and representative health/API/webhook paths returned without content encoding.
3. The unauthenticated workflow API remained HTTP 401 and an absent webhook remained HTTP 404.
4. Six bounded early client disconnects caused zero additional compressor allocations.
5. Restarting the proxy retained the behavior, and n8n had no host port binding.

No memory-exhaustion test, staging-data access, external webhook, or WhatsApp send was performed. Initial harness attempts exposed that Docker Desktop does not allow a host connection through an `--internal` network. The final test separates the private n8n network from a loopback-only proxy edge network; the successful result is from this corrected test topology.

## Residual risk and deployment conditions

The official image still contains the vulnerable library. The control is effective only while **all untrusted requests use the guarded Traefik route**. A direct host port, alternate proxy, unguarded router, or other network path would reopen the issue. Before onboarding a client, verify the deployed Coolify-generated router contains this middleware and repeat harmless tests with `Accept-Encoding: gzip` at the external route. Also confirm port 5678 is not publicly reachable directly. Restrict n8n administration to trusted operators.

The middleware disables compression negotiated by n8n for these proxied requests. No bandwidth or large-editor-asset performance benchmark was part of this gate. If a future supported official n8n image contains `compression >= 1.8.2`, replace the mitigation only after scanning and regression testing that exact digest.

Rollback: keep the middleware attached when reverting the n8n image. Removing the guard while returning to a vulnerable image reopens the release blocker. This change has no database migration or workflow-state effect.

## Authoritative references

- [n8n official releases](https://github.com/n8n-io/n8n/releases)
- [n8n official stable CLI manifest](https://github.com/n8n-io/n8n/blob/stable/packages/cli/package.json)
- [Coolify custom Traefik middleware](https://coolify.io/docs/core/networking/proxy/traefik/custom-middlewares)
- [Coolify Traefik dynamic configuration](https://coolify.io/docs/core/networking/proxy/traefik/dynamic-config)
- [Traefik Headers middleware](https://doc.traefik.io/traefik/v3.4/middlewares/http/headers/)
