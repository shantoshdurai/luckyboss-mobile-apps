# Lucky Boss — Task Notepad
_Started 2026-08-28. Jobseeker app first, then employer portal._

**Decisions (Shantosh, 2026-08-28):** local account persisted on-device, app fully
works with no server; category-first onboarding fork with two paths (trade / office);
package id stays `com.userapp.luckyboss_jobseeker`, only the label changes; English
only in V1 but screens designed icon-first so translation drops in later.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · `[?]` needs Shantosh/sir

---

## Phase 0 — Findings (done, no code)

- **The pushed repo is the old build.** `shantoshdurai/luckyboss-mobile-apps` and
  sir's `Thirumoorthy-a/luckybossapp` (which nests `luckyboss-mobile-apps-2/`) both
  still contain `phone_auth_screen.dart`, `firebase_auth_service.dart`,
  `profile_setup_screen.dart`. The local `C:\Luckyboss\luckyboss_jobseeker` is ahead
  of both. Sir is reviewing an APK built from the old tree — that is why "it's old build".
- **Sir's repo is a Laravel app**, not a Flutter one. The only things worth harvesting:
  - `luckyboss-mobile-apps-2/luckyboss_employer/assets/images/icon.png` + the full
    adaptive launcher set (`ic_launcher_foreground.png` in every `drawable-*dpi`).
    Our jobseeker has only a flat `mipmap-*/ic_launcher.png` and no `icon.png`.
  - `luckyboss_employer/lib/screens/auth/employer_signup_screen.dart` (we have no signup).
  - `luckyboss_*/lib/widgets/profile_avatar.dart`.
  Everything else in his tree is older than ours.
- **Root cause of BOTH reported bugs is one line of code.** `AuthService._persist()`
  is called only inside `_post()` on an HTTP 200. Every offline fallback session
  (`local-email-session`, `standalone-phone-session`, `demo-offline-token`) returns
  `AuthResult.ok` **without ever writing to SharedPreferences**. Therefore:
  - restart the app → `currentSession()` is null → thrown back to sign-in;
  - tap the photo → `authHeaders()` has no `Authorization` → the exact string
    "Please sign in again to update your photo."
- **The spec is already blue-collar-first and our app drifted away from it.**
  Spec §58 job category display order: **1 Construction, 2 Manufacturing, 3 Warehouse**.
  §59 specialisations: Maid & Caregiver, Construction Worker, Manufacturing Labour,
  Warehouse Manpower, Logistics, Healthcare, Hospitality, IT, Engineering, Retail,
  Administration, Work Permit Services. §34 company types include Maid Agency and
  Domestic Worker Agency. Our `AppData.categories` is `IT & Software` first and
  `verifiedSkillDictionary` is 80% programming languages. Sir is not asking for a
  new direction — he is asking us to stop ignoring the spec we were given.
- Spec §31 already lists the fields blue-collar hiring needs: **Languages, Notice
  Period, Availability, Work Permit Information, Preferred Salary, Preferred Location** —
  none of which are in our onboarding wizard today.

---

## Phase 1 — Bugs sir hit (highest priority)

- [x] **1.1 Persist offline sessions.** Move `_persist()` out of `_post()` so every
      successful `AuthResult.ok` is written, including the local/offline ones.
- [x] **1.2 Profile photo must save on-device.** Rewrite `ProfilePhotoService` to
      write the picked image into app documents dir and store the path in the
      profile; attempt the server upload only when a real Sanctum token is present,
      and never fail the local save because the server is unreachable.
- [x] **1.3 Remove the last hardcoded fake data** — `+919876543210` appears three
      times in `auth_service.dart`; `'Santosh Durai'` in `loginDemo()`.
- [x] **1.4 Everything the user types must survive app restart** — profile, skills,
      resume filename, applications, saved jobs. Audit `JobSeekerProvider` for what
      is memory-only today.

## Phase 2 — Identity (app name + icon)

- [x] **2.1** `android:label` → `LuckyBoss` (currently "Lucky Boss").
- [x] **2.2** Adopt the icon from sir's repo: copy `icon.png` + adaptive foreground
      into our jobseeker, generate all densities, add `ic_launcher.xml` adaptive
      config, iOS appiconset, web favicon.
- [x] **2.3** Package id stays `com.userapp.luckyboss_jobseeker` (decided).

## Phase 3 — Standalone APK (no server, no MySQL yet)

- [x] **3.1** Local persistence layer: one `LocalStore` over SharedPreferences that
      owns profile, applications, saved jobs, photo path, resume file.
- [x] **3.2** Bundle a seed job catalogue as a JSON asset covering the spec §58/§59
      categories, so a fresh APK shows real-looking jobs with no backend.
- [ ] **3.3** Keep every API call behind a "if server reachable, sync; else local"
      path so the MySQL switch later is config, not a rewrite.

## Phase 4 — Open the app to all worker types (the main ask)

- [x] **4.1** Rewrite `AppData.categories` to spec §58/§59 order, Construction first.
- [x] **4.2** Split the skill dictionary into per-category vocabularies (trades,
      equipment, certificates) instead of one IT-heavy list.
- [x] **4.3** **Onboarding fork.** First question becomes "What kind of work are you
      looking for?" → a category grid (Construction, Manufacturing, Warehouse,
      Driving & Delivery, Maid & Caregiver, Hospitality, Healthcare, Retail,
      Security, Office & Admin, IT & Engineering). The chosen category decides
      which questions come next.
- [x] **4.4** **Field/trade path collects, instead of "skills":** trade + years done,
      licences & certificates (driving class, forklift, scaffolding, safety card),
      languages spoken, work permit / visa status, expected wage (daily or monthly),
      willing to relocate, availability to start, preferred work location.
      All spec §31 fields — this is filling a gap, not inventing scope.
- [~] **4.5** Home screen must reflect this: category strip leads with Construction,
      and the feed prompt questions adapt to the chosen path.
- [ ] **4.6** Low-text mode — icon-driven choices, minimal typing. English only in
      V1; keep user-facing strings in one place so Tamil/Hindi drops in later.

## Phase 5 — Ship

- [x] **5.1a** Builds clean. `flutter analyze` clean, 16/16 tests pass
      (`test/persistence_test.dart` covers both of sir's bugs). APK at
      `downloads/LuckyBoss_JobSeeker_v1.1.0.apk` (arm64, 21.3 MB).
- [ ] **5.1b** *Sir still has to confirm on the handset:* sign in → close the
      app → reopen → still signed in; then set a profile photo and reopen again.
- [ ] **5.2** Push the *current* tree to `shantoshdurai/luckyboss-mobile-apps` so the
      repo stops showing the old build.
- [ ] **5.3** Update `downloads/` APKs.

## Phase 6 — Employer portal (after jobseeker signs off)

- [ ] **6.1** Same treatment: local persistence, session that survives restart, icon+name.
- [ ] **6.2** Port `employer_signup_screen.dart` from sir's repo — we have no signup.
- [ ] **6.3** Post-vacancy wizard must offer blue-collar fields: wage per day/month,
      accommodation provided, transport provided, work permit sponsored, shift type.
- [ ] **6.4** Rebuild the employer UI to the standard of the new jobseeker app.


---

## Progress log

**2026-08-28 — Phase 1, 2, and most of 3 and 4 landed.**

*Bugs*
- `AuthService` now persists every successful sign-in, including the on-device
  ones. New `AuthSession.isLocal` marks an account that no server issued, and
  `authHeaders()` refuses to attach that token to a request. Fake `+919876543210`
  and the invented 'Santosh Durai' demo name are gone.
- `ProfilePhotoService` saves the photo on the handset as a `data:` URI first and
  treats the upload as a bonus. `ProfilePhotoAvatar` renders local photos through
  `Image.memory`, because `Image.network` cannot read a data URI on Android.
- New `LocalStore` + `JobSeekerProvider.hydrateFromDevice()`. The provider held
  everything in memory and nothing on disk; the write now hangs off
  `notifyListeners()` (debounced 400ms) so no future mutation can forget to save.
  Sign-out clears it.

*Identity*
- Label is `LuckyBoss` / `LuckyBoss Employer` on Android, iOS and web.
- Real agency crest from sir's repo generated into every Android density, an
  adaptive icon (circular cut-out on black), the full iOS appiconset and web
  icons — for both apps.

*Opening the app to all workers*
- `AppData` rewritten around a `WorkCategory` type carrying icon, `WorkPath`,
  roles, abilities and certificates. 14 categories in spec §58/§59 order,
  Construction first.
- New onboarding fork: category grid → (trade, years, work, licences) or
  (background, education/work, key skills). Field path requires no typing.
- Profile gained `roleTitle`, `certificates`, `workPermitStatus`, `payPeriod`.
- Two profile-strength tables. The single old formula put 42% of the score
  behind a resume and an "Executive Bio", so a field candidate could fill in
  everything true about them and still be told they were incomplete.
- Boost cards, the field editor, the profile tab and the offline skill taxonomy
  all follow the fork. New Licences & Cards section.
- Seed job catalogue: 19 field vacancies across all the new categories, so
  choosing Construction no longer lands on an empty feed.


---

## What is left, in order

1. **4.5 — the home feed still opens on the old shape.** The category strip now
   leads with Construction and the feed prompts persist, but the home screen was
   written for a professional candidate. It should lead with the chosen category
   and its prompts should adapt to the path.
2. **4.6 — low-text pass.** The onboarding field path needs no typing now; the
   rest of the app has not had that pass. English only in V1 by decision, but
   keep strings in one place.
3. **5.2 — push the current tree.** Both `shantoshdurai/luckyboss-mobile-apps`
   and sir's repo still hold the old build. Until this happens sir keeps
   reviewing work that was superseded weeks ago. **Needs Shantosh to authorise
   the push.**
4. **Phase 6 — employer portal.** Icons and app name are done for it; nothing
   else is. Its login screen still has no signup, its provider has no
   persistence, and the post-vacancy wizard has no blue-collar fields (wage per
   day, accommodation, transport, permit sponsorship, shift).


---

## Round 2 — Shantosh's review, 2026-08-28 evening

His words, and what was done about each.

**1. "You did not have fixed jobs as of now for their different job
recommendation… we just have backend engineering and something."**
The catalogue was six hand-typed Dart vacancies, four of them software. Now
`assets/data/seed_jobs.json` — **168 vacancies, every category in all three
markets**, loaded through `JobCatalogService`.

**2. "Make fake data which in future we can retrieve back and clean them all and
make the portal work from the MySQL jobs."**
Every row is shaped like a `jobs` table row (snake_case columns) and carries
`"seed": true` with an id prefixed `seed-`. Load it into MySQL unchanged; remove
it later with `DELETE FROM jobs WHERE seed = 1`. `JobCatalogService.fetch()`
already prefers the server, so real postings displace the samples with no code
change. A test asserts both markers stay intact.

**3. "In search jobs it still suggests browse by category… they already gave
those details."**
Replaced. The search screen now opens on **jobs in the candidate's own
category, their trade first**. The full category list moved behind "Looking for
a different kind of work?".

**4. "I can't add profile pictures even though it says choose from device."**
Root cause: `image_picker`'s gallery path opens a hidden file input that does
nothing in a browser, and cannot select a PDF at all. All picking moved to a new
`DocumentService` built on `file_picker` (real file dialog on web — which accepts
a dragged file — system picker on a handset, bytes not paths). Camera still goes
through `image_picker`, which is what it is good at.

**5. "It has add licence and ITI certificate and something but it doesn't mean
what I picked."**
Certificates hung off the *category*, so every trade saw the same five cards.
Introduced `WorkRole`: **119 roles, each with its own abilities and licences**.
A plumber is now offered a Plumbing Licence and a trade test — not a crane
licence. Test: `a plumber is not offered a crane licence`.

**6. "They can upload the certificate which AI will verify later… we click save,
it doesn't mean they're uploading."**
New `LicencesSheet`. Each licence has two distinct states — **claimed** (ticked)
and **uploaded** (the card itself, photo or PDF, marked *Awaiting verification*).
The app can never mark anything verified; only the server may. The profile chips
show `Not uploaded` / `Checking` / `Verified` so the two are never confused. The
button says **Done**, not Save, because every tap is already written.

**7. "List the work you can do" opening a box hinting Flutter / Patient Care.**
That editor is now chips drawn from the candidate's own role, with a typed
entry as an escape hatch below.

**Also fixed, found while working:**
- A construction candidate got **no recommendations at all** — the scorer
  returned 0 whenever `skills` was empty, and the trade path does not fill that
  field first. Matching now scores trade (45), category (25), skills (20),
  licences (10), and a missing *required* licence caps the match at 55 rather
  than pretending the job is open.
- Recommendations and the partner feed were showing other countries' jobs.
- The résumé upload discarded the file when the parser endpoint failed. It now
  keeps the document first and parses only as a bonus.

`flutter analyze` clean · **33/33 tests pass**.

### Still open
- Home feed layout is still shaped for a professional candidate (task 4.5).
- Employer portal — Phase 6, not started beyond icon and name.
- Pushing to GitHub still needs Shantosh's go-ahead (task 5.2).


---

## Round 3 — jobseeker polish, and the employer portal

### Jobseeker fixes

**Profile picture — root cause found.** Both plugins fail on web: `image_picker`'s
gallery path opened nothing, then `file_picker` threw ("Could not open the file
picker on this device"). Web now uses a plain `<input type="file">` through
`dart:js_interop` — no plugin. Handsets keep `file_picker`. See
`lib/services/platform_file_picker/`. Two subtleties handled: the input must be
attached to the document for `.click()` to work in Safari, and there is no
cancel event in older browsers, so a window-focus fallback resolves the future
without cutting short a large file still being read.

**City dropdown.** `CityField.minChars`; the search screen requires 2 characters.
Onboarding keeps tap-to-see-cities.

**Clear buttons.** X on both search fields, "Clear all" plus per-row X on recent
searches. Clearing both fields drops back to the entry view.

**Filters on the first page** — the bar was hidden until after a search.

**The salary prompt could not be typed into.** The Save button was gated on
`setState` per keystroke inside a feed that rebuilds on every provider
notification; between them the field kept losing focus. Now a
`ValueListenableBuilder`, the card is keyed by question id, and Enter submits.

**Keyboard flow.** Dismissed between wizard steps and on scroll drag; no longer
force-opened for sheets whose answer is a tap.

### Employer portal — rebuilt

- **Shares the seeker app's design system and taxonomy.** `app_theme.dart`,
  `app_data.dart` (119 roles), `cities.dart`, the document/upload stack and the
  onboarding components are the same files. A vacancy posted here is scoreable
  against a profile built there because both describe work identically.
- **Persistence.** `EmployerStore` + `EmployerProvider.hydrate()`. Jobs, company,
  pipeline state and notes survive the app closing; the launch gate routes a
  returning recruiter straight to their dashboard.
- **Post-a-job wizard rebuilt** as the mirror of candidate onboarding: industry
  grid → trade → work involved → licences required → country/city → pay **with
  its period** → accommodation / transport / permit sponsorship → shift, plus a
  live preview of how candidates will see it.
- **252 → 357 seeded candidates** (`assets/data/seed_candidates.json`), one per
  role per market, MySQL-shaped, `seed: true`, `DELETE FROM candidates WHERE
  seed = 1`.
- **Spec §14–16** three candidate groups (Applied / Recommended / External) with
  the source named on external rows; **§17** quick contact; **§18** actions;
  **§25–27** match score, plain-English explanation and a rule-based scorer that
  needs no AI; **§71–72** contact credits with the cost stated before spending;
  **§75** private notes; **§78** dashboard cards.

`flutter analyze` clean on both apps · jobseeker 33/33 · employer 15/15.

### Still open
- Jobseeker home feed layout is still shaped for an office candidate (task 4.5).
- Employer: company profile tab still the old design; no signup screen yet
  (sir's repo has one to port); interview scheduling (§19–20), offer letters
  (§41–42) and email/WhatsApp actions need a backend.
- Pushing to GitHub still needs Shantosh's go-ahead (task 5.2).


---

## Round 4 — planned, not built

Shantosh reviewed the employer portal on 2026-08-28 and raised eleven items.
They are written up in full, with file paths and the one open question, in
**[NEXT_SESSION_PLAN.md](NEXT_SESSION_PLAN.md)** — start there next session.

Headlines: two confirmed bugs (the Register-your-company button does nothing;
a posted job never shows which company posted it), company registration with
document upload and AI-assisted verification before a company may post, parity
with the seeker app (settings, AI chat, notifications, drawer), auto-advance
animation on single-select answers, multi-select for country and location in
both apps, searchable skill pickers, and the employer-to-seeker posting contract.

One question is blocking a small change: he may have meant that job categories
should be ordered by demand, or that IT & Service specifically belongs at the
top. The second reverses the blue-collar-first decision and spec section 58, so
nothing was changed.
