# Shared checkout and verified image releases — 2026-10-20

## Canonical workspace

Use `C:/Users/Anup/Desktop/Volitex-AI-Inbox` on `master` across Codex chats. The founder explicitly requested this workflow. AGENTS.md replaces the former per-task worktree instruction with shared-checkout ownership, an atomic local writer lock and normal master commit/push handling. Multiple chats may read; only the current lock owner writes. New chats should use the Local project checkout. An explicitly selected app Worktree environment can create a directory before the agent reads repository instructions; that is separate from the agent's no-new-worktree policy.

The repository now has one registered checkout, reduced from fourteen. Eleven extra checkout heads were already ancestors of the selected integrated source 9b4f13379d1050ba6297861bb4feb00727a6e157. Two divergent detached histories are retained in local archive branches (`codex/archive-n8n-readiness-20261019` and `codex/archive-kilo-baseline-20261019`); they were not blindly merged into the validated candidate.

## Recovery preservation

The original primary checkout's staged and unstaged edits were preserved in a named local stash and private patches before fast-forwarding master. They included older dependency/configuration reversions and removals of operational scripts; those stale changes were not reapplied over the newer integrated implementation. The older untracked workflow is preserved privately, while the current custom-node contract remains canonical. The founder context file remains available locally and is excluded from Git and Docker build contexts.

Recovery material is outside tracked source at `C:/Users/Anup/.codex/backups/volitex-consolidation-20261019-2b5c8516`. It includes a verified self-contained Git bundle, original index/patches, untracked files, local setup files and frozen checkout directories. Some Windows dependency links prevented complete recursive checkout removal; the remaining directories were moved into that recovery archive and their obsolete Git worktree registrations pruned. This preserves recovery and does not claim that all dependency-cache disk space was reclaimed.

## Local runtime references

Before removing checkout paths, the existing local n8n staging worker's custom-node files were copied with matching byte hashes into its private runtime directory. The service was recreated with the same image, command and environment; main, PostgreSQL and Valkey were not replaced. Worker readiness passed after relocation. Its Compose snapshot and custom files are under `/home/anup/.codex/runtimes/volitex-n8n-local-staging-20261013/consolidated/`.

The synthetic node preview was moved to a persistent preview volume and a read-only custom-node mount from the canonical checkout. Its owner/workflow data was retained and readiness passed after relocation. These were local preview/staging operations on October 19, not a production upgrade or client rollout.

## Release ownership

Master pushes run the existing candidate, migration and campaign gates. The publication workflow listens for successful master gate completions and requires all three latest exact-source workflow runs to be successful. A missing, pending or failed gate prevents publication; a manual dispatch without green gates fails.

Publication is restricted to this repository's trusted master events or the explicitly authorized manual workflow. It checks out the exact source SHA, serializes publication per SHA, reuses an existing exact-source image, and otherwise builds, verifies production boot/recovery, scans and publishes the same image. Critical/high application scan findings block publication. The registry image's embedded source marker is checked against the selected commit, and an immutable reference is saved in the publication-evidence artifact. Only the current master source may update the convenience `master` image tag. Production deployment must use an immutable digest.

This is image publication only. No VPS deployment, credential installation, client-provider acceptance or unconditional production-readiness claim follows from a successful publication. Baseline full-suite/lint failures documented in earlier readiness reports are not relabeled green by these focused gates.

## Verification at consolidation

Git confirms one registered checkout and preserved archive refs. The workflow YAML and shell syntax are inspected before commit. Existing application acceptance/security evidence remains in the readiness reports. The new master workflow run and registry publication must be checked after push; queued/running jobs are not reported as published images.

## Publication confirmed — October 20

The repository default branch was still `develop`, so the publisher's new `workflow_run` trigger on master was not being loaded from the default branch. The default branch is now `master`. The first publication was explicitly dispatched after all three exact-source gates passed.

[Publication run 39383998421](https://github.com/YoAnupOP/Volitex-AI-Inbox/actions/runs/39383998421) completed successfully for source `a807ca9e159027f5857f21ed195d1dd92a5cb637`. It built, verified, scanned and pushed the application, then checked the registry image's embedded source marker. Verified immutable reference:

```text
ghcr.io/yoanupop/volitex-ai-inbox@sha256:e43de8261c311ca31eea2ba656fba6b62643f846cacdea9540090677c68d42f6
```

This confirms publication of that source, not later naming edits. Full CE CI remains failed. The restricted n8n profile retains the dependency findings recorded in its assessment; the application's publication scan does not scan or clear the separate n8n image. Actual KVM deployment, complete off-server restore, reboot/recovery, alert delivery, capacity measurement and client calendar/CRM/channel acceptance remain outstanding. A single KVM remains a shared outage domain with no automatic high availability.
