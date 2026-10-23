# Volitex AI Inbox — OSS account features and campaign defaults

Applies to releases containing the OSS account field implementation. Use a published immutable image whose exact source passed the required release gates; older images do not gain these changes by updating Compose alone.

## Account provisioning and editing

- Shipped defaults enable `campaigns` and `whatsapp_campaign`. A stored `ACCOUNT_LEVEL_FEATURE_DEFAULTS` remains the installation's explicit override, including disabled values. Existing installations retain that override during configuration reconciliation. Review it using the existing `bundle exec rake feature_defaults:toggle` task before expecting the new shipped default on an upgraded installation; do not reset unrelated defaults.
- New-account forms show the effective defaults. Account creation without a submitted feature form uses the same defaults in the model. Explicit selections, including all unchecked, take precedence; changing defaults does not update existing accounts.
- Super Admin account New/Edit/Show always includes features and the five stored limit keys. The feature form saves both bitset columns, rejects unknown flag names, and distinguishes an omitted form from an all-unchecked submission.
- These are original OSS Administrate fields. No Enterprise code is restored, no license checks are bypassed, and flags do not install missing Enterprise capabilities. Stored limits are enforced only where the installed OSS implementation supports them; the new fields do not add agent/inbox or Captain quota enforcement.

## Campaign workers and acceptance

- `config/sidekiq.yml` processes `campaigns` by default, after `mailers`, for ordinary single-worker setups.
- Production Compose retains its separately bounded `campaign-worker`. It sets `SIDEKIQ_SKIP_CAMPAIGNS=true` on the ordinary worker so campaigns do not consume the critical/inbound worker's capacity or gain its automation-network membership. Keep the matching Compose file and application image together.
- A feature flag does not launch a campaign or authorize live sends. Approved templates, recipient consent/opt-out, provider delivery reconciliation and the existing KVM queue/recovery/capacity acceptance checks remain required. Use the Super Admin account switches to hold unaccepted accounts disabled.

## Verification

Run `bundle exec rspec spec/requests/super_admin/account_provisioning_spec.rb spec/script/production/compose_spec.rb spec/models/account_spec.rb`. The campaign CI gate includes the provisioning requests after asset compilation; full CE remains a publication gate. Check actual built Super Admin assets in light/dark mode, including checkbox accents, keyboard focus, active navigation and chart contrast.

The custom Tailwind palette explicitly registers `zinc`; badges use supported green tokens. Theme variable blocks precede the form overrides so the existing contrast checks still inspect the correct dark palette. Fixtures for disabled mail and campaign behaviour and Platform API flags explicitly select their intended features instead of relying on an unconfigured account having none.

The October 23 CI security gate also required the narrowly scoped DOMPurify 3.4.16 → 3.4.17 patch for [GHSA-cg2g-xh64-v4q7](https://github.com/advisories/GHSA-cg2g-xh64-v4q7) and [GHSA-mrv2-3pqr-j5jr](https://github.com/advisories/GHSA-mrv2-3pqr-j5jr). Both direct and Vue plugin resolutions are locked to the patched version. `postcss-import` is declared directly at its already locked version because `postcss.config.js` requires it directly; builds must not rely on an accidental hoisted dependency. No audit suppression or gate bypass is included.
