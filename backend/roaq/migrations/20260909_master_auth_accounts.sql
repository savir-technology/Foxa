-- Jeeb Master Auth v2
-- Safe migration: extends the existing `admin` table without removing data.
-- Run once on the same database used by the master dashboard.

ALTER TABLE `admin`
  ADD COLUMN `master_account_type` ENUM('super_admin','employee') NOT NULL DEFAULT 'employee' AFTER `admin_role_id`,
  ADD COLUMN `master_portal_key` VARCHAR(32) NULL DEFAULT NULL AFTER `master_account_type`,
  ADD COLUMN `master_approval_status` ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending' AFTER `master_portal_key`,
  ADD COLUMN `master_approved_by` INT(11) NULL DEFAULT NULL AFTER `master_approval_status`,
  ADD COLUMN `master_approved_at` DATETIME NULL DEFAULT NULL AFTER `master_approved_by`,
  ADD COLUMN `master_rejection_reason` VARCHAR(500) NULL DEFAULT NULL AFTER `master_approved_at`,
  ADD KEY `idx_admin_master_portal` (`master_portal_key`),
  ADD KEY `idx_admin_master_approval` (`master_approval_status`);

-- Preserve existing primary administrator access.
UPDATE `admin`
SET
  `master_account_type` = CASE WHEN `admin_role_id` = 1 THEN 'super_admin' ELSE 'employee' END,
  `master_approval_status` = CASE WHEN `admin_approve` = 1 THEN 'approved' ELSE 'pending' END,
  `master_portal_key` = CASE `admin_role_id`
    WHEN 10 THEN 'finance'
    WHEN 11 THEN 'support'
    WHEN 12 THEN 'operations'
    WHEN 13 THEN 'merchants'
    WHEN 14 THEN 'analytics'
    WHEN 15 THEN 'legal'
    ELSE NULL
  END,
  `master_approved_at` = CASE WHEN `admin_approve` = 1 THEN COALESCE(`admin_last_login_at`, `admin_create`) ELSE NULL END;

UPDATE `admin`
SET `master_account_type` = 'super_admin',
    `master_approval_status` = 'approved',
    `master_portal_key` = NULL
WHERE `admin_role_id` = 1;

CREATE TABLE IF NOT EXISTS `master_auth_audit_log` (
  `audit_id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `actor_admin_id` INT(11) NULL DEFAULT NULL,
  `target_admin_id` INT(11) NULL DEFAULT NULL,
  `action_key` VARCHAR(64) NOT NULL,
  `portal_key` VARCHAR(32) NULL DEFAULT NULL,
  `metadata_json` LONGTEXT NULL,
  `ip_address` VARCHAR(64) NULL DEFAULT NULL,
  `user_agent` VARCHAR(255) NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  KEY `idx_master_auth_audit_actor` (`actor_admin_id`),
  KEY `idx_master_auth_audit_target` (`target_admin_id`),
  KEY `idx_master_auth_audit_action` (`action_key`),
  KEY `idx_master_auth_audit_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
