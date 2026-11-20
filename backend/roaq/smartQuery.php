<?php
header("Content-Type: application/json; charset=UTF-8");

require_once "connect.php";
require_once "ai_formatter.php";

// قراءة الطلب
$raw = file_get_contents('php://input');
$body = $_POST;

if (empty($body) && $raw) {
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) $body = $decoded;
}

if (empty($body) && !empty($_GET['question'])) {
    $body['question'] = $_GET['question'];
    if (!empty($_GET['userid'])) $body['userid'] = $_GET['userid'];
}

$question_raw = $_REQUEST['question'] ?? '';
$question = trim(mb_convert_encoding($question_raw, 'UTF-8', 'auto'));
$userid = isset($_REQUEST['userid']) ? (int)$_REQUEST['userid'] : 0;

if (!$question) {
    echo json_encode(["error" => "Empty question"]);
    exit;
}

// ================= دوال تحسين النص العربي =================
function normalizeArabic($str) {
    $search = ["أ","إ","آ","ا","ة","ه","ى","ي","ئ","ؤ","ٌ","ً","ٍ","ْ","ّ","ِ","ُ","َ"];
    $replace = ["ا","ا","ا","ا","ه","ه","ي","ي","ي","و","","","","","","",""];
    $str = str_replace($search, $replace, $str);
    $str = preg_replace('/\s+/', ' ', trim($str));
    return mb_strtolower($str);
}

function expandSynonyms($str) {
    $synonyms = [$str];
    $t = mb_strtolower($str);

    if (preg_match("/اكس|xbox/i", $t)) {
        $synonyms = array_merge($synonyms, ["اكس بوكس","إكس بوكس","x box","xbox series s","اكس بوكس s","اكس بوكس اس"]);
    }
    return array_unique($synonyms);
}

// ================= دوال قاعدة البيانات =================
function searchItems($con, $text, $limit = 10) {
    if (!$text) return [];

    $norm = normalizeArabic($text);
    $keywords = expandSynonyms($norm);

    $conditions = [];
    $params = [];

    foreach ($keywords as $k) {
        $q = "%$k%";
        // البحث في الاسم والوصف الأصلي + النسخ المطبوعة مؤقتًا
        $conditions[] = "(LOWER(items_name_ar) LIKE ? OR LOWER(items_desc_ar) LIKE ?)";
        $params[] = $q;
        $params[] = $q;
    }

    $sql = "
        SELECT items_id, items_name_ar, items_name_en, items_price, items_desc_ar, items_image, items_count, items_discount
        FROM items
        WHERE " . implode(" OR ", $conditions) . "
        ORDER BY items_id DESC
        LIMIT $limit
    ";

    $stmt = $con->prepare($sql);
    $i = 1;
    foreach ($params as $p) $stmt->bindValue($i++, $p, PDO::PARAM_STR);
    $stmt->execute();

    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function getProductById($con, $id) {
    $stmt = $con->prepare("SELECT * FROM items WHERE items_id=? LIMIT 1");
    $stmt->execute([(int)$id]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function recentOrder($con, $userid) {
    $stmt = $con->prepare("SELECT orders_id, orders_totalprice, orders_status, orders_datetime, orders_pricedelivery
                           FROM orders WHERE orders_usersid=? ORDER BY orders_id DESC LIMIT 1");
    $stmt->execute([$userid]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function similarItems($con, $item) {
    if (!$item) return [];
    $firstWord = explode(" ", $item['items_name_ar'])[0];
    $pattern = "%$firstWord%";
    $stmt = $con->prepare("SELECT items_id, items_name_ar, items_price, items_image
                           FROM items
                           WHERE items_id!=? AND (items_name_ar LIKE ? OR items_desc_ar LIKE ?)
                           LIMIT 4");
    $stmt->execute([$item['items_id'], $pattern, $pattern]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// ================= تحليل النية =================
$intent="unknown";

if(preg_match("/(طلب|حالة طلب|orders|order|status)/iu",$question)) $intent="order_status";
if(preg_match("/(منتج|ابحث|اعرض|عاوز|عايز|أريد|دور|ابحث عن|search|find)/iu",$question)) $intent="search_product";
if(preg_match("/(تفاصيل|product id|id|رقم)/iu",$question)) $intent="product_details";

// ================= تنفيذ النية =================
$data_for_ai = [];

if($intent==="order_status") {
    $order = $userid ? recentOrder($con,$userid) : null;
    $data_for_ai=["type"=>"order","order"=>$order];
} elseif($intent==="product_details") {
    if(preg_match('/\b(\d{1,6})\b/',$question,$m)){
        $prod=getProductById($con,(int)$m[1]);
        $data_for_ai=["type"=>"product","product"=>$prod,"similar"=>similarItems($con,$prod)];
    } else {
        $items = searchItems($con,$question,6);
        $data_for_ai=["type"=>"items","items"=>$items];
    }
} else {
    $items=searchItems($con,$question,12);
    if(count($items)>0) $data_for_ai=["type"=>"items","items"=>$items];
    else $data_for_ai=["type"=>"small_talk","text"=>"لم تُرجع قاعدة البيانات أي نتائج."];
}

// ================= تجهيز الرسالة للذكاء =================
$prompt="سؤال المستخدم: \"$question\"\n\n";
$prompt.="البيانات من قاعدة البيانات:\n".json_encode($data_for_ai, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT);
$prompt.="\n\nاكتب للمستخدم رد مختصر وواضح بالعربية، مع تلخيص النتائج، ";
$prompt.="واستخدم دائمًا **الريال السعودي (SAR)** كوحدة العملة. ";
$prompt.="وإن وجد منتجات مشابهة قم بذكرها بشكل لطيف.";

// ================= استدعاء AI =================
$ai_resp=call_openai($prompt);

// ================= خروج النتيجة =================
$response=[
    "question"=>$question,
    "keyword"=>normalizeArabic($question),
    "intent"=>$intent,
    "data"=>$data_for_ai,
    "ai"=>$ai_resp
];

echo json_encode($response, JSON_UNESCAPED_UNICODE);
