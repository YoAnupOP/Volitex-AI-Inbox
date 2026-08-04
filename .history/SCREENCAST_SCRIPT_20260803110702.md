# Volitex AI Inbox — Meta App Review Screencast Script

> **Purpose:** Demonstrate each requested permission in live use inside Volitex AI Inbox.
> **⚠️ Meta Rule:** Submit a SEPARATE video clip per permission. Do NOT combine multiple permissions in one video. Record 5 short clips (one per permission), each 30–90 seconds.
> **Recording tips:** 1080p, quiet room, narrate clearly in English. Set app UI language to English. Show BOTH the Volitex AI Inbox UI AND your phone (WhatsApp/IG app) where relevant.

---

## PERMISSIONS BEING REQUESTED (final list)

| Permission | Video # |
|---|---|
| whatsapp_business_messaging | Video 1 |
| whatsapp_business_management | Video 2 |
| instagram_business_basic | Video 3 |
| instagram_business_manage_messages | Video 4 |
| Human Agent | Video 5 |

**NOT requesting:** `instagram_business_manage_comments` — Volitex AI Inbox does not have a comments feature. Requesting it would cause rejection ("unnecessary permission"). Can be requested later if the feature is built.

---

## PRE-RECORDING CHECKLIST (do NOT skip)

- [ ] Heroku app loads over HTTPS with no browser warnings
- [ ] WhatsApp inbox connected via **manual setup** (own Meta app credentials)
- [ ] Instagram inbox connected and authorized
- [ ] WhatsApp webhook verified in Meta dashboard (green checkmark)
- [ ] Instagram webhook verified in Meta dashboard
- [ ] Meta WhatsApp **test number** active, OR a real WABA number connected
- [ ] A second phone/account ready to act as the "customer"
- [ ] IG Business account linked to a Facebook Page
- [ ] You're logged into Volitex AI Inbox as an agent
- [ ] Browser zoom at 100%, close unrelated tabs, hide bookmarks bar
- [ ] App UI language set to English

---

## VIDEO 1 — whatsapp_business_messaging (~60 sec)

**Goal:** Prove you can receive AND send WhatsApp messages.

**Actions:**
1. On the customer phone: open WhatsApp, send a message to the business number (e.g. "Hi, I'm interested in your automation service").
2. On screen: the message appears in the Volitex AI Inbox WhatsApp inbox in real time.
3. Click into the conversation, type a reply: "Thanks for reaching out! How can we help?"
4. On the customer phone: show the reply arriving.

**Narration:**
> "Here a customer sends a WhatsApp message to our business number. It arrives instantly in Volitex AI Inbox. Our agent replies from the platform, and the customer receives it on WhatsApp. This uses the whatsapp_business_messaging permission to send and receive messages."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses whatsapp_business_messaging to receive incoming WhatsApp messages from customers and send replies from human agents back to customers on WhatsApp. This is the core messaging functionality of our customer conversation platform."

---

## VIDEO 2 — whatsapp_business_management (~45 sec)

**Goal:** Prove you manage the WABA / templates / phone through the platform.

**Actions:**
1. In Volitex: go to **Settings → Inboxes → [your WhatsApp inbox] → Configuration**.
2. Show the Phone Number ID, Business Account ID, connection status.
3. Click **Sync Templates** — show templates syncing from the WABA.
4. (Optional) Briefly show the same WABA in the Meta dashboard to connect the dots.

**Narration:**
> "Through the platform we manage the WhatsApp Business Account — the connected phone number, business account, and message templates. Here we sync approved message templates from WhatsApp so agents can use them. This uses whatsapp_business_management."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses whatsapp_business_management to manage WhatsApp Business Account assets on behalf of onboarded businesses — including viewing phone number configuration and syncing approved message templates so agents can use them in conversations."

---

## VIDEO 3 — instagram_business_basic (~30 sec)

**Goal:** Prove you read the IG business profile.

**Actions:**
1. In Volitex: open the Instagram inbox (or Settings → Inboxes → Instagram inbox).
2. Show the connected IG business profile — username, avatar visible in the inbox header/settings.

**Narration:**
> "The platform reads the connected Instagram business profile — the username and profile identity — to route and display conversations. This uses instagram_business_basic."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses instagram_business_basic to read basic metadata (username, profile ID) of connected Instagram Business accounts, so incoming conversations can be correctly routed and displayed with the business identity."

---

## VIDEO 4 — instagram_business_manage_messages (~60 sec)

**Goal:** Prove you receive AND send IG DMs.

**Actions:**
1. On a test IG account: send a DM to your IG business account.
2. On screen: the DM appears in the Volitex Instagram inbox.
3. Reply from Volitex.
4. On the test IG account: show the reply arriving.

**Narration:**
> "A customer sends a direct message to our Instagram business account. It appears in Volitex AI Inbox, our agent replies, and the customer receives it on Instagram. This uses instagram_business_manage_messages."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses instagram_business_manage_messages to receive incoming Instagram direct messages from customers and send replies from human agents back to customers on Instagram. This enables businesses to manage Instagram customer conversations from our platform."

---

## VIDEO 5 — HUMAN AGENT (~60 sec) ⚠️ MOST IMPORTANT

**Goal:** Prove a HUMAN takes over and replies within the window. This is the #1 rejection reason — be explicit.

**Actions:**
1. Show a conversation that was being handled by automation/a bot (or just an unassigned incoming conversation).
2. Click **"Assign to me"** (the button in the conversation header).
3. As the human agent, type a personalized reply and send it.
4. On the customer phone: show the human's reply arriving.

**Narration:**
> "When a conversation needs human attention, a human agent takes over. Here the agent assigns the conversation to themselves and replies directly to the customer. The customer receives the human agent's message within the 24-hour messaging window. This demonstrates the Human Agent use case — a real person responding to the customer."

**Say the words "human agent" and "within the 24-hour window" out loud.** Reviewers listen for this.

**Written description (paste in App Review):**
> "Volitex AI Inbox supports the Human Agent use case: when automated handling is insufficient, a human agent assigns the conversation to themselves and replies directly to the customer within the 24-hour messaging window. A real person is always available to respond."

---

## AFTER RECORDING

- [ ] Watch each clip — confirm the permission is visibly demonstrated
- [ ] Confirm no localhost URLs, no Chatwoot branding, no errors on screen
- [ ] Upload each clip to its corresponding permission in the App Review submission
- [ ] Paste the written description for each permission (provided above)
- [ ] Do NOT submit in draft mode — click Submit!
