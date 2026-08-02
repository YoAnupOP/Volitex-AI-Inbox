# Volitex AI — Client Onboarding SOP

> **Purpose:** Step-by-step checklist for onboarding a new client onto Volitex AI Inbox (WhatsApp / Instagram / Combo automation).
> **Owner:** Volitex AI (founder / future onboarding team)
> **Target timeline:** 3–5 business days per client
> **Version:** 1.0

---

## Overview — The 7 Phases

| Phase | Name | Duration | Owner |
|---|---|---|---|
| 0 | Sales → Onboarding Handoff | Same day as payment | You |
| 1 | Discovery & Requirements | Day 1 | You + Client |
| 2 | Technical Setup (Meta + Inbox + n8n) | Day 1–2 | You |
| 3 | AI Configuration | Day 2–3 | You |
| 4 | Testing & QA | Day 3–4 | You + Client |
| 5 | Go-Live | Day 4–5 | You |
| 6 | Training & Handoff | Day 5 | You + Client |
| 7 | Post-Onboarding Check-ins | Week 2 & 4 | You |

---

## Phase 0: Sales → Onboarding Handoff

**Trigger:** Client has signed agreement + paid setup fee.

- [ ] Confirm **setup fee received** (₹15,000–25,000) — no work starts before this
- [ ] Confirm **first month subscription** payment method set up
- [ ] Record client details in your client tracker (sheet/CRM):
  - Business name, contact person, email, phone
  - Package: WhatsApp / Instagram / Combo
  - Tier: Starter / Growth / Pro
  - Niche: Real Estate / E-commerce / Influencer / Other
  - Agreed go-live date
- [ ] Send **Welcome Email** (see Template A) with:
  - Onboarding timeline
  - Discovery call scheduling link
  - List of things client must keep ready (see Phase 1 checklist)
- [ ] Create client folder in your drive: `Clients/<BusinessName>/` with subfolders: `Assets`, `Prompts`, `Agreements`, `Credentials`

**⛔ Hard rule:** No payment = no onboarding call. No exceptions.

---

## Phase 1: Discovery & Requirements (Day 1)

**Duration:** 45–60 min call. Record it (with permission).

### 1.1 Client must keep ready (send this list in Welcome Email):

- [ ] Facebook account with **admin access to their Meta Business Portfolio** (or willingness to create one)
- [ ] Access to the phone with their WhatsApp / WhatsApp Business app
- [ ] Instagram Business/Creator account credentials (for IG package) — must be linked to a Facebook Page
- [ ] Business details: website, services/product list, pricing sheet, FAQs
- [ ] Logo + brand assets (for inbox display)
- [ ] List of team members who need inbox access (name + email + role)

### 1.2 Discovery call questions (fill answers in client tracker):

**Business context:**
- [ ] What are the top 10 questions customers ask you?
- [ ] What does a qualified lead look like for you? (budget, location, timeline, etc.)
- [ ] What action should the AI drive? (book site visit / capture lead / answer FAQ / take order)
- [ ] Current monthly message volume estimate?
- [ ] Current response time? Who handles messages today?

**Number & account status (CRITICAL — determines technical path):**
- [ ] Is your business number on: **Personal WhatsApp** / **WhatsApp Business App** / **Already on API (another provider)** / **Need new number**?
- [ ] (Instagram package) Is your IG account a Business/Creator account? Linked to a Facebook Page?

**Tier confirmation:**
- [ ] Confirm tier features they bought (show feature list, avoid disputes later)
- [ ] Any custom requirements outside the tier? → Quote separately or decline

### 1.3 Number Decision Tree (follow exactly):

```
Client's number status?
│
├── 📱 WhatsApp Business App (MOST COMMON — best case)
│   └── ✅ COEXISTENCE PATH (Phase 2, Path A)
│       - No number deletion, no backup needed
│       - Business App keeps working alongside API
│       - Requires Business App version 2.24.17+
│
├── 📱 Personal WhatsApp
│   └── Step 1: Client converts to WhatsApp Business App first
│       (same number, chats preserved — official in-app migration)
│       Step 2: Then follow COEXISTENCE PATH (Path A)
│
├── 🔁 Already on another BSP/API provider
│   └── MIGRATION PATH (Phase 2, Path C)
│       - Number migration from old BSP to Volitex Meta app
│       - Client must ask old provider to release/disable the number
│
└── 🆕 Wants a new dedicated number
    └── NEW NUMBER PATH (Phase 2, Path B)
        - Recommend physical SIM/eSIM (₹300–400, most reliable)
        - Avoid VoIP/virtual numbers (Meta often blocks OTP to them)
```

### 1.4 Set expectations verbally (say this on the call):

- "Coexistence ke baad aapki Business App chalti rahegi, lekin **broadcast lists band ho jayengi**, aur **linked devices re-link** karne padenge."
- "API se bheje gaye template messages ke **Meta charges aapke WABA pe directly** lagenge — hum usme involved nahi hain."
- "AI perfect nahi hota — pehle 2 hafte hum prompts tune karenge based on real conversations."
- "Go-live ke baad 1 week hyper-care period hota hai — main daily monitor karunga."

---

## Phase 2: Technical Setup (Day 1–2)

### 2.1 Volitex AI Inbox account provisioning

Run the provisioning rake task (or manual steps until the task is built):

- [ ] Create **Account** (client business name)
- [ ] Create **Admin user** (client's email, temp password — force reset on first login)
- [ ] Create **Inbox(es)** per package:
  - WhatsApp package → 1 WhatsApp Cloud inbox
  - Instagram package → 1 Instagram inbox
  - Combo → both
- [ ] Set **account custom attributes** (tier config — this drives n8n behavior):

```json
{
  "tier": "growth",
  "package": "combo",
  "features": {
    "ai_faq": true,
    "lead_qualification": true,
    "appointment_booking": true,
    "human_handoff": true,
    "rag_knowledge_base": false,
    "custom_workflows": false
  },
  "monthly_conversation_cap": 3000,
  "niche": "real_estate",
  "onboarded_at": "2026-08-02"
}
```

- [ ] Create **account webhook** → n8n Router URL, events: `message_created`, `conversation_created`, `conversation_status_changed`
- [ ] Add client logo to account branding
- [ ] Invite team members with correct roles (agent vs admin) — per tier seat limits:
  - Starter: 1 seat | Growth: 3 seats | Pro: unlimited

### 2.2 Meta / WABA connection

#### Path A: COEXISTENCE (client on Business App) — preferred

**Prerequisite:** Your Meta app must have Embedded Signup configured with Business App onboarding enabled (App Dashboard → WhatsApp → Embedded Signup Builder).

- [ ] Verify client's Business App version ≥ 2.24.17 (ask them to update if needed)
- [ ] Send client your **Embedded Signup link**
- [ ] Client selects **"Connect existing WhatsApp Business account"**
- [ ] Client enters Business App number → receives verification code → taps **Connect to Business Platform** in the app → pastes code
- [ ] Client chooses whether to **share chat history** (recommend: yes)
- [ ] You receive: `waba_id`, `phone_number_id`, exchangeable `code`
- [ ] Complete server-side onboarding: exchange code → business token → **skip phone registration** (already registered) → subscribe app to client's WABA webhooks
- [ ] **Within 24 hours (HARD DEADLINE):** initiate contacts sync + history sync via `smb_app_data` API — miss this window and client must re-onboard
- [ ] Tell client: keep Business App open during sync; linked devices will need re-linking
- [ ] Verify in Inbox settings → Account Health: **Coexistence: ACTIVE** (`is_on_biz_app: true`, `platform_type: CLOUD_API`)

#### Path B: NEW NUMBER

- [ ] Client gets new SIM/eSIM (they handle this — give them the requirement: "active SIM that can receive SMS/calls")
- [ ] Client goes through Embedded Signup → enters new number → OTP verification
- [ ] Complete server-side onboarding: exchange code → token → **register phone number** → subscribe webhooks
- [ ] Set display name (needs Meta approval — can take up to 48h)
- [ ] Client adds **payment method** to their WABA (see 2.3)

#### Path C: MIGRATION from another BSP

- [ ] Client asks old provider to disable two-factor PIN / release the number
- [ ] Client completes Embedded Signup with the same number (migration flow)
- [ ] Verify old provider's webhooks are disconnected (avoid duplicate processing)
- [ ] Test inbound + outbound before declaring done

### 2.3 Meta billing setup (client's responsibility — guide them)

- [ ] Client opens **WhatsApp Manager → Payment settings** (or Business Suite → Billing)
- [ ] Client adds payment method: credit/debit card (Visa/MC/RuPay) — India WABAs bill in INR
- [ ] **If client has no card:** fallback = your card on their WABA + monthly invoice at actuals + 10–15% handling (document in agreement; track for GST)
- [ ] Screenshot confirmation saved to client folder

**⛔ Hard rule:** No payment method on WABA = no go-live. Messages won't send without it.

### 2.4 Instagram connection (IG / Combo packages)

- [ ] Confirm IG account is **Business or Creator** type (not personal)
- [ ] Confirm IG is **linked to a Facebook Page** (client does this in IG app: Settings → Account → Linked accounts)
- [ ] Confirm **"Allow access to messages"** is ON (IG app: Settings → Privacy → Messages)
- [ ] Connect via Volitex AI Inbox: Settings → Inboxes → Add Instagram → OAuth flow with client's Facebook login
- [ ] Send test DM from a personal IG account → verify it appears in inbox

### 2.5 n8n configuration

- [ ] Verify account webhook from 2.1 is hitting the **Router Workflow** (check n8n execution log)
- [ ] Verify Router correctly fetches this account's config (tier/features) from Chatwoot API
- [ ] Set client-specific **AI credentials/model** if different from default
- [ ] Initialize client's **monthly conversation counter** (Redis/Postgres) at 0
- [ ] Add client to the **alert list** (cap-reached alerts, error alerts → your email/WhatsApp)

---

## Phase 3: AI Configuration (Day 2–3)

- [ ] Select **niche prompt template** (Real Estate / E-commerce / Influencer base)
- [ ] Customize with discovery call answers:
  - Business name, services, pricing, locations
  - Top 10 FAQs → verified answers (client must approve wording)
  - Qualification questions + scoring logic (Growth/Pro only)
  - Booking flow + calendar link (Growth/Pro only)
  - Escalation triggers (e.g., "agent", "call me", angry sentiment, pricing negotiation)
- [ ] Configure **handoff behavior** per tier:
  - Starter: notify owner (assignment to admin)
  - Growth: round-robin/team routing
  - Pro: routing + SLA alerts
- [ ] Set **AI identity rules**: bot introduces itself as the business's assistant, never claims to be human, offers human option
- [ ] Configure **off-hours behavior** (if applicable): AI continues, or away message + capture
- [ ] (Pro only) Knowledge base: collect client docs → structure → load into RAG store
- [ ] Save final prompt + config to `Clients/<BusinessName>/Prompts/`

---

## Phase 4: Testing & QA (Day 3–4)

**Test from a real personal WhatsApp/IG account (yours), not the client's.**

### WhatsApp tests:
- [ ] Inbound message → appears in Volitex AI Inbox, correct account
- [ ] AI reply → arrives on WhatsApp, correct tone/content
- [ ] Reply in inbox as agent → arrives on WhatsApp (human path works)
- [ ] (Coexistence) Client sends message from **Business App** → appears in inbox as outgoing (echo sync works)
- [ ] Handoff trigger ("I want to talk to a human") → AI stops, agent notified
- [ ] After handoff, AI does NOT reply again until conversation resolved/reopened
- [ ] Media: send image/document → renders in inbox
- [ ] 24h window behavior: verify AI doesn't attempt free-form reply outside window (template path if configured)

### Instagram tests (IG/Combo):
- [ ] DM → inbox → AI reply → back to IG
- [ ] Story mention / comment (if in scope) → handled per config
- [ ] Handoff works

### Config & safety tests:
- [ ] Wrong/gibberish message → AI responds gracefully, doesn't hallucinate prices/policies
- [ ] Abusive message → escalation/blocking behavior per config
- [ ] Conversation counter increments (check n8n)
- [ ] Webhook failure recovery: stop n8n for 5 min, send message, restart → message processes (no loss)
- [ ] Load sanity: 10 rapid messages → all processed, no duplicates

### Client UAT:
- [ ] 30-min call: client sends test messages, verifies AI answers match approved FAQs
- [ ] Client signs off (written confirmation in WhatsApp/email — save it)

---

## Phase 5: Go-Live (Day 4–5)

- [ ] Client announces/redirects customers to the number (their choice of timing)
- [ ] AI automation switched ON for live traffic
- [ ] **Hyper-care week starts:** you monitor daily
  - Check AI responses daily for hallucinations/bad answers
  - Check handoff rate (target: <30% conversations need human)
  - Check error logs (n8n + Volitex AI Inbox)
- [ ] Day 1 evening: send client a short "Day 1 report" (conversations handled, leads captured, issues found)

---

## Phase 6: Training & Handoff (Day 5)

**45-min training call (record it, share recording):**

- [ ] Inbox tour: conversations, filters, assignment, resolving
- [ ] How to reply as human agent (and when AI pauses)
- [ ] How to add team members (within seat limits)
- [ ] How to read basic reports
- [ ] What to do when AI gives wrong answer → report to you, don't fight the bot
- [ ] (Coexistence) What changed in their Business App: broadcast lists off, re-link devices, app still works for 1:1
- [ ] Billing recap: your invoice (subscription) vs Meta charges (their WABA) — two separate things
- [ ] Support channel: how to reach you + expected response time per tier

---

## Phase 7: Post-Onboarding Check-ins

**Week 2 check-in (30 min):**
- [ ] Review metrics: conversations, AI resolution rate, handoff rate, leads captured
- [ ] Prompt tuning based on real conversation logs
- [ ] Ask: "What's the AI getting wrong?" → fix top 3 issues

**Week 4 check-in (30 min):**
- [ ] Monthly report walkthrough
- [ ] ROI conversation: leads/deals attributed to automation
- [ ] Upsell evaluation: approaching conversation cap? → propose tier upgrade
- [ ] Ask for: **testimonial + Google/Clutch review + 1 referral** (especially pilot clients)
- [ ] Update client tracker: status = "Active — Stable"

---

## Appendix A: Welcome Email Template

```
Subject: Welcome to Volitex AI — Your Onboarding Starts Now 🚀

Hi [Name],

Payment confirmed — welcome aboard! Here's what happens next:

1. Discovery Call (45–60 min): Book your slot here: [link]
2. Before the call, please keep ready:
   - Facebook account with admin access to your Meta Business Portfolio
   - The phone with your WhatsApp Business app installed (updated to latest version)
   - [IG package] Your Instagram login (must be a Business/Creator account linked to a Facebook Page)
   - Your services/pricing/FAQ documents
   - Team member details who'll use the inbox (name, email)
3. Timeline: We'll have you live within 3–5 business days.

Your package: [Package] — [Tier]
Your onboarding manager: [You]

See you on the call,
[Your name], Volitex AI
```

## Appendix B: Common Issues & Fixes

| Issue | Cause | Fix |
|---|---|---|
| Embedded signup fails with number error | Number still active on personal WhatsApp | Convert to Business App first, then coexistence |
| "Connect existing account" option not visible | Business App < 2.24.17, or feature not enabled in your app | Update app / check Embedded Signup Builder config |
| Messages not arriving in inbox | Webhook subscription failed | Re-run webhook setup; verify WABA subscription in Meta dashboard |
| AI replies but customer doesn't receive | WABA payment method missing | Client adds card in WhatsApp Manager |
| Echo messages duplicated | Old BSP still connected | Disconnect old provider's webhooks |
| History sync didn't happen | 24h window missed after onboarding | Re-onboard (offboard → embedded signup again) |
| IG DMs not arriving | "Allow access to messages" off | IG app → Settings → Privacy → Messages → enable |

## Appendix C: Onboarding Completion Checklist (sign-off)

- [ ] Account + users created, tier attributes set
- [ ] WABA connected (coexistence/new/migration), webhooks verified
- [ ] Payment method on WABA confirmed
- [ ] n8n routing verified, counter initialized
- [ ] AI prompts approved by client
- [ ] All Phase 4 tests passed
- [ ] Client UAT sign-off received (written)
- [ ] Training call done, recording shared
- [ ] Week 2 & Week 4 check-ins scheduled
- [ ] Client tracker updated: status = "Live — Hyper-care"
