<?php 

include '../../connect.php';
require_once __DIR__ . '/../../notifications/notification_helper.php';

$msgError = array()  ;

$table = "items";

$name = filterRequest("name");

$namear = filterRequest("namear"); 

$desc = filterRequest("desc"); 

$descar = filterRequest("descar"); 

$count = filterRequest("count");  

$price = filterRequest("price"); 

$discount = filterRequest("discount"); 

$catid = filterRequest("catid"); 

$datenow = filterRequest("datenow"); 
 

$imagename = imageUpload( "../../upload/items" , "files") ;

$data = array( 
"items_name"            => $name,
"items_name_ar"         => $namear,
"items_desc"            => $desc,
"items_desc_ar"         => $descar,
"items_count"           => $count,
"items_price"           => $price,
"items_discount"        => $discount,
"items_active"          => "1",
"items_image"           => $imagename,
"items_cat"             => $catid,
"items_date"            => $datenow
);

$countInserted = insertData($table , $data, false);

if ($countInserted > 0) {
    $itemId = (int)$con->lastInsertId();

    broadcastNotification(
        $con,
        'new_product',
        'تمت إضافة منتج جديد',
        $namear ?: ($name ?: 'منتج جديد متاح الآن'),
        'item',
        $itemId,
        [
            'item_id' => (string)$itemId,
        ],
        null
    );

    echo json_encode(array("status" => "success"));
} else {
    echo json_encode(array("status" => "failure"));
}
