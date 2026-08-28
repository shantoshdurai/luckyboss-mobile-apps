# Lucky Boss — Round 4 plan

_Written 2026-08-28 from Shantosh's review of the employer portal._

**Status: sections 1, 2, 4.1 and 4.2 are now BUILT.** What remains is section 3
(AI chat, notifications, drawer, rebuilding the company profile tab), section 5
(the category-order question and the Laravel endpoints), and the parts of 4.2
not yet done. See "What landed" at the foot of this file.

**Order to work in:** Section 1 (bugs — these are wrong right now, not missing),
then 2 (registration & verification, the biggest piece), then 3 (parity), then
4 (interaction, touches both apps), then 5 (data).

---

## 1. Confirmed bugs — fix before anything else

### 1.1 "Register your company" is a dead button
`lib/screens/auth/employer_login_screen.dart:251` — `onPressed: () {}`. It
renders, it is tappable, and it does nothing. Whatever else happens to
registration, this button must either work or not be on screen.

### 1.2 A posted job never says who posted it
Shantosh: *"we put a job but it doesn't even say what company we are and which
company posted the job. That's not right, right?"*

Two separate faults:

- `post_job_wizard_screen.dart:140` sets `companyName: provider.company.name`,
  which is `''` for anyone who has not filled in their profile — and nothing
  makes them. So the field is usually empty at the moment of posting.
- `active_jobs_tab.dart` never renders `companyName` at all, so even when it is
  set nobody sees it.

Fix both, and make company name non-empty before a job can be posted (see §2.4).

### 1.3 Requirement chips cannot be searched
Shantosh: *"they cant even search skills fix it have search and add"*

Screenshot 3 — step 2 of the posting wizard lists ~25 ability chips with no way
to filter and no way to add one that is missing. It is worse than it looks: the
full ability list for Construction is longer, so an employer scrolls a wall of
chips hunting for "Scaffolding".

Add a search field above the chip grid that filters as you type, plus an "add
this" affordance for a term not in the list. **The job seeker app has the same
problem** in `TradeStep` and in `ProfileFieldEditor` — the free-text row added
last session helps but there is still no filtering of a long list. Build one
widget and use it in both apps: `widgets/searchable_chip_picker.dart`.

---

## 2. Company registration and verification

Shantosh: *"in the register their company you need to ask for everything which
matters for a company like their certificates to verify their identity, their
company names... and it is not straight register, we take all info to process to
verify them with AI letting them know we contact them after verification"*

And: *"they need to get verified before even applying"* — i.e. before posting.

This is the biggest piece of work in this round. Right now anyone types any
email and an 8-character password and is inside with a live employer account.

### 2.1 A registration wizard, not a form
New: `lib/screens/auth/company_registration_screen.dart`. Same four-step shape
as the posting wizard so it feels like one app.

1. **Company** — legal name, trading name, company type (`CompanyProfile.types`,
   already exists and is blue-collar first), country, city, address, year
   established, company size.
2. **Contact** — contact person name, role, work email, phone, WhatsApp.
3. **Proof** — the documents. This is the point of the whole flow:
   - Business registration / incorporation certificate (**required**)
   - Licence to operate where the trade needs one — employment agency licence,
     construction registration, and so on
   - Tax or GST registration
   - Company photos — office, site, premises (Shantosh: *"they need to upload
     their company pictures in the profile"*)
   - Logo — **he questioned whether this is needed** (*"logo or logo do we need
     logo I don't think so"*). Ask him. My recommendation: keep it, optional,
     because a job card with a logo reads as a real employer to a candidate. Not
     a blocker either way.
4. **Review & submit** — show everything back, then submit.

All uploads go through the existing shared `DocumentService` +
`UploadedDocument` (already copied into the employer app). Add
`DocumentKind.companyRegistration`, `.licence`, `.taxCertificate`,
`.companyPhoto`.

### 2.2 Verification states
`CompanyProfile` needs a status, and it must behave like the candidate licence
states — the app can never mark itself verified.

```
enum CompanyStatus { draft, submitted, underReview, verified, rejected }
```

After submit the app shows a holding screen: *"We have your documents. Lucky
Boss will verify them and contact you on <phone> — usually within one working
day."* Not a spinner, not a fake progress bar. Rejected shows the reason and
what to re-upload.

### 2.3 Where the AI check goes
He wants AI to do the first pass. Do **not** let the handset decide — same rule
as candidate licences. The shape:

1. App uploads documents and submits.
2. Server runs a vision/OCR pass: does the registration certificate name match
   the company name given, is it in date, is the licence number well-formed.
3. AI output is a **recommendation with a confidence**, written to the record.
4. A human at Lucky Boss approves or rejects.
5. Only the server flips `CompanyStatus.verified`.

Until the endpoint exists, the standalone build should submit locally, sit at
`submitted`, and say plainly that verification happens once they are online.
Never auto-verify to unblock the demo — that is the same lie as the old fake
auth, and it teaches sir the wrong thing about what is working.

### 2.4 Gating
An unverified company may: register, fill in its profile, browse. It may **not**
publish a job or reveal candidate contacts. Posting while unverified should save
as `JobStatus.draft` with a clear banner, not fail silently.

Decide with Shantosh whether a demo bypass flag is wanted for showing sir.

---

## 3. Parity with the job seeker app

Shantosh: *"we don't even have a dashboard for settings and stuff or any other
thing, a chat... we are not having anything which we had in the job seeker app"*

The seeker app has these; the employer app has none of them:

| Seeker app | Employer app | Notes |
|---|---|---|
| `notifications_screen.dart` | — | New applicant, interview due, expiry warnings |
| `lucky_ai_copilot_modal.dart` | — | Job description writing, match explanations. AI credits already counted on the dashboard |
| `app_drawer.dart` | — | Brand header, navigation, sign-out |
| Settings (theme, notifications) | — | Dark mode toggle exists on the provider but is unreachable |
| `seeker_profile_tab.dart` (rebuilt) | `company_profile_tab.dart` (old design) | Only screen left on the pre-rebuild design; now visibly out of place |

Rebuild `company_profile_tab.dart` on the new design system while doing this —
company details, documents with their verification state, photos, plan, team,
settings, sign-out.

---

## 4. Interaction — applies to BOTH apps

### 4.1 Auto-advance with animation
Shantosh: *"if they click something it automatically gives an animation and then
moves towards something like below... so that they don't want to scroll manually
and it will make the process very fast and effective"*

On a **single-select** answer, scroll the next question into view with a short
animation. Two rules that matter:

- Only for single-select. Auto-scrolling after a multi-select tap fights the
  user, who is not finished choosing.
- Never auto-advance the whole step. Moving to the next screen on one tap makes
  a mis-tap unrecoverable without a Back press.

Implementation: `GlobalKey` per `RevealedField`, then
`Scrollable.ensureVisible(key.currentContext, duration: 300ms,
curve: Curves.easeInOut, alignment: 0.1)` after the selection's `setState`.
Wrap it in the existing `RevealedField` so every wizard gets it at once.

Screens affected: seeker `TradeStep`, `FieldDetailsStep`, `WorkCategoryStep`,
`EducationStep`, `WorkStep`; employer posting wizard steps 1–4; the new
registration wizard.

### 4.2 Multiple selection where it makes sense
Shantosh: *"choosing Indian, Malaysian, Singapore — let them have three of them.
What if they want three countries... not for everything, for things which can be
given multiple options"* — and he stressed this applies **mainly to the job
seeker app**.

Change to multi-select:

- **Preferred country** — seeker onboarding and feed prompt. Someone open to
  Singapore *and* Malaysia is the normal case for this agency, not the exception.
- **Preferred city / location** — same reasoning.
- **Job category (seeker)** — a general worker will take construction or
  warehouse. Cap at 3 so matching stays meaningful.
- **Shift pattern (employer)** — a site often runs day *and* night.
- **Employer target country** — a company hiring across markets.

Leave single-select:

- **Trade / role** — on both sides. A candidate who is a plumber *and* an
  electrician *and* a welder is not credible to an employer, and it wrecks the
  match score. If he pushes, cap at 2 with a "main trade" marked.
- **Work permit status** — mutually exclusive by definition.
- **Availability**, **pay period** — one answer each.

**This is a schema change, so do it deliberately:**
`SeekerProfileModel.preferredCountry` → `preferredCountries` (list);
`EmployerJobModel.countryCode` → keep single (a job is at one site) but let the
*search* accept several. `fromJson` must read the old key and migrate, or every
existing install loses its answer. There are tests covering both fields — update
them in the same commit.

---

## 5. Data and backend

### 5.1 Job category order — **QUESTION FOR SHANTOSH**
He wrote: *"i feel in job catogry it and service needs to be in top like prety
which one will be demand more like that"*

Two readings and I could not tell which:

- **(a)** Order categories by hiring demand rather than the spec's §58 order.
- **(b)** "IT and Service" specifically should move to the top.

I have not changed anything, because (b) reverses the blue-collar-first decision
from earlier in the week and spec §58 explicitly sets Construction, Manufacturing,
Warehouse as 1-2-3. **Ask him which he meant before touching `AppData`.** If it
is (a), the honest fix is to sort by live vacancy count per category rather than
guessing a fixed order.

### 5.2 The posting → seeker contract
He asked me to think ahead about how the backend connects the two apps.

The groundwork is already done: `EmployerJobModel.toJson()` writes the same
snake_case columns that `JobModel.fromCatalogJson()` reads, and both apps share
the 119-role taxonomy. So a job posted in the employer app is already in the
shape the seeker app consumes.

What is missing:

1. **Company identity travels with the job.** Add to the payload:
   `company_id`, `company_name`, `company_logo_url`, `company_verified`,
   `company_type`. The seeker's job card and detail screen should show the
   company and a verified mark — that is what he is asking for in §1.2.
2. **`POST /api/v1/employer/jobs`** does not exist. `routes/api.php` registers
   `GET /jobs` and `GET /jobs/{job}` only. The old provider had a note about
   this; the endpoint still needs building in Laravel.
3. **Only verified companies' jobs reach the feed** — server-side filter, not a
   client one.
4. **Applications flow back**: a seeker applying should create a row the
   employer's Applied table reads, replacing that slice of the seeded pool.

---

## Current state at end of this session

- **Job seeker**: `flutter analyze` clean, 33/33 tests. APK
  `downloads/LuckyBoss_JobSeeker_v1.2.0.apk`. Web on `127.0.0.1:8099`.
- **Employer**: `flutter analyze` clean except one deprecation in the untouched
  `company_profile_tab.dart`, 15/15 tests. APK
  `downloads/LuckyBoss_EmployerPortal_v2.0.0.apk`. Web on `127.0.0.1:8100`.
- Both local web servers are still running — kill them with `taskkill` or just
  close the session.
- **Still not pushed to GitHub.** Both repos hold the old build and need
  Shantosh's go-ahead (task 5.2 in `TASKS.md`).


---

## What landed (same session, after the plan was written)

### §1 — the bugs
- **1.1** "Register your company" now opens
  `screens/auth/company_registration_screen.dart`. It was `onPressed: () {}`.
- **1.2** Jobs carry `companyId`, `companyName`, `companyLogoUrl`,
  `companyVerified` and `companyType`, all in the MySQL column shape the seeker
  app reads. The jobs list renders the company with a verified tick, and shows
  "No company name set" in red if it is missing. Posting without a company name
  now asks for it in a dialog rather than posting anonymously.
- **1.3** New `widgets/searchable_chip_picker.dart`, in **both** apps. Search
  appears only above 12 options, selected chips survive filtering, and anything
  typed can be added. Wired into the seeker's trade step (roles, abilities,
  licences) and the employer's posting wizard (roles, abilities, licences).

### §2 — registration and verification
- Four-step wizard: company → contact → proof → review, ending in
  `screens/auth/verification_pending_screen.dart`.
- New `DocumentKind`s: `companyRegistration` (required), `licence`,
  `taxCertificate`, `companyPhoto`. All go through the shared `DocumentService`.
- `CompanyStatus { draft, submitted, underReview, verified, rejected }`.
  `submitForVerification()` moves to `submitted` and **stops there** — the app
  can never verify itself.
- **Gating is live.** An unverified company saves vacancies as `JobStatus.draft`
  rather than losing them, and cannot spend a contact credit on a candidate who
  did not apply. A banner on the dashboard says why.

### §3 — partial
- `screens/settings_screen.dart`: verification state, dark mode (the provider
  had a toggle no screen exposed), plan counters, account, and sign-out — which
  did not exist at all. Reached from the dashboard header.
- **Still missing:** AI copilot chat, notifications screen, drawer, and the
  company profile tab is still on the old design.

### §4 — interaction
- **4.1** `revealNextQuestion()` in `onboarding_components.dart`, used by the
  seeker trade step and all four employer wizard steps. Single-select only, and
  it never advances a whole step.
- **4.2** Seeker `preferredCountry` → `preferredCountries` (list), with
  `fromJson` reading the old key so existing installs keep their answer — there
  is a test for exactly that. The feed prompt is now multi-choice. Employer
  target country stays single: a vacancy is at one site.
- **Not yet done:** multi-select for preferred city, seeker job category
  (cap 3), and employer shift pattern.

**Tests: seeker 35/35, employer 19/19. `flutter analyze` clean on both** apart
from one deprecation in the untouched `company_profile_tab.dart`.


---

## Round 5 — §3 parity, §4.2 completion, and the Enter-key bug

### The Enter key jumping tabs — root cause found
Shantosh reported it twice: *"many tabs have this problem of keyboard — after
typing, when I press enter it goes to another tab."*

A `TextField` with neither `textInputAction` nor `onSubmitted` falls back to
Flutter's **default focus traversal** on Enter. Traversal walks the whole widget
tree looking for the next focusable thing, and on a tabbed screen that is
frequently a tab — which then takes the keypress. Fixed from both ends:

- Every tab body is wrapped in a `FocusTraversalGroup`, and both bottom
  navigation bars are inside `ExcludeFocus`, so focus cannot leave the tab it
  started in. Same for the employer ATS `TabBarView`, which sits above the
  notes field.
- Nine remaining fields across both apps got an explicit
  `textInputAction: done` + `onSubmitted: unfocus`, so they never reach the
  fallback at all.

### Category order — decided
Fixed order, ranked by demand. **Construction first, IT & Software second**,
then Manufacturing, Warehouse, Healthcare, Hospitality, Driving, Retail, Maid &
Caregiver, Office, Engineering, Security, Cleaning, Finance.

This deviates from spec §58 (Construction, Manufacturing, Warehouse as 1-2-3).
Shantosh made the call explicitly after I flagged the conflict: *"we need to
have fixed... IT needs more priority than others, not deserve last place, [make
it] 2nd one."* IT moved from thirteenth to second; the field categories that
carry the agency's volume all stay on the first screen. Regenerated
`app_data.dart`, `seed_jobs.json` and `seed_candidates.json` from the same
source, and the order test now pins the new arrangement with the reasoning.

### §3 parity — done
- **`employer_notifications_screen.dart`** — derived from real state, not a
  placeholder: verification blocking publishing, drafts not live, new applicants
  per job, strong matches nobody has opened, interviews, offers, expiry,
  low credits.
- **Lucky AI for employers** — `employer_copilot_service.dart`. Tries the
  Laravel endpoint, and when that fails answers from the jobs and candidates
  **on the device**, labelled `FROM YOUR LUCKY BOSS DATA — NOT AI`.
- **`settings_screen.dart`** — verification state, dark mode (a provider toggle
  no screen exposed), plan counters, account, sign-out (which did not exist).
- **`company_profile_tab.dart` rebuilt** on the shared design system, with
  workplace photos and per-document verification state.

### The seeker copilot was fabricating salary figures
Found while building the employer one. With the server unreachable it returned
hardcoded bands — "Singapore SGD 3,500–5,500", "India INR 8–15 LPA" — marked
`isLive: true`, directly below a comment promising "no fabricated fallback". A
candidate deciding what to ask an employer for was being handed numbers nobody
had checked, dressed as advice.

Replaced with an answer computed from the 168 real vacancies in the bundled
catalogue, marked `isLive: false`. Two tests pin it, including one asserting the
old invented figures never appear.

A second bug surfaced from that test: only a *network exception* fell back to
the catalogue. A server answering 500 gave a bare "unavailable" while an
unreachable one gave a useful answer — the same event from the candidate's side.
Both paths now fall back.

### §4.2 — completed
- Employer **shift pattern** is multi-select (a site runs days and nights).
- Seeker **job category** is multi-select, capped at 3, with the first choice
  marked "Main work" because it decides the rest of the wizard. Matching scores
  against every chosen category and takes the best — using only the first would
  rank a warehouse job at 25% for someone who said they would take warehouse
  work, just not first.
- Old single-value keys still read on load, so existing installs keep their
  answers.

**Tests: seeker 37/37, employer 25/25. `flutter analyze` clean on both.**

### Still open
- Seeker home feed layout — Shantosh picked this as next.
- Employer drawer.
- Interview scheduling (§19–20), offer letters (§41–42), email/WhatsApp actions
  — all need Laravel endpoints that do not exist.
- **Still not pushed to GitHub.**
