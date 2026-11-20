-- Optional permissions table for admin panel modules
-- Run this once in your database if you need per-account module access control.

CREATE TABLE IF NOT EXISTS `admin_module_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_type` enum('admin','employee') NOT NULL,
  `account_id` int(11) NOT NULL,
  `module_key` enum('super_admin','accounts','crm','property','content') NOT NULL,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_account_module` (`account_type`,`account_id`,`module_key`),
  KEY `idx_account` (`account_type`,`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Example: give full access to primary admin (admin_id=1)
-- INSERT INTO admin_module_permissions (account_type, account_id, module_key, is_enabled)
-- VALUES
-- ('admin', 1, 'super_admin', 1),
-- ('admin', 1, 'accounts', 1),
-- ('admin', 1, 'crm', 1),
-- ('admin', 1, 'property', 1),
-- ('admin', 1, 'content', 1);

-- Example: employee (users_id=108) can access CRM + Property only
-- INSERT INTO admin_module_permissions (account_type, account_id, module_key, is_enabled)
-- VALUES
-- ('employee', 108, 'crm', 1),
-- ('employee', 108, 'property', 1),
-- ('employee', 108, 'accounts', 0),
-- ('employee', 108, 'content', 0),
-- ('employee', 108, 'super_admin', 0)
-- ON DUPLICATE KEY UPDATE is_enabled = VALUES(is_enabled);
