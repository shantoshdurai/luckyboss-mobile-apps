# 🌟 Lucky Boss Platform — Quick Setup & Installation Guide

An enterprise multi-tenant recruitment, ATS candidate pipeline, and AI matching platform connecting corporate employers across **Singapore, Malaysia, and India** with verified job seekers.

---

## 📋 System Prerequisites

You only need **PHP and Composer** (Zero Node.js or npm required):
* **PHP >= 8.2** (Extensions: `pdo_sqlite`, `mbstring`, `openssl`, `curl`, `fileinfo`)
* **Composer >= 2.2**

---

## ⚡ 1-Minute Quick Start (Web Portal)

### 1. Clone or Extract the Project
```bash
git clone https://github.com/shantoshdurai/luckyboss.git
cd luckyboss
```
*(Or extract `luckyboss-production.zip`)*

### 2. Install PHP Dependencies
```bash
composer install
```

### 3. Setup Environment & Key
```bash
cp .env.example .env
php artisan key:generate
```

### 4. Database Setup & Demo Seeding
```bash
php artisan migrate:fresh --seed
```

### 5. Start the Server
```bash
php artisan serve --port=8000
```
Open **[http://127.0.0.1:8000](http://127.0.0.1:8000)** in your browser!

---

## 🔑 Pre-Seeded Demo Accounts

| Role | Email | Password | Access URL |
| :--- | :--- | :--- | :--- |
| **Super Admin** | `admin@luckyboss.test` | `password` | [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin) |
| **Corporate Employer** | `employer@luckyboss.test` | `password` | [http://127.0.0.1:8000/employer](http://127.0.0.1:8000/employer) |
| **Job Seeker (Candidate)** | `candidate@luckyboss.test` | `password` | [http://127.0.0.1:8000/job-seeker](http://127.0.0.1:8000/job-seeker) |

---

## 📱 Mobile Applications

* **GitHub Repository**: [https://github.com/shantoshdurai/luckyboss-mobile-apps](https://github.com/shantoshdurai/luckyboss-mobile-apps)
* **Pre-Built APKs**:
  - `LuckyBoss_JobSeeker_v1.0.0.apk` (18.2 MB)
  - `LuckyBoss_EmployerPortal_v1.0.0.apk` (18.0 MB)
* **Local Web Previews**:
  - Job Seeker App: `http://127.0.0.1:8081`
  - Employer Portal: `http://127.0.0.1:8082`
