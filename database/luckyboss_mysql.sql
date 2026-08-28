-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 21, 2026 at 10:44 AM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 7.4.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `luckyboss`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_records`
--

CREATE TABLE `admin_records` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `module` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admin_records`
--

INSERT INTO `admin_records` (`id`, `module`, `name`, `slug`, `description`, `payload`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'email-templates', 'Interview Invitation', 'interview-invitation', 'Default interview invitation template', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(2, 'notification-sounds', 'Application Update', 'application-update', 'Job seeker sound payload', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(3, 'mobile-app-settings', 'Job Seeker Android', 'job-seeker-android', 'Minimum version and store URL', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(4, 'home-sections', 'Featured Jobs', 'featured-jobs', 'Website and app home section', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(5, 'location-masters', 'Singapore', 'singapore', 'Country master', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(6, 'general-settings', 'Portal Branding', 'portal-branding', 'Logo and primary color settings', '[]', 1, '2026-08-20 05:20:18', '2026-08-21 00:39:24'),
(7, 'branding', 'Website Branding', 'website-branding', 'Public website and portal brand settings', '{\"logo_url\":\"http:\\/\\/127.0.0.1:8000\\/uploads\\/branding\\/lucky-boss-20260820115507.png\",\"favicon_url\":\"http:\\/\\/127.0.0.1:8000\\/uploads\\/branding\\/favicon-20260821075904.png\",\"site_name\":\"Lucky Boss Portal\",\"seo_title\":\"Lucky Boss Portal | AI-Powered Recruitment\",\"seo_description\":\"Find jobs, build your career, and manage recruitment with Lucky Boss Portal.\",\"primary_color\":\"#031f49\",\"secondary_color\":\"#18a66a\"}', 1, '2026-08-20 06:25:07', '2026-08-21 02:29:04'),
(8, 'contact-information', 'Official Contact', 'official-contact', 'Official public office and contact details', '{\"office_address\":\"Singapore\",\"official_email\":\"hello@luckyboss.test\",\"official_phone\":null,\"facebook_url\":\"https:\\/\\/www.facebook.com\\/\",\"instagram_url\":\"https:\\/\\/www.instagram.com\\/\",\"linkedin_url\":\"https:\\/\\/www.linkedin.com\\/\",\"youtube_url\":\"https:\\/\\/www.youtube.com\\/\",\"whatsapp_url\":\"https:\\/\\/wa.me\\/\"}', 1, '2026-08-20 06:25:07', '2026-08-20 08:56:31');

-- --------------------------------------------------------

--
-- Table structure for table `api_integrations`
--

CREATE TABLE `api_integrations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `key` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `encrypted_secret` text DEFAULT NULL,
  `encrypted_webhook_secret` text DEFAULT NULL,
  `webhook_secret_hint` varchar(255) DEFAULT NULL,
  `environment` varchar(255) NOT NULL DEFAULT 'sandbox',
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `monthly_limit` bigint(20) UNSIGNED DEFAULT NULL,
  `usage_count` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `last_requested_at` timestamp NULL DEFAULT NULL,
  `last_error` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `api_integrations`
--

INSERT INTO `api_integrations` (`id`, `key`, `name`, `provider`, `encrypted_secret`, `encrypted_webhook_secret`, `webhook_secret_hint`, `environment`, `is_enabled`, `monthly_limit`, `usage_count`, `last_requested_at`, `last_error`, `created_at`, `updated_at`) VALUES
(1, 'platform_openai', 'OpenAI GPT', 'OpenAI', NULL, NULL, NULL, 'sandbox', 0, 10000000, 0, NULL, NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(2, 'resume_parser', 'Resume Parser', 'Manual fallback', NULL, NULL, NULL, 'sandbox', 0, 5000, 0, NULL, NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(3, 'payment_gateway', 'Payment Gateway', 'Manual / Stripe ready', NULL, NULL, NULL, 'sandbox', 0, NULL, 0, NULL, NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(4, 'whatsapp', 'WhatsApp', 'Cloud API', NULL, NULL, NULL, 'sandbox', 0, 100000, 0, NULL, NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `application_status_histories`
--

CREATE TABLE `application_status_histories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `job_application_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `from_status` varchar(255) DEFAULT NULL,
  `to_status` varchar(255) NOT NULL,
  `remark` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL,
  `action` varchar(255) NOT NULL,
  `entity_type` varchar(255) DEFAULT NULL,
  `entity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values`)),
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `backup_logs`
--

CREATE TABLE `backup_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'queued',
  `path` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `blogs`
--

CREATE TABLE `blogs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `slug` varchar(255) NOT NULL,
  `category` varchar(255) DEFAULT NULL,
  `short_description` text NOT NULL,
  `content` longtext NOT NULL,
  `author` varchar(255) NOT NULL DEFAULT 'Lucky Boss Team',
  `published_at` timestamp NULL DEFAULT NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `blogs`
--

INSERT INTO `blogs` (`id`, `title`, `image_path`, `slug`, `category`, `short_description`, `content`, `author`, `published_at`, `is_published`, `created_at`, `updated_at`) VALUES
(1, 'How to Prepare for a Warehouse Supervisor Interview', 'images/lucky-boss-logo.png', 'how-to-prepare-for-a-warehouse-supervisor-interview', 'Interview Tips', 'Practical preparation tips for leading warehouse teams and demonstrating operational confidence.', 'A strong warehouse supervisor interview begins with specific examples. Prepare to explain how you improve safety, plan shifts, manage stock accuracy, and support your team through busy periods.', 'Lucky Boss Team', '2026-08-20 00:39:24', 1, '2026-08-20 04:57:54', '2026-08-21 00:39:24'),
(2, 'Creating a Resume That Gets Noticed', 'images/lucky-boss-logo.png', 'creating-a-resume-that-gets-noticed', 'Resume Tips', 'A clear, focused resume helps employers quickly understand your experience and potential.', 'Lead with your most relevant experience, use measurable outcomes where possible, and tailor your skills to the role you want. Keep your contact details current and make your availability clear.', 'Lucky Boss Team', '2026-08-16 00:39:24', 1, '2026-08-20 04:57:54', '2026-08-21 00:39:24'),
(3, 'Building a More Effective Hiring Pipeline', 'images/lucky-boss-logo.png', 'building-a-more-effective-hiring-pipeline', 'Employer Guides', 'Simple habits that help employers turn applications into confident hiring decisions.', 'Define the outcome for every hiring stage, respond quickly to suitable applicants, and keep candidates informed. A consistent process improves both hiring quality and employer reputation.', 'Lucky Boss Team', '2026-08-11 00:39:24', 1, '2026-08-20 04:57:54', '2026-08-21 00:39:24'),
(4, 'How to Write Better Job Descriptions', 'images/lucky-boss-logo.png', 'how-to-write-better-job-descriptions', 'Employer Guides', 'Clear job descriptions attract better matched applicants.', 'Describe the outcome of the role, the essential skills, the working arrangement, and the next step. Avoid long lists of vague requirements.', 'Lucky Boss Team', '2026-08-07 00:39:24', 1, '2026-08-21 00:17:03', '2026-08-21 00:39:24'),
(5, 'Preparing for Your First Interview', 'images/lucky-boss-logo.png', 'preparing-for-your-first-interview', 'Interview Tips', 'A practical checklist for confident job interviews.', 'Review the role, prepare concise examples from your experience, test your meeting link, and prepare thoughtful questions for the interviewer.', 'Lucky Boss Team', '2026-08-17 00:39:24', 1, '2026-08-21 00:17:03', '2026-08-21 00:39:24'),
(6, 'Skills That Stand Out in Logistics', 'images/lucky-boss-logo.png', 'skills-that-stand-out-in-logistics', 'Industry News', 'The capabilities modern logistics teams value most.', 'Safety awareness, inventory accuracy, communication, and comfort with operational systems are increasingly valuable across logistics roles.', 'Lucky Boss Team', '2026-08-13 00:39:24', 1, '2026-08-21 00:17:03', '2026-08-21 00:39:24'),
(7, 'Making Your Profile Searchable', 'images/lucky-boss-logo.png', 'making-your-profile-searchable', 'Resume Tips', 'Small profile improvements that help employers find you.', 'Use specific job titles, list your strongest skills, keep your location current, and explain measurable achievements in your work history.', 'Lucky Boss Team', '2026-08-14 00:39:24', 1, '2026-08-21 00:17:03', '2026-08-21 00:39:24'),
(8, 'Interview Feedback That Improves Hiring', 'images/lucky-boss-logo.png', 'interview-feedback-that-improves-hiring', 'Employer Guides', 'Turn interview notes into consistent hiring decisions.', 'Record evidence against the role requirements, separate facts from impressions, and capture a clear recommendation while the conversation is fresh.', 'Lucky Boss Team', '2026-08-17 00:39:24', 1, '2026-08-21 00:17:03', '2026-08-21 00:39:24');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba', 'i:1;', 1787301539),
('laravel-cache-5c785c036466adea360111aa28563bfd556b5fba:timer', 'i:1787301539;', 1787301539),
('laravel-cache-ac3478d69a3c81fa62e60f5c3696165a4e5e6ac4', 'i:1;', 1787242556),
('laravel-cache-ac3478d69a3c81fa62e60f5c3696165a4e5e6ac4:timer', 'i:1787242556;', 1787242556),
('laravel-cache-feature-flag:employer_byoai_enabled', 'b:1;', 1787302005);

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `candidate_archives`
--

CREATE TABLE `candidate_archives` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `job_id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `archived_by` bigint(20) UNSIGNED NOT NULL,
  `reason` varchar(255) NOT NULL,
  `remarks` text DEFAULT NULL,
  `restored_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `candidate_experiences`
--

CREATE TABLE `candidate_experiences` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `company` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `started_at` date DEFAULT NULL,
  `ended_at` date DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `candidate_notes`
--

CREATE TABLE `candidate_notes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `job_application_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `note` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `candidate_profiles`
--

CREATE TABLE `candidate_profiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `profile_photo_path` varchar(255) DEFAULT NULL,
  `country_code` varchar(3) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `current_title` varchar(255) DEFAULT NULL,
  `professional_summary` text DEFAULT NULL,
  `current_location` varchar(255) DEFAULT NULL,
  `preferred_location` varchar(255) DEFAULT NULL,
  `years_experience` smallint(5) UNSIGNED DEFAULT NULL,
  `current_salary` decimal(12,2) DEFAULT NULL,
  `expected_salary` decimal(12,2) DEFAULT NULL,
  `preferred_currency` varchar(3) DEFAULT NULL,
  `notice_period` varchar(255) DEFAULT NULL,
  `availability` varchar(255) DEFAULT NULL,
  `profile_completion` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `resume_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`resume_data`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `candidate_profiles`
--

INSERT INTO `candidate_profiles` (`id`, `user_id`, `profile_photo_path`, `country_code`, `date_of_birth`, `gender`, `current_title`, `professional_summary`, `current_location`, `preferred_location`, `years_experience`, `current_salary`, `expected_salary`, `preferred_currency`, `notice_period`, `availability`, `profile_completion`, `is_visible`, `resume_data`, `created_at`, `updated_at`) VALUES
(1, 3, NULL, 'SG', NULL, NULL, 'Warehouse Coordinator', NULL, 'Singapore', 'Singapore', 4, NULL, NULL, NULL, NULL, NULL, 65, 1, NULL, '2026-08-20 04:32:53', '2026-08-20 04:32:53'),
(2, 5, 'uploads/candidates/profile-20260820160338-WFHfne.jpg', 'SG', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'SGD', NULL, NULL, 18, 1, '{\"personal\":{\"whatsapp_number\":null},\"summary\":{\"ai_notes\":null},\"experience\":[],\"education\":[],\"skills\":[],\"projects\":[],\"certifications\":[],\"languages\":[],\"current_employment\":[],\"job_preferences\":[],\"mobility\":[],\"international_jobs\":[],\"achievements\":[],\"online_profiles\":[],\"references\":[],\"documents\":[],\"declaration\":[]}', '2026-08-20 09:50:04', '2026-08-20 10:33:38');

-- --------------------------------------------------------

--
-- Table structure for table `candidate_resumes`
--

CREATE TABLE `candidate_resumes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `summary` text DEFAULT NULL,
  `parsed_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`parsed_data`)),
  `parse_status` varchar(255) NOT NULL DEFAULT 'manual',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `candidate_skills`
--

CREATE TABLE `candidate_skills` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `level` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `communication_logs`
--

CREATE TABLE `communication_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL,
  `sender_id` bigint(20) UNSIGNED DEFAULT NULL,
  `recipient_id` bigint(20) UNSIGNED DEFAULT NULL,
  `channel` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'queued',
  `subject` varchar(255) DEFAULT NULL,
  `body` text NOT NULL,
  `sent_at` timestamp NULL DEFAULT NULL,
  `error` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `communication_templates`
--

CREATE TABLE `communication_templates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `body` longtext NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `companies`
--

CREATE TABLE `companies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_type_id` bigint(20) UNSIGNED DEFAULT NULL,
  `company_grade_id` bigint(20) UNSIGNED DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `logo_path` varchar(255) DEFAULT NULL,
  `registration_number` varchar(255) DEFAULT NULL,
  `industry` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `country_code` varchar(3) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `companies`
--

INSERT INTO `companies` (`id`, `company_type_id`, `company_grade_id`, `name`, `logo_path`, `registration_number`, `industry`, `email`, `phone`, `website`, `country_code`, `state`, `city`, `address`, `status`, `verified_at`, `created_at`, `updated_at`) VALUES
(1, 1, 4, 'Lucky Boss Demo Recruitment', NULL, NULL, 'Recruitment', 'hello@luckyboss.test', NULL, NULL, 'SG', NULL, NULL, NULL, 'verified', NULL, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(2, 2, NULL, 'Maac Technologies', 'uploads/companies/company-20260821060714-yQxpxH.webp', '9944995493', NULL, 'thiru.maac@gmail.com', '9944995493', NULL, 'SG', NULL, NULL, NULL, 'verified', '2026-08-20 11:01:40', '2026-08-20 10:55:16', '2026-08-21 00:37:14');

-- --------------------------------------------------------

--
-- Table structure for table `company_grades`
--

CREATE TABLE `company_grades` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `company_grades`
--

INSERT INTO `company_grades` (`id`, `name`, `slug`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Standard', 'standard', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(2, 'Silver', 'silver', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(3, 'Gold', 'gold', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(4, 'Premium', 'premium', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(5, 'Corporate', 'corporate', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(6, 'Enterprise', 'enterprise', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52');

-- --------------------------------------------------------

--
-- Table structure for table `company_types`
--

CREATE TABLE `company_types` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `company_types`
--

INSERT INTO `company_types` (`id`, `name`, `slug`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Recruitment Agency', 'recruitment-agency', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(2, 'Construction', 'construction', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(3, 'Manufacturing', 'manufacturing', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(4, 'Logistics', 'logistics', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(5, 'Warehouse', 'warehouse', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(6, 'Healthcare', 'healthcare', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(7, 'Hospitality', 'hospitality', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(8, 'IT', 'it', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(9, 'Retail', 'retail', 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52');

-- --------------------------------------------------------

--
-- Table structure for table `company_users`
--

CREATE TABLE `company_users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `company_role` varchar(255) NOT NULL DEFAULT 'recruiter',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `company_users`
--

INSERT INTO `company_users` (`id`, `company_id`, `user_id`, `company_role`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'company-admin', 1, '2026-08-20 04:32:53', '2026-08-21 00:39:24'),
(2, 2, 6, 'company-admin', 1, '2026-08-20 10:55:16', '2026-08-20 10:55:16');

-- --------------------------------------------------------

--
-- Table structure for table `countries`
--

CREATE TABLE `countries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(3) NOT NULL,
  `name` varchar(255) NOT NULL,
  `sort_order` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `countries`
--

INSERT INTO `countries` (`id`, `code`, `name`, `sort_order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'IN', 'India', 1, 1, '2026-08-21 00:39:24', '2026-08-21 00:39:24'),
(2, 'SG', 'Singapore', 1, 1, '2026-08-21 00:39:24', '2026-08-21 00:39:24');

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

CREATE TABLE `currencies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(3) NOT NULL,
  `name` varchar(255) NOT NULL,
  `symbol` varchar(8) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `currencies`
--

INSERT INTO `currencies` (`id`, `code`, `name`, `symbol`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'SGD', 'Singapore Dollar', 'S$', 1, '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(2, 'INR', 'Indian Rupee', 'Rs', 1, '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(3, 'MYR', 'Malaysian Ringgit', 'RM', 1, '2026-08-20 05:03:52', '2026-08-20 05:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `employer_ai_settings`
--

CREATE TABLE `employer_ai_settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `encrypted_api_key` text DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `last_tested_at` timestamp NULL DEFAULT NULL,
  `last_status` varchar(255) NOT NULL DEFAULT 'not_configured',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employer_documents`
--

CREATE TABLE `employer_documents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employer_notes`
--

CREATE TABLE `employer_notes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `note` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employer_portal_records`
--

CREATE TABLE `employer_portal_records` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `section` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `external_sources`
--

CREATE TABLE `external_sources` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `source_type` varchar(255) NOT NULL,
  `feed_type` varchar(255) NOT NULL DEFAULT 'manual',
  `status` varchar(255) NOT NULL DEFAULT 'active',
  `contacts_visible` tinyint(1) NOT NULL DEFAULT 0,
  `import_limit` int(10) UNSIGNED DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `external_sources`
--

INSERT INTO `external_sources` (`id`, `name`, `source_type`, `feed_type`, `status`, `contacts_visible`, `import_limit`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Demo Recruitment Partner', 'Recruitment Partner', 'manual', 'active', 0, 100, NULL, '2026-08-20 05:20:18', '2026-08-20 05:20:18');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `feature_flags`
--

CREATE TABLE `feature_flags` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `key` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `feature_flags`
--

INSERT INTO `feature_flags` (`id`, `key`, `name`, `description`, `is_enabled`, `created_at`, `updated_at`) VALUES
(1, 'platform_ai_enabled', 'Platform AI', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(2, 'employer_byoai_enabled', 'Employer BYOAI', NULL, 1, '2026-08-20 04:32:52', '2026-08-21 00:27:42'),
(3, 'ai_matching_enabled', 'AI Matching', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(4, 'external_jobs_enabled', 'External Jobs', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(5, 'external_candidates_enabled', 'External Candidates', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(6, 'candidate_monetization_enabled', 'Candidate Monetization', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(7, 'google_calendar_enabled', 'Google Calendar', NULL, 0, '2026-08-20 04:32:52', '2026-08-20 04:32:52');

-- --------------------------------------------------------

--
-- Table structure for table `import_batches`
--

CREATE TABLE `import_batches` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `external_source_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `data_type` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'queued',
  `records_received` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `records_imported` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `records_failed` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `error_log` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `import_batches`
--

INSERT INTO `import_batches` (`id`, `external_source_id`, `user_id`, `data_type`, `status`, `records_received`, `records_imported`, `records_failed`, `error_log`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'candidates', 'completed', 10, 8, 2, NULL, '2026-08-20 05:20:18', '2026-08-20 05:20:18');

-- --------------------------------------------------------

--
-- Table structure for table `interviews`
--

CREATE TABLE `interviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `job_application_id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `interviewer_id` bigint(20) UNSIGNED DEFAULT NULL,
  `mode` varchar(255) NOT NULL DEFAULT 'in-person',
  `scheduled_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `duration_minutes` smallint(5) UNSIGNED NOT NULL DEFAULT 45,
  `time_zone` varchar(255) NOT NULL DEFAULT 'Asia/Singapore',
  `venue` varchar(255) DEFAULT NULL,
  `meeting_link` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'scheduled',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `payment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `number` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'employer',
  `status` varchar(255) NOT NULL DEFAULT 'issued',
  `currency_code` varchar(3) NOT NULL DEFAULT 'SGD',
  `amount` decimal(12,2) NOT NULL,
  `tax_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`id`, `payment_id`, `company_id`, `user_id`, `number`, `type`, `status`, `currency_code`, `amount`, `tax_amount`, `created_at`, `updated_at`) VALUES
(1, 1, 1, NULL, 'INV-LB-0001', 'employer', 'issued', 'SGD', '299.00', '0.00', '2026-08-20 05:20:18', '2026-08-20 05:20:18');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `job_category_id` bigint(20) UNSIGNED DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `description` longtext NOT NULL,
  `country_code` varchar(3) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `work_mode` varchar(255) NOT NULL DEFAULT 'on-site',
  `job_type` varchar(255) NOT NULL DEFAULT 'full-time',
  `experience_min` smallint(5) UNSIGNED DEFAULT NULL,
  `experience_max` smallint(5) UNSIGNED DEFAULT NULL,
  `salary_min` decimal(12,2) DEFAULT NULL,
  `salary_max` decimal(12,2) DEFAULT NULL,
  `currency_code` varchar(3) NOT NULL DEFAULT 'SGD',
  `salary_visible` tinyint(1) NOT NULL DEFAULT 1,
  `vacancies` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `closing_date` date DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'draft',
  `is_featured` tinyint(1) NOT NULL DEFAULT 0,
  `is_urgent` tinyint(1) NOT NULL DEFAULT 0,
  `is_sponsored` tinyint(1) NOT NULL DEFAULT 0,
  `is_external` tinyint(1) NOT NULL DEFAULT 0,
  `is_paid_apply` tinyint(1) NOT NULL DEFAULT 0,
  `application_fee` decimal(12,2) DEFAULT NULL,
  `published_at` timestamp NULL DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `jobs`
--

INSERT INTO `jobs` (`id`, `company_id`, `job_category_id`, `title`, `image_path`, `description`, `country_code`, `location`, `work_mode`, `job_type`, `experience_min`, `experience_max`, `salary_min`, `salary_max`, `currency_code`, `salary_visible`, `vacancies`, `closing_date`, `status`, `is_featured`, `is_urgent`, `is_sponsored`, `is_external`, `is_paid_apply`, `application_fee`, `published_at`, `archived_at`, `created_at`, `updated_at`) VALUES
(1, 1, 3, 'Warehouse Supervisor', 'uploads/jobs/job-20260820144240-MxZzfl.jpg', 'Lead warehouse operations and coordinate a high-performing team.', 'SG', 'Singapore', 'on-site', 'full-time', 3, 5, '3000.00', '4500.00', 'SGD', 1, 1, '2026-09-20', 'published', 1, 0, 0, 0, 0, NULL, '2026-08-20 04:32:52', NULL, '2026-08-20 04:32:52', '2026-08-20 09:12:40'),
(2, 1, 3, 'Warehouse Coordinator', 'images/lucky-boss-logo.png', 'Test job listing for Warehouse Coordinator.', 'SG', 'Jurong East', 'on-site', 'full-time', 0, 3, '2800.00', '3800.00', 'SGD', 1, 1, '2026-09-19', 'published', 1, 0, 0, 0, 0, NULL, '2026-08-20 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(3, 1, 1, 'Construction Site Supervisor', 'images/lucky-boss-logo.png', 'Test job listing for Construction Site Supervisor.', 'SG', 'Kallang', 'on-site', 'full-time', 1, 4, '4200.00', '5800.00', 'SGD', 1, 1, '2026-09-20', 'published', 1, 0, 0, 0, 0, NULL, '2026-08-19 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(4, 1, 5, 'Logistics Operations Executive', 'images/lucky-boss-logo.png', 'Test job listing for Logistics Operations Executive.', 'SG', 'Tuas', 'on-site', 'full-time', 2, 5, '3200.00', '4600.00', 'SGD', 1, 1, '2026-09-21', 'published', 1, 0, 0, 0, 0, NULL, '2026-08-18 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(5, 1, 2, 'Manufacturing Quality Engineer', 'images/lucky-boss-logo.png', 'Test job listing for Manufacturing Quality Engineer.', 'MY', 'Shah Alam', 'on-site', 'full-time', 3, 6, '4500.00', '6500.00', 'MYR', 1, 1, '2026-09-22', 'published', 0, 1, 0, 0, 0, NULL, '2026-08-17 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(6, 1, 4, 'Healthcare Assistant', 'images/lucky-boss-logo.png', 'Test job listing for Healthcare Assistant.', 'SG', 'Singapore', 'on-site', 'full-time', 0, 3, '2400.00', '3400.00', 'SGD', 1, 1, '2026-09-23', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-16 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(7, 1, 6, 'Hospitality Front Office Manager', 'images/lucky-boss-logo.png', 'Test job listing for Hospitality Front Office Manager.', 'SG', 'Orchard', 'on-site', 'full-time', 1, 4, '3600.00', '5000.00', 'SGD', 1, 1, '2026-09-24', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-15 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(8, 1, 1, 'Recruitment Consultant', 'images/lucky-boss-logo.png', 'Test job listing for Recruitment Consultant.', 'IN', 'Chennai', 'on-site', 'full-time', 2, 5, '3000.00', '5000.00', 'INR', 1, 1, '2026-09-25', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-14 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(9, 1, 1, 'Retail Store Manager', 'images/lucky-boss-logo.png', 'Test job listing for Retail Store Manager.', 'MY', 'Kuala Lumpur', 'on-site', 'full-time', 3, 6, '3800.00', '5600.00', 'MYR', 1, 1, '2026-09-26', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-13 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(10, 1, 1, 'IT Support Specialist', 'images/lucky-boss-logo.png', 'Test job listing for IT Support Specialist.', 'SG', 'Paya Lebar', 'on-site', 'full-time', 0, 3, '3500.00', '5200.00', 'SGD', 1, 1, '2026-09-27', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-12 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12'),
(11, 1, 3, 'Warehouse Picker and Packer', 'images/lucky-boss-logo.png', 'Test job listing for Warehouse Picker and Packer.', 'SG', 'Woodlands', 'on-site', 'full-time', 1, 4, '2200.00', '3000.00', 'SGD', 1, 1, '2026-09-28', 'published', 0, 0, 0, 0, 0, NULL, '2026-08-11 09:10:12', NULL, '2026-08-20 09:10:12', '2026-08-20 09:10:12');

-- --------------------------------------------------------

--
-- Table structure for table `job_alerts`
--

CREATE TABLE `job_alerts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `keyword` varchar(255) DEFAULT NULL,
  `job_category_id` bigint(20) UNSIGNED DEFAULT NULL,
  `country_code` varchar(3) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `salary_min` decimal(12,2) DEFAULT NULL,
  `experience_min` smallint(5) UNSIGNED DEFAULT NULL,
  `frequency` varchar(255) NOT NULL DEFAULT 'weekly',
  `channels` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`channels`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_applications`
--

CREATE TABLE `job_applications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `job_id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `assigned_to` bigint(20) UNSIGNED DEFAULT NULL,
  `source` varchar(255) NOT NULL DEFAULT 'Direct Applicant',
  `status` varchar(255) NOT NULL DEFAULT 'New',
  `match_score` decimal(5,2) DEFAULT NULL,
  `applied_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_activity_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `job_applications`
--

INSERT INTO `job_applications` (`id`, `job_id`, `candidate_id`, `assigned_to`, `source`, `status`, `match_score`, `applied_at`, `last_activity_at`, `created_at`, `updated_at`) VALUES
(1, 1, 3, NULL, 'Direct Applicant', 'Shortlisted', '88.00', '2026-08-20 10:02:53', NULL, '2026-08-20 04:32:53', '2026-08-20 04:32:53');

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_categories`
--

CREATE TABLE `job_categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `icon_image_path` varchar(255) DEFAULT NULL,
  `sort_order` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `show_on_home` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `job_categories`
--

INSERT INTO `job_categories` (`id`, `name`, `slug`, `description`, `icon`, `icon_image_path`, `sort_order`, `show_on_home`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Construction', 'construction', NULL, 'hard-hat', 'uploads/master-icons/category-20260821074706-5gFd9H.png', 1, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:17:06'),
(2, 'Manufacturing', 'manufacturing', NULL, 'factory', 'uploads/master-icons/category-20260821074721-Q3B0wJ.png', 2, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:17:21'),
(3, 'Warehouse', 'warehouse', NULL, 'warehouse', 'uploads/master-icons/category-20260821074735-hstpaI.png', 3, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:17:35'),
(4, 'Healthcare', 'healthcare', NULL, 'heart-pulse', 'uploads/master-icons/category-20260821074743-sha2bQ.png', 4, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:17:43'),
(5, 'Logistics', 'logistics', NULL, 'truck', 'uploads/master-icons/category-20260821074752-eEoX8l.png', 5, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:17:52'),
(6, 'Hospitality', 'hospitality', NULL, 'utensils', 'uploads/master-icons/category-20260821074806-IRpiBB.png', 6, 1, 1, '2026-08-20 04:32:52', '2026-08-21 02:18:06'),
(7, 'Domestic Worker', 'domestic-worker', NULL, 'house', 'uploads/master-icons/category-20260821074826-5dnoN5.png', 7, 1, 1, '2026-08-21 00:17:03', '2026-08-21 02:18:26'),
(8, 'Engineering', 'engineering', NULL, 'settings-2', 'uploads/master-icons/category-20260821074843-T6992Y.png', 8, 1, 1, '2026-08-21 00:17:03', '2026-08-21 02:18:43'),
(9, 'Sales', 'sales', NULL, 'handshake', 'images/lucky-boss-logo.png', 9, 1, 1, '2026-08-21 00:17:03', '2026-08-21 00:17:03'),
(10, 'Administration', 'administration', NULL, 'clipboard-list', 'images/lucky-boss-logo.png', 10, 1, 1, '2026-08-21 00:17:03', '2026-08-21 00:17:03'),
(11, 'Security', 'security', NULL, 'shield-check', 'images/lucky-boss-logo.png', 11, 1, 1, '2026-08-21 00:17:03', '2026-08-21 00:17:03');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `recipient_id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL,
  `job_application_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'portal',
  `subject` varchar(255) DEFAULT NULL,
  `body` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_08_20_095026_create_personal_access_tokens_table', 1),
(5, '2026_08_20_100000_create_lucky_boss_core_tables', 1),
(6, '2026_08_20_110000_create_job_applications_table', 1),
(7, '2026_08_20_120000_create_blogs_table', 2),
(8, '2026_08_20_130000_create_recruitment_platform_modules', 3),
(9, '2026_08_20_140000_create_admin_operations_tables', 4),
(10, '2026_08_20_150000_create_advanced_platform_tables', 5),
(11, '2026_08_20_151000_add_encrypted_webhook_secret_to_integrations', 6),
(12, '2026_08_20_150000_create_employer_notes_table', 7),
(13, '2026_08_20_160000_create_employer_documents_table', 7),
(14, '2026_08_20_170000_add_admin_job_controls_to_jobs_table', 7),
(15, '2026_08_20_180000_add_icon_image_to_job_categories', 7),
(16, '2026_08_20_190000_add_image_to_jobs_table', 7),
(17, '2026_08_20_200000_add_image_to_blogs_table', 8),
(18, '2026_08_20_210000_add_manual_resume_data_to_candidate_profiles', 9),
(19, '2026_08_20_220000_create_employer_portal_records_table', 10),
(20, '2026_08_20_230000_add_logo_to_companies_table', 11),
(21, '2026_08_21_120000_create_countries_table', 12);

-- --------------------------------------------------------

--
-- Table structure for table `offers`
--

CREATE TABLE `offers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `job_application_id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `position` varchar(255) NOT NULL,
  `salary` decimal(12,2) NOT NULL,
  `currency_code` varchar(3) NOT NULL DEFAULT 'SGD',
  `joining_date` date DEFAULT NULL,
  `work_location` varchar(255) DEFAULT NULL,
  `terms` text DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'draft',
  `sent_at` timestamp NULL DEFAULT NULL,
  `responded_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_type_id` bigint(20) UNSIGNED DEFAULT NULL,
  `company_grade_id` bigint(20) UNSIGNED DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `validity_days` int(10) UNSIGNED NOT NULL DEFAULT 30,
  `entitlements` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`entitlements`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `packages`
--

INSERT INTO `packages` (`id`, `company_type_id`, `company_grade_id`, `name`, `slug`, `description`, `validity_days`, `entitlements`, `is_active`, `created_at`, `updated_at`) VALUES
(1, NULL, NULL, 'Starter', 'starter', 'Starter employer recruitment package', 30, '{\"job_posts\":5,\"candidate_views\":50,\"ai_matching\":false,\"byoai\":true}', 1, '2026-08-20 05:03:52', '2026-08-21 00:27:09'),
(2, NULL, NULL, 'Professional', 'professional', 'Professional employer recruitment package', 30, '{\"job_posts\":25,\"candidate_views\":500,\"ai_matching\":true,\"byoai\":true}', 1, '2026-08-20 05:03:52', '2026-08-21 00:27:09'),
(3, NULL, NULL, 'Enterprise', 'enterprise', 'Enterprise employer recruitment package', 30, '{\"job_posts\":-1,\"candidate_views\":-1,\"ai_matching\":true,\"external_candidates\":true,\"byoai\":true}', 1, '2026-08-20 05:03:52', '2026-08-21 00:27:09');

-- --------------------------------------------------------

--
-- Table structure for table `package_prices`
--

CREATE TABLE `package_prices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `package_id` bigint(20) UNSIGNED NOT NULL,
  `currency_code` varchar(3) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `tax_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `package_prices`
--

INSERT INTO `package_prices` (`id`, `package_id`, `currency_code`, `amount`, `tax_rate`, `created_at`, `updated_at`) VALUES
(1, 1, 'SGD', '99.00', '0.00', '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(2, 2, 'SGD', '299.00', '0.00', '2026-08-20 05:03:52', '2026-08-20 05:03:52'),
(3, 3, 'SGD', '799.00', '0.00', '2026-08-20 05:03:52', '2026-08-20 05:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `company_id` bigint(20) UNSIGNED DEFAULT NULL,
  `subscription_id` bigint(20) UNSIGNED DEFAULT NULL,
  `job_id` bigint(20) UNSIGNED DEFAULT NULL,
  `reference` varchar(255) NOT NULL,
  `purpose` varchar(255) NOT NULL,
  `gateway` varchar(255) NOT NULL DEFAULT 'manual',
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `currency_code` varchar(3) NOT NULL DEFAULT 'SGD',
  `amount` decimal(12,2) NOT NULL,
  `gateway_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`gateway_payload`)),
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `user_id`, `company_id`, `subscription_id`, `job_id`, `reference`, `purpose`, `gateway`, `status`, `currency_code`, `amount`, `gateway_payload`, `paid_at`, `created_at`, `updated_at`) VALUES
(1, NULL, 1, 1, NULL, 'LB-DEMO-001', 'subscription', 'manual', 'paid', 'SGD', '299.00', NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52', '2026-08-20 05:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--

CREATE TABLE `permissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `module` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `permissions`
--

INSERT INTO `permissions` (`id`, `name`, `slug`, `module`, `created_at`, `updated_at`) VALUES
(1, 'Employers Manage', 'employers.manage', 'employers', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(2, 'Candidates Manage', 'candidates.manage', 'candidates', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(3, 'Jobs Manage', 'jobs.manage', 'jobs', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(4, 'Recruitment Manage', 'recruitment.manage', 'recruitment', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(5, 'Subscriptions Manage', 'subscriptions.manage', 'subscriptions', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(6, 'Payments Manage', 'payments.manage', 'payments', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(7, 'Cms Manage', 'cms.manage', 'cms', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(8, 'Support Manage', 'support.manage', 'support', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(9, 'Api Manage', 'api.manage', 'api', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(10, 'Reports View', 'reports.view', 'reports', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(11, 'Settings Manage', 'settings.manage', 'settings', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(12, 'Security Manage', 'security.manage', 'security', '2026-08-20 05:41:19', '2026-08-20 05:41:19');

-- --------------------------------------------------------

--
-- Table structure for table `permission_role`
--

CREATE TABLE `permission_role` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `permission_role`
--

INSERT INTO `permission_role` (`permission_id`, `role_id`) VALUES
(1, 4),
(2, 4),
(2, 5),
(3, 4),
(3, 5),
(4, 4),
(4, 5),
(5, 6),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 4),
(10, 5),
(10, 6),
(11, 9);

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `platform_notifications`
--

CREATE TABLE `platform_notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `sound` varchar(255) DEFAULT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `platform_notifications`
--

INSERT INTO `platform_notifications` (`id`, `user_id`, `type`, `title`, `body`, `data`, `sound`, `read_at`, `created_at`, `updated_at`) VALUES
(1, 3, 'application_update', 'Your application was shortlisted', 'Lucky Boss Demo Recruitment shortlisted you for Warehouse Supervisor.', NULL, 'application_update', NULL, '2026-08-20 05:03:52', '2026-08-20 05:03:52');

-- --------------------------------------------------------

--
-- Table structure for table `queue_jobs`
--

CREATE TABLE `queue_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `guard_name` varchar(255) NOT NULL DEFAULT 'web',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `name`, `slug`, `guard_name`, `created_at`, `updated_at`) VALUES
(1, 'Super Admin', 'super-admin', 'web', '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(2, 'Employer', 'employer', 'web', '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(3, 'Job Seeker', 'job-seeker', 'web', '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(4, 'Operations Admin', 'operations-admin', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(5, 'Recruitment Manager', 'recruitment-manager', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(6, 'Finance Admin', 'finance-admin', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(7, 'Content Manager', 'content-manager', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(8, 'Support Agent', 'support-agent', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19'),
(9, 'API Manager', 'api-manager', 'web', '2026-08-20 05:41:19', '2026-08-20 05:41:19');

-- --------------------------------------------------------

--
-- Table structure for table `role_user`
--

CREATE TABLE `role_user` (
  `role_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `role_user`
--

INSERT INTO `role_user` (`role_id`, `user_id`, `created_at`, `updated_at`) VALUES
(1, 1, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(1, 4, '2026-08-20 09:09:57', '2026-08-20 09:09:57'),
(2, 2, '2026-08-20 04:32:53', '2026-08-20 04:32:53'),
(2, 6, '2026-08-20 10:55:16', '2026-08-20 10:55:16'),
(3, 3, '2026-08-20 04:32:53', '2026-08-20 04:32:53'),
(3, 5, '2026-08-20 09:50:04', '2026-08-20 09:50:04');

-- --------------------------------------------------------

--
-- Table structure for table `saved_jobs`
--

CREATE TABLE `saved_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `candidate_id` bigint(20) UNSIGNED NOT NULL,
  `job_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `security_logs`
--

CREATE TABLE `security_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `event` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('0FcqwXpXA5QqPu6gFiklXd5WHOAacBskjurhxt22', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiSUVRSVRYUmpRaUdmSHlPbGROZld4aVpNTDRodEJkZ0ljZUNGeEtJdSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjk6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9jb250YWN0IjtzOjU6InJvdXRlIjtzOjE0OiJjb250YWN0LnB1YmxpYyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787295500),
('15IGCKYXYmDrw4YolcQTjVTvw1K8yItjDOhjkACZ', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoia0lTZzRxdWN5WmJrS29DNms0c1liR0NJNlJvb3FwdzFLNmRGVW5UOSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9hYm91dC11cyI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787295500),
('1IzTzM1Mpxf0RmdNBf0EdwhvOpV6Pf4uOEGaoGch', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibkhBbElaSE4zeFQ2U0pEUUFobkNEZVNURkxORlFmWFhOY01DVzlwRCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NjA6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzL3N1Z2dlc3Rpb25zP2ZpZWxkPWxvY2F0aW9uJnE9U2luZyI7czo1OiJyb3V0ZSI7czoxNjoiam9icy5zdWdnZXN0aW9ucyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787295501),
('2KRwZ9xPaISMxmCrvl9CuzlGElQ2jQD10IugC1AC', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiZVpwdkNmcGtHZGIyRXlpNkJCOW5YQWhKblpyRjlsa3FpSWxVelRDcSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7czo0OiJob21lIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787299403),
('4vqQcmkSFaR8eWEdcwpTCfkUzpWUXL8tRAY1vKH7', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUEo5dWVUeFZHT1NGZHBsWnlVU3hFQ0NNWk41a2FsVnNnUEJGMnFvSSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9lbXBsb3llcnMiO3M6NToicm91dGUiO3M6MTY6ImVtcGxveWVycy5wdWJsaWMiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787295499),
('8NNSn993tVoAsSBExFouAMIlX6z2Il5LMood7Mzz', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoia1Z3VXZBeld4ZGRHRjd0Y2F6RVk5UFA0WmhtV2ozSTlYTjRZRUh0QiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9yZWZ1bmQtcG9saWN5IjtzOjU6InJvdXRlIjtzOjk6InBhZ2Uuc2hvdyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787295501),
('9YfqxdRibw4LrKv83ywaoZnu84K22M7yxjRdyr7R', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiOGJoeXpmVVVmZE1IVkhOS2lxVWxRb2xXcnpybzBwZ3FzSG9LbVE0MyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9wcml2YWN5LXBvbGljeSI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787295501),
('CCivlcwMUPgs2WQyJKdI91gyFErmto3toqCpTHUv', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.134.0 Chrome/148.0.7778.280 Electron/42.8.1 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiYUVUc0lrM0NvT1J5cVNJUkFCRTJETEprN2E0T0RudTcweXlFbUlUdSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo0MDoiaHR0cDovLzEyNy4wLjAuMTo4MDAwL2pvYi1zZWVrZXIvcHJvZmlsZSI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjI3OiJodHRwOi8vMTI3LjAuMC4xOjgwMDAvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787293894),
('CGaQg9j9Vq6A0324ujk4Iyu710ay8J1GJ0wohKgI', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUW9xTThhRnR4a095Y0htQTUyYUEya3R5d0ppUGJZTWdXNEdTVXVxUyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2ItY2F0ZWdvcmllcyI7czo1OiJyb3V0ZSI7czoxNjoiY2F0ZWdvcmllcy5pbmRleCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787295499),
('cLL7yww4sFW2KNHFq97VcqtqIal3kFG8kNcIcNA0', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoia0VVc3l0aHFobTZSeVlLSGZEcGdZc2pvUGFHT3Z0Q1d3NllmUm9sbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NjA6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzL3N1Z2dlc3Rpb25zP2ZpZWxkPWxvY2F0aW9uJnE9U2luZyI7czo1OiJyb3V0ZSI7czoxNjoiam9icy5zdWdnZXN0aW9ucyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299405),
('cshWqi1xsqutYTC9MH4Vtpz0qFsKxluutfFbKyIh', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiRmZGYk9wN1NGSUVqYnN5M1RSZ3A2THg0NFY2VkNUVWE0dW1qZTc0byI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDg6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy90ZXJtcy1hbmQtY29uZGl0aW9ucyI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787295501),
('eexp8rNqDo5cBDN1r2689v2UmM83Tl7O4iifUica', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVWRtZkZvT2czUnNUV3lDNXU4eURROEpzVllWQVJMMjJnUkoydENTRCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9ibG9nIjtzOjU6InJvdXRlIjtzOjExOiJibG9ncy5pbmRleCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299404),
('Eqbo8qR6UQHr09yjMGj7CSCGaxAhNesDgG0jWFMN', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiaERZMXNBbTFuZWFIQjBYM0l2OVlxSm1LVjFGcUkxQUpZRE5kQU92ayI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9ibG9nIjtzOjU6InJvdXRlIjtzOjExOiJibG9ncy5pbmRleCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787295500),
('ER6PW4pWsyW0f8RCRpmHT8JH2WWzos6XrXGVuNRb', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiNGhKRHVSR0JaUzJFRU42OWJnYks0bFBEdUpFRDdheTRwQm5DVkRkaSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9mYXEiO3M6NToicm91dGUiO3M6OToicGFnZS5zaG93Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787299404),
('esx3wCiPKNwcg0Z9i0hFAmi0J6QwybxyVSJQxNHS', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoidWxCT2prUUIxamtJTkJlU0JQSklJbFBINGJmdmtoWUE2T2M5SGV1OSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9yZWZ1bmQtcG9saWN5IjtzOjU6InJvdXRlIjtzOjk6InBhZ2Uuc2hvdyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299405),
('G7Gh9whU5tthUwR2UvxaUPItNYzbaF0DwXRRsKf6', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiR2pXODBSalliZTFDVkliQTlUR1ltWEVBOXN5WTduSHljVlRwcjRYUiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9mYXEiO3M6NToicm91dGUiO3M6OToicGFnZS5zaG93Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787295500),
('GCySoMoPs1jyexQL85YSKnEyuLidzQjGerXIyKIs', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiZGpUdXpuYkhoQllYd2Q3TXQzV3BFWE1rVHIzMTBJWm56NzRTUkNpRSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjk6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9jb250YWN0IjtzOjU6InJvdXRlIjtzOjE0OiJjb250YWN0LnB1YmxpYyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299404),
('HJkX6EvlMbGjfZESMNswh4heApdKa82xXR659kIr', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiR0h2ckx4a09FTTNBWE5QcVVjelhyNG5TNFNZMjAzNnJwUWxVazNqbSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzM6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2Itc2Vla2VycyI7czo1OiJyb3V0ZSI7czoxNDoic2Vla2Vycy5wdWJsaWMiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299404),
('HP4z97h8YxctaRgSwiYjRkUDUh28SCfpMRHWDu9m', 1, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoibEVmbTgzS0tWSGtKZDdxeHVmOU9lM055VzdQYUlLb29WVHh0N3B3MyI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6MzoidXJsIjthOjA6e31zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aToxO30=', 1787301827),
('Ig86k6oaoU8dlhD89JgIX7YyaFV7a38Q4zV4sitm', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVzJ4R0VvNGZNNXVyVkFGTG1EOHZDN055RmV6V1FPVTJ2ZDdEZ3ZJYiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzIjtzOjU6InJvdXRlIjtzOjEwOiJqb2JzLmluZGV4Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787295499),
('IZhvQiDqlZiIKPJ7PaRmDNrKMqFE4IIHZekAuZQA', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoicVRkQnJ2d2NOOFc3ZzZqTHVWQ0JNcE5NaTQ0dXFwaDZPSFJFYTNEYiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2ItY2F0ZWdvcmllcyI7czo1OiJyb3V0ZSI7czoxNjoiY2F0ZWdvcmllcy5pbmRleCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299403),
('KTBTbiai4oAuj1JD8gZnmEEyfKbkT5dYeZFMOm2N', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiczFGTUNZMURVV2dQdkcwVlpNeXN1NXNwa0RpaUJBeUdIbllybURkbyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NTc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzL3N1Z2dlc3Rpb25zP2ZpZWxkPXRpdGxlJnE9V2FyZSI7czo1OiJyb3V0ZSI7czoxNjoiam9icy5zdWdnZXN0aW9ucyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299405),
('Mc5Vt3z2BKqmuYWl2417RzqZVAEfLOhZKtusQQb7', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiaFpSaFByMkJBOGx0YWNnTmtDUDUza1lLQlNpeGVWckVORGNyRnBaeiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9hYm91dC11cyI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299404),
('onnJMbDjCMZkGmTvsP0FgJCfLOUefBX3lX6wmqUQ', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoidjhrQ2VKQlA3eHNUSlU3c2QxU0RHOXJTN3QzblFHeGhhTFNGNEhicCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7czo0OiJob21lIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787295498),
('oTr3x63Oo5FL1fl1XF4rSXGak5qKlMFGqQZHeeys', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoidldTaUZvZFhPWUNVNjNjZWdKdDl6QnlvSk82QUswQTVlRm5RVTVRWSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9lbXBsb3llcnMiO3M6NToicm91dGUiO3M6MTY6ImVtcGxveWVycy5wdWJsaWMiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299404),
('RwEk55jM6maZRI8AHHm7LNJWvpsRX16hoK5GpGdr', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiN3kzM2tIb1owcG4yclZGa0t1RG5XNTNQNkJvZVpIMWtBQ3FnbjBWMiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzM6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2Itc2Vla2VycyI7czo1OiJyb3V0ZSI7czoxNDoic2Vla2Vycy5wdWJsaWMiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787295500),
('tdiptagf7hBSA5VcmgxGO8uGzTMwScG3MRefJKGc', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoieG9OdEJGM3RHQzRwNEV3SGt4SjVVQzRoaUJkYW4yNDN5OGlLN0VXdCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzP2tleXdvcmQ9V2FyZWhvdXNlIjtzOjU6InJvdXRlIjtzOjEwOiJqb2JzLmluZGV4Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787295501),
('uhV9R7EJQ5UKpEhWhQ7sOeOqJszA6k9PfS0qqqE5', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVTNKbVBIYmdnUWNjRzVyb2k1RUxOQzEyV2xSVTBJbDBIenlaN0tVeSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9hYm91dC11cyI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299010),
('UT6aOUdSQK1aVUQyYihLWs5fYXjhirCcl1L1aYF9', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoid3NSaFYwNFZyZHJQbDc5b1RRaEhCaDlIQUlmRGZNSjJOOVlwa2xWaSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjk6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9jb250YWN0IjtzOjU6InJvdXRlIjtzOjE0OiJjb250YWN0LnB1YmxpYyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299010),
('wqJal96Exu102vPKxUmf1KqDdRXbjoIU0DzjCVFJ', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiZzgzNGFJVFlCSkdGTURVbjRHbUMxN0IybTE0YU8ybHF3endmamMzdSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDg6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy90ZXJtcy1hbmQtY29uZGl0aW9ucyI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299404),
('WZRZj6C7g55bjWFGPvwhXgT8kUhoqvJwdjOH7RhP', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiZ3JHdUlJUWZzVGxCczV0SHNsMW1PQWNvZ1lXcms3eWhoR0xXVXBuYiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDI6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9wYWdlcy9wcml2YWN5LXBvbGljeSI7czo1OiJyb3V0ZSI7czo5OiJwYWdlLnNob3ciO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1787299405),
('x7ztZe6SPjaMnuYMW3pDXsau4RSBYYthPGTgr3G2', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.134.0 Chrome/148.0.7778.280 Electron/42.8.1 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiQjBWd0I4S0Z6amY1WlEyaVFpWHhVSUoxTVB5Y0VYRW9hdTFGVkR3ZSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7czo0OiJob21lIjt9fQ==', 1787301782),
('XEFd39fHvnuM2aHSTiz5Ae6Ajfd6bqU4eUh1QUeu', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoib2xtb1E5c3Y2SGVKR084cEd2N3ZKYjhmMHJHOGpyM1loNnBSa2x4MyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjY6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9qb2JzIjtzOjU6InJvdXRlIjtzOjEwOiJqb2JzLmluZGV4Ijt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1787299403),
('zzdbpFHeBkobbgbTBBzJdE6pp9THpE39hgC86dR1', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-IN) WindowsPowerShell/5.1.19041.6456', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiTk1zendoRTUwWXBvckg0bTBselVqR3JJd1M3emRCbEJuSVZ1TVM5QiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9zcGVjaWFsaXphdGlvbnMiO3M6NToicm91dGUiO3M6MjE6InNwZWNpYWxpemF0aW9ucy5pbmRleCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1787299403);

-- --------------------------------------------------------

--
-- Table structure for table `sliders`
--

CREATE TABLE `sliders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `cta_text` varchar(255) DEFAULT NULL,
  `cta_url` varchar(255) DEFAULT NULL,
  `sort_order` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `starts_at` date DEFAULT NULL,
  `ends_at` date DEFAULT NULL,
  `web_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `app_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sliders`
--

INSERT INTO `sliders` (`id`, `title`, `subtitle`, `image_path`, `cta_text`, `cta_url`, `sort_order`, `starts_at`, `ends_at`, `web_enabled`, `app_enabled`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Find the Right Job. Build a Better Career.', 'AI-powered recruitment for Singapore, Malaysia, India & More.', 'uploads/sliders/slider-20260820145652-YhflCU.jpg', 'Search Jobs', '/#jobs', 1, NULL, NULL, 1, 1, 1, '2026-08-20 05:03:52', '2026-08-20 09:26:52');

-- --------------------------------------------------------

--
-- Table structure for table `subscriptions`
--

CREATE TABLE `subscriptions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` bigint(20) UNSIGNED NOT NULL,
  `package_id` bigint(20) UNSIGNED NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `starts_at` date DEFAULT NULL,
  `expires_at` date DEFAULT NULL,
  `entitlements` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`entitlements`)),
  `currency_code` varchar(3) NOT NULL DEFAULT 'SGD',
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subscriptions`
--

INSERT INTO `subscriptions` (`id`, `company_id`, `package_id`, `status`, `starts_at`, `expires_at`, `entitlements`, `currency_code`, `amount`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'active', '2026-08-21', '2026-11-19', '{\"job_posts\":25,\"candidate_views\":500,\"ai_matching\":true,\"byoai\":true}', 'SGD', '299.00', '2026-08-20 05:03:52', '2026-08-21 00:39:24');

-- --------------------------------------------------------

--
-- Table structure for table `support_tickets`
--

CREATE TABLE `support_tickets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `assigned_to` bigint(20) UNSIGNED DEFAULT NULL,
  `source` varchar(255) NOT NULL DEFAULT 'website',
  `subject` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'new',
  `priority` varchar(255) NOT NULL DEFAULT 'normal',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `support_tickets`
--

INSERT INTO `support_tickets` (`id`, `user_id`, `assigned_to`, `source`, `subject`, `message`, `status`, `priority`, `created_at`, `updated_at`) VALUES
(1, 3, NULL, 'website', 'Need help with job application', 'Please advise on completing my profile.', 'new', 'normal', '2026-08-20 05:20:18', '2026-08-20 05:20:18');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `country_code` varchar(3) DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `country_code`, `email_verified_at`, `password`, `is_active`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Lucky Boss Admin', 'admincrm@luckyboss.org', NULL, 'SG', NULL, '$2y$12$qyKHUWPLvxohxvsbNTOK4eLkUjBeF8ec8SIfrL9.LsiEy5HH.hRy.', 1, NULL, '2026-08-20 04:32:52', '2026-08-20 06:56:33'),
(2, 'Arun Kumar', 'employer@luckyboss.test', '+6591234567', 'SG', NULL, '$2y$12$kCMndc3MMrlfeE.6RyJquOB40MgkaWpPkAVbMUYN9FRL.1x5lyHq6', 1, NULL, '2026-08-20 04:32:52', '2026-08-20 04:32:52'),
(3, 'Maya Tan', 'candidate@luckyboss.test', '+6587654321', 'SG', NULL, '$2y$12$oqkICc8aYiRwBSRnC54g/ecvD738HYPRc4w/Na88L2ui4YpRZNuXi', 1, NULL, '2026-08-20 04:32:53', '2026-08-20 04:32:53'),
(4, 'Lucky Boss Admin', 'admin@luckyboss.test', NULL, 'SG', NULL, '$2y$12$edsAbLg4GgdVPMPyNDZ1VuGvuyC/m7dxF7WiOCLyh2GU2ULnUqIb2', 1, NULL, '2026-08-20 09:09:57', '2026-08-20 09:09:57'),
(5, 'thiru', 'thiru9944@gmail.com', '7373727190', 'SG', NULL, '$2y$12$JePcvY9YQva4ViPu9kosTur7EkOnJ746To9wgEk0l4c3OcXTN5EwO', 1, NULL, '2026-08-20 09:50:04', '2026-08-20 09:50:04'),
(6, 'maac', 'thiru.maac@gmail.com', '9944995493', 'SG', NULL, '$2y$12$k7IacJUS6kR7ZmNNpQbt.enBQELKWf43yasbZYsSPe.2JozmrRciu', 1, NULL, '2026-08-20 10:55:16', '2026-08-20 10:55:16');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_records`
--
ALTER TABLE `admin_records`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `admin_records_module_slug_unique` (`module`,`slug`),
  ADD KEY `admin_records_module_index` (`module`),
  ADD KEY `admin_records_slug_index` (`slug`);

--
-- Indexes for table `api_integrations`
--
ALTER TABLE `api_integrations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `api_integrations_key_unique` (`key`);

--
-- Indexes for table `application_status_histories`
--
ALTER TABLE `application_status_histories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `application_status_histories_job_application_id_foreign` (`job_application_id`),
  ADD KEY `application_status_histories_user_id_foreign` (`user_id`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `audit_logs_user_id_foreign` (`user_id`),
  ADD KEY `audit_logs_company_id_foreign` (`company_id`),
  ADD KEY `audit_logs_entity_type_entity_id_index` (`entity_type`,`entity_id`);

--
-- Indexes for table `backup_logs`
--
ALTER TABLE `backup_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `backup_logs_created_by_foreign` (`created_by`);

--
-- Indexes for table `blogs`
--
ALTER TABLE `blogs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `blogs_slug_unique` (`slug`),
  ADD KEY `blogs_published_at_index` (`published_at`),
  ADD KEY `blogs_is_published_index` (`is_published`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `candidate_archives`
--
ALTER TABLE `candidate_archives`
  ADD PRIMARY KEY (`id`),
  ADD KEY `candidate_archives_company_id_foreign` (`company_id`),
  ADD KEY `candidate_archives_job_id_foreign` (`job_id`),
  ADD KEY `candidate_archives_candidate_id_foreign` (`candidate_id`),
  ADD KEY `candidate_archives_archived_by_foreign` (`archived_by`);

--
-- Indexes for table `candidate_experiences`
--
ALTER TABLE `candidate_experiences`
  ADD PRIMARY KEY (`id`),
  ADD KEY `candidate_experiences_candidate_id_foreign` (`candidate_id`);

--
-- Indexes for table `candidate_notes`
--
ALTER TABLE `candidate_notes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `candidate_notes_company_id_foreign` (`company_id`),
  ADD KEY `candidate_notes_job_application_id_foreign` (`job_application_id`),
  ADD KEY `candidate_notes_user_id_foreign` (`user_id`);

--
-- Indexes for table `candidate_profiles`
--
ALTER TABLE `candidate_profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `candidate_profiles_user_id_unique` (`user_id`);

--
-- Indexes for table `candidate_resumes`
--
ALTER TABLE `candidate_resumes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `candidate_resumes_candidate_id_foreign` (`candidate_id`);

--
-- Indexes for table `candidate_skills`
--
ALTER TABLE `candidate_skills`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `candidate_skills_candidate_id_name_unique` (`candidate_id`,`name`);

--
-- Indexes for table `communication_logs`
--
ALTER TABLE `communication_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `communication_logs_company_id_foreign` (`company_id`),
  ADD KEY `communication_logs_sender_id_foreign` (`sender_id`),
  ADD KEY `communication_logs_recipient_id_foreign` (`recipient_id`);

--
-- Indexes for table `communication_templates`
--
ALTER TABLE `communication_templates`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `companies`
--
ALTER TABLE `companies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `companies_company_type_id_foreign` (`company_type_id`),
  ADD KEY `companies_company_grade_id_foreign` (`company_grade_id`),
  ADD KEY `companies_registration_number_index` (`registration_number`),
  ADD KEY `companies_country_code_index` (`country_code`),
  ADD KEY `companies_status_index` (`status`);

--
-- Indexes for table `company_grades`
--
ALTER TABLE `company_grades`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `company_grades_slug_unique` (`slug`);

--
-- Indexes for table `company_types`
--
ALTER TABLE `company_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `company_types_slug_unique` (`slug`);

--
-- Indexes for table `company_users`
--
ALTER TABLE `company_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `company_users_company_id_user_id_unique` (`company_id`,`user_id`),
  ADD KEY `company_users_user_id_foreign` (`user_id`);

--
-- Indexes for table `countries`
--
ALTER TABLE `countries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `countries_code_unique` (`code`),
  ADD UNIQUE KEY `countries_name_unique` (`name`);

--
-- Indexes for table `currencies`
--
ALTER TABLE `currencies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `currencies_code_unique` (`code`);

--
-- Indexes for table `employer_ai_settings`
--
ALTER TABLE `employer_ai_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `employer_ai_settings_company_id_unique` (`company_id`);

--
-- Indexes for table `employer_documents`
--
ALTER TABLE `employer_documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employer_documents_company_id_foreign` (`company_id`),
  ADD KEY `employer_documents_status_index` (`status`);

--
-- Indexes for table `employer_notes`
--
ALTER TABLE `employer_notes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employer_notes_company_id_foreign` (`company_id`),
  ADD KEY `employer_notes_user_id_foreign` (`user_id`);

--
-- Indexes for table `employer_portal_records`
--
ALTER TABLE `employer_portal_records`
  ADD PRIMARY KEY (`id`),
  ADD KEY `employer_portal_records_company_id_foreign` (`company_id`),
  ADD KEY `employer_portal_records_created_by_foreign` (`created_by`),
  ADD KEY `employer_portal_records_section_index` (`section`);

--
-- Indexes for table `external_sources`
--
ALTER TABLE `external_sources`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `feature_flags`
--
ALTER TABLE `feature_flags`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `feature_flags_key_unique` (`key`);

--
-- Indexes for table `import_batches`
--
ALTER TABLE `import_batches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `import_batches_external_source_id_foreign` (`external_source_id`),
  ADD KEY `import_batches_user_id_foreign` (`user_id`);

--
-- Indexes for table `interviews`
--
ALTER TABLE `interviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `interviews_job_application_id_foreign` (`job_application_id`),
  ADD KEY `interviews_company_id_foreign` (`company_id`),
  ADD KEY `interviews_interviewer_id_foreign` (`interviewer_id`),
  ADD KEY `interviews_status_index` (`status`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoices_number_unique` (`number`),
  ADD KEY `invoices_payment_id_foreign` (`payment_id`),
  ADD KEY `invoices_company_id_foreign` (`company_id`),
  ADD KEY `invoices_user_id_foreign` (`user_id`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_company_id_foreign` (`company_id`),
  ADD KEY `jobs_job_category_id_foreign` (`job_category_id`),
  ADD KEY `jobs_title_index` (`title`),
  ADD KEY `jobs_country_code_index` (`country_code`),
  ADD KEY `jobs_closing_date_index` (`closing_date`),
  ADD KEY `jobs_status_index` (`status`);

--
-- Indexes for table `job_alerts`
--
ALTER TABLE `job_alerts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `job_alerts_candidate_id_foreign` (`candidate_id`),
  ADD KEY `job_alerts_job_category_id_foreign` (`job_category_id`);

--
-- Indexes for table `job_applications`
--
ALTER TABLE `job_applications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `job_applications_job_id_candidate_id_unique` (`job_id`,`candidate_id`),
  ADD KEY `job_applications_candidate_id_foreign` (`candidate_id`),
  ADD KEY `job_applications_status_index` (`status`),
  ADD KEY `job_applications_assigned_to_foreign` (`assigned_to`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `job_categories`
--
ALTER TABLE `job_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `job_categories_slug_unique` (`slug`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `messages_sender_id_foreign` (`sender_id`),
  ADD KEY `messages_recipient_id_foreign` (`recipient_id`),
  ADD KEY `messages_company_id_foreign` (`company_id`),
  ADD KEY `messages_job_application_id_foreign` (`job_application_id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `offers`
--
ALTER TABLE `offers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `offers_job_application_id_foreign` (`job_application_id`),
  ADD KEY `offers_company_id_foreign` (`company_id`),
  ADD KEY `offers_status_index` (`status`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `packages_slug_unique` (`slug`),
  ADD KEY `packages_company_type_id_foreign` (`company_type_id`),
  ADD KEY `packages_company_grade_id_foreign` (`company_grade_id`);

--
-- Indexes for table `package_prices`
--
ALTER TABLE `package_prices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `package_prices_package_id_currency_code_unique` (`package_id`,`currency_code`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `payments_reference_unique` (`reference`),
  ADD KEY `payments_user_id_foreign` (`user_id`),
  ADD KEY `payments_company_id_foreign` (`company_id`),
  ADD KEY `payments_subscription_id_foreign` (`subscription_id`),
  ADD KEY `payments_job_id_foreign` (`job_id`),
  ADD KEY `payments_status_index` (`status`);

--
-- Indexes for table `permissions`
--
ALTER TABLE `permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `permissions_slug_unique` (`slug`);

--
-- Indexes for table `permission_role`
--
ALTER TABLE `permission_role`
  ADD PRIMARY KEY (`permission_id`,`role_id`),
  ADD KEY `permission_role_role_id_foreign` (`role_id`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `platform_notifications`
--
ALTER TABLE `platform_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `platform_notifications_user_id_foreign` (`user_id`);

--
-- Indexes for table `queue_jobs`
--
ALTER TABLE `queue_jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `queue_jobs_queue_index` (`queue`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `roles_slug_unique` (`slug`);

--
-- Indexes for table `role_user`
--
ALTER TABLE `role_user`
  ADD PRIMARY KEY (`role_id`,`user_id`),
  ADD KEY `role_user_user_id_foreign` (`user_id`);

--
-- Indexes for table `saved_jobs`
--
ALTER TABLE `saved_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `saved_jobs_candidate_id_job_id_unique` (`candidate_id`,`job_id`),
  ADD KEY `saved_jobs_job_id_foreign` (`job_id`);

--
-- Indexes for table `security_logs`
--
ALTER TABLE `security_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `security_logs_user_id_foreign` (`user_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `sliders`
--
ALTER TABLE `sliders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `subscriptions_company_id_foreign` (`company_id`),
  ADD KEY `subscriptions_package_id_foreign` (`package_id`),
  ADD KEY `subscriptions_status_index` (`status`),
  ADD KEY `subscriptions_expires_at_index` (`expires_at`);

--
-- Indexes for table `support_tickets`
--
ALTER TABLE `support_tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `support_tickets_user_id_foreign` (`user_id`),
  ADD KEY `support_tickets_assigned_to_foreign` (`assigned_to`),
  ADD KEY `support_tickets_status_index` (`status`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_phone_unique` (`phone`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_records`
--
ALTER TABLE `admin_records`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `api_integrations`
--
ALTER TABLE `api_integrations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `application_status_histories`
--
ALTER TABLE `application_status_histories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `backup_logs`
--
ALTER TABLE `backup_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `blogs`
--
ALTER TABLE `blogs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `candidate_archives`
--
ALTER TABLE `candidate_archives`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `candidate_experiences`
--
ALTER TABLE `candidate_experiences`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `candidate_notes`
--
ALTER TABLE `candidate_notes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `candidate_profiles`
--
ALTER TABLE `candidate_profiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `candidate_resumes`
--
ALTER TABLE `candidate_resumes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `candidate_skills`
--
ALTER TABLE `candidate_skills`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `communication_logs`
--
ALTER TABLE `communication_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `communication_templates`
--
ALTER TABLE `communication_templates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `companies`
--
ALTER TABLE `companies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `company_grades`
--
ALTER TABLE `company_grades`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `company_types`
--
ALTER TABLE `company_types`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `company_users`
--
ALTER TABLE `company_users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `countries`
--
ALTER TABLE `countries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `currencies`
--
ALTER TABLE `currencies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `employer_ai_settings`
--
ALTER TABLE `employer_ai_settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employer_documents`
--
ALTER TABLE `employer_documents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employer_notes`
--
ALTER TABLE `employer_notes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employer_portal_records`
--
ALTER TABLE `employer_portal_records`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `external_sources`
--
ALTER TABLE `external_sources`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `feature_flags`
--
ALTER TABLE `feature_flags`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `import_batches`
--
ALTER TABLE `import_batches`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `interviews`
--
ALTER TABLE `interviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `job_alerts`
--
ALTER TABLE `job_alerts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `job_applications`
--
ALTER TABLE `job_applications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `job_categories`
--
ALTER TABLE `job_categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `offers`
--
ALTER TABLE `offers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `package_prices`
--
ALTER TABLE `package_prices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `permissions`
--
ALTER TABLE `permissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `platform_notifications`
--
ALTER TABLE `platform_notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `queue_jobs`
--
ALTER TABLE `queue_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `saved_jobs`
--
ALTER TABLE `saved_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `security_logs`
--
ALTER TABLE `security_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sliders`
--
ALTER TABLE `sliders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `subscriptions`
--
ALTER TABLE `subscriptions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `support_tickets`
--
ALTER TABLE `support_tickets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `application_status_histories`
--
ALTER TABLE `application_status_histories`
  ADD CONSTRAINT `application_status_histories_job_application_id_foreign` FOREIGN KEY (`job_application_id`) REFERENCES `job_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `application_status_histories_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `audit_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `backup_logs`
--
ALTER TABLE `backup_logs`
  ADD CONSTRAINT `backup_logs_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `candidate_archives`
--
ALTER TABLE `candidate_archives`
  ADD CONSTRAINT `candidate_archives_archived_by_foreign` FOREIGN KEY (`archived_by`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `candidate_archives_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `candidate_archives_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `candidate_archives_job_id_foreign` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `candidate_experiences`
--
ALTER TABLE `candidate_experiences`
  ADD CONSTRAINT `candidate_experiences_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `candidate_notes`
--
ALTER TABLE `candidate_notes`
  ADD CONSTRAINT `candidate_notes_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `candidate_notes_job_application_id_foreign` FOREIGN KEY (`job_application_id`) REFERENCES `job_applications` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `candidate_notes_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `candidate_profiles`
--
ALTER TABLE `candidate_profiles`
  ADD CONSTRAINT `candidate_profiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `candidate_resumes`
--
ALTER TABLE `candidate_resumes`
  ADD CONSTRAINT `candidate_resumes_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `candidate_skills`
--
ALTER TABLE `candidate_skills`
  ADD CONSTRAINT `candidate_skills_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `communication_logs`
--
ALTER TABLE `communication_logs`
  ADD CONSTRAINT `communication_logs_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `communication_logs_recipient_id_foreign` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `communication_logs_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `companies`
--
ALTER TABLE `companies`
  ADD CONSTRAINT `companies_company_grade_id_foreign` FOREIGN KEY (`company_grade_id`) REFERENCES `company_grades` (`id`),
  ADD CONSTRAINT `companies_company_type_id_foreign` FOREIGN KEY (`company_type_id`) REFERENCES `company_types` (`id`);

--
-- Constraints for table `company_users`
--
ALTER TABLE `company_users`
  ADD CONSTRAINT `company_users_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `company_users_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employer_ai_settings`
--
ALTER TABLE `employer_ai_settings`
  ADD CONSTRAINT `employer_ai_settings_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employer_documents`
--
ALTER TABLE `employer_documents`
  ADD CONSTRAINT `employer_documents_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employer_notes`
--
ALTER TABLE `employer_notes`
  ADD CONSTRAINT `employer_notes_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `employer_notes_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `employer_portal_records`
--
ALTER TABLE `employer_portal_records`
  ADD CONSTRAINT `employer_portal_records_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `employer_portal_records_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `import_batches`
--
ALTER TABLE `import_batches`
  ADD CONSTRAINT `import_batches_external_source_id_foreign` FOREIGN KEY (`external_source_id`) REFERENCES `external_sources` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `import_batches_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `interviews`
--
ALTER TABLE `interviews`
  ADD CONSTRAINT `interviews_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `interviews_interviewer_id_foreign` FOREIGN KEY (`interviewer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `interviews_job_application_id_foreign` FOREIGN KEY (`job_application_id`) REFERENCES `job_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `invoices_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `invoices_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `jobs`
--
ALTER TABLE `jobs`
  ADD CONSTRAINT `jobs_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `jobs_job_category_id_foreign` FOREIGN KEY (`job_category_id`) REFERENCES `job_categories` (`id`);

--
-- Constraints for table `job_alerts`
--
ALTER TABLE `job_alerts`
  ADD CONSTRAINT `job_alerts_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `job_alerts_job_category_id_foreign` FOREIGN KEY (`job_category_id`) REFERENCES `job_categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `job_applications`
--
ALTER TABLE `job_applications`
  ADD CONSTRAINT `job_applications_assigned_to_foreign` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `job_applications_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `job_applications_job_id_foreign` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `messages_job_application_id_foreign` FOREIGN KEY (`job_application_id`) REFERENCES `job_applications` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `messages_recipient_id_foreign` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `offers`
--
ALTER TABLE `offers`
  ADD CONSTRAINT `offers_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `offers_job_application_id_foreign` FOREIGN KEY (`job_application_id`) REFERENCES `job_applications` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `packages`
--
ALTER TABLE `packages`
  ADD CONSTRAINT `packages_company_grade_id_foreign` FOREIGN KEY (`company_grade_id`) REFERENCES `company_grades` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `packages_company_type_id_foreign` FOREIGN KEY (`company_type_id`) REFERENCES `company_types` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `package_prices`
--
ALTER TABLE `package_prices`
  ADD CONSTRAINT `package_prices_package_id_foreign` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `payments_job_id_foreign` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `payments_subscription_id_foreign` FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `payments_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `permission_role`
--
ALTER TABLE `permission_role`
  ADD CONSTRAINT `permission_role_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `permission_role_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `platform_notifications`
--
ALTER TABLE `platform_notifications`
  ADD CONSTRAINT `platform_notifications_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `role_user`
--
ALTER TABLE `role_user`
  ADD CONSTRAINT `role_user_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_user_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `saved_jobs`
--
ALTER TABLE `saved_jobs`
  ADD CONSTRAINT `saved_jobs_candidate_id_foreign` FOREIGN KEY (`candidate_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `saved_jobs_job_id_foreign` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `security_logs`
--
ALTER TABLE `security_logs`
  ADD CONSTRAINT `security_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD CONSTRAINT `subscriptions_company_id_foreign` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `subscriptions_package_id_foreign` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`);

--
-- Constraints for table `support_tickets`
--
ALTER TABLE `support_tickets`
  ADD CONSTRAINT `support_tickets_assigned_to_foreign` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `support_tickets_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
