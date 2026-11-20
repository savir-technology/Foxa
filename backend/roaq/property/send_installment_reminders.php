<?php
// Script: Create internal installment reminders + optional push.
require_once '../connect.php';
require_once '../notifications/notification_service.php';

try {
    // Run reminders for both: 3 days before + due date.
    $sql = "SELECT pi.installment_id, pi.user_id, pi.plan_id, pi.due_date, pi.amount, pi.status,
                   DATEDIFF(pi.due_date, CURDATE()) AS days_left,
                   i.items_id AS item_id, i.items_name_ar AS property_name
            FROM property_installments pi
            JOIN property_plans pp ON pp.plan_id = pi.plan_id
            JOIN items i ON i.items_id = pp.item_id
            WHERE pi.status IN ('pending', 'late')
              AND DATEDIFF(pi.due_date, CURDATE()) IN (3, 0)";

    $stmt = $con->query($sql);
    $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];

    $created = 0;
    foreach ($rows as $row) {
      $daysLeft = (int) ($row['days_left'] ?? 0);

      $title = $daysLeft === 0 ? 'تذكير سداد القسط اليوم' : 'تذكير قسط بعد 3 أيام';
      $body = $daysLeft === 0
          ? 'قسطك المستحق اليوم للعقار ' . ($row['property_name'] ?? '') . ' بقيمة ' . $row['amount'] . '.'
          : 'متبقي 3 أيام على قسط العقار ' . ($row['property_name'] ?? '') . ' بقيمة ' . $row['amount'] . '.';

      $ok = notifyUser(
          (int) $row['user_id'],
          $title,
          $body,
          'installment',
          [
              'installment_id' => (int) $row['installment_id'],
              'plan_id' => (int) $row['plan_id'],
              'item_id' => (int) $row['item_id'],
              'due_date' => $row['due_date'],
              'amount' => (float) $row['amount'],
          ],
          'installment_reminder_' . (int) $row['installment_id'] . '_d' . $daysLeft
      );

      if ($ok) {
        $created++;
      }
    }

    echo json_encode([
      'status' => 'success',
      'checked' => count($rows),
      'created_notifications' => $created,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    error_log('send_installment_reminders.php error: ' . $e->getMessage());
    echo json_encode([
      'status' => 'error',
      'message' => 'server error',
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
