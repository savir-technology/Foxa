<?php
require_once "../../../connect.php";
require_once "../administration/common.php";
require_once "../../../asset_urls.php";
header('Content-Type: application/json; charset=utf-8');
masterSetCorsHeaders();
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Cache-Control: no-cache, no-store, must-revalidate');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit(); }

function entityValue(string $table, string $alias, string $column, string $fallback = "''"): string {
    return tableExists($table) && columnExists($table, $column) ? "COALESCE({$alias}.{$column}, {$fallback})" : $fallback;
}
function entityMedia(?string $value, string $folder): string {
    $value = trim((string)$value); if ($value === '') return '';
    if (preg_match('/^https?:\\/\\//i', $value)) return $value;
    return 'https://savir-technology.online/roaqv2/' . trim($folder, '/') . '/' . basename(ltrim($value, '/'));
}
function entityRows(string $sql, array $params = []): array { global $con; $s=$con->prepare($sql); $s->execute($params); return $s->fetchAll(PDO::FETCH_ASSOC) ?: []; }
function entityFirst(string $sql, array $params = []): ?array { $r=entityRows($sql,$params); return $r[0] ?? null; }

try {
    $admin=requireMasterAuth(); requireMasterPermission($admin,'dashboard.view');
    $type=strtolower(trim((string)($_GET['type'] ?? 'vendor'))); $id=max(0,(int)($_GET['id'] ?? $_GET['vendor_id'] ?? 0));
    if ($id<=0) respondJson(['status'=>'error','message'=>'id is required'],400);
    $settings=tableExists('vendor_store_settings') ? 'LEFT JOIN vendor_store_settings s ON s.vendor_id=v.vendor_id' : '';

    if (in_array($type,['vendor','restaurant','store'],true)) {
        if (!tableExists('vendors')) respondJson(['status'=>'error','message'=>'vendors table is missing'],404);
        $vendorLogo=entityValue('vendors','v','vendor_logo', tableExists('vendor_store_settings')&&columnExists('vendor_store_settings','vendor_logo') ? entityValue('vendor_store_settings','s','vendor_logo') : "''");
        $v=entityFirst("SELECT v.vendor_id AS id,".entityValue('vendors','v','vendor_name')." AS vendor_name,".entityValue('vendors','v','store_name')." AS store_name,".entityValue('vendors','v','vendor_type',"'restaurant'")." AS vendor_type,".entityValue('vendors','v','vendor_status',"'active'")." AS vendor_status,".entityValue('vendors','v','vendor_is_verified','1')." AS vendor_is_verified,".entityValue('vendors','v','vendor_phone')." AS phone,".entityValue('vendors','v','vendor_email')." AS email,".entityValue('vendors','v','vendor_description')." AS description,{$vendorLogo} AS logo,".(tableExists('vendor_store_settings')?entityValue('vendor_store_settings','s','store_address'):"''")." AS address,".(tableExists('vendor_store_settings')?entityValue('vendor_store_settings','s','is_open','1'):'1')." AS is_open FROM vendors v {$settings} WHERE v.vendor_id=:id LIMIT 1",[':id'=>$id]);
        if (!$v) respondJson(['status'=>'error','message'=>'Vendor not found'],404); $v['logo_url']=entityMedia($v['logo']??'','uploads/vendors/logo');
        $products=tableExists('items')?entityRows("SELECT i.items_id AS id,".entityValue('items','i','items_name_ar')." AS name_ar,".entityValue('items','i','items_name_en')." AS name_en,".entityValue('items','i','items_price','0')." AS price,".entityValue('items','i','items_active','1')." AS is_active,".entityValue('items','i','items_desc_ar')." AS description,".entityValue('items','i','items_image')." AS image FROM items i WHERE i.vendor_id=:id ORDER BY i.items_id DESC LIMIT 200",[':id'=>$id]):[];
        foreach($products as &$p) $p['image_url']=entityMedia($p['image']??'','uploud/items'); unset($p);
        $orders=(tableExists('order_items')&&tableExists('orders'))?entityRows("SELECT DISTINCT o.orders_id AS id,o.orders_datetime,COALESCE(o.status,o.orders_status,'') AS status,".(tableExists('users')?entityValue('users','u','users_name',"'عميل'"):"'عميل'")." AS customer_name,".entityValue('orders','o','orders_totalprice','0')." AS total FROM order_items oi JOIN orders o ON o.orders_id=oi.order_id ".(tableExists('users')?'LEFT JOIN users u ON u.users_id=o.orders_usersid':'')." WHERE oi.vendor_id=:id ORDER BY o.orders_datetime DESC LIMIT 100",[':id'=>$id]):[];
        // restaurant_hours in production uses hour_id as its ordering column.
        // Do not reference optional columns here because one SQL error would
        // discard the complete entity response.
        $hours = tableExists('restaurant_hours') ? entityRows("SELECT day_key, opens_at, closes_at, is_open FROM restaurant_hours WHERE vendor_id=:id ORDER BY hour_id", [':id'=>$id]) : [];
        respondJson(['status'=>'success','data'=>['entity'=>$v,'vendor'=>$v,'products'=>$products,'orders'=>$orders,'hours'=>$hours]]);
    }

    if ($type==='driver') {
        if (!tableExists('delivery_users')) respondJson(['status'=>'error','message'=>'drivers table is missing'],404);
        $d=entityFirst("SELECT du.id,".entityValue('delivery_users','du','name',"'سائق'")." AS name,".entityValue('delivery_users','du','phone')." AS phone,".entityValue('delivery_users','du','email')." AS email,COALESCE(NULLIF(".entityValue('delivery_users','du','status',"''").",''),'offline') AS status,".entityValue('delivery_users','du','vehicle_type')." AS vehicle_type,".entityValue('delivery_users','du','vehicle_number')." AS vehicle_number,".entityValue('delivery_users','du','latitude')." AS latitude,".entityValue('delivery_users','du','longitude')." AS longitude,".entityValue('delivery_users','du','last_seen_at')." AS last_seen_at,".entityValue('delivery_users','du','profile_image')." AS image FROM delivery_users du WHERE du.id=:id LIMIT 1",[':id'=>$id]);
        if (!$d) respondJson(['status'=>'error','message'=>'Driver not found'],404); $d['image_url']=entityMedia($d['image']??'','uploads/drivers');
        $active="COALESCE(o.status,o.orders_status,'') NOT IN ('delivered','completed','canceled','cancelled','failed','archive','archived','4')";
        $cur=tableExists('orders')?entityRows("SELECT o.orders_id AS id,o.orders_datetime,COALESCE(o.status,o.orders_status,'') AS status,".entityValue('orders','o','orders_totalprice','0')." AS total,".entityValue('orders','o','orders_recipient_name',"'عميل'")." AS customer_name,".entityValue('orders','o','orders_recipient_address_name',"''")." AS address FROM orders o WHERE o.delivery_id=:id AND {$active} ORDER BY o.orders_datetime DESC LIMIT 50",[':id'=>$id]):[];
        $prev=tableExists('orders')?entityRows("SELECT o.orders_id AS id,o.orders_datetime,COALESCE(o.status,o.orders_status,'') AS status,".entityValue('orders','o','orders_totalprice','0')." AS total,".entityValue('orders','o','orders_recipient_name',"'عميل'")." AS customer_name FROM orders o WHERE o.delivery_id=:id AND NOT ({$active}) ORDER BY o.orders_datetime DESC LIMIT 100",[':id'=>$id]):[];
        $rating=(tableExists('driver_ratings')&&columnExists('driver_ratings','driver_id'))?entityFirst("SELECT ROUND(AVG(rating),1) AS average_rating,COUNT(*) AS ratings_count FROM driver_ratings WHERE driver_id=:id",[':id'=>$id]):['average_rating'=>0,'ratings_count'=>0];
        respondJson(['status'=>'success','data'=>['entity'=>$d,'driver'=>$d,'current_trips'=>$cur,'previous_trips'=>$prev,'ratings'=>$rating]]);
    }

    if (in_array($type,['order','customer','user'],true)) {
        if (!tableExists('orders')) respondJson(['status'=>'error','message'=>'orders table is missing'],404);
        $o=entityFirst("SELECT o.orders_id AS id,COALESCE(o.status,o.orders_status,'') AS status,".entityValue('orders','o','orders_datetime')." AS orders_datetime,".entityValue('orders','o','orders_totalprice','0')." AS total,".entityValue('orders','o','orders_recipient_name',"'عميل'")." AS customer_name,".entityValue('orders','o','orders_recipient_phone',"''")." AS phone,".entityValue('orders','o','orders_recipient_address_name',"''")." AS address,o.orders_usersid AS user_id FROM orders o WHERE o.orders_id=:id LIMIT 1",[':id'=>$id]);
        if (!$o) respondJson(['status'=>'error','message'=>'Order not found'],404); $c=null;
        if (tableExists('users')&&!empty($o['user_id'])) $c=entityFirst("SELECT u.users_id AS id,".entityValue('users','u','users_name',"'عميل'")." AS name,".entityValue('users','u','users_phone')." AS phone,".entityValue('users','u','users_image')." AS image FROM users u WHERE u.users_id=:id LIMIT 1",[':id'=>$o['user_id']]);
        $c=$c?:['id'=>$o['user_id'],'name'=>$o['customer_name'],'phone'=>$o['phone'],'image'=>''];
        $c['address']=$o['address']; $c['image_url']=entityMedia($c['image']??'','uploads/users');
        $customerOrders = entityRows("SELECT o.orders_id AS id, COALESCE(o.status,o.orders_status,'') AS status, o.orders_datetime, ".entityValue('orders','o','orders_totalprice','0')." AS total, ".entityValue('orders','o','orders_recipient_address_name',"''")." AS address FROM orders o WHERE o.orders_usersid=:id ORDER BY o.orders_datetime DESC LIMIT 100", [':id'=>(int)($o['user_id'] ?? 0)]);
        $favorites = [];
        if (tableExists('favorite') && tableExists('items') && (int)($o['user_id'] ?? 0) > 0) {
            $favorites = entityRows("SELECT f.favorite_id AS id, f.favorite_itemsid AS item_id, i.items_name_ar AS name_ar, i.items_name_en AS name_en, i.items_price AS price, i.items_image AS image FROM favorite f INNER JOIN items i ON i.items_id=f.favorite_itemsid WHERE f.favorite_usersid=:id ORDER BY f.favorite_id DESC LIMIT 100", [':id'=>(int)$o['user_id']]);
            foreach ($favorites as &$favorite) { $favorite['image_url'] = entityMedia($favorite['image'] ?? '', 'uploud/items'); } unset($favorite);
        }
        respondJson(['status'=>'success','data'=>['entity'=>$c,'customer'=>$c,'current_order'=>$o,'orders'=>$customerOrders ?: [$o],'favorites'=>$favorites]]);
    }
    respondJson(['status'=>'error','message'=>'Unsupported entity type'],400);
} catch(Throwable $e) { respondJson(['status'=>'error','message'=>$e->getMessage()],500); }
