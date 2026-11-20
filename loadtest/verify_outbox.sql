-- Run on staging after the notification outbox worker has processed the burst.
SELECT status, COUNT(*) AS event_count
FROM notification_outbox
GROUP BY status
ORDER BY status;

SELECT COUNT(*) AS pending_or_processing
FROM notification_outbox
WHERE status IN ('pending', 'processing');

SELECT COUNT(*) AS failed_events
FROM notification_outbox
WHERE status = 'failed';

-- Expected after the worker catches up:
-- pending_or_processing = 0
-- failed_events = 0
