# Volitex AI Inbox — Meta App Review Screencast Script

> **Purpose:** Demonstrate each requested permission in live use inside Volitex AI Inbox.
> **Recording tips:** 1080p, quiet room, narrate clearly. Show BOTH the Volitex AI Inbox UI AND your phone (WhatsApp/IG app) side by side where possible. Keep it under ~6 minutes total. One continuous take is fine; or record 6 short clips and submit per-permission.

---

## PRE-RECORDING CHECKLIST (do NOT skip)

- [ ] Heroku app loads over HTTPS with no browser warnings
- [ ] WhatsApp inbox connected via **manual setup** (own Meta app credentials)
- [ ] Instagram inbox connected and authorized
- [ ] WhatsApp webhook verified in Meta dashboard (green checkmark)
- [ ] Instagram webhook verified in Meta dashboard
- [ ] Meta WhatsApp **test number** active, OR a real WABA number connected
- [ ] A second phone/account ready to act as the "customer"
- [ ] IG Business account linked to a Facebook Page, with at least one published post
- [ ] You're logged into Volitex AI Inbox as an agent
- [ ] Browser zoom at 100%, close unrelated tabs, hide bookmarks bar

---

## SEGMENT 0 — INTRO (0:00–0:15)

**On screen:** Volitex AI Inbox dashboard, logged in.

**Narration:**
> "This is Volitex AI Inbox, the internal platform we use at Volitex AI to manage WhatsApp and Instagram customer conversations for our automation clients. I'll demonstrate each permission our app requests."

---

## SEGMENT 1 — whatsapp_business_messaging (0:15–1:15)

**Goal:** Prove you can receive AND send WhatsApp messages.

**Actions:**
1. On the customer phone: open WhatsApp, send a message to the business number (e.g. "Hi, I'm interested in your automation service").
2. On screen: the message appears in the Volitex AI Inbox WhatsApp inbox in real time.
3. Click into the conversation, type a reply: "Thanks for reaching out! How can we help?"
4. On the customer phone: show the reply arriving.

**Narration:**
> "Here a customer sends a WhatsApp message to our business number. It arrives instantly in Volitex AI Inbox. Our agent replies from the platform, and the customer receives it on WhatsApp. This uses the whatsapp_business_messaging permission to send and receive messages."

---

## SEGMENT 2 — whatsapp_business_management (1:15–2:00)

**Goal:** Prove you manage the WABA / templates / phone through the platform.

**Actions:**
1. In Volitex: go to **Settings → Inboxes → [your WhatsApp inbox] → Configuration**.
2. Show the Phone Number ID, Business Account ID, connection status.
3. Click **Sync Templates** (Settings → inbox → WhatsApp templates area) — show templates syncing from the WABA.
4. (Optional) Briefly show the same WABA in the Meta dashboard to connect the dots.

**Narration:**
> "Through the platform we manage the WhatsApp Business Account — the connected phone number, business account, and message templates. Here we sync approved message templates from WhatsApp so agents can use them. This uses whatsapp_business_management."

---

## SEGMENT 3 — instagram_business_basic (2:00–2:30)

**Goal:** Prove you read the IG business profile.

**Actions:**
1. In Volitex: open the Instagram inbox.
2. Show the connected IG business profile — username, avatar visible in the inbox header/settings.

**Narration:**
> "The platform reads the connected Instagram business profile — the username and profile identity — to route and display conversations. This uses instagram_business_basic."

---

## SEGMENT 4 — instagram_business_manage_messages (2:30–3:15)

**Goal:** Prove you receive AND send IG DMs.

**Actions:**
1. On a test IG account: send a DM to your IG business account.
2. On screen: the DM appears in the Volitex Instagram inbox.
3. Reply from Volitex.
4. On the test IG account: show the reply arriving.

**Narration:**
> "A customer sends a direct message to our Instagram business account. It appears in Volitex AI Inbox, our agent replies, and the customer receives it on Instagram. This uses instagram_business_manage_messages."

---

## SEGMENT 5 — instagram_business_manage_comments (3:15–4:00)

**Goal:** Prove you read AND reply to IG comments.

**Actions:**
1. On a test IG account: comment on a post from your IG business account.
2. On screen: the comment appears in Volitex (as a conversation/comment thread).
3. Reply to the comment from Volitex.
4. On the test IG account / post: show the reply posted under the comment.

**Narration:**
> "A customer comments on one of our Instagram posts. The comment appears in the platform, our agent replies, and the reply is posted back to Instagram. This uses instagram_business_manage_comments."

---

## SEGMENT 6 — HUMAN AGENT (4:00–5:00) ⚠️ MOST IMPORTANT

**Goal:** Prove a HUMAN takes over and replies within the window. This is the #1 rejection reason — be explicit.

**Actions:**
1. Show a conversation that was being handled by automation/a bot (or just an unassigned incoming conversation).
2. Click **"Assign to me"** (the button in the conversation header).
3. As the human agent, type a personalized reply and send it.
4. On the customer phone: show the human's reply arriving.

**Narration:**
> "When a conversation needs human attention, a human agent takes over. Here the agent assigns the conversation to themselves and replies directly to the customer. The customer receives the human agent's message within the 24-hour messaging window. This demonstrates the Human Agent use case — a real person responding to the customer."

**Say the words "human agent" and "within the 24-hour window" out loud.** Reviewers listen for this.

---

## SEGMENT 7 — CLOSING (5:00–5:15)

**On screen:** Volitex AI Inbox dashboard.

**Narration:**
> "This is how Volitex AI Inbox uses each requested permission to help businesses manage WhatsApp and Instagram customer conversations with a human in the loop. Thank you."

---

## AFTER RECORDING

- [ ] Watch it once — confirm every permission is visibly demonstrated
- [ ] Confirm no localhost URLs, no Chatwoot branding, no errors on screen
- [ ] Upload to the App Review submission for EACH permission (Meta lets you attach the same video to multiple permissions)
- [ ] In each permission's "how you use it" text field, write 1-2 sentences matching the narration above
