<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
include "connect.php";

header("Content-Type: text/html; charset=UTF-8");

function track_h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

function track_resolve_url(?string $url): string
{
    $value = trim((string)$url);
    if ($value === '') {
        return '';
    }

    if (preg_match('#^https?://#i', $value)) {
        return $value;
    }

    $value = str_replace('\\', '/', $value);
    $value = ltrim($value, '/');

    if (strpos($value, 'zahra/') === 0) {
        return 'https://savir-technology.online/roaqv2/' . substr($value, strlen('zahra/'));
    }

    return 'https://savir-technology.online/roaqv2/' . $value;
}

function track_normalize_status(string $status): string
{
    $status = strtolower(trim($status));
    switch ($status) {
        case 'assigned':
        case 'accepted':
        case 'confirmed':
            return 'assigned';
        case 'preparing':
        case 'packing':
        case 'packed':
            return 'preparing';
        case 'on the way':
        case 'ontheway':
        case 'delivering':
        case 'out_for_delivery':
            return 'on_the_way';
        case 'arrived at customer':
        case 'arrived':
        case 'near_customer':
            return 'arrived';
        case 'delivered':
        case 'complete':
        case 'completed':
            return 'delivered';
        case 'cancelled':
        case 'canceled':
        case 'rejected':
        case 'failed':
            return 'failed';
        default:
            return 'pending';
    }
}

function track_status_label(string $status): string
{
    switch (track_normalize_status($status)) {
        case 'assigned':
            return 'تم تعيين السائق';
        case 'preparing':
            return 'جاري التحضير';
        case 'on_the_way':
            return 'في الطريق';
        case 'arrived':
            return 'وصل إلى العنوان';
        case 'delivered':
            return 'تم التوصيل';
        case 'failed':
            return 'تم رفض الطلب';
        default:
            return 'قيد الانتظار';
    }
}

function track_status_color(string $status): string
{
    switch (track_normalize_status($status)) {
        case 'assigned':
        case 'preparing':
            return '#1B6B45';
        case 'on_the_way':
            return '#2F7AE5';
        case 'arrived':
            return '#C47A12';
        case 'delivered':
            return '#117A45';
        case 'failed':
            return '#B42318';
        default:
            return '#6B7280';
    }
}

function track_status_bg(string $status): string
{
    switch (track_normalize_status($status)) {
        case 'assigned':
        case 'preparing':
            return '#EAF6EE';
        case 'on_the_way':
            return '#EAF2FF';
        case 'arrived':
            return '#FFF4E5';
        case 'delivered':
            return '#E9F9EF';
        case 'failed':
            return '#FDECEC';
        default:
            return '#F3F4F6';
    }
}

$token = trim((string)($_GET['token'] ?? ''));
if ($token === '') {
    http_response_code(400);
    echo '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>رابط التتبع</title><style>body{margin:0;font-family:Arial,sans-serif;background:#f5f7f6;display:flex;align-items:center;justify-content:center;min-height:100vh}.card{background:#fff;border-radius:24px;box-shadow:0 16px 50px rgba(15,23,42,.08);padding:28px;max-width:520px;width:calc(100% - 32px);text-align:center}h1{margin:0 0 12px;font-size:28px}p{margin:0;color:#667085;line-height:1.8}</style></head><body><div class="card"><h1>رابط التتبع غير صحيح</h1><p>افتح الرابط مرة أخرى من داخل التطبيق أو اطلب من صاحب الطلب مشاركة الرابط الصحيح.</p></div></body></html>';
    exit;
}

$stmt = $con->prepare("
    SELECT
        o.orders_id,
        o.orders_status,
        o.orders_datetime,
        o.orders_totalprice,
        o.orders_share_token,
        o.orders_recipient_name,
        o.orders_recipient_address_name,
        o.orders_recipient_address_line,
        o.orders_recipient_location_note,
        o.orders_recipient_phone,
        o.orders_estimated_minutes,
        o.orders_delivery_note,
        v.vendor_name,
        v.store_name,
        v.vendor_logo,
        v.vendor_description,
        vss.store_banner_url,
        COALESCE(vss.store_address, v.vendor_description, '') AS store_address
    FROM orders o
    LEFT JOIN vendor_orders vo ON vo.order_id = o.orders_id
    LEFT JOIN (
        SELECT order_id, MIN(vendor_id) AS vendor_id
        FROM order_items
        GROUP BY order_id
    ) oi_vendor ON oi_vendor.order_id = o.orders_id
    LEFT JOIN vendors v ON v.vendor_id = COALESCE(vo.vendor_id, oi_vendor.vendor_id)
    LEFT JOIN vendor_store_settings vss ON vss.vendor_id = v.vendor_id
    WHERE o.orders_share_token = :token
    LIMIT 1
");
$stmt->execute([':token' => $token]);
$order = $stmt->fetch(PDO::FETCH_ASSOC);


if (!$order) {
    http_response_code(404);
    echo '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>الطلب غير موجود</title><style>body{margin:0;font-family:Arial,sans-serif;background:#f5f7f6;display:flex;align-items:center;justify-content:center;min-height:100vh}.card{background:#fff;border-radius:24px;box-shadow:0 16px 50px rgba(15,23,42,.08);padding:28px;max-width:520px;width:calc(100% - 32px);text-align:center}h1{margin:0 0 12px;font-size:28px}p{margin:0;color:#667085;line-height:1.8}</style></head><body><div class="card"><h1>الطلب غير موجود</h1><p>قد يكون الرابط منتهيًا أو غير صحيح. تأكد من رقم التتبع ثم حاول مرة أخرى.</p></div></body></html>';
    exit;
}

$orderId = (int)($order['orders_id'] ?? 0);
$storeName = trim((string)($order['store_name'] ?? $order['vendor_name'] ?? ''));
$recipientName = trim((string)($order['orders_recipient_name'] ?? ''));
$addressParts = array_filter([
    trim((string)($order['orders_recipient_address_name'] ?? '')),
    trim((string)($order['orders_recipient_address_line'] ?? '')),
    trim((string)($order['orders_recipient_location_note'] ?? '')),
]);
$recipientAddress = implode(' • ', $addressParts);
$storeBannerUrl = track_resolve_url($order['store_banner_url'] ?? '');
$storeLogoUrl = track_resolve_url($order['vendor_logo'] ?? '');
$heroBackgroundCss = $storeBannerUrl !== ''
    ? "url('" . str_replace("'", "\\'", $storeBannerUrl) . "') center/cover no-repeat"
    : "linear-gradient(135deg, #d7eadf, #eef5ef)";
$driverAvatarPlaceholder = 'data:image/svg+xml;utf8,' . rawurlencode('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="24" fill="#eef3ef"/><path d="M50 19a18 18 0 100 36 18 18 0 000-36zm0 43c-18 0-33 10-33 22v7h66v-7c0-12-15-22-33-22z" fill="#1B6B45"/></svg>');
$initialStatus = trim((string)($order['orders_status'] ?? 'pending'));
$initialStatusLabel = track_status_label($initialStatus);
$initialStatusColor = track_status_color($initialStatus);
$initialStatusBg = track_status_bg($initialStatus);
$estimatedMinutes = (int)($order['orders_estimated_minutes'] ?? 0);
$estimatedMinutes = $estimatedMinutes > 0 ? $estimatedMinutes : 45;
$totalPrice = trim((string)($order['orders_totalprice'] ?? ''));
$deliveryNote = trim((string)($order['orders_delivery_note'] ?? ''));
$firebaseBase = 'https://savirv604-default-rtdb.firebaseio.com';
$pageTitle = $storeName !== '' ? $storeName . ' - تتبع الطلب' : 'تتبع الطلب';
?>
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
  <meta name="theme-color" content="#1B6B45">
  <title><?php echo track_h($pageTitle); ?></title>
  <style>
    :root{
      --green:#1B6B45;
      --green-2:#2F8A58;
      --bg:#f3f6f4;
      --text:#151a16;
      --muted:#6b7280;
      --card:#ffffff;
      --border:#e4ebe6;
      --shadow:0 18px 50px rgba(10, 38, 24, .08);
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      font-family:system-ui,-apple-system,"Segoe UI",Tahoma,Arial,sans-serif;
      background:
        radial-gradient(circle at top right, rgba(27,107,69,.08), transparent 28%),
        radial-gradient(circle at top left, rgba(47,138,88,.08), transparent 26%),
        var(--bg);
      color:var(--text);
    }
    .shell{
      max-width:960px;
      margin:0 auto;
      padding:16px 16px 28px;
    }
    .hero{
      position:relative;
      min-height:240px;
      border-radius:28px;
      overflow:hidden;
      background:
        linear-gradient(180deg, rgba(17,24,39,.1), rgba(17,24,39,.65)),
        <?php echo $heroBackgroundCss; ?>;
      box-shadow:var(--shadow);
    }
    .hero::after{
      content:"";
      position:absolute;
      inset:0;
      background:linear-gradient(180deg, rgba(12,18,12,.05), rgba(12,18,12,.48));
      pointer-events:none;
    }
    .hero-body{
      position:relative;
      z-index:1;
      min-height:240px;
      display:flex;
      flex-direction:column;
      justify-content:space-between;
      padding:18px;
      color:#fff;
    }
    .top-row{
      display:flex;
      align-items:flex-start;
      justify-content:space-between;
      gap:12px;
      direction:ltr;
    }
    .status-pill{
      display:inline-flex;
      align-items:center;
      gap:8px;
      padding:10px 14px;
      border-radius:999px;
      font-weight:800;
      font-size:14px;
      color:<?php echo track_h($initialStatusColor); ?>;
      background:rgba(255,255,255,.92);
      backdrop-filter:blur(8px);
      box-shadow:0 10px 30px rgba(0,0,0,.12);
      max-width:100%;
    }
    .status-dot{
      width:10px;
      height:10px;
      border-radius:50%;
      background:currentColor;
      box-shadow:0 0 0 5px rgba(255,255,255,.2);
      flex:0 0 auto;
    }
    .order-chip{
      padding:10px 14px;
      border-radius:999px;
      background:rgba(15,23,42,.4);
      color:#fff;
      font-weight:700;
      font-size:13px;
      letter-spacing:.3px;
      backdrop-filter:blur(8px);
      white-space:nowrap;
    }
    .store-row{
      display:flex;
      align-items:center;
      gap:14px;
      margin-top:auto;
      direction:rtl;
    }
    .store-logo{
      width:68px;
      height:68px;
      border-radius:18px;
      background:#fff;
      object-fit:cover;
      flex:0 0 auto;
      border:3px solid rgba(255,255,255,.9);
      box-shadow:0 14px 32px rgba(0,0,0,.18);
    }
    .store-copy{
      min-width:0;
      flex:1;
    }
    .store-copy h1{
      margin:0;
      font-size:28px;
      line-height:1.15;
      font-weight:900;
      text-shadow:0 2px 12px rgba(0,0,0,.35);
    }
    .store-copy p{
      margin:6px 0 0;
      color:rgba(255,255,255,.9);
      font-size:14px;
      line-height:1.6;
      text-shadow:0 2px 12px rgba(0,0,0,.25);
    }
    .grid{
      display:grid;
      grid-template-columns:repeat(12, 1fr);
      gap:16px;
      margin-top:16px;
    }
    .card{
      background:var(--card);
      border:1px solid var(--border);
      border-radius:24px;
      box-shadow:var(--shadow);
      padding:18px;
    }
    .main-card{grid-column:span 8}
    .side-card{grid-column:span 4}
    .section-title{
      margin:0 0 12px;
      font-size:18px;
      font-weight:900;
      color:#1a211d;
    }
    .meta-grid{
      display:grid;
      grid-template-columns:repeat(2, minmax(0, 1fr));
      gap:12px;
    }
    .meta{
      background:#f8fbf8;
      border:1px solid #edf2ee;
      border-radius:18px;
      padding:14px;
      min-width:0;
    }
    .meta .label{
      color:var(--muted);
      font-size:12px;
      font-weight:700;
      margin-bottom:6px;
    }
    .meta .value{
      font-size:16px;
      font-weight:900;
      line-height:1.5;
      word-break:break-word;
    }
    .meta .value.small{
      font-size:14px;
      font-weight:700;
      color:#28302b;
    }
    .live-banner{
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap:12px;
      padding:14px 16px;
      border-radius:20px;
      background:<?php echo track_h($initialStatusBg); ?>;
      border:1px solid rgba(27,107,69,.12);
      margin-top:16px;
    }
    .live-banner strong{
      display:block;
      font-size:18px;
      color:<?php echo track_h($initialStatusColor); ?>;
      margin-bottom:4px;
    }
    .live-banner span{
      color:#4b5563;
      font-size:14px;
      line-height:1.5;
    }
    .live-pill{
      padding:10px 14px;
      border-radius:999px;
      background:#fff;
      border:1px solid rgba(27,107,69,.14);
      color:<?php echo track_h($initialStatusColor); ?>;
      font-size:13px;
      font-weight:800;
      white-space:nowrap;
      box-shadow:0 10px 20px rgba(27,107,69,.05);
    }
    .driver-card{
      display:flex;
      flex-direction:column;
      gap:12px;
    }
    .driver-top{
      display:flex;
      align-items:center;
      gap:14px;
      min-width:0;
    }
    .driver-avatar{
      width:76px;
      height:76px;
      border-radius:22px;
      object-fit:cover;
      background:#eef3ef;
      border:1px solid #dfe8e2;
      flex:0 0 auto;
    }
    .driver-copy{
      min-width:0;
      flex:1;
    }
    .driver-copy h2{
      margin:0;
      font-size:22px;
      line-height:1.2;
      font-weight:900;
    }
    .driver-copy p{
      margin:6px 0 0;
      color:#667085;
      line-height:1.6;
      font-size:14px;
    }
    .driver-stats{
      display:grid;
      grid-template-columns:repeat(2, minmax(0, 1fr));
      gap:12px;
    }
    .stat{
      background:#f8fbf8;
      border:1px solid #edf2ee;
      border-radius:18px;
      padding:14px;
    }
    .stat .label{
      color:var(--muted);
      font-size:12px;
      font-weight:700;
      margin-bottom:6px;
    }
    .stat .value{
      font-size:16px;
      font-weight:900;
    }
    .footer-note{
      margin-top:16px;
      color:#667085;
      font-size:13px;
      text-align:center;
      line-height:1.7;
    }
    .loading{
      display:inline-flex;
      align-items:center;
      gap:8px;
    }
    .spinner{
      width:14px;
      height:14px;
      border-radius:50%;
      border:2px solid rgba(255,255,255,.35);
      border-top-color:#fff;
      animation:spin 1s linear infinite;
    }
    @keyframes spin { to { transform:rotate(360deg); } }
    @media (max-width: 860px){
      .main-card,.side-card{grid-column:span 12}
    }
    @media (max-width: 640px){
      .shell{padding:12px 12px 20px}
      .hero{min-height:220px;border-radius:24px}
      .hero-body{min-height:220px;padding:16px}
      .store-copy h1{font-size:22px}
      .meta-grid,.driver-stats{grid-template-columns:1fr}
      .grid{gap:12px}
      .card{padding:16px;border-radius:22px}
      .status-pill,.order-chip{font-size:12px}
    }
  </style>
</head>
<body>
  <div class="shell">
    <div class="hero">
      <div class="hero-body">
        <div class="top-row">
          <div class="status-pill" id="status-pill" style="color:<?php echo track_h($initialStatusColor); ?>;">
            <span class="status-dot"></span>
            <span id="status-label"><?php echo track_h($initialStatusLabel); ?></span>
          </div>
          <div class="order-chip">#<?php echo track_h((string)$orderId); ?></div>
        </div>

        <div class="store-row">
          <?php if ($storeLogoUrl !== ''): ?>
            <img class="store-logo" src="<?php echo track_h($storeLogoUrl); ?>" alt="<?php echo track_h($storeName); ?>">
          <?php else: ?>
            <div class="store-logo" style="display:flex;align-items:center;justify-content:center;color:#1B6B45;font-weight:900;">AE</div>
          <?php endif; ?>
          <div class="store-copy">
            <h1><?php echo track_h($storeName !== '' ? $storeName : 'تتبع الطلب'); ?></h1>
            <p id="status-copy">جارٍ تحميل الحالة المباشرة الآن...</p>
          </div>
        </div>
      </div>
    </div>

    <div class="grid">
      <div class="card main-card">
        <h3 class="section-title">تفاصيل الطلب</h3>
        <div class="meta-grid">
          <div class="meta">
            <div class="label">رقم الطلب</div>
            <div class="value">#<?php echo track_h((string)$orderId); ?></div>
          </div>
          <div class="meta">
            <div class="label">الوقت المتوقع</div>
            <div class="value" id="eta-value"><?php echo track_h((string)$estimatedMinutes); ?> دقيقة</div>
          </div>
          <div class="meta">
            <div class="label">اسم العميل</div>
            <div class="value small"><?php echo track_h($recipientName !== '' ? $recipientName : '—'); ?></div>
          </div>
          <div class="meta">
            <div class="label">العنوان</div>
            <div class="value small"><?php echo track_h($recipientAddress !== '' ? $recipientAddress : '—'); ?></div>
          </div>
        </div>

        <div class="live-banner">
          <div>
            <strong id="live-status"><?php echo track_h($initialStatusLabel); ?></strong>
            <span id="live-subtitle">سيتم تحديث هذه الصفحة تلقائيًا كل بضع ثوانٍ.</span>
          </div>
          <div class="live-pill" id="live-pill">مباشر</div>
        </div>

        <?php if ($deliveryNote !== ''): ?>
          <div class="meta" style="margin-top:12px;">
            <div class="label">ملاحظة التوصيل</div>
            <div class="value small"><?php echo track_h($deliveryNote); ?></div>
          </div>
        <?php endif; ?>
      </div>

      <div class="card side-card">
        <h3 class="section-title">ملخص مباشر</h3>
        <div class="driver-card">
          <div class="driver-top">
            <img class="driver-avatar" id="driver-avatar" src="<?php echo track_h($driverAvatarPlaceholder); ?>" alt="driver">
            <div class="driver-copy">
              <h2 id="driver-name">في انتظار تعيين السائق</h2>
              <p id="driver-meta">معلومات السائق ستظهر هنا بمجرد بدء التتبع المباشر.</p>
            </div>
          </div>
          <div class="driver-stats">
            <div class="stat">
              <div class="label">المسافة الحالية</div>
              <div class="value" id="distance-value">-</div>
            </div>
            <div class="stat">
              <div class="label">آخر تحديث</div>
              <div class="value" id="updated-value">-</div>
            </div>
            <div class="stat">
              <div class="label">المطعم</div>
              <div class="value" id="store-value"><?php echo track_h($storeName !== '' ? $storeName : '—'); ?></div>
            </div>
            <div class="stat">
              <div class="label">إجمالي الطلب</div>
              <div class="value" id="total-value"><?php echo track_h($totalPrice !== '' ? $totalPrice : '—'); ?></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="footer-note">
      في حال لم تظهر التحديثات فورًا، انتظر بضع ثوانٍ أو أعد فتح الرابط مرة أخرى.<br>
      هذا الرابط مخصص لمشاركة حالة الطلب المباشرة مع العميل أو أي شخص تريده.
    </div>
  </div>

  <script>
    const ORDER_ID = <?= json_encode($orderId) ?>;
    const FIREBASE_BASE = <?= json_encode($firebaseBase) ?>;
    const INITIAL_STATUS = <?= json_encode($initialStatus) ?>;
    const INITIAL_STATUS_LABEL = <?= json_encode($initialStatusLabel) ?>;

    const statusLabel = document.getElementById('status-label');
    const statusCopy = document.getElementById('status-copy');
    const liveStatus = document.getElementById('live-status');
    const liveSubtitle = document.getElementById('live-subtitle');
    const etaValue = document.getElementById('eta-value');
    const distanceValue = document.getElementById('distance-value');
    const updatedValue = document.getElementById('updated-value');
    const driverName = document.getElementById('driver-name');
    const driverMeta = document.getElementById('driver-meta');
    const driverAvatar = document.getElementById('driver-avatar');
    const livePill = document.getElementById('live-pill');
    const statusPill = document.getElementById('status-pill');

    function normalizeStatus(value) {
      const status = String(value || '').toLowerCase().trim();
      switch (status) {
        case 'assigned':
        case 'accepted':
        case 'confirmed':
          return 'assigned';
        case 'preparing':
        case 'packing':
        case 'packed':
          return 'preparing';
        case 'on the way':
        case 'ontheway':
        case 'delivering':
        case 'out_for_delivery':
          return 'on_the_way';
        case 'arrived at customer':
        case 'arrived':
        case 'near_customer':
          return 'arrived';
        case 'delivered':
        case 'complete':
        case 'completed':
          return 'delivered';
        case 'cancelled':
        case 'canceled':
        case 'rejected':
        case 'failed':
          return 'failed';
        default:
          return 'pending';
      }
    }

    function statusLabelAr(value) {
      switch (normalizeStatus(value)) {
        case 'assigned':
          return 'تم تعيين السائق';
        case 'preparing':
          return 'جاري التحضير';
        case 'on_the_way':
          return 'في الطريق';
        case 'arrived':
          return 'وصل إلى العنوان';
        case 'delivered':
          return 'تم التوصيل';
        case 'failed':
          return 'تم رفض الطلب';
        default:
          return 'قيد الانتظار';
      }
    }

    function statusColor(value) {
      switch (normalizeStatus(value)) {
        case 'assigned':
        case 'preparing':
          return '#1B6B45';
        case 'on_the_way':
          return '#2F7AE5';
        case 'arrived':
          return '#C47A12';
        case 'delivered':
          return '#117A45';
        case 'failed':
          return '#B42318';
        default:
          return '#6B7280';
      }
    }

    function formatDistance(data) {
      const raw = Number(data?.route_distance_km ?? data?.distance_km);
      if (!Number.isFinite(raw) || raw <= 0) {
        return 'غير متوفر';
      }
      return `${raw.toFixed(raw < 10 ? 1 : 0)} كم`;
    }

    function formatEta(data) {
      const eta = Number(data?.eta_minutes);
      if (!Number.isFinite(eta) || eta <= 0) {
        return 'غير متوفر';
      }
      return `${Math.round(eta)} دقيقة`;
    }

    function formatUpdated(data) {
      const raw = data?.last_updated;
      if (!raw) {
        return 'الآن';
      }
      try {
        const dt = new Date(raw);
        if (Number.isNaN(dt.getTime())) {
          return 'الآن';
        }
        return dt.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });
      } catch (_) {
        return 'الآن';
      }
    }

    function driverTitle(data) {
      const name = String(data?.driver?.name || '').trim();
      if (name) {
        return name;
      }
      const id = String(data?.driver?.id || '').trim();
      return id ? `السائق #${id}` : 'في انتظار تعيين السائق';
    }

    function driverText(data) {
      const vehicle = String(data?.driver?.vehicle || '').trim();
      const phone = String(data?.driver?.phone || '').trim();
      const parts = [];
      if (vehicle) parts.push(vehicle);
      if (phone) parts.push(phone);
      if (!parts.length) {
        return 'معلومات السائق ستظهر هنا بمجرد بدء التتبع المباشر.';
      }
      return parts.join(' • ');
    }

    function driverAvatarUrl(data) {
      const photo = String(data?.driver?.photo_url || '').trim();
      if (photo) {
        return photo;
      }
      return driverAvatar.src;
    }

    function applyLiveData(data) {
      const status = statusLabelAr(data?.status || INITIAL_STATUS);
      const color = statusColor(data?.status || INITIAL_STATUS);
      statusLabel.textContent = status;
      liveStatus.textContent = status;
      liveSubtitle.textContent = 'يتم تحديث هذه الصفحة تلقائيًا من حالة الطلب المباشرة.';
      statusCopy.textContent = status + ' - ' + (data?.driver?.name ? `السائق: ${data.driver.name}` : 'جاري متابعة التحديثات الآن');
      etaValue.textContent = formatEta(data);
      distanceValue.textContent = formatDistance(data);
      updatedValue.textContent = formatUpdated(data);
      driverName.textContent = driverTitle(data);
      driverMeta.textContent = driverText(data);
      driverAvatar.src = driverAvatarUrl(data);
      livePill.textContent = 'مباشر';
      statusPill.style.color = color;
      statusPill.style.background = 'rgba(255,255,255,.92)';
      statusLabel.style.color = color;
      liveStatus.style.color = color;
    }

    async function loadTracking() {
      if (!ORDER_ID) {
        return;
      }

      try {
        const response = await fetch(`${FIREBASE_BASE}/order_tracking/${ORDER_ID}.json?ts=${Date.now()}`, {
          cache: 'no-store',
        });
        if (!response.ok) {
          throw new Error('HTTP ' + response.status);
        }
        const data = await response.json();
        if (data) {
          applyLiveData(data);
        } else {
          applyLiveData({ status: INITIAL_STATUS });
        }
      } catch (error) {
        applyLiveData({ status: INITIAL_STATUS });
      }
    }

    loadTracking();
    setInterval(loadTracking, 10000);
  </script>
</body>
</html>
