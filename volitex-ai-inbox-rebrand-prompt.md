# Volitex AI Inbox — Full White-Label Rebrand Prompt

## Context

This is a Chatwoot v4.16.2 fork (Community Edition — `enterprise/` folder already
removed, `CW_EDITION=ce` set in `docker/Dockerfile`). It is being rebranded into an
internal, white-labeled tool called **Volitex AI Inbox**, owned by the agency
**Volitex AI**. This is NOT a resold/SaaS product — it is an internal operating
tool used to deliver a WhatsApp & Instagram Automation service to clients. Clients
will log in and see only "Volitex AI Inbox" branding — zero visible trace of
"Chatwoot" anywhere in the UI, emails, metadata, or user-facing text.

Legal basis: core Chatwoot code (everything outside the removed `enterprise/`
folder) is MIT-licensed, which explicitly permits modifying and rebranding. The
MIT copyright notice must remain intact in the repo's LICENSE file — do not
delete or alter `LICENSE`. Do not touch, restore, or reference anything from the
removed `enterprise/` folder.

A brand identity reference file is provided at the repo root:
`volitex_ai_brand_identity.html`. Read it first and extract:
- Exact hex colors: `#000000` (primary/black), `#FFFFFF` (white/reversed),
  `#111111` (off-black, dark surfaces), `#F4F4F4` (off-white, light surfaces)
- Font: **Space Grotesk** (Google Fonts) — weight 600 for "VOLITEX" wordmark,
  weight 300 for "AI", weight 500 for headlines, weight 400 for body text
- The SVG symbol mark (compound triangle "V", `fill-rule: evenodd`, path data
  `M10,10 L90,10 L50,90 Z M27,10 L73,10 L50,77 Z` in a 100x100 viewBox) — this is
  a scalable vector, use it directly for favicon/logo generation, do not
  approximate it with a different shape.
- Tagline reference: "Technology that amplifies human ambition"

## Goal

100% hardcoded, permanent rebrand from "Chatwoot" to "Volitex AI Inbox" across
the entire non-enterprise codebase — text, visual identity, and metadata. This
is a direct source-code edit, not a config/env-var toggle (that toggle is an
enterprise-only feature we don't have access to, so everything must be edited
at the source level).

## Phase 1 — Text & Naming (do this first, verify, then move to Phase 2)

Search the entire codebase (excluding `node_modules/`, `.git/`, `tmp/`, `log/`,
`vendor/`) for case-insensitive occurrences of "chatwoot" and replace per these
rules:

- User-facing product name → "Volitex AI Inbox"
- Company/copyright name → "Volitex AI" (only where it refers to the company,
  not the MIT LICENSE file's Chatwoot Inc. copyright notice — leave LICENSE
  untouched)
- Email domains / sender addresses referencing chatwoot.com → replace with a
  placeholder `volitexai.tech` domain (flag these for me to confirm real
  addresses afterward, don't invent real mailboxes)
- Package/app identifiers (`package.json` `name` field, `Gemfile` app name,
  `config/application.rb` module name if it's a display string, not a Ruby
  constant that would break code — flag any Ruby CONSTANT/module renames
  instead of doing them blindly, since renaming Ruby modules can break require
  paths)

Specifically check and update:
- `config/locales/en.yml` and other locale files — all user-visible strings
- `app/javascript/` — Vue components with hardcoded "Chatwoot" text, page
  titles, meta descriptions
- `app/views/` — mailer templates, layout titles, installation/onboarding views
- `public/` — manifest.json, robots.txt, any static HTML
- `config/installation_config.yml` — default installation name/values
- `README.md` (can be replaced entirely with a short internal-tool description,
  doesn't need to match upstream structure)
- `package.json` — `name`, `description`, `author` fields
- Vite/webpack config titles, PWA manifest (`workbox-config.js` references)

Do NOT rename:
- Ruby class/module names, gem names, or file paths that would break
  `require`/`autoload` (e.g. do not rename the `Chatwoot` Ruby module if one
  exists internally as a namespace — flag it to me instead, don't guess)
- Anything inside git history — this is a working-tree text/asset edit only

After Phase 1, run a final case-insensitive grep for "chatwoot" across the
codebase (excluding LICENSE, node_modules, .git) and give me a list of any
remaining matches with file paths, so I can review before we call text-rebrand
complete.

## Phase 2 — Visual Identity

1. Add Space Grotesk via Google Fonts `<link>` tags (preconnect +
   stylesheet) to the main HTML entry point(s) — same pattern as in
   `volitex_ai_brand_identity.html`.
2. Replace the Chatwoot logo assets (`app/assets/images/`,
   `app/javascript/dashboard` logo references, sidebar logo, login-page logo)
   with the Volitex AI SVG symbol mark from the brand identity file. Keep it as
   inline SVG or an `.svg` file (not a rasterized PNG) so it scales cleanly.
3. Generate favicon set (favicon.ico, apple-touch-icon, PWA icons referenced in
   manifest.json) from the same SVG mark, in black (#000000) on transparent/white
   background for light contexts, white (#FFFFFF) for dark contexts, matching
   section 02 ("on light / on dark") of the brand identity file.
4. Update the color theme variables (Chatwoot uses CSS custom properties /
   Tailwind config for its color system — find `tailwind.config.js` and any
   `:root` CSS variable definitions for primary/brand colors) to use:
   - `#000000` primary
   - `#111111` dark surface
   - `#F4F4F4` light surface
   - `#FFFFFF` text-on-dark
   Do not do a wholesale replacement of Chatwoot's entire semantic color
   system (success/error/warning colors should stay functional, e.g. green for
   success, red for error) — only replace brand/primary/accent color tokens.
5. Update `<title>` tags and meta tags across entry HTML files to "Volitex AI
   Inbox".

After Phase 2, take a screenshot or describe what the login page and main
dashboard look like after restart, so I can visually confirm before we
consider this done.

## Phase 3 — Verification

1. Confirm the app still boots cleanly (`foreman start -f Procfile.dev` or
   equivalent) with no new errors introduced by the rebrand.
2. Give me a summary list of every file changed, grouped by Phase 1 (text) vs
   Phase 2 (visual), so I have a clear diff to review before committing.
3. Do NOT `git commit` automatically — leave changes unstaged so I can review
   `git diff` myself first.

## Constraints

- Do not modify anything under a path that no longer exists (`enterprise/` —
  already removed, don't try to "fix" references to it beyond removing dead
  imports if any linter/boot error surfaces one).
- Do not touch `LICENSE` (root MIT license) — must remain intact per license
  terms.
- Do not invent fake data, fake case studies, or fake email addresses —
  flag placeholders clearly (e.g. `TODO: confirm real support email`) instead
  of guessing.
- If a rename risks breaking a Ruby constant, module, or require path, stop
  and flag it to me instead of proceeding — don't guess on anything that could
  break app boot.
