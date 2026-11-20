<?php
require_once "connect.php";

$stmt = $con->prepare("SELECT items_id, items_name_ar, items_desc_ar FROM items LIMIT 20");
$stmt->execute();
$data = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "<pre>";
print_r($data);
echo "</pre>";
