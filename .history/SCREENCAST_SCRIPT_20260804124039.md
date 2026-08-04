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
| instagram_business_manage_comments | Video 5 |
| Human Agent | Video 6 |

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

## VIDEO 1 — whatsapp_business_messaging (~75 sec)

**Goal:** Prove you can receive AND send WhatsApp messages, including business-initiated template messages.

**Actions:**

**Part 1: Receive + Reply (0-40 sec)**
1. On the customer phone: open WhatsApp, send a message to the business number (e.g. "Hi, I'm interested in your automation service").
2. On screen: the message appears in the Volitex AI Inbox WhatsApp inbox in real time.
3. Click into the conversation, type a reply: "Thanks for reaching out! How can we help?"
4. On the customer phone: show the reply arriving.

**Part 2: Business-Initiated Template Message (40-75 sec)**
5. In Volitex: click **"New Message"** (or + icon) → select WhatsApp inbox.
6. Enter the customer's phone number.
7. Click **"Template"** tab → select an approved template (e.g., "welcome_offer" or "order_update").
8. Fill any template variables if required.
9. Click **Send**.
10. On the customer phone: show the template message arriving as a new message from the business.

**Narration:**
> "Here a customer sends a WhatsApp message to our business number. It arrives instantly in Volitex AI Inbox. Our agent replies from the platform, and the customer receives it on WhatsApp. The platform can also initiate conversations using approved message templates — here we send a template message to a customer, and they receive it on WhatsApp. This uses the whatsapp_business_messaging permission to send and receive messages, both reactive replies and proactive business-initiated conversations."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses whatsapp_business_messaging to receive incoming WhatsApp messages from customers and send replies from human agents back to customers on WhatsApp. The platform also supports business-initiated conversations using approved message templates, allowing businesses to proactively reach customers who have opted in. This is the core messaging functionality of our customer conversation platform."

---

## VIDEO 2 — whatsapp_business_management (~60 sec)

**Goal:** Prove you manage the WABA / templates / phone through the platform.
**Meta requirement covered:** "Demonstrate how your app user creates a message template on your app **or the WhatsApp Manager**" — we use the WhatsApp Manager option (explicitly allowed).

**Actions:**
1. In **Meta WhatsApp Manager** (business.facebook.com → WhatsApp Manager → Message Templates): click **Create Template**, fill in name/category/language/body (e.g. a "welcome_offer" utility template), and submit it. Show it listed in the template manager.
2. In Volitex: go to **Settings → Inboxes → [your WhatsApp inbox] → Configuration**.
3. Show the Phone Number ID, Business Account ID, connection status.
4. Click **Sync Templates** — show templates syncing from the WABA, including the one just created.
5. Open a WhatsApp conversation, click the template picker in the reply box, and show the synced template available to send.

**Narration:**
> "Message templates are created in the WhatsApp Manager — here we create a new template for our business. Then in Volitex AI Inbox, we manage the WhatsApp Business Account — the connected phone number and business account — and sync the approved templates from WhatsApp so our agents can use them in conversations. This uses whatsapp_business_management."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses whatsapp_business_management to manage WhatsApp Business Account assets on behalf of onboarded businesses — including viewing phone number configuration and syncing approved message templates (created in the WhatsApp Manager) so agents can use them in customer conversations."

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

## VIDEO 5 — instagram_business_manage_comments (~60 sec)

**Goal:** Prove you can receive, reply to, and delete Instagram comments.

**Actions:**
1. On a test IG account: comment on a post from your IG business account.
2. On screen: the comment appears in Volitex AI Inbox as a message with an "Instagram Comment" badge.
3. Reply to the comment from Volitex (use the reply-to feature on the comment message).
4. On the test IG account / post: show the reply posted under the comment.
5. In Volitex: delete the comment message (context menu → delete).
6. On the IG post: show the comment is removed.

**Narration:**
> "A customer comments on one of our Instagram posts. The comment appears in Volitex AI Inbox with a comment badge. Our agent replies to the comment, and the reply is posted back to Instagram. The agent can also delete the comment, which removes it from Instagram. This uses instagram_business_manage_comments."

**Written description (paste in App Review):**
> "Volitex AI Inbox uses instagram_business_manage_comments to receive Instagram post comments as messages, allow agents to reply to comments (which posts the reply back to Instagram), and delete comments when needed. This enables businesses to manage Instagram comment engagement from our platform."

---

## VIDEO 6 — HUMAN AGENT (~60 sec) ⚠️ MOST IMPORTANT

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
