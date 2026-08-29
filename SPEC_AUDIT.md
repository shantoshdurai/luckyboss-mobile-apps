# Lucky Boss — spec audit

_Checked 2026-08-29 against "Lucky Boss Portal Functional Specification" (81
sections), for the two Flutter apps only. The Laravel portal and the admin panel
are not covered — see the note at the end._

**Short answer: no, we have not satisfied everything.** Both apps cover the
sections that matter for a candidate and a recruiter on a phone. What is
missing splits cleanly in two: **the admin app, which does not exist at all**,
and **the employer features that need a server** — interviews, offer letters,
email, packages, AI keys.

Legend: **Done** · **Partial** · **Missing** · **Server** (blocked on Laravel) ·
**Admin** (belongs to the admin panel, out of scope for these two apps)

---

## Job seeker app

| § | Section | State | Note |
|---|---|---|---|
| 28 | Three-table dashboard | **Partial** | Applied / Recommended / External all exist as feed sections. Rendered as cards, not tables — a seven-column table is not readable on a handset. |
| 29 | Minimum registration | **Done** | Name, phone, email, password. Asked in the new account step. |
| 30 | After quick registration | **Done** | Search, save, apply immediately; completion percentage on home. |
| 31 | Complete resume profile | **Done** | All 20 fields present, including the ones missing before: languages, notice period, availability, work permit, certificates, photo. |
| 32 | AI resume builder | **Partial** | Case 2 (manual) works. Case 1 needs `POST /api/v1/resume/parse`, which does not exist. Case 3 (candidate BYOAI) the spec itself recommends against for v1. |
| 62 | Job seeker payment | **Missing** | `PurchaseRecord` model exists; no payment flow. Spec has this OFF initially. |
| 63 | Paid apply job | **Missing** | `JobModel.applicationFee` is carried and displayed; nothing charges. |
| 64 | Multi-currency | **Done** | INR / SGD / MYR throughout, with pay periods. |
| 65 | Purchase history | **Partial** | Model exists, no screen. |
| 80 | Job seeker dashboard | **Partial** | Profile completion, applied, matching, saved, interviews, offers all computed. Purchase History section missing. |
| 81 | Chatbot | **Done** | Lucky AI, reachable from the header and the drawer. |

## Employer app

| § | Section | State | Note |
|---|---|---|---|
| 13–16 | Three candidate tables | **Done** | Applied / Recommended / External, source named on external rows. |
| 17 | Phone & email quick contact | **Partial** | Tap to copy. Tap-to-dial and mail composer need `url_launcher`. |
| 18 | Action button | **Partial** | Status change, archive, notes, match explanation. Missing the ones needing a server: email, WhatsApp, portal message, assessment, letters. |
| 19–20 | Interview schedule + notification | **Server** | Needs an endpoint and FCM. Deliberately not on the menu as a dead button. |
| 21–23 | Archive candidate | **Done** | Reason recorded, scoped to job, restorable. |
| 24 | Bulk actions | **Missing** | No multi-select on the candidate list. |
| 25 | Match score visual | **Done** | Percentage plus STRONG/FAIR/WEAK. |
| 26 | Match explanation | **Done** | Plain-English reasons, including what is missing. |
| 27 | No-AI matching fallback | **Done** | The scorer is rule-based; it needs no model at all. |
| 33–38 | Subscriptions, grades, packages, expiry | **Partial** | Credits and expiry are shown. Package tiers, grades and assignment are **Admin**. |
| 34 | Company type | **Done** | Blue-collar-first list, used in registration. |
| 39 | Employer role management | **Missing** | Single user per company. Multi-recruiter needs accounts, i.e. a server. |
| 40 | Company identity lock | **Partial** | Identity travels with every posting; the lock itself is a server rule. |
| 41–42 | Offer letter | **Server** | |
| 43–45 | Email composer, schedule, calendar | **Server** | |
| 46 | Candidate status | **Done** | Six stages, persisted. |
| 55 | Real-time alert centre | **Partial** | Notifications derived from live state; push needs FCM (§47–53). |
| 61 | Job promotion | **Done** | Featured / Urgent / Sponsored with dates, priority and pricing. |
| 66 | Employer payment history | **Done** | Charges recorded and shown in settings. |
| 71–74 | Contact access, security, activity log | **Partial** | Credits and masking done. The activity log (§74) is not recorded. |
| 75 | Employer notes | **Done** | |
| 76 | Assign recruiter | **Missing** | Needs multi-user, so a server. |
| 77 | Kanban + table | **Partial** | Table view only. Spec calls Kanban optional and later. |
| 78 | Employer dashboard | **Done** | All nine cards. |

## Not started at all

| § | Section | Note |
|---|---|---|
| 3 | Central feature control | **Admin** — every toggle in the app currently reads a local default. |
| 4–12 | Two-tier AI, employer API keys, security, package access | **Admin** + **Server**. §11 in particular is about key storage, which must never touch a handset. |
| 47–54 | Notification sounds | Needs FCM. |
| 57–60 | Home page management, category order, specialisations, sliders | **Admin**. Category order is currently a fixed list in `app_data.dart`. |
| 67–70 | AI usage accounting, API failure log, third-party jobs/candidates admin | **Admin**. |
| 79 | Admin dashboard | **Admin app does not exist.** |

---

## What this means

Three separate pieces of work remain, and they are not the same size:

1. **The Laravel API.** `POST /api/v1/employer/jobs`, resume parsing, company
   verification, interview scheduling, offer letters, email. Roughly a third of
   the spec is waiting on this, and both apps are already shaped to call it —
   the JSON columns match the MySQL tables.

2. **The admin panel.** Sections 3, 4–12, 57–60, 67–70 and 79 are an admin
   product, and nothing has been built for it. It is the largest untouched
   piece of the specification. Worth confirming with sir whether that is the
   web portal's job (`luckyboss-website`) rather than a third app.

3. **Small gaps in the two apps**, none blocked on anything:
   - Bulk actions on the candidate list (§24)
   - Tap-to-dial and mail composer (§17) — one package
   - Contact activity log (§74)
   - Purchase history screen for candidates (§65)

_Everything marked **Server** or **Admin** is deliberately absent rather than
half-built. A scheduling screen that cannot send an invitation, or a package
selector that enforces nothing, would look finished in a demo and mislead
whoever relied on it._
