<?php
require_once __DIR__ . '/notification_service.php';

/**
 * Backward-compatible wrapper.
 */
function sendNotification($user_id, $title, $body, $type = 'chat')
{
    return notifyUser((int) $user_id, (string) $title, (string) $body, (string) $type);
}
