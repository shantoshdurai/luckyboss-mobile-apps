# ?? Lucky Boss Mobile Applications Monorepo

> **Cross-Border AI-Powered Recruitment Network for Singapore ????, Malaysia ????, and India ????**

This repository contains the complete mobile ecosystem for **Lucky Boss**, structured as two dedicated Flutter applications:

```
luckyboss-mobile-apps/
+-- apps/
¦   +-- jobseeker-app/       # ?? Candidate Mobile App (Play Store & App Store)
¦   +-- employer-app/        # ?? Employer Recruiter Portal App
+-- .gitignore
+-- README.md
```

---

## ?? Apps Overview

### 1. ?? Job Seeker App (`apps/jobseeker-app`)
Built for candidates across India, Singapore, and Malaysia to find verified cross-border jobs and track hiring progress.

- **Fast Phone Authentication**:
  - Auto-selects country dial codes (`+91 India`, `+65 Singapore`, `+60 Malaysia`).
  - Centered 5–5 digit muscle-memory phone formatting (`98765-43210`).
  - 4-digit modern sans-serif OTP verification with auto-submit.
- **Onboarding & AI Resume Setup**:
  - 3-step wizard with resume upload simulation.
  - Automatic AI skill extraction and candidate profile verification.
- **Explore Jobs Feed**:
  - Multi-country selector pill (`???? IN (INR)`, `???? SG (SGD)`, `???? MY (MYR)`).
  - Multi-dimensional filters: **Work Mode** (`Remote`, `Hybrid`, `On-site`) and **Role Categories** (`IT & Software`, `Logistics & Warehouse`, `Healthcare`, `Finance`, `Manufacturing`).
  - AI Fit matching scores (`94% Fit`).
- **Rich Job Details & 1-Click Quick Apply**:
  - Comprehensive specifications grid (Compensation, Location, Work Mode, Job Type).
  - Lucky AI Compatibility Breakdown radar meters.
  - Responsibilities bullet points & required competency chips.
  - Sticky bottom **`1-Click Quick Apply ?`** action.
- **My Applications ATS Pipeline**:
  - 4-stage milestone tracker (`Applied` ? `Shortlist` ? `Interview` ? `Offer`).
  - Scheduled interview cards with Google Meet links & recruiter feedback notes.
- **Candidate Profile & System Settings**:
  - Initial avatar `AM` and verified green badge `?`.
  - 95% profile completion meter.
  - PDF resume preview.
  - ?? **Dark / Night Mode** interactive toggle.
  - ?? **Push Notifications** toggle.
  - ?? **Privacy Policy & Cross-Border Compliance** modal.

---

### 2. ?? Employer Recruiter App (`apps/employer-app`)
Designed for corporate hiring managers and recruiters to manage cross-border job postings and candidate pipelines.

- **Web-Aligned Authentication**:
  - Clean corporate sign-in using work email and password (demo: `employer@luckyboss.test` / `password`).
  - Enterprise registration redirection for unregistered organizations.
- **Command Dashboard**:
  - Verified Enterprise banner with multi-country badge.
  - Real-time recruitment metrics (`Active Jobs`, `Total Applications`, `Scheduled Interviews`).
  - Quick-access **`+ Post a New Vacancy`** banner.
- **Candidate ATS Pipeline**:
  - Applicant cards with AI compatibility fit percentages (`94% AI Fit`).
  - Candidate experience level, location, and hiring stage selector (`Interview`, `Shortlisted`, `New`).
  - **`Connect ?`** action for direct scheduling.
- **3-Step Post Job Wizard**:
  - Title & Category selection.
  - Cross-border country, currency, and compensation range.
  - AI screening requirements & competency tags.
- **Company Profile & Recruiter Settings**:
  - Enterprise Plan badge (`Firebase Blaze • Unlimited ATS Pipelines`).
  - ?? Dark Mode toggle.
  - ?? New Applicant Alerts toggle.
  - ?? ATS Data Compliance policy.

---

## ??? Tech Stack & Architecture

- **Framework**: Flutter 3.38+ / Dart 3.x
- **State Management**: Provider (`ChangeNotifierProvider`)
- **Typography**: Google Fonts (`Plus Jakarta Sans` & `Cormorant Garamond` / `Fraunces`)
- **Authentication**: Firebase Phone Auth & Firebase Auth Service
- **Networking**: REST API Client & Cloud Sync Services
- **Platforms Supported**: Android (APK/AAB), iOS (IPA), Flutter Web

---

## ?? Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.24.0`)
- [Android Studio](https://developer.android.com/studio) / Xcode (for iOS)
- Chrome browser (for Flutter Web testing)

---

### Running the Job Seeker App
```bash
cd apps/jobseeker-app
flutter pub get
flutter run
```
To run on Chrome:
```bash
flutter run -d chrome --web-port 8081
```

---

### Running the Employer Recruiter App
```bash
cd apps/employer-app
flutter pub get
flutter run
```
To run on Chrome:
```bash
flutter run -d chrome --web-port 8082
```

---

## ?? Running Tests & Analyzer

Run the automated test suite and static analysis across both applications:

```bash
# Job Seeker App
cd apps/jobseeker-app
flutter analyze
flutter test

# Employer App
cd ../employer-app
flutter analyze
flutter test
```

---

## ?? Building for Production

### Android Release APK / App Bundle
```bash
# Build Android App Bundle (.aab) for Google Play Store
cd apps/jobseeker-app
flutter build appbundle --release

# Build Standalone APK (.apk)
flutter build apk --release
```

### Flutter Web Release
```bash
cd apps/jobseeker-app
flutter build web --release
```

---

## ?? How to Push to GitHub & Share

To create a new GitHub repository and push this code:

1. **Create a new repository on GitHub** (e.g. `luckyboss-mobile-apps`).
2. **Run the following commands**:
```bash
# Inside the root repository directory
git init
git add .
git commit -m "feat: complete LuckyBoss Flutter mobile applications for Job Seeker and Employer"
git branch -M main
git remote add origin https://github.com/YOUR_ORGANIZATION/luckyboss-mobile-apps.git
git push -u origin main
```

---

## ?? License
Proprietary — © 2026 Lucky Boss Global Recruitment Network. All rights reserved.
