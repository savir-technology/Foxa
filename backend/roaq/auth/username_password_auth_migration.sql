-- Migration for username + password authentication
-- Run this on the existing production database before adding a unique username constraint.

-- 1) Ensure every user has a non-empty username.
UPDATE users
SET users_name = CONCAT('user_', users_id)
WHERE TRIM(COALESCE(users_name, '')) = '';

-- 2) Rename duplicate usernames so every account becomes unique.
UPDATE users u
JOIN (
    SELECT users_id, CONCAT(users_name, '_', users_id) AS new_username
    FROM (
        SELECT users_id,
               users_name,
               ROW_NUMBER() OVER (PARTITION BY users_name ORDER BY users_id ASC) AS row_num
        FROM users
    ) ranked
    WHERE row_num > 1
) duplicates ON duplicates.users_id = u.users_id
SET u.users_name = duplicates.new_username;

-- 3) Add a unique index so the database also enforces unique usernames.
ALTER TABLE users
ADD UNIQUE KEY uk_users_name (users_name);
