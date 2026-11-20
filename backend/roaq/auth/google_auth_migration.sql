ALTER TABLE `users`
  ADD COLUMN `firebase_uid` varchar(191) DEFAULT NULL AFTER `users_image`,
  ADD COLUMN `auth_provider` varchar(30) DEFAULT NULL AFTER `firebase_uid`;

ALTER TABLE `users`
  ADD UNIQUE KEY `uk_users_firebase_uid` (`firebase_uid`);

ALTER TABLE `users`
  ADD KEY `idx_users_email` (`users_email`);
