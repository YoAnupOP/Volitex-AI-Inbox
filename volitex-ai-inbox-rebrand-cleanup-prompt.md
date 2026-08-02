# Volitex AI Inbox — Rebrand Cleanup Pass (Super Admin + Residual Blue Accents)

## Context

We already completed a rebrand pass on the main dashboard (`app/javascript/dashboard/`)
and portal (`app/javascript/portal/`) — text, colors, fonts, logo, and dark-mode
disable are done and verified working there. This is a follow-up, narrower pass
to catch what that first pass didn't cover.

Brand reference file at repo root: `volitex_ai_brand_identity.html` — same
palette as before: `#000000` (primary/black), `#FFFFFF` (white), `#111111`
(off-black), `#F4F4F4` (off-white). Font: Space Grotesk. Compound-triangle "V"
SVG logo (same file has the exact path/viewBox).

## Task 1 — Rebrand the Super Admin console

The Super Admin console (`localhost:3000/super_admin/...`) currently still
shows the original Chatwoot blue circular logo and "Chatwoot" branding in its
sidebar header, separate from the main dashboard we already fixed. This is a
distinct Rails-view-based section — likely under `app/views/layouts/` (a
super_admin-specific layout) and/or `app/views/super_admin/` partials, not the
Vue.js dashboard app.

Find where the Super Admin sidebar renders its logo and product name (look for
a layout file used specifically by `Administrate` gem views — Chatwoot's
super_admin uses the Administrate gem, so check for an
`app/views/layouts/administrate/` override or an `administrate.rb` initializer
that sets branding/logo, in addition to searching `app/views/super_admin/` and
any relevant `app/assets/` locations for the blue logo asset). Replace:
- The Chatwoot circular logo with the Volitex AI "V" SVG mark
- Any "Chatwoot" text in the super_admin layout/header with "Volitex AI Inbox"
- Check if this layout pulls in its own separate stylesheet/color variables
  (Administrate often ships its own default theme) — if so, apply the same
  black/off-black/off-white palette there too, don't assume the main
  dashboard's theme file automatically covers this section.

## Task 2 — Find and eliminate ALL residual Chatwoot blue accents

The main dashboard and login page were re-themed to the monochrome brand
palette, but some interactive states were missed — confirmed example: the
"Forgot your password?" link on the login page turns blue (a Chatwoot default
link/hover color) when hovered, instead of using the brand palette.

This means there are likely more instances of Chatwoot's original blue
(commonly a shade like `#1f93ff` / `#0069ff`-ish blue used for links, hover
states, focus rings, and active states) that our first color-token pass missed
because they're defined as hover/focus/active pseudo-states or link-specific
styles rather than the main button/surface tokens we already changed.

Do this:
1. Search the SCSS/CSS across `app/javascript/dashboard/assets/scss/` and any
   portal/widget stylesheets for hardcoded blue hex values or blue-ish color
   variables (e.g. anything resembling Chatwoot's default `--w-500`,
   `--woot-blue`, or Tailwind `blue-*` utility classes if used directly)
   still applied to: links, hover states, focus rings, active/selected states,
   checkboxes/radio buttons, toggle switches, and form-field focus borders.
2. Replace these with the brand palette equivalents — for a monochrome brand,
   hover/focus states should generally shift between black/off-black/off-white
   shades, not introduce a new hue. Use judgment for what reads well (e.g. a
   link hover might go from black to a mid-gray rather than staying pure
   black, for visual feedback) but do NOT introduce blue, purple, or any
   non-brand hue anywhere.
3. Pay specific attention to: login/signup/forgot-password page link styles,
   form input focus-border colors, checkbox/toggle "checked" states, and any
   "active" navigation item indicator color in the sidebar.
4. After making changes, do a final broad search across the same directories
   for the literal Chatwoot blue hex codes to confirm nothing was missed, and
   report any remaining matches you couldn't confidently replace (rather than
   guessing on ambiguous cases like semantic colors — e.g. leave
   success-green/error-red untouched, only fix brand/link/focus/accent blues).

## Constraints (same as before)

- Do not touch `LICENSE`.
- Do not restore or reference anything from the removed `enterprise/` folder.
- Do not rename Ruby modules/classes/constants — flag instead of guessing if a
  rename looks necessary.
- Leave changes unstaged — do not `git commit`.
- After both tasks, restart the app and give me:
  1. A confirmation that Super Admin login page and dashboard visually show
     the Volitex AI Inbox branding (I will screenshot-verify myself after).
  2. A complete list of every file changed, grouped by Task 1 vs Task 2.
