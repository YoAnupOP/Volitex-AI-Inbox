# Chatwoot Development Guidelines

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Seed Local Test Data**: `bundle exec rails db:seed` (quickly populates minimal data for standard feature verification)
- **Seed Search Test Data**: `bundle exec rails search:setup_test_data` (bulk fixture generation for search/performance/manual load scenarios)
- **Seed Account Sample Data (richer test data)**: `Seeders::AccountSeeder` is available as an internal utility and is exposed through Super Admin `Accounts#seed`, but can be used directly in dev workflows too:
  - UI path: Super Admin → Accounts → Seed (enqueues `Internal::SeedAccountJob`).
  - CLI path: `bundle exec rails runner "Internal::SeedAccountJob.perform_now(Account.find(<id>))"` (or call `Seeders::AccountSeeder.new(account: Account.find(<id>)).perform!` directly).
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:  
  - Do not write custom CSS  
  - Do not use scoped CSS  
  - Do not use inline styles  
  - Always use Tailwind utility classes  
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- Prefer the smallest production-ready change that solves the current problem.
- Build for the expected production path first. Do not add speculative guards, fallbacks, retries, or edge-case handling unless the caller can actually hit that case or production has proven it necessary.
- When an impossible or misconfigured state would indicate a setup/deployment bug, let it fail loudly instead of silently skipping behavior.
- For locked/internal configs that must exist in production, prefer direct reads (`find`, `find_by!`, required hash keys) over silent fallbacks.
- Do not add validation or response checks unless the code uses the result or the check changes behavior meaningfully.
- Prefer existing repo dependencies/client libraries over hand-rolled protocol code for auth, signing, parsing, or API plumbing.
- Avoid one-use private helpers unless they hide real complexity or make the main flow meaningfully easier to read.
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- In specs, avoid custom helper methods for setup/data. Prefer `let` values and direct per-example setup; only add a helper when it removes meaningful repeated complexity.
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
- Prefer `with_modified_env` (from spec helpers) over stubbing `ENV` directly in specs
- Specs in parallel/reloading environments: prefer comparing `error.class.name` over constant class equality when asserting raised errors

## Root-Cause Fix Policy

- Prefer root-cause fixes over patch fixes. Investigate and address the underlying cause while preserving the existing architecture, infrastructure, design patterns, and established conventions.
- Avoid superficial workarounds, symptom masking, and unnecessary architectural changes. Make the smallest correct change that permanently resolves the issue.
- Use temporary patches only when technically justified. Clearly document their limitations and identify the path to a permanent fix.
- Verify changes with relevant tests and checks before considering the issue resolved. Follow the existing guidance on when to add new specs; report any verification that remains incomplete.

## Codex Shared Checkout and Release Workflow

- The founder explicitly requests one shared checkout across all Codex chats: `C:/Users/Anup/Desktop/Volitex-AI-Inbox`, on `master`.
- Reuse that checkout. Do not create another worktree or task branch unless the user explicitly requests one. If a chat starts in an older worktree, inspect its pending work and continue from the canonical checkout without discarding anything.
- Serialize changes across chats. Inspect Git status before editing; do not overwrite, stash, reset, or commit another active chat's unfinished changes. Wait for an active writer to finish before changing shared files or Git state.
- Before writing, atomically create `.codex/write.lock/` and record the owning chat and timestamp in `owner.json`. Reuse only your own lock; inspect the owning chat before clearing a stale lock, and never clear an active writer's lock. Release your lock when the task ends. Read-only chats do not need the lock.
- Handle Git and release operations for the nontechnical founder. Commit reviewed task changes and normally push `master` when authorized work is complete; do not leave completed work stranded on a task branch. Never force-push `master`.
- Required candidate, migration, campaign, and full CE CI runs gate image publication for the exact commit. Successful master gates automatically publish the checked application image; failures block publication. Do not bypass gates or describe a queued release as published.
- Deployments use the verified immutable image digest. The `master` image tag is a convenience pointer, not a production pin. Image publication does not deploy to a server or establish live client readiness.
- Keep private local configuration and recovery snapshots outside tracked source. Never commit `.env`, credentials, or founder context files containing private information.

### Deployment and ongoing operations ownership

- The founder buys Hostinger KVM 4, completes the basic initial steps requiring his identity or provider access, and supplies the required server access and permissions. Codex is the technical deployment and operations agent for Volitex AI Inbox and n8n; do not routinely hand executable technical tasks back to the nontechnical founder when the available tools and authorization allow Codex to complete them safely.
- After access is supplied, execute the deployment using `docs/operations/first-client-production-runbook.md` and the verified immutable release kit: provision configuration and private services, apply migrations, configure integrations, and record acceptance evidence before declaring clients live. Inspect existing state first; reuse completed work.
- Ongoing scope includes monitoring configuration, health checks, log review, troubleshooting, incident response, security and application updates, routine maintenance, backups, and recovery verification. Use existing authorization for routine safe operations; obtain approval for destructive recovery, data loss, new spending, or actions outside the agreed scope. Leave a protected change/incident record and a concise founder-facing outcome.
- Record the actual server, access method, alert destination, monitoring/backup schedules, recovery objectives, escalation contact, and maintenance window in protected operational records; never store credentials in this file or Git. Ask the founder only for missing access, business decisions, identity/consent steps, or approvals that cannot be completed with available permissions.
- This ownership instruction does not itself create continuous execution or 24/7 coverage. Configure and verify persistent server-side monitoring, backup scheduling and alert delivery; explicitly record how alerts reach an available operator or agent, coverage gaps and escalation. Do not claim unattended maintenance or incident response is active merely because a chat or this file exists.
- Distinguish verified release artifacts from a deployed and accepted service. Recheck current advisories and registry availability before deployment; complete actual server restore/reboot/alert and client integration acceptance. Report incomplete or unverified requirements plainly and keep campaigns gated until their separate acceptance checks pass.

## Commit Messages

- Prefer Conventional Commits: `type(scope): subject` (scope optional)
- Example: `feat(auth): add user authentication`
- Don't reference Claude in commit messages

## PR Description Format

- Start with a short, user-facing paragraph describing the product change.
- Add a `Closes` section with relevant issue links (GitHub, Linear, etc.).
- For feature PRs, add `How to test` from a product/UX standpoint.
- For bugfix PRs, use `How to reproduce` when helpful.
- Optionally add a `What changed` section for implementation highlights.
- Do not add a `How this was tested` section listing specs/commands.

## Project-Specific

- **Translations**:
  - For product and source-string changes, only update `en.yml` and `en.json`; other languages are handled through Crowdin and the community
  - Crowdin-generated translation sync PRs may update non-English locale files; do not flag those changes solely for modifying translated locale files
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
- When modifying existing OSS features for Enterprise-only behavior, add an Enterprise module (via `prepend_mod_with`/`include_mod_with`) instead of editing OSS files directly—especially for policies, controllers, and services. For Enterprise-exclusive features, place code directly under `enterprise/`.

## Branding / White-labeling note

- The product name is **Volitex AI Inbox**. Use the full name in product labels, workflow titles and operational documentation. Preserve existing internal identifiers, repository paths, domains and API contracts.
- For user-facing strings that currently contain "Chatwoot" but should adapt to branded/self-hosted installs, prefer applying `replaceInstallationName` from `shared/composables/useBranding` in the UI layer (for example tooltip and suggestion labels) instead of adding hardcoded brand-specific copy.
