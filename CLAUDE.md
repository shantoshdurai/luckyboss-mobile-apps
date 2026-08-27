# 🌟 Lucky Boss — Master Architecture & Project Handover Guide for Claude

> **Project Name**: Lucky Boss (Global Recruitment, ATS Pipeline & AI Career Platform)  
> **Target Markets**: Singapore (SG), Malaysia (MY), India (IN)  
> **Brand Identity**: Primary Navy (`#031F49`), Emerald Green (`#18A66A` / `#10B981`), Accent Blue (`#2563EB`), White Backgrounds (`#FFFFFF`)  
> **Primary Repositories**:
> - **🌐 Web Portal (Laravel 12 Pure PHP)**: `https://github.com/shantoshdurai/luckyboss`
> - **📱 Mobile Applications (Flutter)**: `https://github.com/shantoshdurai/luckyboss-mobile-apps`

---

## 📌 1. Executive Project Summary

**Lucky Boss** is an enterprise multi-tenant recruitment ecosystem connecting corporate employers with verified job seekers across Southeast Asia and India.

The ecosystem consists of three major deliverables:
1. **Laravel 12 Web Portal & Backend API**: A monolithic PHP platform managing Super Admin operations, Corporate Employer ATS dashboards, Candidate Portals, Public Job Feeds, and Dual-Engine AI services.
2. **Lucky Boss Job Seeker Mobile App (Flutter)**: An iOS/Android/Web application for candidates featuring phone auth, resume setup, job browsing, application tracking, and the *Lucky AI Career Copilot*.
3. **Lucky Boss Employer Portal Mobile App (Flutter)**: An iOS/Android/Web application for hiring managers featuring vacancy creation wizard, candidate pipeline management, and match telemetry.

---

## 🏗️ 2. Architectural Overview & Tech Stack

### A. Backend & Web Portal (`luckyboss-app for jobseeker`)
* **Framework**: Laravel 12 (PHP 8.2+)
* **Database**: SQLite pre-seeded (`database/database.sqlite`), ready for MySQL/PostgreSQL production migration.
* **Frontend**: Blade Templates, Tailwind CSS 3.4, Alpine.js 3.x.
* **Asset Bundling**: **Zero Node.js runtime requirement**. All CSS/JS assets are pre-compiled and bundled into `public/build/` and static fallbacks `public/css/app.css` & `public/js/app.js`.
* **AI Architecture (Dual-Engine)**:
  1. *Primary Engine*: Google Gemini 2.5 Flash / OpenAI GPT-4o Mini (Multimodal Vision OCR for PDF/DOCX resumes, Job Description Generator, Semantic Match Scoring).
  2. *Fallback Engine*: Pure PHP Offline Heuristic NLP parser (100% zero-downtime guarantee if API keys are exhausted or offline).
* **API Endpoints**: RESTful endpoints under `/api/v1/` for mobile app synchronization (`/jobs`, `/auth`, `/applications`, `/ai/copilot`, `/resume/parse`).

### B. Mobile Applications (`luckyboss_jobseeker` & `luckyboss_employer`)
* **Framework**: Flutter 3.44.0 (Dart 3.x)
* **Platforms**: Android (Pre-built Release APKs: 18 MB), iOS, and Web.
* **State Management**: `Provider` + Service layer pattern.
* **UI/UX Standard**: High-contrast, clean white backgrounds, Google Fonts (Plus Jakarta Sans & Newsreader), tree-shaken vector icons.
* **Auth**: Firebase Auth (Phone OTP + Email/Password) with seamless fallback demo defaults.

---

## 📂 3. Directory & Repository Structure

```text
C:\Luckyboss\
├── 📁 luckyboss-app for jobseeker/     <-- Laravel Web Portal & Backend API Repo
│   ├── app/Http/Controllers/          <-- Admin, Employer, Seeker, API Controllers
│   ├── app/Services/                  <-- AIService, ResumeParserService, SalaryBenchmarkService
│   ├── database/database.sqlite       <-- Pre-seeded SQLite database
│   ├── public/build/ & public/css/    <-- Pre-compiled production assets
│   ├── resources/views/               <-- Blade UI components & layouts
│   └── routes/web.php & api.php       <-- All web and mobile API routes
│
├── 📁 luckyboss_jobseeker/              <-- Final Job Seeker Flutter App
│   ├── lib/core/theme/                <-- AppTheme (Navy, Emerald, Plus Jakarta Sans)
│   ├── lib/screens/auth/              <-- PhoneAuthScreen, OtpVerificationScreen
│   ├── lib/screens/onboarding/        <-- ProfileSetupScreen (3-step manual & resume upload)
│   ├── lib/screens/tabs/              <-- ExploreJobsTab, ApplicationsTab, SeekerProfileTab
│   ├── lib/widgets/                   <-- LuckyAICopilotModal, LuckyBossBrandLogo
│   └── lib/services/                  <-- ApiService, FirebaseAuthService, GeminiCopilotService
│
├── 📁 luckyboss_employer/               <-- Final Employer Portal Flutter App
│   ├── lib/screens/auth/              <-- EmployerLoginScreen (Large 76px brand logo)
│   ├── lib/screens/jobs/              <-- PostJobWizardScreen (Comprehensive vacancy form)
│   ├── lib/screens/tabs/              <-- EmployerDashboardTab, CandidatesTab, ActiveJobsTab
│   └── lib/providers/                 <-- EmployerProvider (Real-time job & candidate state)
│
├── 📁 downloads/                        <-- Pre-built Android Phone APKs
│   ├── LuckyBoss_JobSeeker_v1.0.0.apk    (18.2 MB, arm64-v8a)
│   └── LuckyBoss_EmployerPortal_v1.0.0.apk (18.0 MB, arm64-v8a)
│
├── 📁 luckyboss-apps-git/               <-- Git Root for Mobile Apps Repository
├── 📄 luckyboss-production.zip         <-- Lightweight 8.8 MB standalone Laravel Web package
└── 📄 CLAUDE.md                        <-- This handover document
```

---

## ⚡ 4. How to Run Everything Locally

### 1. Run Laravel Web Portal (Port 8000)
```bash
cd "c:\Luckyboss\luckyboss-app for jobseeker"
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --port=8000
```
* **URL**: `http://127.0.0.1:8000`
* **Test Accounts**:
  - **Super Admin**: `admin@luckyboss.test` | `password` -> `http://127.0.0.1:8000/admin`
  - **Employer**: `employer@luckyboss.test` | `password` -> `http://127.0.0.1:8000/employer`
  - **Candidate**: `candidate@luckyboss.test` | `password` -> `http://127.0.0.1:8000/job-seeker`

### 2. Run Job Seeker Mobile App (Web Preview: Port 8081 / Android)
```bash
cd "c:\Luckyboss\luckyboss_jobseeker"
flutter pub get
flutter run -d chrome --web-port=8081
# Or to build APK:
flutter build apk --release --split-per-abi
```

### 3. Run Employer Portal Mobile App (Web Preview: Port 8082 / Android)
```bash
cd "c:\Luckyboss\luckyboss_employer"
flutter pub get
flutter run -d chrome --web-port=8082
# Or to build APK:
flutter build apk --release --split-per-abi
```

---

## 🛠️ 5. What Was Completed & Key Decisions Made

1. **Branding & Layout Integrity**:
   - Removed all clutter, duplicate texts, and third-party AI provider watermarks.
   - Employer login header features the enlarged 76px Lucky Boss logo with the official tagline: *"GROWTH PARTNER IN YOUR HIRING JOURNEY"*.
   - Splash screens and onboarding are pure white background (`#FFFFFF`) with sharp SVG/PNG logos.
2. **Zero Node.js Dependency in Web**:
   - Re-compiled all CSS & JavaScript directly into standalone assets.
   - Added Blade `@if(file_exists(...))` fallbacks so Laravel runs out-of-the-box with **PHP only** (`php artisan serve`).
3. **No Fake Data / Natural User Flows**:
   - Cleaned up profile onboarding: skills and bio start blank so users type manually or verify extracted data.
   - Profile strength starts at 0% and dynamically recalculates based on actual filled fields.
   - Removed pre-filled mock filenames (e.g. `Santosh_Resume.pdf`).
   - Notification bell badges dynamically clear when "Mark All Read" is clicked.
4. **AI Copilot Refinements**:
   - Copilot modal in mobile apps displays clean, well-spaced plain text without raw markdown asterisks (`**`).
   - Post Vacancy wizard in Employer Portal is a comprehensive multi-field form (Title, Category, Work Mode, Location, Country/Currency, Salary Range, Experience Level, Job Type, Description, Dynamic Skill Chips).
5. **Release APK Builds**:
   - Generated split-per-ABI lightweight release APKs (18 MB each) saved in `downloads/` and `C:\Users\Dog\Downloads\LuckyBoss_APKs`.

---

## 🚀 6. Next Roadmap & Open Tasks for Claude

When picking up the project, here are the main milestones and potential next steps:

1. **Resume OCR & AI Extraction Pipeline**:
   - Connect the mobile file picker directly to the Laravel backend endpoint (`POST /api/v1/resume/parse`).
   - Parse PDF/DOCX resumes via Gemini 2.5 Flash multimodal vision API, extract candidate details (`name`, `email`, `phone`, `skills`, `bio`), and present an editable review screen before saving to profile.
2. **Dynamic Semantic Job Matching (0–100%)**:
   - Implement vector/keyword matching between candidate skills and job requirements in the backend.
   - Display verified match percentage tags on Job Cards and Candidate Pipeline.
3. **Real-time Push Notifications**:
   - Setup Firebase Cloud Messaging (FCM) server keys in Laravel to send instant push notifications when an application status updates (e.g., Shortlisted, Interview Invite, Offer Extended).
4. **Cloud / Production Deployment**:
   - Prepare Dockerfile or deployment scripts for Cloudways, AWS EC2, or DigitalOcean.
   - Configure MySQL database, Redis queue worker for asynchronous AI jobs, and SSL certificate.

---

## 💬 7. Instructions for Claude

- Read this file (`CLAUDE.md`) thoroughly to understand the full context of Lucky Boss.
- Always maintain the brand design system: Navy (`#031F49`), Emerald Green (`#18A66A`), and clean White backgrounds.
- Keep the pure PHP zero-Node requirement intact for Laravel web deployments.
- If anything is unclear, ask Shantosh specific clarifying questions before making major architectural changes.
