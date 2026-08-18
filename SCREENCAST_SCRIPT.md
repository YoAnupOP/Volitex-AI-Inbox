# Volitex AI Inbox — Meta App Review Screencast Script (Final)

> **Status:** Final pre-submission script, aligned to a code-verified audit of the deployed app.
> **Meta rule:** ONE video per permission. Do NOT combine permissions in one video. Five clips, 45–90 seconds each.
> **Recording:** 1080p, English UI, narrate slowly in English. Show the Volitex AI Inbox UI (https://inbox.volitexai.tech) AND the native WhatsApp/Instagram client side by side where required.
> **Do NOT say:** "should work", "can be used to", hypotheticals. Do NOT show n8n/Groq/AI automation/internal code. Do NOT imply Volitex is a Meta Business Partner / Tech Provider / Solution Partner (App Review approval grants none of those — separate programs).

---

## PREREQUISITES (all must be true before recording)

- [ ] **BLOCKER FIX SHIPPED:** Instagram inbox settings page shows a read-only **Instagram Account ID** field next to the username/inbox name on `inbox.volitexai.tech` (data source: `inbox.instagram_id`, already stored in DB and returned by the inbox API — a UI field must render it). Verify it is visible in production before recording Video 3.
- [ ] Heroku app loads over HTTPS with no warnings; Volitex branding only (no Chatwoot strings); language set to English; bookmarks bar hidden; zoom 100%.
- [ ] WhatsApp inbox connected via manual setup; webhook verified (green) in Meta dashboard; message delivery tested end-to-end recently.
- [ ] WhatsApp business-initiated send (sidebar compose → template) rehearsed successfully. **If it fails rehearsal, cut Video 1 Part 2 — receive + reply alone satisfies the requirement.**
- [ ] WhatsApp templates synced at least once (Settings → Inboxes → WhatsApp inbox → Configuration → Sync Templates) so the template picker is populated.
- [ ] Instagram inbox connected and authorized; IG Business account linked to a Facebook Page; Instagram webhooks verified in Meta dashboard.
- [ ] The IG inbox's inbox name exactly matches the Instagram username (it is editable — rename it back if needed), so the username is correctly demonstrated in Video 3.
- [ ] Instagram OAuth login flow rehearsed so the PERMISSION GRANT SCREEN actually appears during recording. Reauthorize of an already-authorized account may skip the grant screen — use a fresh IG Business account connection, or first remove the app from the IG account's Facebook Settings → "Apps and websites" so the consent screen reappears. If V3 captures the full grant, V4/V5 may use a short reauthorize with narration referring back to V3.
- [ ] IG post with at least two public comments from a test account (for Video 5).
- [ ] A second phone/account ready as the "customer" (WhatsApp) and a personal IG account ready as the "commenting customer".
- [ ] Logged into Volitex as an agent; all notifications muted; close unrelated tabs/windows.
- [ ] Meta App Dashboard session logged in (needed for videos 2 and 4: WhatsApp Manager, API Integration Helper).

---

## VIDEO 1 — whatsapp_business_messaging (~60–75 sec)

**Requirement:** App sends a WhatsApp message to a number; the WhatsApp client receives and displays it.
**Route:** Live receive + agent reply (+ optional human-agent segment; + optional business-initiated template).

**Actions**
1. Customer phone: send a WhatsApp message to the business number ("Hi, I'm interested in your service").
2. Volitex: message appears in real time in the WhatsApp inbox conversation list. Open it.
3. Volitex: agent clicks "Assign to me", types a normal reply ("Thanks for reaching out — how can we help?"), sends.
4. Customer phone: reply arrives and displays in WhatsApp.
5. *(Optional — only if rehearsal passed)* Sidebar compose button (pen icon) → select customer → select WhatsApp inbox → choose an approved template → send. Customer phone: template message receives.

**Narration**
> "A customer sends a WhatsApp message to our business number. It arrives in real time in Volitex AI Inbox. The human agent assigns the conversation to themselves and replies directly from the platform, and the customer receives the reply in WhatsApp. This is how our platform uses the whatsapp_business_messaging permission to send and receive WhatsApp messages."

**Written description (paste in App Review)**
> "Volitex AI Inbox uses whatsapp_business_messaging to receive incoming WhatsApp messages from customers in real time and to send human-agent replies back to customers on WhatsApp. Volitex AI Inbox is our client-facing inbox platform that manages WhatsApp Business conversations for onboarded businesses. Messaging is performed through the WhatsApp Cloud API using the connected business phone number."

**Evidence the reviewer must see**
- Incoming message visible in Volitex, then on the phone.
- Agent typing and sending inside Volitex.
- Phone screen showing the received reply.

---

## VIDEO 2 — whatsapp_business_management (~60 sec)

**Requirement:** Demonstrate creating a message template **on the app or the WhatsApp Manager**.
**Route:** Create the template in the WhatsApp Manager (explicitly allowed), then show Volitex managing the WABA assets and syncing the template.

**Actions**
1. business.facebook.com → WhatsApp Manager → Message Templates → **Create template**: set name, category, language, body. Submit. Show it in the template list.
2. Volitex: Settings → Inboxes → [WhatsApp inbox] → open the **Account Health** tab: show Phone Number, Phone Number ID, Business Account ID, status/quality fields (these are the managed WABA assets).
3. Volitex: **Configuration** tab → click **Sync Templates**.
4. Volitex: open a WhatsApp conversation → template icon in the reply box → the just-synced template appears in the picker.

**Narration**
> "We create a message template in the WhatsApp Manager. In Volitex AI Inbox we manage the connected WhatsApp Business Account — here you can see the phone number, the phone number ID, and the business account ID — and we sync the approved message templates. The synced template is immediately available for our agents to use in conversations. This uses the whatsapp_business_management permission."

**Written description (paste in App Review)**
> "Volitex AI Inbox uses whatsapp_business_management to manage the WhatsApp Business Account assets of onboarded businesses. Our platform displays WhatsApp Business Account details — phone number, phone number ID and business account ID — and syncs approved message templates created in the WhatsApp Manager so agents can use them in customer conversations."

**Evidence the reviewer must see**
- Template creation form and submission in WhatsApp Manager.
- Asset fields (phone number ID, business account ID) rendered in Volitex.
- Sync Templates click → success toast → template visible in the conversation template picker.

---

## VIDEO 3 — instagram_business_basic (~75 sec)

**Requirement:** Demonstrate the complete Instagram login process (permission granted), then demonstrate getting basic metadata — **username and ID** — on your app platform.

**Actions**

*Part 1 — Login & grant (0–40s)*
1. Volitex: Settings → Inboxes → Add Inbox → Instagram → **Connect Instagram** (use a spare business IG account, or: open the existing IG inbox → Reauthorize, which shows the same full login + grant screens without deleting conversations).
2. Instagram/Facebook login screen: log in.
3. Permission grant screen: show the requested permissions, click Continue/Allow.
4. Redirect back to Volitex: inbox created successfully.

*Part 2 — Metadata (40–75s)*
5. Open the newly connected Instagram inbox (inbox list + inbox settings).
6. Show the **username** (inbox name = the IG username, e.g. `@yourbusiness`).
7. Show the read-only **Instagram Account ID** field in the inbox settings.

**Narration**
> "The user connects their Instagram Business account through the full login flow and grants the requested permissions, including instagram_business_basic. Once authorized, Volitex AI Inbox retrieves the account's basic metadata — here you can see the username and the Instagram Business account ID displayed in the platform. This uses the instagram_business_basic permission."

**Written description (paste in App Review)**
> "Volitex AI Inbox uses instagram_business_basic to read basic metadata of connected Instagram Business accounts. When a user completes the Instagram login flow and grants the permission, our platform retrieves the account's username and Instagram Business account ID and displays them, which we use to identify and route the business's conversations."

**Evidence the reviewer must see**
- Complete redirect → Instagram login → permission grant → redirect back sequence, uncut.
- Username visible as the inbox name.
- The Instagram Account ID rendered on screen (the blocker fix).

---

## VIDEO 4 — instagram_business_manage_messages (~90 sec)

**Requirement:** Login/permission grant; app sends an Instagram message and the Instagram client displays it; generate a cURL request via Meta's API Integration Helper.

**Actions**

*Part 1 — Grant (0–15s)*
1. Briefly re-run the authorization (Instagram inbox → Reauthorize → login → grant screen showing permissions incl. `instagram_business_manage_messages` → Continue).

*Part 2 — Receive + send DM (15–55s)*
2. Personal IG account: send a DM to the business account.
3. Volitex: DM appears in the Instagram inbox conversation.
4. Volitex: agent replies "Thanks for reaching out — how can we help?".
5. Personal IG account (Instagram app on phone): reply visible in the Instagram inbox.

*Part 3 — cURL via API Integration Helper (55–90s)*
6. Meta App Dashboard → Instagram → **API Integration Helper**.
7. Choose the send-message operation (POST `/{ig-user-id}/messages`), generate the cURL command.
8. Show the generated cURL with the access token and payload.

**Narration**
> "The user grants instagram_business_manage_messages during the Instagram login flow. A customer sends a direct message to our business account; it appears in Volitex AI Inbox, our agent replies, and the customer receives it in their Instagram inbox. Here is the cURL request generated with Meta's API Integration Helper for the send-message endpoint — this is the same Instagram Graph API call our platform makes to send replies. This uses the instagram_business_manage_messages permission."

**Written description (paste in App Review)**
> "Volitex AI Inbox uses instagram_business_manage_messages to view, manage, and respond to Instagram direct messages. Our platform receives incoming DMs in real time through Instagram webhooks and sends agent replies through the Instagram Graph API messaging endpoint — the same request shown as a cURL command generated from Meta's API Integration Helper."

**Evidence the reviewer must see**
- Grant screen showing the permission; DM visible in Volitex; agent reply sent; phone showing the reply in the IG inbox; the generated cURL on screen.

---

## VIDEO 5 — instagram_business_manage_comments (~90 sec)

**Requirement:** Login/permission grant; create a new comment; update an existing comment; delete a comment; show each result both in Volitex and the native Instagram app.

> **API fact (be precise, do not overclaim):** The Instagram API offers create, reply, delete, and hide/unhide for comments. There is **no text-edit endpoint**. The supported "update an existing comment" operation is toggling visibility via the update endpoint (`hide=true/false`). Do NOT narrate delete + recreate as an update.

**Actions**

*Part 1 — Grant (0–10s)*
1. Briefly re-run authorization and show `instagram_business_manage_comments` on the grant screen → Continue.

*Part 2 — Create (10–35s)*
2. Personal IG account: post a new comment on one of the business posts.
3. Volitex: open the Instagram inbox → **Comments** workspace (in the Instagram conversation) or Settings → Inboxes → IG inbox → **Comments** tab. The new comment appears under the media item. The same event also appears in the conversation list with the **"Instagram Comment"** badge.
4. Volitex: reply to the comment from the Comments Manager.
5. Native Instagram app: open the post → the reply is visible under the comment.

*Part 3 — Update (35–60s)*
6. Narrate: "The Instagram API supports updating an existing comment through its update operation — toggling whether the comment is hidden."
7. Volitex: click **Hide** on an existing comment. Show the comment marked hidden in Volitex.
8. Native Instagram app: open the post → the comment is no longer publicly displayed.
9. Volitex: click **Unhide** → native app shows it back.

*Part 4 — Delete (60–90s)*
10. Volitex: click **Delete** on a comment → it disappears from the Comments Manager (and optionally from the conversation's comment thread).
11. Native Instagram app: open the post → the comment is gone.

**Narration**
> "The user grants instagram_business_manage_comments during login. A customer comments on our Instagram post; the comment appears in our Comments Manager and as a conversation with an Instagram Comment badge. Our agent replies, and you can see the reply on the native Instagram post. To update an existing comment, our platform uses the Instagram update operation to hide or unhide it — the comment disappears and reappears on the post in the Instagram app. Finally, our agent deletes a comment, and it is removed from Instagram. This uses the instagram_business_manage_comments permission."

**Written description (paste in App Review)**
> "Volitex AI Inbox uses instagram_business_manage_comments to manage Instagram comments for onboarded businesses: receiving comments in real time in our Comments Manager, creating replies to comments, updating an existing comment's visibility through the Instagram comment update endpoint (hide/unhide), and deleting comments. All actions are reflected both in our platform and in the native Instagram post."
>
> **Implementation note for the review team:** the Instagram API does not provide a text-edit operation for comments; the update operation our platform demonstrates is the API-supported visibility update (hide/unhide).

**Evidence the reviewer must see**
- Grant screen; comment appearing in Volitex (Manager + badge); reply sent and visible on the native post; hide → hidden in native app → unhide → back; delete → removed in native app.

---

## ORDER & LOGISTICS

Record in this order: **V1 → V2 → V3 → V4 → V5** (V3 first if you want the login flow captured with maximum care and can use a spare IG business account).

Keep a human agent visible in V1 (assign + reply) — human-in-the-loop strengthens the WhatsApp messaging review without needing a separate Human Agent video (Human Agent is not one of the five requested permissions).

---

## PRE-SUBMISSION CHECKLIST

- [ ] Instagram Account ID field live in production and visible in Video 3
- [ ] Each clip = exactly one permission; no mixed permission demos
- [ ] Exact permission name spoken/shown in each clip's relevant segment
- [ ] Written descriptions pasted per permission (above), using "Volitex AI Inbox" product name and our agency context
- [ ] No localhost, no Chatwoot branding, no error toasts, no n8n/Groq/AI-automation content, no partner-program claims
- [ ] Native client footage included in V1, V4, V5
- [ ] cURL from Meta API Integration Helper visible in V4
- [ ] Videos uploaded to the matching permission in the App Review form; then Submit (not draft)
