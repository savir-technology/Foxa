<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
require_once __DIR__ . '/vendor/autoload.php';
define("MB", 1048576);
function filterRequest($field) {
    return isset($_POST[$field]) ? filter_var($_POST[$field], FILTER_SANITIZE_STRING) : (isset($_GET[$field]) ? filter_var($_GET[$field], FILTER_SANITIZE_STRING) : null);
}
function getAllData($table, $where = null, $values = null, $json = true)
{
    global $con;
    $data = array();
    if ($where == null) {
        $stmt = $con->prepare("SELECT  * FROM $table   ");
    } else {
        $stmt = $con->prepare("SELECT  * FROM $table WHERE   $where ");
    }
    $stmt->execute($values);
    $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $count  = $stmt->rowCount();
    if ($json == true) {
        if ($count > 0) {
            echo json_encode(array("status" => "success", "data" => $data));
        } else {
            echo json_encode(array("status" => "failure"));
        }
        return $count;
    } else {
        if ($count > 0) {
            return  array("status" => "success", "data" => $data);
        } else {
            return  array("status" => "failure");
        }
    }
}
function getData($table, $where = null, $values = null, $json = true)   
{
    global $con;
    $data = array();
    $stmt = $con->prepare("SELECT  * FROM $table WHERE   $where ");
    $stmt->execute($values);
    $data = $stmt->fetch(PDO::FETCH_ASSOC);
    $count  = $stmt->rowCount();
    if ($json == true) {
        if ($count > 0) {
            echo json_encode(array("status" => "success", "data" => $data));
        } else {
            echo json_encode(array("status" => "failure"));
        }
    } else {
        return $count;
    }
}
function insertData($table, $data, $json = true)
{
    global $con;
    foreach ($data as $field => $v)
        $ins[] = ':' . $field;
    $ins = implode(',', $ins);
    $fields = implode(',', array_keys($data));
    $sql = "INSERT INTO $table ($fields) VALUES ($ins)";
    $stmt = $con->prepare($sql);
    foreach ($data as $f => $v) {
        $stmt->bindValue(':' . $f, $v);
    }
    $stmt->execute();
    $count = $stmt->rowCount();
    if ($json == true) {
        if ($count > 0) {
            echo json_encode(array("status" => "success"));
        } else {
            echo json_encode(array("status" => "failure"));
        }
    }
    return $count;
}
function updateData($table, $data, $where, $json = true)
{
    global $con;
    $cols = array();
    $vals = array();
    foreach ($data as $key => $val) {
        $vals[] = "$val";
        $cols[] = "`$key` =  ? ";
    }
    $sql = "UPDATE $table SET " . implode(', ', $cols) . " WHERE $where";
    $stmt = $con->prepare($sql);
    $stmt->execute($vals);
    $count = $stmt->rowCount();
    if ($json == true) {
        if ($count > 0) {
            echo json_encode(array("status" => "success"));
        } else {
            echo json_encode(array("status" => "failure"));
        }
    }
    return $count;
}
function deleteData($table, $where, $json = true)
{
    global $con;
    try {
        $stmt = $con->prepare("DELETE FROM $table WHERE $where");
        $stmt->execute();
        $count = $stmt->rowCount();
        if ($json == true) {
            if ($count > 0) {
                echo json_encode(array("status" => "success"));
            } else {
                echo json_encode(array("status" => "failure"));
            }
        }
        return $count;
    } catch (PDOException $e) {
        // لو الخطأ ناتج عن قيود العلاقة
        if ($e->getCode() == "23000") {
            if ($json == true) {
                echo json_encode(array(
                    "status" => "error",
                    "message" => "لا يمكن حذف هذا المنتج لأنه مرتبط بطلبات موجودة."
                ));
            }
        } else {
            if ($json == true) {
                echo json_encode(array(
                    "status" => "error",
                    "message" => $e->getMessage()
                ));
            }
        }
    }
}
function distance($lat1, $lon1, $lat2, $lon2) {
    $earth_radius = 6371;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat/2) * sin($dLat/2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon/2) * sin($dLon/2);
    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
    return $earth_radius * $c;
}
function deliveryNormalizeCoordinate($value): ?float
{
    if ($value === null) {
        return null;
    }
    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null' || !is_numeric($text)) {
        return null;
    }
    $number = (float)$text;
    if (!is_finite($number) || $number == 0.0) {
        return null;
    }
    return $number;
}
function deliveryCoordinatePairFromText($value): ?array
{
    if ($value === null) {
        return null;
    }
    $text = trim((string)$value);
    if ($text === '' || strtolower($text) === 'null') {
        return null;
    }
    if (!preg_match('/(-?\d+(?:\.\d+)?)\s*[,;|\s]+\s*(-?\d+(?:\.\d+)?)/', $text, $matches)) {
        return null;
    }
    $latitude = (float)$matches[1];
    $longitude = (float)$matches[2];
    if (!is_finite($latitude) || !is_finite($longitude) || ($latitude == 0.0 && $longitude == 0.0)) {
        return null;
    }
    return [
        'lat' => $latitude,
        'lng' => $longitude,
    ];
}
function deliveryResolveCoordinatePair($latitude, $longitude, $textFallback = null): array
{
    $resolved = [
        'lat' => deliveryNormalizeCoordinate($latitude),
        'lng' => deliveryNormalizeCoordinate($longitude),
    ];
    if ($resolved['lat'] === null || $resolved['lng'] === null) {
        $fallback = deliveryCoordinatePairFromText($textFallback);
        if (is_array($fallback)) {
            if ($resolved['lat'] === null) {
                $resolved['lat'] = $fallback['lat'];
            }
            if ($resolved['lng'] === null) {
                $resolved['lng'] = $fallback['lng'];
            }
        }
    }
    return $resolved;
}
function imageUpload($dir, $imageRequest)
{
    global $msgError;
    if (isset($_FILES[$imageRequest])) {
        $imagename  = rand(1000, 10000) . $_FILES[$imageRequest]['name'];
        $imagetmp   = $_FILES[$imageRequest]['tmp_name'];
        $imagesize  = $_FILES[$imageRequest]['size'];
        $allowExt   = array("jpg", "png", "gif", "mp3", "pdf" , "svg");
        $strToArray = explode(".", $imagename);
        $ext        = end($strToArray);
        $ext        = strtolower($ext);
        if (!empty($imagename) && !in_array($ext, $allowExt)) {
            $msgError = "EXT";
        }
        if ($imagesize > 2 * MB) {
            $msgError = "size";
        }
        if (empty($msgError)) {
            move_uploaded_file($imagetmp,  $dir . "/" . $imagename);
            return $imagename;
        } else {
            return "fail";
        }
    }else {
        return 'empty' ; 
    }
}
function checkAuthenticate() {
    $authUser = "Islam";
    $authPass = "150102003";
    $ip       = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $userAgent  = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
    $time     = date("Y-m-d H:i:s");
    $baseDir  = __DIR__;
    $devicesFile = $baseDir . "/devices.json";
    $blockFile = $baseDir . "/blocked.txt";
    $logFile  = $baseDir . "/logs.txt";
    $maxAttempts = 3;
    $cookieName  = "savir_device";
    $cookieTTL   = 60 * 60 * 24 * 365; // سنة
    if (empty($_COOKIE[$cookieName])) {
        $deviceToken = bin2hex(random_bytes(16));
        setcookie($cookieName, $deviceToken, time() + $cookieTTL, "/", "", false, true);
        $_COOKIE[$cookieName] = $deviceToken;
    } else {
        $deviceToken = $_COOKIE[$cookieName];
    }
    $deviceKey = md5($ip . '||' . $userAgent . '||' . $deviceToken);
    $readJsonFile = function($path) {
        if (!file_exists($path)) return [];
        $fh = fopen($path, "r");
        if (!$fh) return [];
        flock($fh, LOCK_SH);
        $data = stream_get_contents($fh);
        flock($fh, LOCK_UN);
        fclose($fh);
        $arr = json_decode($data, true);
        return is_array($arr) ? $arr : [];
    };
    $writeJsonFile = function($path, $data) {
        $dir = dirname($path);
        if (!is_dir($dir)) @mkdir($dir, 0755, true);
        $fh = fopen($path, "c+");
        if (!$fh) return false;
        flock($fh, LOCK_EX);
        ftruncate($fh, 0);
        rewind($fh);
        fwrite($fh, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        fflush($fh);
        flock($fh, LOCK_UN);
        fclose($fh);
        return true;
    };
    // 4) لو الجهاز محظور بالفعل
    $blockedList = file_exists($blockFile) ? file($blockFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) : [];
    if (in_array($deviceKey, $blockedList)) {
        header('HTTP/1.0 403 Forbidden');
        echo "🚫 تم حظرك من الدخول.";
        exit;
    }
    // 5) تحسين قراءة Authentication headers و دعم API clients
    $inputUser = $_SERVER['PHP_AUTH_USER'] ?? null;
    $inputPass = $_SERVER['PHP_AUTH_PW'] ?? null;
    $authHeader = $_SERVER['HTTP_AUTHORIZATION']
                ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
                ?? (function_exists('apache_request_headers') ? (array_change_key_case(apache_request_headers(), CASE_LOWER)['authorization'] ?? null) : null);
    if ((!$inputUser || !$inputPass) && $authHeader && stripos($authHeader, 'basic ') === 0) {
        $cred = base64_decode(substr($authHeader, 6));
        list($u, $p) = explode(':', $cred, 2) + [null, null];
        if (!$inputUser) $inputUser = $u;
        if (!$inputPass) $inputPass = $p;
    }
    $accept = $_SERVER['HTTP_ACCEPT'] ?? '';
    $uri = $_SERVER['REQUEST_URI'] ?? '';
    $isApiRequest = stripos($accept, 'application/json') !== false || preg_match('#^/api/#i', $uri);
    // دعم OPTIONS (preflight)
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        masterSetCorsHeaders();
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Access-Control-Allow-Origin');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        http_response_code(200);
        exit;
    }
    // لو مفيش credentials -> رد مناسب (JSON للـ API، وWWW-Authenticate للصفحات)
    if (!$inputUser || !$inputPass) {
        http_response_code(401);
        if ($isApiRequest) {
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode(['error' => 'Authentication required']);
        } else {
            header('WWW-Authenticate: Basic realm="My Secure Zone"');
            header('Content-Type: text/plain; charset=utf-8');
            echo "Authentication required!";
        }
        exit;
    }
    // التحقق من صحة بيانات الاعتماد
    if ($inputUser !== $authUser || $inputPass !== $authPass) {
        $wrongUser = $inputUser ?? 'unknown';
        $log = "[$time] محاولة دخول فاشلة | يوزر: $wrongUser | DeviceKey: $deviceKey | IP: $ip | Browser: $userAgent\n";
        file_put_contents($logFile, $log, FILE_APPEND);
        $devices = $readJsonFile($devicesFile);
        if (!isset($devices[$deviceKey])) {
            $devices[$deviceKey] = [
                'ip' => $ip,
                'ua' => $userAgent,
                'token' => $deviceToken,
                'attempts' => 0,
                'first_attempt' => $time,
                'last_attempt' => $time
            ];
        }
        $devices[$deviceKey]['attempts'] += 1;
        $devices[$deviceKey]['last_attempt'] = $time;
        if ($devices[$deviceKey]['attempts'] >= $maxAttempts) {
            file_put_contents($blockFile, $deviceKey . PHP_EOL, FILE_APPEND | LOCK_EX);
            if (function_exists('sendMailWithAttachment') && file_exists($logFile)) {
                sendMailWithAttachment("support@savir-technology.com", "🚫 Device Blocked - $ip", "<h3>تم حظر جهاز بعد محاولات خاطئة.</h3>", $logFile);
            }
            unset($devices[$deviceKey]);
            $writeJsonFile($devicesFile, $devices);
            header('HTTP/1.0 403 Forbidden');
            echo "🚫 تم حظرك نهائيًا بسبب محاولات خاطئة متكررة.";
            exit;
        } else {
            $writeJsonFile($devicesFile, $devices);
            if (function_exists('sendMailWithAttachment') && file_exists($logFile)) {
                sendMailWithAttachment("support@savir-technology.com", "⚠️ Failed Login Attempt", "<h3>محاولة دخول فاشلة تم تسجيلها.</h3>", $logFile);
            }
            $remaining = $maxAttempts - $devices[$deviceKey]['attempts'];
            if ($isApiRequest) {
                http_response_code(401);
                header('Content-Type: application/json; charset=utf-8');
                echo json_encode(['error' => 'Unauthorized', 'remaining' => $remaining]);
            } else {
                header('WWW-Authenticate: Basic realm="My Secure Zone"');
                header('HTTP/1.0 401 Unauthorized');
                echo "Unauthorized access detected! محاولات متبقية لهذا الجهاز: $remaining";
            }
            exit;
        }
    }
    // نجاح
    $successUser = $inputUser;
    $log = "[$time] دخول ناجح | يوزر: $successUser | DeviceKey: $deviceKey | IP: $ip | Browser: $userAgent\n";
    file_put_contents($logFile, $log, FILE_APPEND);
    $devices = $readJsonFile($devicesFile);
    if (isset($devices[$deviceKey])) {
        unset($devices[$deviceKey]);
        $writeJsonFile($devicesFile, $devices);
    }
    if (function_exists('sendMailWithAttachment') && file_exists($logFile)) {
        sendMailWithAttachment(
            "support@savir-technology.com",
            "✅ Successful Login",
            "<h3>تم تسجيل دخول ناجح.</h3><p>يوزر: $successUser<br>IP: $ip<br>Browser: $userAgent</p>",
            $logFile
        );
    }
    return true;
}
function   printFailure($message = "none")
{
    echo     json_encode(array("status" => "failure", "message" => $message));
}
function   printSuccess($message = "none")
{
    echo     json_encode(array("status" => "success", "message" => $message));
}
function result($count)
{
    if ($count > 0) {
        printSuccess();
    } else {
        printFailure();
    }
}
function sendEmail($to, $subject, $code)
{
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com';
        $mail->SMTPAuth = true;
        $mail->Username = 'emtkatof@gmail.com';
        $mail->Password = 'ozvo omup hfsl kyxv';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;
        $mail->CharSet = 'UTF-8';
        $mail->setFrom('emtkatof@gmail.com', 'FOXA');
        $mail->addAddress($to);
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body = "
        <html>
        <head>
          <title>$subject</title>
        </head>
        <body style='font-family: Arial, sans-serif; background-color:#f9f9f9; margin:0; padding:0;'>
          <table width='100%' cellpadding='0' cellspacing='0'>
            <tr>
              <td align='center' style='padding: 40px 10px;'>
                <table width='600' cellpadding='0' cellspacing='0' style='background:#ffffff; border-radius:15px; overflow:hidden; box-shadow:0 6px 16px rgba(0,0,0,0.1);'>
                  <!-- Header -->
                  <tr>
                    <td align='center' style='background:linear-gradient(135deg, #2196F3, #F14216); padding:25px;'>
                      <h1 style='color:#ffffff; margin:0; font-size:24px;'>FOXA</h1>
                      <p style='color:#ffeaea; margin:5px 0 0; font-size:14px;'>Secure Verification</p>
                    </td>
                  </tr>
                  <!-- Content -->
                  <tr>
                    <td style='padding:40px; color:#333333; text-align:center;'>
                      <h2 style='margin-top:0; font-size:22px; color:#F14216;'>Your Verification Code</h2>
                      <p style='font-size:16px; color:#555;'>Use the following code to complete your verification:</p>
                      <div style='margin:30px 0;'>
                        <span style='display:inline-block; background:#f4f8ff; color:#2196F3; font-size:32px; letter-spacing:10px; padding:15px 30px; border-radius:10px; font-weight:bold; border:2px solid #F14216;'>
                          " . htmlspecialchars((string)$code, ENT_QUOTES, 'UTF-8') . "
                        </span>
                      </div>
                      <p style='font-size:14px; color:#999;'>This code will expire in 10 minutes.</p>
                    </td>
                  </tr>
                  <!-- Footer -->
                  <tr>
                    <td align='center' style='background:#f7f7f7; padding:15px; font-size:12px; color:#777;'>
                      &copy; ".date("Y")." FOXA. All Rights Reserved.
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        ";
        $mail->AltBody = "$code";
        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Email sending failed: " . $mail->ErrorInfo);
        return false;
    }
}
function sendEmailWithFallback($to, $subject, $code)
{
    // محاولة إرسال البريد عبر SMTP (Gmail)
    if (sendEmail($to, $subject, $code)) {
        error_log("Email sent successfully via SMTP to: $to");
        return true;
    }
    
    error_log("SMTP email failed, trying fallback to: $to");
    // محاولة إرسال البريد عبر PHP mail() كخيار بديل
    try {
        $mail = new PHPMailer(true);
        $mail->isMail();
        $mail->CharSet = 'UTF-8';
        $mail->setFrom('no-reply@aleppoeats.com', 'FOXA');
        $mail->addAddress($to);
        $mail->isHTML(true);
        $mail->Subject = $subject;
        
        // إنشاء محتوى البريد
        $body = "
        <html>
        <head>
          <title>$subject</title>
        </head>
        <body style='font-family: Arial, sans-serif; background-color:#f9f9f9; margin:0; padding:0;'>
          <table width='100%' cellpadding='0' cellspacing='0'>
            <tr>
              <td align='center' style='padding: 40px 10px;'>
                <table width='600' cellpadding='0' cellspacing='0' style='background:#ffffff; border-radius:15px; overflow:hidden; box-shadow:0 6px 16px rgba(0,0,0,0.1);'>
                  <!-- Header -->
                  <tr>
                    <td align='center' style='background:linear-gradient(135deg, #2196F3, #F14216); padding:25px;'>
                      <h1 style='color:#ffffff; margin:0; font-size:24px;'>FOXA</h1>
                      <p style='color:#ffeaea; margin:5px 0 0; font-size:14px;'>Secure Verification</p>
                    </td>
                  </tr>
                  <!-- Content -->
                  <tr>
                    <td style='padding:40px; color:#333333; text-align:center;'>
                      <h2 style='margin-top:0; font-size:22px; color:#F14216;'>Your Verification Code</h2>
                      <p style='font-size:16px; color:#555;'>Use the following code to complete your verification:</p>
                      <div style='margin:30px 0;'>
                        <span style='display:inline-block; background:#f4f8ff; color:#2196F3; font-size:32px; letter-spacing:10px; padding:15px 30px; border-radius:10px; font-weight:bold; border:2px solid #F14216;'>
                          " . htmlspecialchars((string)$code, ENT_QUOTES, 'UTF-8') . "
                        </span>
                      </div>
                      <p style='font-size:14px; color:#999;'>This code will expire in 10 minutes.</p>
                    </td>
                  </tr>
                  <!-- Footer -->
                  <tr>
                    <td align='center' style='background:#f7f7f7; padding:15px; font-size:12px; color:#777;'>
                      &copy; ".date("Y")." FOXA. All Rights Reserved.
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        ";
        
        $mail->Body = $body;
        $mail->AltBody = "رمز التحقق الخاص بك: $code";
        
        // محاولة إرسال البريد
        if ($mail->send()) {
            error_log("Fallback email sent successfully via mail() to: $to");
            return true;
        }
    } catch (Throwable $mailError) {
        error_log('Fallback mail() sending failed: ' . $mailError->getMessage());
    }
    
    // إذا فشل كل المحاولات، حاول إرسال بريد نصي بسيط
    try {
        $textMessage = "رمز التحقق الخاص بك: $code\n\nيرجى استخدام هذا الرمز لإكمال التحقق من حسابك.";  
        $headers = "From: FOXA <no-reply@aleppoeats.com>\r\n";
        $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
        
        if (mail($to, $subject, $textMessage, $headers)) {
            error_log("Simple text email sent successfully to: $to");
            return true;
        }
    } catch (Exception $e) {
        error_log("Simple text email sending failed: " . $e->getMessage());
    }
    
    // إذا فشلت كل المحاولات، أضف سجلًا أكثر تفصيلاً للخطأ
    error_log("All email sending methods failed for: $to");
    return false;
}
function masterSetCorsHeaders(): void
{
    $origin = trim((string)($_SERVER['HTTP_ORIGIN'] ?? ''));
    $isAllowed = in_array(
        $origin,
        [
            'https://savir-technology.online',
            'https://www.savir-technology.online',
        ],
        true
    ) || (bool)preg_match(
        '/^https?:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?$/i',
        $origin
    );

    if ($isAllowed) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Vary: Origin');
    }
}

function respondJson($payload, $statusCode = 200)
{
    masterSetCorsHeaders();
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Access-Control-Allow-Origin');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}
function getRequestPayload()
{
    $payload = json_decode(file_get_contents("php://input"), true);
    if (!is_array($payload)) {
        $payload = $_POST;
    }
    return is_array($payload) ? $payload : [];
}
function tableExists($tableName)
{
    static $tableExistsCache = [];
    $cacheKey = (string)$tableName;
    if (array_key_exists($cacheKey, $tableExistsCache)) {
        return $tableExistsCache[$cacheKey];
    }

    global $con;
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table_name
    ");
    $stmt->execute([':table_name' => $tableName]);
    $tableExistsCache[$cacheKey] = (int)$stmt->fetchColumn() > 0;
    return $tableExistsCache[$cacheKey];
}
function columnExists($tableName, $columnName)
{
    static $columnExistsCache = [];
    $cacheKey = (string)$tableName . ':' . (string)$columnName;
    if (array_key_exists($cacheKey, $columnExistsCache)) {
        return $columnExistsCache[$cacheKey];
    }

    global $con;
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table_name
          AND COLUMN_NAME = :column_name
    ");
    $stmt->execute([
        ':table_name' => $tableName,
        ':column_name' => $columnName,
    ]);
    $columnExistsCache[$cacheKey] = (int)$stmt->fetchColumn() > 0;
    return $columnExistsCache[$cacheKey];
}
function getMasterRoleSeedPermissions(array $roleSeeds, array $allPermissionKeys): array
{
    $map = [];
    foreach ($roleSeeds as $seed) {
        $roleId = (int)($seed[0] ?? 0);
        $decoded = json_decode((string)($seed[3] ?? '[]'), true);
        $map[$roleId] = is_array($decoded) ? array_values($decoded) : [];
    }
    $map[1] = array_values($allPermissionKeys);
    $map[2] = [
        'dashboard.view', 'finance.view', 'finance.refund', 'finance.withdrawals',
        'finance.fees', 'finance.expenses', 'finance.settlements',
        'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete',
        'Finance',
    ];
    $map[3] = ['dashboard.view', 'restaurants.view', 'restaurants.approve', 'restaurants.reject', 'restaurants.suspend', 'restaurants.edit', 'orders.view', 'orders.edit', 'Restaurants', 'Orders'];
    $map[4] = ['dashboard.view', 'drivers.view', 'drivers.approve', 'drivers.reject', 'drivers.suspend', 'drivers.edit', 'Drivers'];
    $map[5] = ['dashboard.view', 'customers.view', 'customers.edit', 'customers.block', 'notifications.send', 'Support', 'Users'];
    return $map;
}
function indexExists($tableName, $indexName)
{
    global $con;
    $stmt = $con->prepare("
        SELECT COUNT(*)
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table_name
          AND INDEX_NAME = :index_name
    ");
    $stmt->execute([
        ':table_name' => $tableName,
        ':index_name' => $indexName,
    ]);
    return (int)$stmt->fetchColumn() > 0;
}
function ensureWalletSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('wallet')) {
        $con->exec("
            CREATE TABLE wallet (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                points INT NOT NULL DEFAULT 0,
                balance DECIMAL(12,2) NOT NULL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY wallet_user_id_unique (user_id),
                INDEX wallet_user_id_idx (user_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ");
        $schemaReady = true;
        return;
    }
    if (!columnExists('wallet', 'points')) {
        $con->exec("ALTER TABLE wallet ADD COLUMN points INT NOT NULL DEFAULT 0");
    }
    if (!columnExists('wallet', 'balance')) {
        $con->exec("ALTER TABLE wallet ADD COLUMN balance DECIMAL(12,2) NOT NULL DEFAULT 0");
    }
    $hasUniqueUserIndex = indexExists('wallet', 'wallet_user_id_unique');
    if (!$hasUniqueUserIndex && columnExists('wallet', 'id') && columnExists('wallet', 'user_id')) {
        $con->exec("DELETE FROM wallet WHERE user_id <= 0");
        $con->exec("
            CREATE TEMPORARY TABLE wallet_merge_tmp AS
            SELECT
                MIN(id) AS keep_id,
                user_id,
                COALESCE(SUM(points), 0) AS total_points,
                COALESCE(SUM(balance), 0) AS total_balance
            FROM wallet
            GROUP BY user_id
        ");
        $con->exec("
            UPDATE wallet w
            INNER JOIN wallet_merge_tmp m ON m.keep_id = w.id
            SET
                w.points = m.total_points,
                w.balance = m.total_balance
        ");
        $con->exec("
            DELETE w
            FROM wallet w
            INNER JOIN wallet_merge_tmp m ON m.user_id = w.user_id
            WHERE w.id <> m.keep_id
        ");
        $con->exec("DROP TEMPORARY TABLE IF EXISTS wallet_merge_tmp");
    }
    if (!$hasUniqueUserIndex) {
        $con->exec("ALTER TABLE wallet ADD UNIQUE KEY wallet_user_id_unique (user_id)");
    }
    $con->exec("
        UPDATE wallet
        SET balance = points
        WHERE points > 0
          AND balance <= 0
    ");
    $schemaReady = true;
}
function columnInfo($tableName, $columnName)
{
    global $con;
    $stmt = $con->prepare("
        SELECT COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = :table_name
          AND COLUMN_NAME = :column_name
        LIMIT 1
    ");
    $stmt->execute([
        ':table_name' => $tableName,
        ':column_name' => $columnName,
    ]);
    $info = $stmt->fetch(PDO::FETCH_ASSOC);
    return $info ?: null;
}
function ensureUserAuthSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    $userColumns = [
        "auth_provider" => "ALTER TABLE users ADD COLUMN auth_provider VARCHAR(32) NOT NULL DEFAULT 'email' AFTER user_role",
        "profile_completed" => "ALTER TABLE users ADD COLUMN profile_completed TINYINT(1) NOT NULL DEFAULT 0 AFTER auth_provider",
        "whatsapp_phone_verified_at" => "ALTER TABLE users ADD COLUMN whatsapp_phone_verified_at DATETIME DEFAULT NULL AFTER profile_completed",
        "last_login_at" => "ALTER TABLE users ADD COLUMN last_login_at DATETIME DEFAULT NULL AFTER whatsapp_phone_verified_at",
        "users_locale" => "ALTER TABLE users ADD COLUMN users_locale VARCHAR(8) DEFAULT NULL AFTER last_login_at",
        "users_terms_accepted_at" => "ALTER TABLE users ADD COLUMN users_terms_accepted_at DATETIME DEFAULT NULL AFTER users_locale",
        "users_marketing_opt_in" => "ALTER TABLE users ADD COLUMN users_marketing_opt_in TINYINT(1) NOT NULL DEFAULT 0 AFTER users_terms_accepted_at",
        "session_version" => "ALTER TABLE users ADD COLUMN session_version INT(11) NOT NULL DEFAULT 1 AFTER users_marketing_opt_in",
    ];
    foreach ($userColumns as $columnName => $sql) {
        if (!columnExists('users', $columnName)) {
            $con->exec($sql);
        }
    }
    if (!tableExists('user_sessions')) {
        $con->exec("
            CREATE TABLE user_sessions (
                session_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                user_id INT(11) NOT NULL,
                access_token VARCHAR(128) NOT NULL,
                refresh_token VARCHAR(128) DEFAULT NULL,
                user_agent VARCHAR(255) DEFAULT NULL,
                ip_address VARCHAR(64) DEFAULT NULL,
                device_name VARCHAR(120) DEFAULT NULL,
                last_used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME NOT NULL,
                refresh_expires_at DATETIME DEFAULT NULL,
                revoked_at DATETIME DEFAULT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (session_id),
                UNIQUE KEY uniq_user_sessions_token (access_token),
                UNIQUE KEY uniq_user_sessions_refresh (refresh_token),
                KEY idx_user_sessions_user (user_id),
                KEY idx_user_sessions_expires (expires_at),
                CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id)
                    REFERENCES users (users_id)
                    ON DELETE CASCADE
                    ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (!tableExists('user_otp_requests')) {
        $con->exec("
            CREATE TABLE user_otp_requests (
                otp_request_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                phone_e164 VARCHAR(20) NOT NULL,
                provider VARCHAR(32) NOT NULL DEFAULT 'local_debug',
                provider_sid VARCHAR(64) DEFAULT NULL,
                channel VARCHAR(16) NOT NULL DEFAULT 'whatsapp',
                otp_code_hash VARCHAR(255) DEFAULT NULL,
                request_status VARCHAR(32) NOT NULL DEFAULT 'pending',
                send_attempts INT(11) NOT NULL DEFAULT 1,
                verify_attempts INT(11) NOT NULL DEFAULT 0,
                metadata LONGTEXT DEFAULT NULL,
                expires_at DATETIME NOT NULL,
                verified_at DATETIME DEFAULT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (otp_request_id),
                KEY idx_user_otp_phone (phone_e164),
                KEY idx_user_otp_status (request_status, expires_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    $schemaReady = true;
}
function ensureMasterAuthSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('master_role_profiles')) {
        $con->exec("
            CREATE TABLE master_role_profiles (
                role_id INT(11) NOT NULL,
                role_name VARCHAR(120) NOT NULL,
                role_scope VARCHAR(255) NOT NULL,
                permissions_json LONGTEXT NOT NULL,
                tint_hex VARCHAR(16) DEFAULT '#3B82F6',
                sort_order INT(11) NOT NULL DEFAULT 0,
                PRIMARY KEY (role_id),
                KEY idx_master_role_profiles_sort (sort_order)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    $masterPermissionSeeds = [
        ['dashboard.view', 'Dashboard', 'View Dashboard'],
        ['restaurants.view', 'Restaurants', 'View Restaurants'],
        ['restaurants.approve', 'Restaurants', 'Approve Restaurant'],
        ['restaurants.reject', 'Restaurants', 'Reject Restaurant'],
        ['restaurants.suspend', 'Restaurants', 'Suspend Restaurant'],
        ['restaurants.delete', 'Restaurants', 'Delete Restaurant'],
        ['restaurants.edit', 'Restaurants', 'Edit Restaurant'],
        ['drivers.view', 'Drivers', 'View Drivers'],
        ['drivers.approve', 'Drivers', 'Approve Driver'],
        ['drivers.reject', 'Drivers', 'Reject Driver'],
        ['drivers.suspend', 'Drivers', 'Suspend Driver'],
        ['drivers.delete', 'Drivers', 'Delete Driver'],
        ['drivers.edit', 'Drivers', 'Edit Driver'],
        ['orders.view', 'Orders', 'View Orders'],
        ['orders.edit', 'Orders', 'Edit Orders'],
        ['orders.cancel', 'Orders', 'Cancel Orders'],
        ['orders.assign_driver', 'Orders', 'Assign Driver'],
        ['customers.view', 'Customers', 'View Customers'],
        ['customers.edit', 'Customers', 'Edit Customers'],
        ['customers.block', 'Customers', 'Block Customers'],
        ['coupons.view', 'Coupons', 'View Coupons'],
        ['coupons.create', 'Coupons', 'Create Coupon'],
        ['coupons.edit', 'Coupons', 'Edit Coupon'],
        ['coupons.delete', 'Coupons', 'Delete Coupon'],
        ['reports.view', 'Reports', 'View Reports'],
        ['reports.export', 'Reports', 'Export Reports'],
        ['finance.view', 'Finance', 'View Transactions'],
        ['finance.refund', 'Finance', 'Refund'],
        ['finance.withdrawals', 'Finance', 'Withdrawals'],
        ['finance.wallets', 'Finance', 'Manage Customer Wallets'],
        ['finance.fees', 'Finance', 'Manage Delivery Fees'],
        ['finance.expenses', 'Finance', 'Manage Expenses'],
        ['finance.settlements', 'Finance', 'Manage Settlements'],
        ['marketing.view', 'Marketing', 'View Marketing'],
        ['marketing.create', 'Marketing', 'Create Marketing Content'],
        ['marketing.edit', 'Marketing', 'Edit Marketing Content'],
        ['marketing.delete', 'Marketing', 'Delete Marketing Content'],
        ['support.view', 'Support', 'View Support'],
        ['support.reply', 'Support', 'Reply to Support Cases'],
        ['support.assign', 'Support', 'Assign Support Cases'],
        ['notifications.view', 'Notifications', 'View Notifications'],
        ['notifications.send', 'Notifications', 'Send Notifications'],
        ['settings.view', 'Settings', 'View Settings'],
        ['settings.edit', 'Settings', 'Edit Settings'],
        ['administration.view', 'Administration', 'View Administrators'],
        ['administration.create', 'Administration', 'Create Administrator'],
        ['administration.edit', 'Administration', 'Edit Administrator'],
        ['administration.delete', 'Administration', 'Delete Administrator'],
        ['administration.manage_roles', 'Administration', 'Manage Roles'],
        ['super_admin', 'Administration', 'Super Admin'],
        ['Vendors', 'Legacy', 'Legacy Vendors Module'],
        ['Restaurants', 'Legacy', 'Legacy Restaurants Module'],
        ['Drivers', 'Legacy', 'Legacy Drivers Module'],
        ['Orders', 'Legacy', 'Legacy Orders Module'],
        ['Users', 'Legacy', 'Legacy Users Module'],
        ['Finance', 'Legacy', 'Legacy Finance Module'],
        ['Reports', 'Legacy', 'Legacy Reports Module'],
        ['Support', 'Legacy', 'Legacy Support Module'],
        ['Content', 'Legacy', 'Legacy Content Module'],
        ['Settings', 'Legacy', 'Legacy Settings Module'],
    ];
    $masterRoleSeeds = [
        [
            1,
            'الأدمن الأساسي',
            'كافة الصلاحيات على المنصة',
            json_encode(['Vendors', 'Finance', 'Restaurants', 'Drivers', 'Support', 'Content', 'Settings'], JSON_UNESCAPED_UNICODE),
            '#3B82F6',
            1,
        ],
        [
            2,
            'مدير الحسابات',
            'متابعة التسويات والملفات المالية',
            json_encode(['Finance', 'Invoices', 'Settlements', 'Reports'], JSON_UNESCAPED_UNICODE),
            '#F59E0B',
            2,
        ],
        [
            3,
            'مدير المطاعم',
            'إدارة المطاعم والمنيوهات والطلبات',
            json_encode(['Restaurants', 'Menus', 'Branches', 'Orders'], JSON_UNESCAPED_UNICODE),
            '#10B981',
            3,
        ],
        [
            4,
            'مدير قسم السائقين',
            'متابعة السائقين والحركة التشغيلية',
            json_encode(['Drivers', 'Shifts', 'Tracking', 'Incidents'], JSON_UNESCAPED_UNICODE),
            '#8B5CF6',
            4,
        ],
        [
            5,
            'مدير الدعم الفني',
            'حل التذاكر والمتابعة والدعم',
            json_encode(['Chats', 'Tickets', 'Returns', 'Disputes'], JSON_UNESCAPED_UNICODE),
            '#EC4899',
            5,
        ],
    ];
    $roleStmt = $con->prepare("
        INSERT INTO master_role_profiles (
            role_id,
            role_name,
            role_scope,
            permissions_json,
            tint_hex,
            sort_order
        ) VALUES (
            :role_id,
            :role_name,
            :role_scope,
            :permissions_json,
            :tint_hex,
            :sort_order
        )
        ON DUPLICATE KEY UPDATE
            role_name = IF(role_name = '', VALUES(role_name), role_name),
            role_scope = IF(role_scope = '', VALUES(role_scope), role_scope),
            permissions_json = IF(permissions_json = '' OR permissions_json = '[]', VALUES(permissions_json), permissions_json),
            tint_hex = IF(tint_hex = '' OR tint_hex IS NULL, VALUES(tint_hex), tint_hex),
            sort_order = IF(sort_order = 0, VALUES(sort_order), sort_order)
    ");
    foreach ($masterRoleSeeds as $seed) {
        $roleStmt->execute([
            ':role_id' => $seed[0],
            ':role_name' => $seed[1],
            ':role_scope' => $seed[2],
            ':permissions_json' => $seed[3],
            ':tint_hex' => $seed[4],
            ':sort_order' => $seed[5],
        ]);
    }
    if (!tableExists('master_permissions')) {
        $con->exec("
            CREATE TABLE master_permissions (
                permission_id INT(11) NOT NULL AUTO_INCREMENT,
                permission_key VARCHAR(96) NOT NULL,
                permission_group VARCHAR(96) NOT NULL,
                permission_label VARCHAR(160) NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (permission_id),
                UNIQUE KEY uniq_master_permissions_key (permission_key),
                KEY idx_master_permissions_group (permission_group)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (!tableExists('master_role_permissions')) {
        $con->exec("
            CREATE TABLE master_role_permissions (
                role_id INT(11) NOT NULL,
                permission_key VARCHAR(96) NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (role_id, permission_key),
                KEY idx_master_role_permissions_key (permission_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (!tableExists('master_admin_permissions')) {
        $con->exec("
            CREATE TABLE master_admin_permissions (
                admin_id INT(11) NOT NULL,
                permission_key VARCHAR(96) NOT NULL,
                effect ENUM('allow','deny') NOT NULL DEFAULT 'allow',
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (admin_id, permission_key),
                KEY idx_master_admin_permissions_key (permission_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    $permissionStmt = $con->prepare("
        INSERT INTO master_permissions (permission_key, permission_group, permission_label)
        VALUES (:permission_key, :permission_group, :permission_label)
        ON DUPLICATE KEY UPDATE
            permission_group = VALUES(permission_group),
            permission_label = VALUES(permission_label)
    ");
    foreach ($masterPermissionSeeds as $seed) {
        $permissionStmt->execute([
            ':permission_key' => $seed[0],
            ':permission_group' => $seed[1],
            ':permission_label' => $seed[2],
        ]);
    }
    $allPermissionKeys = array_map(static function ($seed) {
        return $seed[0];
    }, $masterPermissionSeeds);
    $superPermissionsJson = json_encode($allPermissionKeys, JSON_UNESCAPED_UNICODE);
    $superStmt = $con->prepare("
        UPDATE master_role_profiles
        SET role_name = 'Super Admin',
            role_scope = 'Full platform administration access',
            permissions_json = :permissions_json
        WHERE role_id = 1
    ");
    $superStmt->execute([':permissions_json' => $superPermissionsJson]);
    $rolePermissionStmt = $con->prepare("
        INSERT IGNORE INTO master_role_permissions (role_id, permission_key)
        VALUES (:role_id, :permission_key)
    ");
    foreach (getMasterRoleSeedPermissions($masterRoleSeeds, $allPermissionKeys) as $roleId => $permissionKeys) {
        $con->prepare("DELETE FROM master_role_permissions WHERE role_id = :role_id")->execute([
            ':role_id' => (int)$roleId,
        ]);
        foreach ($permissionKeys as $permissionKey) {
            $rolePermissionStmt->execute([
                ':role_id' => (int)$roleId,
                ':permission_key' => (string)$permissionKey,
            ]);
        }
    }
    if (!tableExists('admin')) {
        $con->exec("
            CREATE TABLE admin (
                admin_id INT(11) NOT NULL AUTO_INCREMENT,
                admin_name VARCHAR(255) NOT NULL,
                admin_password VARCHAR(255) NOT NULL,
                admin_email VARCHAR(255) NOT NULL,
                admin_phone VARCHAR(30) NOT NULL,
                admin_verfiycode VARCHAR(10) DEFAULT NULL,
                admin_verify_expires_at DATETIME DEFAULT NULL,
                admin_reset_code VARCHAR(10) DEFAULT NULL,
                admin_reset_expires_at DATETIME DEFAULT NULL,
                admin_approve TINYINT(4) NOT NULL DEFAULT 0,
                admin_role_id INT(11) NOT NULL DEFAULT 1,
                admin_last_login_at DATETIME DEFAULT NULL,
                admin_create DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (admin_id),
                UNIQUE KEY uniq_admin_email (admin_email),
                KEY idx_admin_role_id (admin_role_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ");
    } else {
        $adminColumnSql = [
            "admin_phone" => [
                "modify" => "ALTER TABLE admin MODIFY admin_phone VARCHAR(30) NOT NULL",
                "add" => "ALTER TABLE admin ADD COLUMN admin_phone VARCHAR(30) NOT NULL AFTER admin_email",
            ],
            "admin_verfiycode" => [
                "modify" => "ALTER TABLE admin MODIFY admin_verfiycode VARCHAR(10) DEFAULT NULL",
                "add" => "ALTER TABLE admin ADD COLUMN admin_verfiycode VARCHAR(10) DEFAULT NULL AFTER admin_phone",
            ],
            "admin_verify_expires_at" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_verify_expires_at DATETIME DEFAULT NULL AFTER admin_verfiycode",
            ],
            "admin_reset_code" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_reset_code VARCHAR(10) DEFAULT NULL AFTER admin_verify_expires_at",
            ],
            "admin_reset_expires_at" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_reset_expires_at DATETIME DEFAULT NULL AFTER admin_reset_code",
            ],
            "admin_role_id" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_role_id INT(11) NOT NULL DEFAULT 1 AFTER admin_approve",
            ],
            "admin_last_login_at" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_last_login_at DATETIME DEFAULT NULL AFTER admin_role_id",
            ],
            "admin_profile_image" => [
                "add" => "ALTER TABLE admin ADD COLUMN admin_profile_image VARCHAR(255) DEFAULT NULL AFTER admin_phone",
            ],
        ];
        foreach ($adminColumnSql as $columnName => $statements) {
            if (columnExists('admin', $columnName)) {
                if (!empty($statements['modify'])) {
                    $con->exec($statements['modify']);
                }
                continue;
            }
            if (!empty($statements['add'])) {
                $con->exec($statements['add']);
            }
        }
    }
    if (tableExists('admin')) {
        $con->exec("UPDATE admin SET admin_role_id = 1 WHERE admin_role_id IS NULL OR admin_role_id = 0");
    }
    if (tableExists('delivery_users') && !columnExists('delivery_users', 'approval_status')) {
        $con->exec("ALTER TABLE delivery_users ADD COLUMN approval_status ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending' AFTER status");
        $con->exec("UPDATE delivery_users SET approval_status = CASE WHEN profile_completed = 1 THEN 'approved' ELSE 'pending' END");
    }
    if (tableExists('delivery_users') && !columnExists('delivery_users', 'approval_note')) {
        $con->exec("ALTER TABLE delivery_users ADD COLUMN approval_note TEXT DEFAULT NULL AFTER approval_status");
    }
    if (tableExists('vendors') && !columnExists('vendors', 'vendor_approval_status')) {
        $con->exec("ALTER TABLE vendors ADD COLUMN vendor_approval_status ENUM('pending','approved','rejected','suspended','more_info') NOT NULL DEFAULT 'pending' AFTER vendor_is_verified");
        $con->exec("
            UPDATE vendors
            SET vendor_approval_status = CASE
                WHEN vendor_status = 'active' AND vendor_is_verified = 1 THEN 'approved'
                WHEN vendor_status = 'suspended' THEN 'suspended'
                ELSE 'pending'
            END
        ");
    }
    if (tableExists('vendors') && !columnExists('vendors', 'vendor_approval_note')) {
        $con->exec("ALTER TABLE vendors ADD COLUMN vendor_approval_note TEXT DEFAULT NULL AFTER vendor_approval_status");
    }
    if (!tableExists('master_sessions')) {
        $con->exec("
            CREATE TABLE master_sessions (
                session_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                admin_id INT(11) NOT NULL,
                access_token VARCHAR(128) NOT NULL,
                user_agent VARCHAR(255) DEFAULT NULL,
                ip_address VARCHAR(64) DEFAULT NULL,
                last_used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (session_id),
                UNIQUE KEY uniq_master_sessions_token (access_token),
                KEY idx_master_sessions_admin (admin_id),
                CONSTRAINT fk_master_sessions_admin FOREIGN KEY (admin_id)
                    REFERENCES admin (admin_id)
                    ON DELETE CASCADE
                    ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    $schemaReady = true;
}

/**
 * Keep the six employee portals available after a clean install or after a
 * database migration. This is idempotent and never changes existing admin
 * accounts.
 */
function ensureMasterPortalRoles(): void
{
    global $con;
    static $ready = false;
    if ($ready) {
        return;
    }

    ensureMasterAuthSchema();
    $roles = [
        [10, 'مسؤول الإدارة المالية', 'المالية والإيرادات والمحافظ والعروض والتقارير المالية', ['dashboard.view', 'finance.view', 'finance.refund', 'finance.withdrawals', 'finance.wallets', 'finance.fees', 'finance.expenses', 'finance.settlements', 'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete', 'reports.view', 'reports.export'], '#F59E0B', 10],
        [11, 'مسؤول الدعم الفني', 'الدردشات وخدمة العملاء ومراقبة التواصل', ['dashboard.view', 'support.view', 'support.reply', 'support.assign', 'customers.view', 'drivers.view', 'restaurants.view', 'orders.view'], '#EC4899', 11],
        [12, 'مسؤول إدارة العمليات', 'الطلبات والتوصيل والموافقات والحظر', ['dashboard.view', 'orders.view', 'orders.edit', 'orders.cancel', 'orders.assign_driver', 'drivers.view', 'drivers.edit', 'drivers.approve', 'drivers.reject', 'drivers.suspend', 'restaurants.view', 'restaurants.approve', 'restaurants.reject', 'customers.view', 'customers.block', 'settings.view', 'settings.edit'], '#2563EB', 12],
        [13, 'مسؤول المطاعم والمتاجر', 'المتاجر والمنتجات والأقسام والعروض والإعلانات', ['dashboard.view', 'restaurants.view', 'restaurants.approve', 'restaurants.reject', 'restaurants.suspend', 'restaurants.delete', 'restaurants.edit', 'marketing.view', 'marketing.create', 'marketing.edit', 'marketing.delete', 'coupons.view', 'coupons.create', 'coupons.edit', 'coupons.delete'], '#10B981', 13],
        [14, 'مسؤول التقارير والمراقبة', 'تقارير وتحليلات ومراجعة أداء المنظومة', ['dashboard.view', 'reports.view', 'reports.export', 'orders.view', 'customers.view', 'drivers.view', 'restaurants.view', 'finance.view', 'marketing.view'], '#8B5CF6', 14],
        [15, 'مسؤول الأمن والشؤون القانونية', 'السياسات والكوكيز والوثائق القانونية', ['dashboard.view', 'settings.view', 'settings.edit', 'administration.view', 'reports.view'], '#64748B', 15],
    ];

    $roleStmt = $con->prepare("INSERT INTO master_role_profiles
        (role_id, role_name, role_scope, permissions_json, tint_hex, sort_order)
        VALUES (:id, :name, :scope, :permissions, :tint, :sort)
        ON DUPLICATE KEY UPDATE
            role_name = IF(role_name = '', VALUES(role_name), role_name),
            role_scope = IF(role_scope = '', VALUES(role_scope), role_scope),
            permissions_json = VALUES(permissions_json),
            tint_hex = IF(tint_hex = '' OR tint_hex IS NULL, VALUES(tint_hex), tint_hex),
            sort_order = IF(sort_order = 0, VALUES(sort_order), sort_order)");
    $existingRoleStmt = $con->prepare('SELECT permissions_json FROM master_role_profiles WHERE role_id = :id LIMIT 1');
    $deleteStmt = $con->prepare('DELETE FROM master_role_permissions WHERE role_id = :id');
    $permissionStmt = $con->prepare('INSERT IGNORE INTO master_role_permissions (role_id, permission_key) VALUES (:id, :permission)');
    foreach ($roles as $role) {
        $permissions = array_values(array_unique($role[3]));
        $existingRoleStmt->execute([':id' => $role[0]]);
        $existingPermissions = json_decode((string)$existingRoleStmt->fetchColumn(), true);
        $hasExistingPermissions = is_array($existingPermissions) && $existingPermissions !== [];
        if ($hasExistingPermissions) {
            // Preserve custom grants while ensuring every portal keeps its
            // required baseline permissions after a repeatable deployment.
            $permissions = array_values(array_unique(array_merge($permissions, $existingPermissions)));
        }
        $roleStmt->execute([
            ':id' => $role[0], ':name' => $role[1], ':scope' => $role[2],
            ':permissions' => json_encode($permissions, JSON_UNESCAPED_UNICODE),
            ':tint' => $role[4], ':sort' => $role[5],
        ]);
        if (!$hasExistingPermissions) {
            $deleteStmt->execute([':id' => $role[0]]);
        }
        foreach ($permissions as $permission) {
            $permissionStmt->execute([':id' => $role[0], ':permission' => $permission]);
        }
    }
    $ready = true;
}
function ensureMasterDashboardSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('master_dashboard_sections')) {
        $con->exec("
            CREATE TABLE master_dashboard_sections (
                section_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                section_key VARCHAR(64) NOT NULL,
                section_index INT(11) NOT NULL,
                permission_key VARCHAR(64) NOT NULL DEFAULT '',
                title_ar VARCHAR(120) NOT NULL,
                subtitle_en VARCHAR(120) NOT NULL,
                pages_count_label VARCHAR(120) NOT NULL,
                icon_key VARCHAR(64) NOT NULL,
                accent_hex VARCHAR(16) NOT NULL DEFAULT '#3B82F6',
                icon_background_hex VARCHAR(16) NOT NULL DEFAULT '#EEF2FF',
                action_color_hex VARCHAR(16) NOT NULL DEFAULT '#3B82F6',
                sort_order INT(11) NOT NULL DEFAULT 0,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (section_id),
                UNIQUE KEY uniq_master_dashboard_sections_key (section_key),
                KEY idx_master_dashboard_sections_sort (sort_order),
                KEY idx_master_dashboard_sections_permission (permission_key),
                KEY idx_master_dashboard_sections_active (is_active)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    $sectionSeeds = [
        [
            'operations',
            1,
            'Support',
            'لوحة العمليات',
            'Operations Center',
            '3 صفحات فرعية',
            'warning',
            '#6E3BEA',
            '#F2ECFF',
            '#E11B22',
            1,
        ],
        [
            'orders',
            2,
            'Vendors',
            'إدارة الطلبات',
            'Orders Management',
            '6 صفحات فرعية',
            'orders',
            '#2563EB',
            '#EAF1FF',
            '#2563EB',
            2,
        ],
        [
            'delivery',
            3,
            'Drivers',
            'التوصيل والوجستيات',
            'Delivery & Logistics',
            '5 صفحات فرعية',
            'delivery',
            '#1E7D3F',
            '#EAF5ED',
            '#1E7D3F',
            3,
        ],
        [
            'restaurants',
            4,
            'Restaurants',
            'إدارة المطاعم',
            'Restaurants Management',
            '7 صفحات فرعية',
            'store',
            '#F59E0B',
            '#FFF3E5',
            '#F59E0B',
            4,
        ],
        [
            'customers',
            5,
            'Users',
            'العملاء',
            'Customers',
            '6 صفحات فرعية',
            'users',
            '#1E7D3F',
            '#EAF5ED',
            '#1E7D3F',
            5,
        ],
        [
            'finance',
            6,
            'Finance',
            'الإدارة المالية',
            'Finance',
            '6 صفحات فرعية',
            'finance',
            '#E5A100',
            '#FFF5D9',
            '#CF8B00',
            6,
        ],
        [
            'marketing',
            7,
            'Content',
            'التسويق والنمو',
            'Marketing & Growth',
            '7 صفحات فرعية',
            'marketing',
            '#E11D48',
            '#FFE7EF',
            '#E11D48',
            7,
        ],
        [
            'communication',
            8,
            'Support',
            'مركز التواصل',
            'Communication Center',
            '5 صفحات فرعية',
            'communication',
            '#2563EB',
            '#EAF1FF',
            '#2563EB',
            8,
        ],
        [
            'quality',
            9,
            'Support',
            'الجودة وخدمة العملاء',
            'Quality & Support',
            '4 صفحات فرعية',
            'quality',
            '#F43F5E',
            '#FFEBEF',
            '#F43F5E',
            9,
        ],
        [
            'reports',
            10,
            'Reports',
            'التقارير والتحليلات',
            'Analytics & Reports',
            '8 صفحات فرعية',
            'reports',
            '#7C3AED',
            '#F1ECFF',
            '#7C3AED',
            10,
        ],
        [
            'settings',
            11,
            'Settings',
            'إعدادات المنصة',
            'Platform Settings',
            '9 مجموعات إعدادات',
            'settings',
            '#0E9F9A',
            '#E8FBF8',
            '#0E9F9A',
            11,
        ],
        [
            'administration',
            12,
            'Settings',
            'الإدارة والصلاحيات',
            'Administration',
            '4 صفحات فرعية',
            'administration',
            '#2563EB',
            '#EAF1FF',
            '#2563EB',
            12,
        ],
    ];
    $sectionStmt = $con->prepare("
        INSERT INTO master_dashboard_sections (
            section_key,
            section_index,
            permission_key,
            title_ar,
            subtitle_en,
            pages_count_label,
            icon_key,
            accent_hex,
            icon_background_hex,
            action_color_hex,
            sort_order,
            is_active
        ) VALUES (
            :section_key,
            :section_index,
            :permission_key,
            :title_ar,
            :subtitle_en,
            :pages_count_label,
            :icon_key,
            :accent_hex,
            :icon_background_hex,
            :action_color_hex,
            :sort_order,
            1
        )
        ON DUPLICATE KEY UPDATE
            section_index = VALUES(section_index),
            permission_key = VALUES(permission_key),
            title_ar = VALUES(title_ar),
            subtitle_en = VALUES(subtitle_en),
            pages_count_label = VALUES(pages_count_label),
            icon_key = VALUES(icon_key),
            accent_hex = VALUES(accent_hex),
            icon_background_hex = VALUES(icon_background_hex),
            action_color_hex = VALUES(action_color_hex),
            sort_order = VALUES(sort_order),
            is_active = VALUES(is_active)
    ");
    foreach ($sectionSeeds as $seed) {
        $sectionStmt->execute([
            ':section_key' => $seed[0],
            ':section_index' => $seed[1],
            ':permission_key' => $seed[2],
            ':title_ar' => $seed[3],
            ':subtitle_en' => $seed[4],
            ':pages_count_label' => $seed[5],
            ':icon_key' => $seed[6],
            ':accent_hex' => $seed[7],
            ':icon_background_hex' => $seed[8],
            ':action_color_hex' => $seed[9],
            ':sort_order' => $seed[10],
        ]);
    }
    $schemaReady = true;
}
function ensureDriverAuthSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('driver_email_otp_requests')) {
        $con->exec("
            CREATE TABLE driver_email_otp_requests (
                otp_request_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                email VARCHAR(190) NOT NULL,
                otp_code_hash VARCHAR(255) NOT NULL,
                verification_token VARCHAR(128) DEFAULT NULL,
                request_status VARCHAR(32) NOT NULL DEFAULT 'pending',
                send_attempts INT(11) NOT NULL DEFAULT 1,
                verify_attempts INT(11) NOT NULL DEFAULT 0,
                metadata LONGTEXT DEFAULT NULL,
                expires_at DATETIME NOT NULL,
                verified_at DATETIME DEFAULT NULL,
                used_at DATETIME DEFAULT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (otp_request_id),
                KEY idx_driver_email_otp_email (email),
                KEY idx_driver_email_otp_token (verification_token),
                KEY idx_driver_email_otp_status (request_status, expires_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (tableExists('delivery_users')) {
        $driverColumns = [
            'name' => "ALTER TABLE delivery_users ADD COLUMN name VARCHAR(191) DEFAULT NULL",
            'phone' => "ALTER TABLE delivery_users ADD COLUMN phone VARCHAR(30) DEFAULT NULL",
            'email' => "ALTER TABLE delivery_users ADD COLUMN email VARCHAR(190) DEFAULT NULL",
            'password' => "ALTER TABLE delivery_users ADD COLUMN password VARCHAR(255) DEFAULT NULL",
            'vehicle_type' => "ALTER TABLE delivery_users ADD COLUMN vehicle_type VARCHAR(100) DEFAULT NULL",
            'vehicle_number' => "ALTER TABLE delivery_users ADD COLUMN vehicle_number VARCHAR(100) DEFAULT NULL",
            'vendor_id' => "ALTER TABLE delivery_users ADD COLUMN vendor_id INT(11) DEFAULT NULL",
            'auth_provider' => "ALTER TABLE delivery_users ADD COLUMN auth_provider VARCHAR(32) NOT NULL DEFAULT 'email'",
            'profile_completed' => "ALTER TABLE delivery_users ADD COLUMN profile_completed TINYINT(1) NOT NULL DEFAULT 0",
            'profile_image' => "ALTER TABLE delivery_users ADD COLUMN profile_image VARCHAR(255) DEFAULT NULL",
            'email_verified_at' => "ALTER TABLE delivery_users ADD COLUMN email_verified_at DATETIME DEFAULT NULL",
            'password_set_at' => "ALTER TABLE delivery_users ADD COLUMN password_set_at DATETIME DEFAULT NULL",
            'last_login_at' => "ALTER TABLE delivery_users ADD COLUMN last_login_at DATETIME DEFAULT NULL",
            'notifications_enabled' => "ALTER TABLE delivery_users ADD COLUMN notifications_enabled TINYINT(1) NOT NULL DEFAULT 1",
            'location_sharing_enabled' => "ALTER TABLE delivery_users ADD COLUMN location_sharing_enabled TINYINT(1) NOT NULL DEFAULT 1",
            'locale_code' => "ALTER TABLE delivery_users ADD COLUMN locale_code VARCHAR(10) NOT NULL DEFAULT 'en'",
            'theme_mode' => "ALTER TABLE delivery_users ADD COLUMN theme_mode VARCHAR(10) NOT NULL DEFAULT 'dark'",
        ];
        foreach ($driverColumns as $columnName => $sql) {
            try {
                if (!columnExists('delivery_users', $columnName)) {
                    $con->exec($sql);
                }
            } catch (Throwable $columnError) {
                error_log(
                    'delivery_users schema upgrade failed for ' .
                    $columnName .
                    ': ' .
                    $columnError->getMessage()
                );
            }
        }
    } else {
        error_log('delivery_users table not found; skipping driver auth schema upgrades');
    }
    $schemaReady = true;
}
function ensureAleppoFoodOrderingSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    $cartColumns = [
        "cart_context_type" => "ALTER TABLE cart ADD COLUMN cart_context_type VARCHAR(32) NOT NULL DEFAULT 'product' AFTER cart_config_hash",
        "cart_vendor_id" => "ALTER TABLE cart ADD COLUMN cart_vendor_id INT DEFAULT NULL AFTER cart_context_type",
        "cart_unit_price" => "ALTER TABLE cart ADD COLUMN cart_unit_price DECIMAL(10,2) DEFAULT NULL AFTER cart_vendor_id",
        "cart_item_note" => "ALTER TABLE cart ADD COLUMN cart_item_note TEXT DEFAULT NULL AFTER cart_unit_price",
        "cart_menu_options_json" => "ALTER TABLE cart ADD COLUMN cart_menu_options_json LONGTEXT DEFAULT NULL AFTER cart_item_note",
        "cart_menu_options_summary" => "ALTER TABLE cart ADD COLUMN cart_menu_options_summary TEXT DEFAULT NULL AFTER cart_menu_options_json",
        "cart_variant_attributes_json" => "ALTER TABLE cart ADD COLUMN cart_variant_attributes_json LONGTEXT DEFAULT NULL AFTER cart_menu_options_summary",
        "cart_quantity_weight" => "ALTER TABLE cart ADD COLUMN cart_quantity_weight DECIMAL(12,3) DEFAULT NULL AFTER cart_variant_attributes_json",
    ];
    foreach ($cartColumns as $columnName => $sql) {
        if (!columnExists('cart', $columnName)) {
            $con->exec($sql);
        }
    }

    // Shared catalogue fields. Existing restaurant rows keep their defaults,
    // while stores can describe units and arbitrary product attributes.
    if (tableExists('vendors') && !columnExists('vendors', 'vendor_type')) {
        $con->exec("ALTER TABLE vendors ADD COLUMN vendor_type VARCHAR(24) NOT NULL DEFAULT 'restaurant' AFTER vendor_is_verified");
    }
    if (tableExists('vendors') && !columnExists('vendors', 'store_category')) {
        $con->exec("ALTER TABLE vendors ADD COLUMN store_category VARCHAR(32) DEFAULT NULL AFTER vendor_type");
    }
    if (tableExists('vendors')) {
        $vendorResetColumns = [
            'vendor_reset_code' => "ALTER TABLE vendors ADD COLUMN vendor_reset_code VARCHAR(10) DEFAULT NULL AFTER store_category",
            'vendor_reset_expires_at' => "ALTER TABLE vendors ADD COLUMN vendor_reset_expires_at DATETIME DEFAULT NULL AFTER vendor_reset_code",
        ];
        foreach ($vendorResetColumns as $columnName => $sql) {
            if (!columnExists('vendors', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (tableExists('items')) {
        $itemColumns = [
            'product_type' => "ALTER TABLE items ADD COLUMN product_type VARCHAR(24) NOT NULL DEFAULT 'food' AFTER vendor_id",
            'stock_unit' => "ALTER TABLE items ADD COLUMN stock_unit VARCHAR(16) NOT NULL DEFAULT 'piece' AFTER product_type",
            'stock_step' => "ALTER TABLE items ADD COLUMN stock_step DECIMAL(12,3) NOT NULL DEFAULT 1.000 AFTER stock_unit",
        ];
        foreach ($itemColumns as $columnName => $sql) {
            if (!columnExists('items', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (tableExists('sizes')) {
        // Keep clothing and shoe sizes in the same catalogue while exposing
        // only the relevant set for each product type.
        if (!columnExists('sizes', 'product_type')) {
            $con->exec("ALTER TABLE sizes ADD COLUMN product_type VARCHAR(24) DEFAULT 'fashion' AFTER size_order");
        }
        $fashionSizes = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
        $fashionSizes = array_merge($fashionSizes, range(28, 60));
        $fashionStmt = $con->prepare("INSERT INTO sizes (size_name, size_order, product_type)
            SELECT :name, :size_order, 'fashion' FROM DUAL
            WHERE NOT EXISTS (SELECT 1 FROM sizes WHERE size_name = :name_check AND product_type = 'fashion')");
        foreach ($fashionSizes as $order => $fashionSize) {
            $fashionStmt->execute([
                ':name' => (string)$fashionSize,
                ':name_check' => (string)$fashionSize,
                ':size_order' => $order + 1,
            ]);
        }
        $shoeSizes = [36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47];
        $sizeStmt = $con->prepare("INSERT INTO sizes (size_name, size_order, product_type)
            SELECT :name, :size_order, 'shoes' FROM DUAL
            WHERE NOT EXISTS (SELECT 1 FROM sizes WHERE size_name = :name_check AND product_type = 'shoes')");
        foreach ($shoeSizes as $order => $shoeSize) {
            $sizeStmt->execute([
                ':name' => (string)$shoeSize,
                ':name_check' => (string)$shoeSize,
                ':size_order' => $order + 1,
            ]);
        }
    }
    if (tableExists('item_variants')) {
        // A generic variant may have neither a colour nor a size (for example
        // perfume volume or grocery packaging). Legacy rows are unaffected.
        try {
            $nullableStmt = $con->prepare("SELECT COUNT(*) FROM information_schema.columns
                WHERE table_schema = DATABASE() AND table_name = 'item_variants'
                  AND column_name IN ('color_id', 'size_id') AND is_nullable = 'NO'");
            $nullableStmt->execute();
            if ((int)$nullableStmt->fetchColumn() > 0) {
                $con->exec("ALTER TABLE item_variants MODIFY COLUMN color_id INT NULL, MODIFY COLUMN size_id INT NULL");
            }
        } catch (Throwable $variantCompatibilityError) {
            error_log('item_variants nullable migration skipped: ' . $variantCompatibilityError->getMessage());
        }
        $variantColumns = [
            'sku' => "ALTER TABLE item_variants ADD COLUMN sku VARCHAR(80) DEFAULT NULL AFTER variant_id",
            'stock_quantity' => "ALTER TABLE item_variants ADD COLUMN stock_quantity DECIMAL(12,3) NOT NULL DEFAULT 0 AFTER stock",
            'unit' => "ALTER TABLE item_variants ADD COLUMN unit VARCHAR(16) NOT NULL DEFAULT 'piece' AFTER stock_quantity",
            'unit_quantity' => "ALTER TABLE item_variants ADD COLUMN unit_quantity DECIMAL(12,3) NOT NULL DEFAULT 1.000 AFTER unit",
        ];
        foreach ($variantColumns as $columnName => $sql) {
            if (!columnExists('item_variants', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (tableExists('order_items')) {
        $orderItemColumns = [
            'variant_id' => "ALTER TABLE order_items ADD COLUMN variant_id INT DEFAULT NULL AFTER item_id",
            'quantity_weight' => "ALTER TABLE order_items ADD COLUMN quantity_weight DECIMAL(12,3) DEFAULT NULL AFTER quantity",
            'variant_attributes_json' => "ALTER TABLE order_items ADD COLUMN variant_attributes_json LONGTEXT DEFAULT NULL AFTER food_menu_options_summary",
            'stock_unit' => "ALTER TABLE order_items ADD COLUMN stock_unit VARCHAR(16) DEFAULT NULL AFTER variant_attributes_json",
        ];
        foreach ($orderItemColumns as $columnName => $sql) {
            if (!columnExists('order_items', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('item_attributes')) {
        $con->exec("CREATE TABLE item_attributes (
            attribute_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            item_id INT NOT NULL,
            name_ar VARCHAR(100) NOT NULL,
            name_en VARCHAR(100) NOT NULL,
            sort_order INT NOT NULL DEFAULT 0,
            is_required TINYINT(1) NOT NULL DEFAULT 0,
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            INDEX idx_item_attributes_item (item_id),
            CONSTRAINT fk_item_attributes_item FOREIGN KEY (item_id) REFERENCES items(items_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    }
    if (!tableExists('item_attribute_values')) {
        $con->exec("CREATE TABLE item_attribute_values (
            value_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            attribute_id INT NOT NULL,
            value_ar VARCHAR(100) NOT NULL,
            value_en VARCHAR(100) NOT NULL,
            sort_order INT NOT NULL DEFAULT 0,
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            INDEX idx_attribute_values_attribute (attribute_id),
            CONSTRAINT fk_attribute_values_attribute FOREIGN KEY (attribute_id) REFERENCES item_attributes(attribute_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    }
    if (!tableExists('item_variant_values')) {
        $con->exec("CREATE TABLE item_variant_values (
            variant_id INT NOT NULL,
            value_id INT NOT NULL,
            PRIMARY KEY (variant_id, value_id),
            CONSTRAINT fk_variant_values_variant FOREIGN KEY (variant_id) REFERENCES item_variants(variant_id) ON DELETE CASCADE,
            CONSTRAINT fk_variant_values_value FOREIGN KEY (value_id) REFERENCES item_attribute_values(value_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    }
    if (!tableExists('food_item_modifier_groups')) {
        $con->exec("
            CREATE TABLE food_item_modifier_groups (
                group_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                item_id INT NOT NULL,
                name_ar VARCHAR(150) NOT NULL,
                name_en VARCHAR(150) NOT NULL,
                group_type VARCHAR(24) NOT NULL DEFAULT 'modifier',
                min_select INT NOT NULL DEFAULT 0,
                max_select INT NOT NULL DEFAULT 1,
                is_required TINYINT(1) NOT NULL DEFAULT 0,
                sort_order INT NOT NULL DEFAULT 0,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_food_modifier_groups_item (item_id),
                CONSTRAINT fk_food_modifier_groups_item
                    FOREIGN KEY (item_id) REFERENCES items(items_id)
                    ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (!columnExists('food_item_modifier_groups', 'group_type')) {
        $con->exec("ALTER TABLE food_item_modifier_groups ADD COLUMN group_type VARCHAR(24) NOT NULL DEFAULT 'modifier' AFTER name_en");
    }
    if (!tableExists('food_item_modifiers')) {
        $con->exec("
            CREATE TABLE food_item_modifiers (
                modifier_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                group_id INT NOT NULL,
                name_ar VARCHAR(150) NOT NULL,
                name_en VARCHAR(150) NOT NULL,
                image_url TEXT DEFAULT NULL,
                price_delta DECIMAL(10,2) NOT NULL DEFAULT 0,
                is_default_selected TINYINT(1) NOT NULL DEFAULT 0,
                is_removable TINYINT(1) NOT NULL DEFAULT 1,
                sort_order INT NOT NULL DEFAULT 0,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_food_modifiers_group (group_id),
                CONSTRAINT fk_food_modifiers_group
                    FOREIGN KEY (group_id) REFERENCES food_item_modifier_groups(group_id)
                    ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    }
    if (!columnExists('food_item_modifiers', 'image_url')) {
        $con->exec("ALTER TABLE food_item_modifiers ADD COLUMN image_url TEXT DEFAULT NULL AFTER name_en");
    }
    if (!columnExists('food_item_modifiers', 'is_default_selected')) {
        $con->exec("ALTER TABLE food_item_modifiers ADD COLUMN is_default_selected TINYINT(1) NOT NULL DEFAULT 0 AFTER price_delta");
    }
    if (!columnExists('food_item_modifiers', 'is_removable')) {
        $con->exec("ALTER TABLE food_item_modifiers ADD COLUMN is_removable TINYINT(1) NOT NULL DEFAULT 1 AFTER is_default_selected");
    }
    $schemaReady = true;
}
function ensureAleppoOrderExperienceSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    $orderColumns = [
        "orders_recipient_label" => "ALTER TABLE orders ADD COLUMN orders_recipient_label VARCHAR(120) DEFAULT NULL AFTER orders_address",
        "orders_recipient_name" => "ALTER TABLE orders ADD COLUMN orders_recipient_name VARCHAR(191) DEFAULT NULL AFTER orders_recipient_label",
        "orders_recipient_phone" => "ALTER TABLE orders ADD COLUMN orders_recipient_phone VARCHAR(32) DEFAULT NULL AFTER orders_recipient_name",
        "orders_recipient_address_name" => "ALTER TABLE orders ADD COLUMN orders_recipient_address_name VARCHAR(191) DEFAULT NULL AFTER orders_recipient_phone",
        "orders_recipient_address_line" => "ALTER TABLE orders ADD COLUMN orders_recipient_address_line TEXT DEFAULT NULL AFTER orders_recipient_address_name",
        "orders_recipient_location_note" => "ALTER TABLE orders ADD COLUMN orders_recipient_location_note TEXT DEFAULT NULL AFTER orders_recipient_address_line",
        "orders_recipient_building" => "ALTER TABLE orders ADD COLUMN orders_recipient_building VARCHAR(120) DEFAULT NULL AFTER orders_recipient_location_note",
        "orders_recipient_floor" => "ALTER TABLE orders ADD COLUMN orders_recipient_floor VARCHAR(64) DEFAULT NULL AFTER orders_recipient_building",
        "orders_recipient_lat" => "ALTER TABLE orders ADD COLUMN orders_recipient_lat DECIMAL(10,7) DEFAULT NULL AFTER orders_recipient_floor",
        "orders_recipient_lng" => "ALTER TABLE orders ADD COLUMN orders_recipient_lng DECIMAL(10,7) DEFAULT NULL AFTER orders_recipient_lat",
        "delivery_latitude" => "ALTER TABLE orders ADD COLUMN delivery_latitude DECIMAL(10,7) DEFAULT NULL AFTER orders_recipient_lng",
        "delivery_longitude" => "ALTER TABLE orders ADD COLUMN delivery_longitude DECIMAL(10,7) DEFAULT NULL AFTER delivery_latitude",
        "delivery_address" => "ALTER TABLE orders ADD COLUMN delivery_address TEXT DEFAULT NULL AFTER delivery_longitude",
        "orders_gift_message" => "ALTER TABLE orders ADD COLUMN orders_gift_message TEXT DEFAULT NULL AFTER delivery_address",
        "orders_delivery_note" => "ALTER TABLE orders ADD COLUMN orders_delivery_note TEXT DEFAULT NULL AFTER orders_gift_message",
        "orders_rejection_reason" => "ALTER TABLE orders ADD COLUMN orders_rejection_reason TEXT DEFAULT NULL AFTER orders_delivery_note",
        "orders_share_token" => "ALTER TABLE orders ADD COLUMN orders_share_token VARCHAR(80) DEFAULT NULL AFTER orders_delivery_note",
        "order_mode" => "ALTER TABLE orders ADD COLUMN order_mode VARCHAR(16) NOT NULL DEFAULT 'asap' AFTER orders_share_token",
        "scheduled_for" => "ALTER TABLE orders ADD COLUMN scheduled_for DATETIME DEFAULT NULL AFTER order_mode",
        "orders_estimated_minutes" => "ALTER TABLE orders ADD COLUMN orders_estimated_minutes INT NOT NULL DEFAULT 45 AFTER scheduled_for",
        "delivery_code" => "ALTER TABLE orders ADD COLUMN delivery_code VARCHAR(16) DEFAULT NULL AFTER orders_estimated_minutes",
        "payment_method" => "ALTER TABLE orders ADD COLUMN payment_method VARCHAR(64) DEFAULT NULL AFTER orders_paymentmethod",
        "paid_amount" => "ALTER TABLE orders ADD COLUMN paid_amount DECIMAL(12,2) NOT NULL DEFAULT 0 AFTER payment_method",
        "transaction_id" => "ALTER TABLE orders ADD COLUMN transaction_id VARCHAR(191) DEFAULT NULL AFTER paid_amount",
        "orders_gateway_ref" => "ALTER TABLE orders ADD COLUMN orders_gateway_ref VARCHAR(191) DEFAULT NULL AFTER transaction_id",
    ];
    foreach ($orderColumns as $columnName => $sql) {
        if (!columnExists('orders', $columnName)) {
            $con->exec($sql);
        }
    }
    $statusLengthStmt = $con->prepare("
        SELECT CHARACTER_MAXIMUM_LENGTH
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'orders'
          AND COLUMN_NAME = 'status'
        LIMIT 1
    ");
    $statusLengthStmt->execute();
    $statusLength = (int)$statusLengthStmt->fetchColumn();
    if ($statusLength > 0 && $statusLength < 50) {
        $con->exec("ALTER TABLE orders MODIFY COLUMN status VARCHAR(50) DEFAULT 'new'");
    }
    $legacyStatuses = [
        'heading_to_restauran' => 'heading_to_restaurant',
        'arrived_at_restauran' => 'arrived_at_restaurant',
    ];
    foreach ($legacyStatuses as $fromStatus => $toStatus) {
        $stmt = $con->prepare("UPDATE orders SET status = ? WHERE status = ?");
        $stmt->execute([$toStatus, $fromStatus]);
    }
    $trackingColumns = [
        "route_distance_km" => "ALTER TABLE delivery_order_tracking ADD COLUMN route_distance_km DECIMAL(10,2) DEFAULT NULL AFTER share_path",
    ];
    foreach ($trackingColumns as $columnName => $sql) {
        if (!columnExists('delivery_order_tracking', $columnName)) {
            $con->exec($sql);
        }
    }
    $orderItemColumns = [
        "food_item_note" => "ALTER TABLE order_items ADD COLUMN food_item_note TEXT DEFAULT NULL AFTER prescription_summary",
        "food_menu_options_json" => "ALTER TABLE order_items ADD COLUMN food_menu_options_json LONGTEXT DEFAULT NULL AFTER food_item_note",
        "food_menu_options_summary" => "ALTER TABLE order_items ADD COLUMN food_menu_options_summary TEXT DEFAULT NULL AFTER food_menu_options_json",
    ];
    foreach ($orderItemColumns as $columnName => $sql) {
        if (!columnExists('order_items', $columnName)) {
            $con->exec($sql);
        }
    }
    $schemaReady = true;
}
function ensureVendorStoreSettingsSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('vendor_store_settings')) {
        $con->exec("
            CREATE TABLE vendor_store_settings (
                vendor_id INT(11) NOT NULL,
                store_name VARCHAR(255) NOT NULL DEFAULT '',
                store_slug VARCHAR(255) NOT NULL DEFAULT '',
                vendor_name VARCHAR(255) NOT NULL DEFAULT '',
                vendor_email VARCHAR(255) NOT NULL DEFAULT '',
                vendor_phone VARCHAR(30) DEFAULT NULL,
                vendor_logo VARCHAR(255) DEFAULT NULL,
                vendor_description TEXT DEFAULT NULL,
                store_banner_url VARCHAR(255) DEFAULT NULL,
                store_address TEXT DEFAULT NULL,
                coverage_km DECIMAL(6,2) DEFAULT NULL,
                coverage_area VARCHAR(255) DEFAULT NULL,
                store_latitude DECIMAL(10,7) DEFAULT NULL,
                store_longitude DECIMAL(10,7) DEFAULT NULL,
                minimum_order DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                language_code VARCHAR(8) NOT NULL DEFAULT 'ar',
                is_open TINYINT(1) NOT NULL DEFAULT 1,
                accepts_preorders TINYINT(1) NOT NULL DEFAULT 1,
                preorder_days_limit INT(11) NOT NULL DEFAULT 7,
                notifications_enabled TINYINT(1) NOT NULL DEFAULT 1,
                temporary_closed_reason VARCHAR(255) DEFAULT NULL,
                restaurant_working_hours_json LONGTEXT DEFAULT NULL,
                working_hours_json LONGTEXT DEFAULT NULL,
                profile_settings_json LONGTEXT DEFAULT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (vendor_id),
                CONSTRAINT fk_vendor_store_settings_vendor
                    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
                    ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $settingsColumns = [
            "store_name" => "ALTER TABLE vendor_store_settings ADD COLUMN store_name VARCHAR(255) NOT NULL DEFAULT '' AFTER vendor_id",
            "store_slug" => "ALTER TABLE vendor_store_settings ADD COLUMN store_slug VARCHAR(255) NOT NULL DEFAULT '' AFTER store_name",
            "vendor_name" => "ALTER TABLE vendor_store_settings ADD COLUMN vendor_name VARCHAR(255) NOT NULL DEFAULT '' AFTER store_slug",
            "vendor_email" => "ALTER TABLE vendor_store_settings ADD COLUMN vendor_email VARCHAR(255) NOT NULL DEFAULT '' AFTER vendor_name",
            "vendor_phone" => "ALTER TABLE vendor_store_settings ADD COLUMN vendor_phone VARCHAR(30) DEFAULT NULL AFTER vendor_email",
            "vendor_logo" => "ALTER TABLE vendor_store_settings ADD COLUMN vendor_logo VARCHAR(255) DEFAULT NULL AFTER vendor_phone",
            "vendor_description" => "ALTER TABLE vendor_store_settings ADD COLUMN vendor_description TEXT DEFAULT NULL AFTER vendor_logo",
            "store_banner_url" => "ALTER TABLE vendor_store_settings ADD COLUMN store_banner_url VARCHAR(255) DEFAULT NULL AFTER vendor_description",
            "store_address" => "ALTER TABLE vendor_store_settings ADD COLUMN store_address TEXT DEFAULT NULL AFTER store_banner_url",
            "coverage_km" => "ALTER TABLE vendor_store_settings ADD COLUMN coverage_km DECIMAL(6,2) DEFAULT NULL AFTER store_address",
            "coverage_area" => "ALTER TABLE vendor_store_settings ADD COLUMN coverage_area VARCHAR(255) DEFAULT NULL AFTER coverage_km",
            "store_latitude" => "ALTER TABLE vendor_store_settings ADD COLUMN store_latitude DECIMAL(10,7) DEFAULT NULL AFTER coverage_area",
            "store_longitude" => "ALTER TABLE vendor_store_settings ADD COLUMN store_longitude DECIMAL(10,7) DEFAULT NULL AFTER store_latitude",
            "minimum_order" => "ALTER TABLE vendor_store_settings ADD COLUMN minimum_order DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER store_longitude",
            "language_code" => "ALTER TABLE vendor_store_settings ADD COLUMN language_code VARCHAR(8) NOT NULL DEFAULT 'ar' AFTER minimum_order",
            "is_open" => "ALTER TABLE vendor_store_settings ADD COLUMN is_open TINYINT(1) NOT NULL DEFAULT 1 AFTER language_code",
            "accepts_preorders" => "ALTER TABLE vendor_store_settings ADD COLUMN accepts_preorders TINYINT(1) NOT NULL DEFAULT 1 AFTER is_open",
            "preorder_days_limit" => "ALTER TABLE vendor_store_settings ADD COLUMN preorder_days_limit INT(11) NOT NULL DEFAULT 7 AFTER accepts_preorders",
            "notifications_enabled" => "ALTER TABLE vendor_store_settings ADD COLUMN notifications_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER preorder_days_limit",
            "temporary_closed_reason" => "ALTER TABLE vendor_store_settings ADD COLUMN temporary_closed_reason VARCHAR(255) DEFAULT NULL AFTER notifications_enabled",
            "restaurant_working_hours_json" => "ALTER TABLE vendor_store_settings ADD COLUMN restaurant_working_hours_json LONGTEXT DEFAULT NULL AFTER temporary_closed_reason",
            "working_hours_json" => "ALTER TABLE vendor_store_settings ADD COLUMN working_hours_json LONGTEXT DEFAULT NULL AFTER restaurant_working_hours_json",
            "profile_settings_json" => "ALTER TABLE vendor_store_settings ADD COLUMN profile_settings_json LONGTEXT DEFAULT NULL AFTER working_hours_json",
            "currency_code" => "ALTER TABLE vendor_store_settings ADD COLUMN currency_code VARCHAR(10) NOT NULL DEFAULT 'SAR' AFTER working_hours_json",
            "currency_symbol" => "ALTER TABLE vendor_store_settings ADD COLUMN currency_symbol VARCHAR(10) NOT NULL DEFAULT 'ر.س' AFTER currency_code",
            "currency_name" => "ALTER TABLE vendor_store_settings ADD COLUMN currency_name VARCHAR(50) NOT NULL DEFAULT 'الريال السعودي' AFTER currency_symbol",
        ];
        foreach ($settingsColumns as $columnName => $sql) {
            if (!columnExists('vendor_store_settings', $columnName)) {
                $con->exec($sql);
            }
        }
        // Store currency metadata is retained as saved. Platform-wide currency
        // consumers should read platform_settings instead of rewriting stores.
    }
    $schemaReady = true;
}
function ensurePlatformSettingsSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('platform_settings')) {
        $con->exec("
            CREATE TABLE platform_settings (
                id INT(11) NOT NULL DEFAULT 1,
                default_currency_code VARCHAR(10) NOT NULL DEFAULT 'SAR',
                default_currency_symbol VARCHAR(10) NOT NULL DEFAULT 'ر.س',
                default_currency_name VARCHAR(50) NOT NULL DEFAULT 'الريال السعودي',
                default_currency_name_en VARCHAR(80) NOT NULL DEFAULT 'Saudi Riyal',
                platform_commission_percent DECIMAL(5,2) NOT NULL DEFAULT 15.00,
                delivery_base_fee DECIMAL(10,2) NOT NULL DEFAULT 10.00,
                delivery_cost_per_km DECIMAL(10,2) NOT NULL DEFAULT 2.50,
                max_delivery_distance_km DECIMAL(10,2) NOT NULL DEFAULT 25.00,
                min_vendor_payout DECIMAL(10,2) NOT NULL DEFAULT 500.00,
                support_phone VARCHAR(30) DEFAULT NULL,
                support_email VARCHAR(255) DEFAULT NULL,
                platform_name_ar VARCHAR(255) NOT NULL DEFAULT 'منصة سفير',
                platform_name_en VARCHAR(255) NOT NULL DEFAULT 'Savir Platform',
                platform_timezone VARCHAR(64) NOT NULL DEFAULT 'Africa/Cairo',
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
        $con->exec("
            INSERT IGNORE INTO platform_settings (id) VALUES (1)
        ");
    } else {
        $settingsColumns = [
            "default_currency_code" => "ALTER TABLE platform_settings ADD COLUMN default_currency_code VARCHAR(10) NOT NULL DEFAULT 'SAR'",
            "default_currency_symbol" => "ALTER TABLE platform_settings ADD COLUMN default_currency_symbol VARCHAR(10) NOT NULL DEFAULT 'ر.س'",
            "default_currency_name" => "ALTER TABLE platform_settings ADD COLUMN default_currency_name VARCHAR(50) NOT NULL DEFAULT 'الريال السعودي'",
            "default_currency_name_en" => "ALTER TABLE platform_settings ADD COLUMN default_currency_name_en VARCHAR(80) NOT NULL DEFAULT 'Saudi Riyal'",
            "platform_commission_percent" => "ALTER TABLE platform_settings ADD COLUMN platform_commission_percent DECIMAL(5,2) NOT NULL DEFAULT 15.00",
            "delivery_base_fee" => "ALTER TABLE platform_settings ADD COLUMN delivery_base_fee DECIMAL(10,2) NOT NULL DEFAULT 10.00",
            "delivery_cost_per_km" => "ALTER TABLE platform_settings ADD COLUMN delivery_cost_per_km DECIMAL(10,2) NOT NULL DEFAULT 2.50",
            "max_delivery_distance_km" => "ALTER TABLE platform_settings ADD COLUMN max_delivery_distance_km DECIMAL(10,2) NOT NULL DEFAULT 25.00",
            "min_vendor_payout" => "ALTER TABLE platform_settings ADD COLUMN min_vendor_payout DECIMAL(10,2) NOT NULL DEFAULT 500.00",
            "support_phone" => "ALTER TABLE platform_settings ADD COLUMN support_phone VARCHAR(30) DEFAULT NULL",
            "support_email" => "ALTER TABLE platform_settings ADD COLUMN support_email VARCHAR(255) DEFAULT NULL",
            "platform_name_ar" => "ALTER TABLE platform_settings ADD COLUMN platform_name_ar VARCHAR(255) NOT NULL DEFAULT 'منصة سفير'",
            "platform_name_en" => "ALTER TABLE platform_settings ADD COLUMN platform_name_en VARCHAR(255) NOT NULL DEFAULT 'Savir Platform'",
            "platform_timezone" => "ALTER TABLE platform_settings ADD COLUMN platform_timezone VARCHAR(64) NOT NULL DEFAULT 'Africa/Cairo' AFTER platform_name_en",
        ];
        foreach ($settingsColumns as $columnName => $sql) {
            if (!columnExists('platform_settings', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    // Existing installations may still contain the old currency defaults.
    // Switch the currency metadata only; stored numeric prices are unchanged.
    // Do not rewrite an administrator-selected currency on every request.
    // Existing installations are migrated separately; platform settings must
    // remain exactly as saved from the Master dashboard.
    $schemaReady = true;
}
function getPlatformTimezoneIdentifier(): string
{
    global $con;
    $fallback = 'Africa/Cairo';
    try {
        ensurePlatformSettingsSchema();
        $stmt = $con->query("SELECT platform_timezone FROM platform_settings WHERE id = 1 LIMIT 1");
        $value = trim((string)($stmt ? $stmt->fetchColumn() : ''));
        if ($value !== '' && in_array($value, DateTimeZone::listIdentifiers(), true)) {
            return $value;
        }
    } catch (Throwable $error) {
        error_log('Platform timezone lookup failed: ' . $error->getMessage());
    }
    return $fallback;
}
function applyPlatformTimezone(): string
{
    global $con;
    $timezone = getPlatformTimezoneIdentifier();
    date_default_timezone_set($timezone);
    // Keep SQL NOW()/CURRENT_TIMESTAMP aligned with PHP. MySQL installations
    // often run in UTC and may not have the IANA timezone tables installed.
    try {
        $offset = (new DateTimeImmutable('now', new DateTimeZone($timezone)))->format('P');
        if (preg_match('/^[+-]\d{2}:\d{2}$/', $offset)) {
            $con->exec("SET time_zone = '" . $offset . "'");
        }
    } catch (Throwable $error) {
        error_log('Platform SQL timezone setup failed: ' . $error->getMessage());
    }
    return $timezone;
}
function getPlatformCurrencySettings(): array
{
    global $con;
    static $currency = null;
    if (is_array($currency)) {
        return $currency;
    }

    $currency = [
        'currency_code' => 'SAR',
        'currency_symbol' => 'ر.س',
        'currency_name' => 'الريال السعودي',
        'currency_name_en' => 'Saudi Riyal',
    ];
    try {
        ensurePlatformSettingsSchema();
        $stmt = $con->query("SELECT default_currency_code, default_currency_symbol,
            default_currency_name, default_currency_name_en
            FROM platform_settings WHERE id = 1 LIMIT 1");
        $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : false;
        if (is_array($row)) {
            foreach ([
                'currency_code' => 'default_currency_code',
                'currency_symbol' => 'default_currency_symbol',
                'currency_name' => 'default_currency_name',
                'currency_name_en' => 'default_currency_name_en',
            ] as $key => $column) {
                $value = trim((string)($row[$column] ?? ''));
                if ($value !== '') {
                    $currency[$key] = $value;
                }
            }
        }
    } catch (Throwable $error) {
        error_log('Platform currency lookup failed: ' . $error->getMessage());
    }
    return $currency;
}
function ensureRestaurantHoursSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('restaurant_hours')) {
        $con->exec("
            CREATE TABLE restaurant_hours (
                hour_id INT(11) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL,
                day_key VARCHAR(16) NOT NULL,
                is_open TINYINT(1) NOT NULL DEFAULT 1,
                opens_at TIME DEFAULT NULL,
                closes_at TIME DEFAULT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (hour_id),
                UNIQUE KEY uniq_restaurant_hours_vendor_day (vendor_id, day_key),
                KEY idx_restaurant_hours_vendor (vendor_id),
                CONSTRAINT fk_restaurant_hours_vendor
                    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
                    ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $hoursColumns = [
            "vendor_id" => "ALTER TABLE restaurant_hours ADD COLUMN vendor_id INT(11) NOT NULL AFTER hour_id",
            "day_key" => "ALTER TABLE restaurant_hours ADD COLUMN day_key VARCHAR(16) NOT NULL AFTER vendor_id",
            "is_open" => "ALTER TABLE restaurant_hours ADD COLUMN is_open TINYINT(1) NOT NULL DEFAULT 1 AFTER day_key",
            "opens_at" => "ALTER TABLE restaurant_hours ADD COLUMN opens_at TIME DEFAULT NULL AFTER is_open",
            "closes_at" => "ALTER TABLE restaurant_hours ADD COLUMN closes_at TIME DEFAULT NULL AFTER opens_at",
            "is_active" => "ALTER TABLE restaurant_hours ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER closes_at",
        ];
        foreach ($hoursColumns as $columnName => $sql) {
            if (!columnExists('restaurant_hours', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    $schemaReady = true;
}
function deliveryWorkingHoursDayLabel($dayKey, $localeCode = 'ar')
{
    $normalized = strtolower(trim((string)$dayKey));
    $english = strtolower(trim((string)$localeCode)) === 'en';
    switch ($normalized) {
        case 'mon':
            return $english ? 'Monday' : 'الاثنين';
        case 'tue':
            return $english ? 'Tuesday' : 'الثلاثاء';
        case 'wed':
            return $english ? 'Wednesday' : 'الأربعاء';
        case 'thu':
            return $english ? 'Thursday' : 'الخميس';
        case 'fri':
            return $english ? 'Friday' : 'الجمعة';
        case 'sat':
            return $english ? 'Saturday' : 'السبت';
        case 'sun':
            return $english ? 'Sunday' : 'الأحد';
        default:
            return $normalized;
    }
}
function deliveryWorkingHoursDefaultRows()
{
    return [
        ['day_key' => 'mon', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 1],
        ['day_key' => 'tue', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 2],
        ['day_key' => 'wed', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 3],
        ['day_key' => 'thu', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 4],
        ['day_key' => 'fri', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 5],
        ['day_key' => 'sat', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 6],
        ['day_key' => 'sun', 'is_open' => 1, 'opens_at' => '00:00:00', 'closes_at' => '23:59:59', 'sort_order' => 7],
    ];
}
function deliveryWorkingHoursFormatTimeForResponse($value)
{
    $time = normalizeWorkingHoursTimeValue($value);
    if ($time === null) {
        return null;
    }
    return substr($time, 0, 5);
}
function deliveryWorkingHoursRowsFromPayload($value)
{
    $rowsByKey = workingHoursRowsByDayKey($value);
    $normalizedRows = [];
    foreach (deliveryWorkingHoursDefaultRows() as $defaultRow) {
        $dayKey = $defaultRow['day_key'];
        $row = $rowsByKey[$dayKey] ?? $defaultRow;
        $normalizedRows[] = [
            'day_key' => $dayKey,
            'is_open' => normalizeWorkingHoursBoolValue($row['is_open'] ?? 1, 1),
            'opens_at' => normalizeWorkingHoursTimeValue($row['opens_at'] ?? $row['open_time'] ?? $defaultRow['opens_at']),
            'closes_at' => normalizeWorkingHoursTimeValue($row['closes_at'] ?? $row['close_time'] ?? $defaultRow['closes_at']),
            'sort_order' => (int)($row['sort_order'] ?? $defaultRow['sort_order']),
        ];
    }
    usort($normalizedRows, function (array $a, array $b) {
        return ((int)$a['sort_order']) <=> ((int)$b['sort_order']);
    });
    return $normalizedRows;
}
function deliveryWorkingHoursRowsToResponse(array $rows, $localeCode = 'ar')
{
    $responseRows = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $dayKey = strtolower(trim((string)($row['day_key'] ?? '')));
        if ($dayKey === '') {
            continue;
        }
        $responseRows[] = [
            'day_key' => $dayKey,
            'day_label' => deliveryWorkingHoursDayLabel($dayKey, $localeCode),
            'is_open' => normalizeWorkingHoursBoolValue($row['is_open'] ?? 1, 1),
            'open_time' => deliveryWorkingHoursFormatTimeForResponse($row['opens_at'] ?? $row['open_time'] ?? null),
            'close_time' => deliveryWorkingHoursFormatTimeForResponse($row['closes_at'] ?? $row['close_time'] ?? null),
            'sort_order' => (int)($row['sort_order'] ?? 0),
        ];
    }
    usort($responseRows, function (array $a, array $b) {
        $compare = ((int)$a['sort_order']) <=> ((int)$b['sort_order']);
        if ($compare !== 0) {
            return $compare;
        }
        return strcmp($a['day_key'], $b['day_key']);
    });
    return $responseRows;
}
function ensureDeliveryWorkingHoursSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('delivery_working_hours')) {
        $con->exec("
            CREATE TABLE delivery_working_hours (
                hour_id INT(11) NOT NULL AUTO_INCREMENT,
                day_key VARCHAR(16) NOT NULL,
                is_open TINYINT(1) NOT NULL DEFAULT 1,
                opens_at TIME DEFAULT NULL,
                closes_at TIME DEFAULT NULL,
                sort_order INT(11) NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (hour_id),
                UNIQUE KEY uniq_delivery_working_hours_day (day_key),
                KEY idx_delivery_working_hours_sort_order (sort_order)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $hoursColumns = [
            "day_key" => "ALTER TABLE delivery_working_hours ADD COLUMN day_key VARCHAR(16) NOT NULL AFTER hour_id",
            "is_open" => "ALTER TABLE delivery_working_hours ADD COLUMN is_open TINYINT(1) NOT NULL DEFAULT 1 AFTER day_key",
            "opens_at" => "ALTER TABLE delivery_working_hours ADD COLUMN opens_at TIME DEFAULT NULL AFTER is_open",
            "closes_at" => "ALTER TABLE delivery_working_hours ADD COLUMN closes_at TIME DEFAULT NULL AFTER opens_at",
            "sort_order" => "ALTER TABLE delivery_working_hours ADD COLUMN sort_order INT(11) NOT NULL DEFAULT 0 AFTER closes_at",
        ];
        foreach ($hoursColumns as $columnName => $sql) {
            if (!columnExists('delivery_working_hours', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    $existingCount = 0;
    try {
        $existingCount = (int)$con->query("SELECT COUNT(*) FROM delivery_working_hours")->fetchColumn();
    } catch (Throwable $countError) {
        error_log('delivery_working_hours seed check failed: ' . $countError->getMessage());
    }
    if ($existingCount === 0) {
        $seedStmt = $con->prepare("
            INSERT INTO delivery_working_hours (
                day_key,
                is_open,
                opens_at,
                closes_at,
                sort_order
            ) VALUES (
                :day_key,
                :is_open,
                :opens_at,
                :closes_at,
                :sort_order
            )
        ");
        foreach (deliveryWorkingHoursDefaultRows() as $row) {
            $seedStmt->execute([
                ':day_key' => $row['day_key'],
                ':is_open' => (int)$row['is_open'],
                ':opens_at' => $row['opens_at'],
                ':closes_at' => $row['closes_at'],
                ':sort_order' => (int)$row['sort_order'],
            ]);
        }
    }
    $schemaReady = true;
}
function fetchDeliveryWorkingHoursRows()
{
    global $con;
    $stmt = $con->query("
        SELECT
            day_key,
            is_open,
            opens_at,
            closes_at,
            sort_order
        FROM delivery_working_hours
        ORDER BY sort_order ASC, hour_id ASC
    ");
    $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    if (!is_array($rows) || empty($rows)) {
        return deliveryWorkingHoursDefaultRows();
    }
    return $rows;
}
function replaceDeliveryWorkingHoursRows($value)
{
    global $con;
    $rows = deliveryWorkingHoursRowsFromPayload($value);
    $con->beginTransaction();
    try {
        $con->exec("DELETE FROM delivery_working_hours");
        $stmt = $con->prepare("
            INSERT INTO delivery_working_hours (
                day_key,
                is_open,
                opens_at,
                closes_at,
                sort_order
            ) VALUES (
                :day_key,
                :is_open,
                :opens_at,
                :closes_at,
                :sort_order
            )
        ");
        foreach ($rows as $row) {
            $stmt->execute([
                ':day_key' => $row['day_key'],
                ':is_open' => (int)$row['is_open'],
                ':opens_at' => $row['opens_at'],
                ':closes_at' => $row['closes_at'],
                ':sort_order' => (int)$row['sort_order'],
            ]);
        }
        $con->commit();
    } catch (Throwable $e) {
        if ($con->inTransaction()) {
            $con->rollBack();
        }
        throw $e;
    }
    return $rows;
}
function normalizeWorkingHoursTimeValue($value)
{
    $time = trim((string)$value);
    if ($time === '') {
        return null;
    }
    if (preg_match('/^\d{1,2}:\d{2}$/', $time)) {
        return $time . ':00';
    }
    if (preg_match('/^\d{1,2}:\d{2}:\d{2}$/', $time)) {
        return $time;
    }
    $timestamp = strtotime($time);
    if ($timestamp === false) {
        return null;
    }
    return date('H:i:s', $timestamp);
}
function normalizeWorkingHoursBoolValue($value, $default = 1)
{
    if ($value === null) {
        return $default ? 1 : 0;
    }
    if (is_bool($value)) {
        return $value ? 1 : 0;
    }
    if (is_numeric($value)) {
        return (int)$value === 1 ? 1 : 0;
    }
    $normalized = strtolower(trim((string)$value));
    if ($normalized === '') {
        return $default ? 1 : 0;
    }
    return in_array($normalized, ['1', 'true', 'yes', 'on'], true) ? 1 : 0;
}
function parseWorkingHoursPayload($value)
{
    if (is_array($value)) {
        $rows = $value;
    } elseif (is_string($value) && trim($value) !== '') {
        $decoded = json_decode($value, true);
        $rows = is_array($decoded) ? $decoded : [];
    } else {
        $rows = [];
    }
    return array_values(array_filter($rows, function ($row) {
        return is_array($row);
    }));
}
function workingHoursRowsFromPayload($value, $vendorId = null)
{
    $rows = [];
    foreach (parseWorkingHoursPayload($value) as $row) {
        $dayKey = strtolower(trim((string)($row['day_key'] ?? $row['dayKey'] ?? '')));
        if ($dayKey === '') {
            continue;
        }
        $normalized = [
            'day_key' => $dayKey,
            'is_open' => normalizeWorkingHoursBoolValue($row['is_open'] ?? $row['isOpen'] ?? 1, 1),
            'opens_at' => normalizeWorkingHoursTimeValue($row['opens_at'] ?? $row['open_time'] ?? $row['openAt'] ?? null),
            'closes_at' => normalizeWorkingHoursTimeValue($row['closes_at'] ?? $row['close_time'] ?? $row['closeAt'] ?? null),
        ];
        if ($vendorId !== null) {
            $normalized['vendor_id'] = (int)$vendorId;
        }
        $rows[] = $normalized;
    }
    return $rows;
}
function workingHoursRowsByDayKey(array $rows)
{
    $map = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $dayKey = strtolower(trim((string)($row['day_key'] ?? '')));
        if ($dayKey === '') {
            continue;
        }
        $map[$dayKey] = [
            'day_key' => $dayKey,
            'is_open' => normalizeWorkingHoursBoolValue($row['is_open'] ?? 1, 1),
            'opens_at' => normalizeWorkingHoursTimeValue($row['opens_at'] ?? $row['open_time'] ?? null),
            'closes_at' => normalizeWorkingHoursTimeValue($row['closes_at'] ?? $row['close_time'] ?? null),
        ];
    }
    return $map;
}
function workingHoursDayKeyCandidates($timestamp)
{
    $timestamp = (int)$timestamp;
    $index = (int)date('N', $timestamp);
    $map = [
        1 => ['mon', 'monday'],
        2 => ['tue', 'tuesday'],
        3 => ['wed', 'wednesday'],
        4 => ['thu', 'thursday'],
        5 => ['fri', 'friday'],
        6 => ['sat', 'saturday'],
        7 => ['sun', 'sunday'],
    ];
    return $map[$index] ?? ['mon', 'monday'];
}
function workingHoursRowMatchesTimestamp(array $row, $timestamp, $anchor = 'same_day')
{
    if (normalizeWorkingHoursBoolValue($row['is_open'] ?? 1, 1) !== 1) {
        return false;
    }
    $opensAt = normalizeWorkingHoursTimeValue($row['opens_at'] ?? $row['open_time'] ?? null);
    $closesAt = normalizeWorkingHoursTimeValue($row['closes_at'] ?? $row['close_time'] ?? null);
    if ($opensAt === null || $closesAt === null) {
        return true;
    }
    $timestamp = (int)$timestamp;
    $baseTimestamp = $anchor === 'previous_day'
        ? strtotime('-1 day', $timestamp)
        : $timestamp;
    if ($baseTimestamp === false) {
        return true;
    }
    $baseDate = date('Y-m-d', $baseTimestamp);
    $openTs = strtotime($baseDate . ' ' . $opensAt);
    $closeTs = strtotime($baseDate . ' ' . $closesAt);
    if ($openTs === false || $closeTs === false) {
        return true;
    }
    if ($closeTs < $openTs) {
        $closeTs = strtotime('+1 day', $closeTs);
    }
    return $timestamp >= $openTs && $timestamp <= $closeTs;
}
function workingHoursMapAllowsTimestamp(array $hoursMap, $timestamp)
{
    if (empty($hoursMap)) {
        return true;
    }
    $timestamp = (int)$timestamp;
    foreach (workingHoursDayKeyCandidates($timestamp) as $dayKey) {
        if (isset($hoursMap[$dayKey]) &&
            workingHoursRowMatchesTimestamp($hoursMap[$dayKey], $timestamp, 'same_day')) {
            return true;
        }
    }
    $previousTimestamp = strtotime('-1 day', $timestamp);
    if ($previousTimestamp !== false) {
        foreach (workingHoursDayKeyCandidates($previousTimestamp) as $dayKey) {
            if (isset($hoursMap[$dayKey]) &&
                workingHoursRowMatchesTimestamp($hoursMap[$dayKey], $timestamp, 'previous_day')) {
                return true;
            }
        }
    }
    return false;
}
function restaurantOpenFromSchedule(array $restaurant, array $hoursMap, $timestamp = null)
{
    $timestamp = $timestamp ?? time();
    $manualOverride = $restaurant['manual_open_override'] ?? null;
    if ($manualOverride !== null && $manualOverride !== '') {
        return (int)$manualOverride === 1;
    }
    if (isset($restaurant['store_is_open']) && (int)$restaurant['store_is_open'] === 0) {
        return false;
    }
    return workingHoursMapAllowsTimestamp($hoursMap, $timestamp);
}
function ensureVendorCategorySchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (tableExists('categories') && !columnExists('categories', 'vendor_id')) {
        $con->exec("ALTER TABLE categories ADD COLUMN vendor_id INT(11) NOT NULL DEFAULT 0 AFTER categories_id");
    }
    if (tableExists('categories') && !columnExists('categories', 'category_type')) {
        $con->exec("ALTER TABLE categories ADD COLUMN category_type VARCHAR(20) NOT NULL DEFAULT 'restaurant' AFTER vendor_id");
    }
    if (tableExists('categories') && !columnExists('categories', 'category_scope')) {
        $con->exec("ALTER TABLE categories ADD COLUMN category_scope VARCHAR(32) NOT NULL DEFAULT 'restaurant' AFTER category_type");
    }
    // Categories are shared across all vendors in the same activity. Do not
    // assign a shared category to the first vendor that uses it.
    if (tableExists('items') && tableExists('vendors') &&
        columnExists('categories', 'category_type') &&
        columnExists('categories', 'category_scope')) {
        $con->exec("UPDATE categories c
            INNER JOIN (
                SELECT i.items_cat,
                       MAX(CASE WHEN LOWER(COALESCE(v.vendor_type, 'restaurant')) = 'store' THEN 1 ELSE 0 END) AS is_store,
                       MIN(CASE WHEN LOWER(COALESCE(v.vendor_type, 'restaurant')) = 'store'
                                THEN COALESCE(NULLIF(v.store_category, ''), 'general')
                                ELSE 'restaurant' END) AS scope_value
                FROM items i
                INNER JOIN vendors v ON v.vendor_id = i.vendor_id
                WHERE i.items_cat IS NOT NULL
                GROUP BY i.items_cat
            ) x ON x.items_cat = c.categories_id
            SET c.category_type = CASE WHEN x.is_store = 1 THEN 'store' ELSE 'restaurant' END,
                c.category_scope = x.scope_value");
    }
    if (columnExists('categories', 'vendor_id')) {
        $con->exec('UPDATE categories SET vendor_id = 0');
    }
    $schemaReady = true;
}
function ensureAccountingVendorSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (tableExists('expenses') && !columnExists('expenses', 'vendor_id')) {
        $con->exec("ALTER TABLE expenses ADD COLUMN vendor_id INT(11) NOT NULL DEFAULT 1 AFTER amount");
    }
    if (tableExists('inventory_waste') && !columnExists('inventory_waste', 'vendor_id')) {
        $con->exec("ALTER TABLE inventory_waste ADD COLUMN vendor_id INT(11) NOT NULL DEFAULT 1 AFTER item_id");
    }
    if (columnExists('expenses', 'vendor_id')) {
      $con->exec("UPDATE expenses SET vendor_id = 1 WHERE vendor_id = 0");
    }
    if (columnExists('inventory_waste', 'vendor_id')) {
      $con->exec("UPDATE inventory_waste SET vendor_id = 1 WHERE vendor_id = 0");
    }
    $schemaReady = true;
}
function parseAds2InternalTargetValue($value)
{
    $value = trim((string) $value);
    if ($value === '') {
        return null;
    }
    if (!preg_match('/^(product|item|restaurant):\s*(\d+)$/i', $value, $matches)) {
        return null;
    }
    $type = strtolower($matches[1]);
    return [
        'type' => $type === 'item' ? 'product' : $type,
        'id' => (int) $matches[2],
    ];
}
function normalizeAds2Targets()
{
    global $con;
    if (!tableExists('ads2') || !columnExists('ads2', 'target_type') || !columnExists('ads2', 'target_id')) {
        return;
    }
    $selectStmt = $con->query("SELECT id, link_url, target_type, target_id FROM ads2");
    if (!$selectStmt) {
        return;
    }
    $updateStmt = $con->prepare("
        UPDATE ads2
        SET target_type = ?, target_id = ?, link_url = ?
        WHERE id = ?
    ");
    while ($row = $selectStmt->fetch(PDO::FETCH_ASSOC)) {
        $currentType = strtolower(trim((string) ($row['target_type'] ?? '')));
        $currentId = (int) ($row['target_id'] ?? 0);
        $linkUrl = trim((string) ($row['link_url'] ?? ''));
        $parsedTarget = parseAds2InternalTargetValue($linkUrl);
        $normalizedType = in_array($currentType, ['restaurant', 'product'], true)
            ? $currentType
            : 'restaurant';
        $normalizedId = $currentId > 0 ? $currentId : 0;
        if ($parsedTarget !== null) {
            $normalizedType = $parsedTarget['type'];
            $normalizedId = $parsedTarget['id'];
        } elseif (!in_array($currentType, ['restaurant', 'product'], true) || $currentId <= 0) {
            $normalizedId = 0;
        }
        $canonicalLink = $normalizedId > 0 ? $normalizedType . ':' . $normalizedId : null;
        if ($normalizedType !== $currentType || $normalizedId !== $currentId || $canonicalLink !== $linkUrl) {
            $updateStmt->execute([
                $normalizedType,
                $normalizedId,
                $canonicalLink,
                $row['id'],
            ]);
        }
    }
    $targetTypeInfo = columnInfo('ads2', 'target_type');
    $targetIdInfo = columnInfo('ads2', 'target_id');
    $currentTargetType = strtolower((string) ($targetTypeInfo['COLUMN_TYPE'] ?? ''));
    $currentTargetTypeNull = strtolower((string) ($targetTypeInfo['IS_NULLABLE'] ?? 'yes'));
    $currentTargetTypeDefault = strtolower(trim((string) ($targetTypeInfo['COLUMN_DEFAULT'] ?? '')));
    $needsTargetTypeAlter = $currentTargetType !== "enum('restaurant','product')" ||
        $currentTargetTypeNull !== 'no' ||
        $currentTargetTypeDefault !== 'restaurant';
    $currentTargetIdType = strtolower((string) ($targetIdInfo['COLUMN_TYPE'] ?? ''));
    $currentTargetIdNull = strtolower((string) ($targetIdInfo['IS_NULLABLE'] ?? 'yes'));
    $currentTargetIdDefault = trim((string) ($targetIdInfo['COLUMN_DEFAULT'] ?? ''));
    $needsTargetIdAlter = strpos($currentTargetIdType, 'int(') === false ||
        $currentTargetIdNull !== 'no' ||
        $currentTargetIdDefault !== '0';
    if ($needsTargetTypeAlter) {
        $con->exec("ALTER TABLE ads2 MODIFY COLUMN target_type ENUM('restaurant','product') NOT NULL DEFAULT 'restaurant' AFTER link_url");
    }
    if ($needsTargetIdAlter) {
        $con->exec("ALTER TABLE ads2 MODIFY COLUMN target_id INT(11) NOT NULL DEFAULT 0 AFTER target_type");
    }
}
function ensureAdsSliderSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('ads2')) {
        $con->exec("
            CREATE TABLE ads2 (
                id INT(11) NOT NULL AUTO_INCREMENT,
                title_ar VARCHAR(255) DEFAULT NULL,
                title_en VARCHAR(255) DEFAULT NULL,
                image_url VARCHAR(255) NOT NULL,
                link_url VARCHAR(255) DEFAULT NULL,
                target_type ENUM('restaurant','product') NOT NULL DEFAULT 'restaurant',
                target_id INT(11) NOT NULL DEFAULT 0,
                placement VARCHAR(32) NOT NULL DEFAULT 'home',
                sort_order INT(11) NOT NULL DEFAULT 0,
                display_seconds INT(11) NOT NULL DEFAULT 8,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                open_in_webview TINYINT(1) NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (id),
                KEY idx_ads2_active_placement (is_active, placement, sort_order),
                KEY idx_ads2_target (target_type, target_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $adsColumns = [
            "title_ar" => "ALTER TABLE ads2 ADD COLUMN title_ar VARCHAR(255) DEFAULT NULL AFTER image_url",
            "title_en" => "ALTER TABLE ads2 ADD COLUMN title_en VARCHAR(255) DEFAULT NULL AFTER title_ar",
            "target_type" => "ALTER TABLE ads2 ADD COLUMN target_type ENUM('restaurant','product') NOT NULL DEFAULT 'restaurant' AFTER link_url",
            "target_id" => "ALTER TABLE ads2 ADD COLUMN target_id INT(11) NOT NULL DEFAULT 0 AFTER target_type",
            "placement" => "ALTER TABLE ads2 ADD COLUMN placement VARCHAR(32) NOT NULL DEFAULT 'home' AFTER target_id",
            "sort_order" => "ALTER TABLE ads2 ADD COLUMN sort_order INT(11) NOT NULL DEFAULT 0 AFTER placement",
            "display_seconds" => "ALTER TABLE ads2 ADD COLUMN display_seconds INT(11) NOT NULL DEFAULT 8 AFTER sort_order",
            "is_active" => "ALTER TABLE ads2 ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER display_seconds",
            "open_in_webview" => "ALTER TABLE ads2 ADD COLUMN open_in_webview TINYINT(1) NOT NULL DEFAULT 0 AFTER is_active",
            "updated_at" => "ALTER TABLE ads2 ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER open_in_webview",
        ];
        foreach ($adsColumns as $columnName => $sql) {
            if (!columnExists('ads2', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    normalizeAds2Targets();
    $schemaReady = true;
}
function normalizeStoryTargetType($value, $fallback = 'restaurant')
{
    $type = strtolower(trim((string)$value));
    if ($type === 'item') {
        $type = 'product';
    }
    if (in_array($type, ['restaurant', 'product'], true)) {
        return $type;
    }
    return in_array($fallback, ['restaurant', 'product'], true) ? $fallback : 'restaurant';
}
function normalizeStoryTargetPair($targetType, $targetId, $fallbackRestaurantId = 0)
{
    $normalizedType = normalizeStoryTargetType($targetType);
    $normalizedId = (int) $targetId;
    if ($normalizedId <= 0 && $fallbackRestaurantId > 0) {
        $normalizedId = (int) $fallbackRestaurantId;
    }
    if ($normalizedId <= 0) {
        $normalizedId = 0;
    }
    return [
        'target_type' => $normalizedType,
        'target_id' => $normalizedId,
    ];
}
function normalizeStoryTargets()
{
    global $con;
    if (!tableExists('restaurant_stories') ||
        !columnExists('restaurant_stories', 'target_type') ||
        !columnExists('restaurant_stories', 'target_id')) {
        return;
    }
    $selectStmt = $con->query("SELECT story_id, vendor_id, target_type, target_id FROM restaurant_stories");
    if (!$selectStmt) {
        return;
    }
    $updateStmt = $con->prepare("
        UPDATE restaurant_stories
        SET target_type = ?, target_id = ?
        WHERE story_id = ?
    ");
    while ($row = $selectStmt->fetch(PDO::FETCH_ASSOC)) {
        $storyId = (int) ($row['story_id'] ?? 0);
        if ($storyId <= 0) {
            continue;
        }
        $fallbackRestaurantId = (int) ($row['vendor_id'] ?? 0);
        $normalized = normalizeStoryTargetPair(
            $row['target_type'] ?? '',
            $row['target_id'] ?? 0,
            $fallbackRestaurantId
        );
        $currentType = normalizeStoryTargetType($row['target_type'] ?? '');
        $currentId = (int) ($row['target_id'] ?? 0);
        if ($currentId <= 0 && $fallbackRestaurantId > 0) {
            $currentId = $fallbackRestaurantId;
        }
        if ($normalized['target_type'] !== $currentType || $normalized['target_id'] !== $currentId) {
            $updateStmt->execute([
                $normalized['target_type'],
                $normalized['target_id'],
                $storyId,
            ]);
        }
    }
}
function ensureStorySchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('restaurant_stories')) {
        $con->exec("
            CREATE TABLE restaurant_stories (
                story_id INT(11) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL DEFAULT 0,
                title_ar VARCHAR(255) DEFAULT NULL,
                title_en VARCHAR(255) DEFAULT NULL,
                media_type VARCHAR(16) NOT NULL DEFAULT 'image',
                image_url TEXT DEFAULT NULL,
                video_url TEXT DEFAULT NULL,
                cta_label_ar VARCHAR(255) DEFAULT NULL,
                cta_label_en VARCHAR(255) DEFAULT NULL,
                target_type ENUM('restaurant','product') NOT NULL DEFAULT 'restaurant',
                target_id INT(11) NOT NULL DEFAULT 0,
                sort_order INT(11) NOT NULL DEFAULT 0,
                starts_at DATETIME DEFAULT NULL,
                ends_at DATETIME DEFAULT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (story_id),
                KEY idx_restaurant_stories_vendor_active (vendor_id, is_active, sort_order),
                KEY idx_restaurant_stories_target (target_type, target_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $storyColumns = [
            "vendor_id" => "ALTER TABLE restaurant_stories ADD COLUMN vendor_id INT(11) NOT NULL DEFAULT 0 AFTER story_id",
            "title_ar" => "ALTER TABLE restaurant_stories ADD COLUMN title_ar VARCHAR(255) DEFAULT NULL AFTER vendor_id",
            "title_en" => "ALTER TABLE restaurant_stories ADD COLUMN title_en VARCHAR(255) DEFAULT NULL AFTER title_ar",
            "media_type" => "ALTER TABLE restaurant_stories ADD COLUMN media_type VARCHAR(16) NOT NULL DEFAULT 'image' AFTER title_en",
            "image_url" => "ALTER TABLE restaurant_stories ADD COLUMN image_url TEXT DEFAULT NULL AFTER media_type",
            "video_url" => "ALTER TABLE restaurant_stories ADD COLUMN video_url TEXT DEFAULT NULL AFTER image_url",
            "cta_label_ar" => "ALTER TABLE restaurant_stories ADD COLUMN cta_label_ar VARCHAR(255) DEFAULT NULL AFTER video_url",
            "cta_label_en" => "ALTER TABLE restaurant_stories ADD COLUMN cta_label_en VARCHAR(255) DEFAULT NULL AFTER cta_label_ar",
            "target_type" => "ALTER TABLE restaurant_stories ADD COLUMN target_type ENUM('restaurant','product') NOT NULL DEFAULT 'restaurant' AFTER cta_label_en",
            "target_id" => "ALTER TABLE restaurant_stories ADD COLUMN target_id INT(11) NOT NULL DEFAULT 0 AFTER target_type",
            "sort_order" => "ALTER TABLE restaurant_stories ADD COLUMN sort_order INT(11) NOT NULL DEFAULT 0 AFTER target_id",
            "starts_at" => "ALTER TABLE restaurant_stories ADD COLUMN starts_at DATETIME DEFAULT NULL AFTER sort_order",
            "ends_at" => "ALTER TABLE restaurant_stories ADD COLUMN ends_at DATETIME DEFAULT NULL AFTER starts_at",
            "is_active" => "ALTER TABLE restaurant_stories ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER ends_at",
            "created_at" => "ALTER TABLE restaurant_stories ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER is_active",
            "updated_at" => "ALTER TABLE restaurant_stories ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at",
        ];
        foreach ($storyColumns as $columnName => $sql) {
            if (!columnExists('restaurant_stories', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    normalizeStoryTargets();
    $schemaReady = true;
}
function normalizeVideoTargetType($value, $fallback = 'product')
{
    $type = strtolower(trim((string) $value));
    if ($type === 'item') {
        $type = 'product';
    }
    if (in_array($type, ['restaurant', 'product'], true)) {
        return $type;
    }
    return in_array($fallback, ['restaurant', 'product'], true) ? $fallback : 'product';
}
function normalizeVideoTargetPair($targetType, $targetId, $legacyProductId = 0)
{
    $rawType = strtolower(trim((string) $targetType));
    if ($rawType === 'item') {
        $rawType = 'product';
    }
    $normalizedId = (int) $targetId;
    $legacyProductId = (int) $legacyProductId;
    $hasExplicitType = in_array($rawType, ['restaurant', 'product'], true);
    $effectiveId = $normalizedId > 0 ? $normalizedId : $legacyProductId;
    if (!$hasExplicitType && $effectiveId <= 0) {
        return [
            'target_type' => null,
            'target_id' => 0,
            'video_product_id' => null,
        ];
    }
    if ($hasExplicitType && $rawType === 'restaurant') {
        return [
            'target_type' => 'restaurant',
            'target_id' => $normalizedId > 0 ? $normalizedId : 0,
            'video_product_id' => null,
        ];
    }
    if ($effectiveId <= 0) {
        return [
            'target_type' => null,
            'target_id' => 0,
            'video_product_id' => null,
        ];
    }
    return [
        'target_type' => 'product',
        'target_id' => $effectiveId,
        'video_product_id' => $effectiveId,
    ];
}
function normalizeVideoTargets()
{
    global $con;
    if (!tableExists('videos') ||
        !columnExists('videos', 'video_target_type') ||
        !columnExists('videos', 'video_target_id')) {
        return;
    }
    $selectStmt = $con->query("
        SELECT video_id, video_product_id, video_target_type, video_target_id
        FROM videos
    ");
    if (!$selectStmt) {
        return;
    }
    $updateStmt = $con->prepare("
        UPDATE videos
        SET video_target_type = ?, video_target_id = ?, video_product_id = ?
        WHERE video_id = ?
    ");
    while ($row = $selectStmt->fetch(PDO::FETCH_ASSOC)) {
        $videoId = (int) ($row['video_id'] ?? 0);
        if ($videoId <= 0) {
            continue;
        }
        $normalized = normalizeVideoTargetPair(
            $row['video_target_type'] ?? '',
            $row['video_target_id'] ?? 0,
            $row['video_product_id'] ?? 0
        );
        $currentRawType = strtolower(trim((string) ($row['video_target_type'] ?? '')));
        $currentType = in_array($currentRawType, ['restaurant', 'product'], true)
            ? $currentRawType
            : ($currentRawType === 'item'
                ? 'product'
                : (($row['video_product_id'] !== null && (int) $row['video_product_id'] > 0)
                    ? 'product'
                    : null));
        $currentId = (int) ($row['video_target_id'] ?? 0);
        $currentProductId = $row['video_product_id'] !== null
            ? (int) $row['video_product_id']
            : null;
        if ($normalized['target_type'] !== $currentType ||
            $normalized['target_id'] !== $currentId ||
            $normalized['video_product_id'] !== $currentProductId) {
            $updateStmt->execute([
                $normalized['target_type'],
                $normalized['target_id'] > 0 ? $normalized['target_id'] : null,
                $normalized['video_product_id'],
                $videoId,
            ]);
        }
    }
}
function ensureVideoSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('videos')) {
        $schemaReady = true;
        return;
    }
    if (!columnExists('videos', 'video_target_type')) {
        $con->exec("ALTER TABLE videos ADD COLUMN video_target_type VARCHAR(16) DEFAULT NULL AFTER video_product_id");
    }
    if (!columnExists('videos', 'video_target_id')) {
        $con->exec("ALTER TABLE videos ADD COLUMN video_target_id INT(11) DEFAULT NULL AFTER video_target_type");
    }
    if (!columnExists('videos', 'video_thumbnail')) {
        $con->exec("ALTER TABLE videos ADD COLUMN video_thumbnail VARCHAR(500) DEFAULT NULL AFTER video_url");
    }
    if (!columnExists('videos', 'video_is_active')) {
        $con->exec("ALTER TABLE videos ADD COLUMN video_is_active TINYINT(1) NOT NULL DEFAULT 1");
    }
    normalizeVideoTargets();
    $schemaReady = true;
}
function ensureLegalContentSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('app_legal_documents')) {
        $con->exec("
            CREATE TABLE app_legal_documents (
                document_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                document_key VARCHAR(120) NOT NULL,
                document_type VARCHAR(40) NOT NULL DEFAULT 'policy',
                title_ar VARCHAR(255) NOT NULL,
                title_en VARCHAR(255) NOT NULL,
                subtitle_ar TEXT DEFAULT NULL,
                subtitle_en TEXT DEFAULT NULL,
                summary_ar_json LONGTEXT DEFAULT NULL,
                summary_en_json LONGTEXT DEFAULT NULL,
                content_ar LONGTEXT DEFAULT NULL,
                content_en LONGTEXT DEFAULT NULL,
                accent_color VARCHAR(24) DEFAULT NULL,
                hero_icon VARCHAR(64) DEFAULT NULL,
                sort_order INT(11) NOT NULL DEFAULT 0,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (document_id),
                UNIQUE KEY uniq_app_legal_documents_key (document_key),
                KEY idx_app_legal_documents_type (document_type),
                KEY idx_app_legal_documents_sort (sort_order)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $documentColumns = [
            'document_key' => "ALTER TABLE app_legal_documents ADD COLUMN document_key VARCHAR(120) NOT NULL AFTER document_id",
            'document_type' => "ALTER TABLE app_legal_documents ADD COLUMN document_type VARCHAR(40) NOT NULL DEFAULT 'policy' AFTER document_key",
            'title_ar' => "ALTER TABLE app_legal_documents ADD COLUMN title_ar VARCHAR(255) NOT NULL AFTER document_type",
            'title_en' => "ALTER TABLE app_legal_documents ADD COLUMN title_en VARCHAR(255) NOT NULL AFTER title_ar",
            'subtitle_ar' => "ALTER TABLE app_legal_documents ADD COLUMN subtitle_ar TEXT DEFAULT NULL AFTER title_en",
            'subtitle_en' => "ALTER TABLE app_legal_documents ADD COLUMN subtitle_en TEXT DEFAULT NULL AFTER subtitle_ar",
            'summary_ar_json' => "ALTER TABLE app_legal_documents ADD COLUMN summary_ar_json LONGTEXT DEFAULT NULL AFTER subtitle_en",
            'summary_en_json' => "ALTER TABLE app_legal_documents ADD COLUMN summary_en_json LONGTEXT DEFAULT NULL AFTER summary_ar_json",
            'content_ar' => "ALTER TABLE app_legal_documents ADD COLUMN content_ar LONGTEXT DEFAULT NULL AFTER summary_en_json",
            'content_en' => "ALTER TABLE app_legal_documents ADD COLUMN content_en LONGTEXT DEFAULT NULL AFTER content_ar",
            'accent_color' => "ALTER TABLE app_legal_documents ADD COLUMN accent_color VARCHAR(24) DEFAULT NULL AFTER content_en",
            'hero_icon' => "ALTER TABLE app_legal_documents ADD COLUMN hero_icon VARCHAR(64) DEFAULT NULL AFTER accent_color",
            'sort_order' => "ALTER TABLE app_legal_documents ADD COLUMN sort_order INT(11) NOT NULL DEFAULT 0 AFTER hero_icon",
            'is_active' => "ALTER TABLE app_legal_documents ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER sort_order",
            'created_at' => "ALTER TABLE app_legal_documents ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER is_active",
            'updated_at' => "ALTER TABLE app_legal_documents ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at",
        ];
        foreach ($documentColumns as $columnName => $sql) {
            if (!columnExists('app_legal_documents', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('app_cookie_consent_profiles')) {
        $con->exec("
            CREATE TABLE app_cookie_consent_profiles (
                profile_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                profile_key VARCHAR(120) NOT NULL,
                title_ar VARCHAR(255) NOT NULL,
                title_en VARCHAR(255) NOT NULL,
                subtitle_ar TEXT DEFAULT NULL,
                subtitle_en TEXT DEFAULT NULL,
                body_ar LONGTEXT DEFAULT NULL,
                body_en LONGTEXT DEFAULT NULL,
                accept_all_label_ar VARCHAR(255) DEFAULT NULL,
                accept_all_label_en VARCHAR(255) DEFAULT NULL,
                customize_label_ar VARCHAR(255) DEFAULT NULL,
                customize_label_en VARCHAR(255) DEFAULT NULL,
                reject_optional_label_ar VARCHAR(255) DEFAULT NULL,
                reject_optional_label_en VARCHAR(255) DEFAULT NULL,
                footer_note_ar TEXT DEFAULT NULL,
                footer_note_en TEXT DEFAULT NULL,
                version_label VARCHAR(32) NOT NULL DEFAULT 'v1',
                accent_color VARCHAR(24) DEFAULT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (profile_id),
                UNIQUE KEY uniq_app_cookie_consent_profiles_key (profile_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $profileColumns = [
            'profile_key' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN profile_key VARCHAR(120) NOT NULL AFTER profile_id",
            'title_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN title_ar VARCHAR(255) NOT NULL AFTER profile_key",
            'title_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN title_en VARCHAR(255) NOT NULL AFTER title_ar",
            'subtitle_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN subtitle_ar TEXT DEFAULT NULL AFTER title_en",
            'subtitle_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN subtitle_en TEXT DEFAULT NULL AFTER subtitle_ar",
            'body_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN body_ar LONGTEXT DEFAULT NULL AFTER subtitle_en",
            'body_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN body_en LONGTEXT DEFAULT NULL AFTER body_ar",
            'accept_all_label_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN accept_all_label_ar VARCHAR(255) DEFAULT NULL AFTER body_en",
            'accept_all_label_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN accept_all_label_en VARCHAR(255) DEFAULT NULL AFTER accept_all_label_ar",
            'customize_label_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN customize_label_ar VARCHAR(255) DEFAULT NULL AFTER accept_all_label_en",
            'customize_label_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN customize_label_en VARCHAR(255) DEFAULT NULL AFTER customize_label_ar",
            'reject_optional_label_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN reject_optional_label_ar VARCHAR(255) DEFAULT NULL AFTER customize_label_en",
            'reject_optional_label_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN reject_optional_label_en VARCHAR(255) DEFAULT NULL AFTER reject_optional_label_ar",
            'footer_note_ar' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN footer_note_ar TEXT DEFAULT NULL AFTER reject_optional_label_en",
            'footer_note_en' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN footer_note_en TEXT DEFAULT NULL AFTER footer_note_ar",
            'version_label' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN version_label VARCHAR(32) NOT NULL DEFAULT 'v1' AFTER footer_note_en",
            'accent_color' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN accent_color VARCHAR(24) DEFAULT NULL AFTER version_label",
            'is_active' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER accent_color",
            'created_at' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER is_active",
            'updated_at' => "ALTER TABLE app_cookie_consent_profiles ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at",
        ];
        foreach ($profileColumns as $columnName => $sql) {
            if (!columnExists('app_cookie_consent_profiles', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('app_cookie_consent_options')) {
        $con->exec("
            CREATE TABLE app_cookie_consent_options (
                option_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                profile_key VARCHAR(120) NOT NULL,
                option_key VARCHAR(120) NOT NULL,
                title_ar VARCHAR(255) NOT NULL,
                title_en VARCHAR(255) NOT NULL,
                description_ar TEXT NOT NULL,
                description_en TEXT NOT NULL,
                badge_ar VARCHAR(255) DEFAULT NULL,
                badge_en VARCHAR(255) DEFAULT NULL,
                icon_name VARCHAR(64) NOT NULL,
                badge_color VARCHAR(24) NOT NULL,
                is_locked TINYINT(1) NOT NULL DEFAULT 0,
                default_enabled TINYINT(1) NOT NULL DEFAULT 0,
                sort_order INT(11) NOT NULL DEFAULT 0,
                preference_keys_json LONGTEXT DEFAULT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (option_id),
                UNIQUE KEY uniq_app_cookie_consent_options_key (profile_key, option_key),
                KEY idx_app_cookie_consent_options_profile (profile_key),
                KEY idx_app_cookie_consent_options_sort (sort_order)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $optionColumns = [
            'profile_key' => "ALTER TABLE app_cookie_consent_options ADD COLUMN profile_key VARCHAR(120) NOT NULL AFTER option_id",
            'option_key' => "ALTER TABLE app_cookie_consent_options ADD COLUMN option_key VARCHAR(120) NOT NULL AFTER profile_key",
            'title_ar' => "ALTER TABLE app_cookie_consent_options ADD COLUMN title_ar VARCHAR(255) NOT NULL AFTER option_key",
            'title_en' => "ALTER TABLE app_cookie_consent_options ADD COLUMN title_en VARCHAR(255) NOT NULL AFTER title_ar",
            'description_ar' => "ALTER TABLE app_cookie_consent_options ADD COLUMN description_ar TEXT NOT NULL AFTER title_en",
            'description_en' => "ALTER TABLE app_cookie_consent_options ADD COLUMN description_en TEXT NOT NULL AFTER description_ar",
            'badge_ar' => "ALTER TABLE app_cookie_consent_options ADD COLUMN badge_ar VARCHAR(255) DEFAULT NULL AFTER description_en",
            'badge_en' => "ALTER TABLE app_cookie_consent_options ADD COLUMN badge_en VARCHAR(255) DEFAULT NULL AFTER badge_ar",
            'icon_name' => "ALTER TABLE app_cookie_consent_options ADD COLUMN icon_name VARCHAR(64) NOT NULL AFTER badge_en",
            'badge_color' => "ALTER TABLE app_cookie_consent_options ADD COLUMN badge_color VARCHAR(24) NOT NULL AFTER icon_name",
            'is_locked' => "ALTER TABLE app_cookie_consent_options ADD COLUMN is_locked TINYINT(1) NOT NULL DEFAULT 0 AFTER badge_color",
            'default_enabled' => "ALTER TABLE app_cookie_consent_options ADD COLUMN default_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER is_locked",
            'sort_order' => "ALTER TABLE app_cookie_consent_options ADD COLUMN sort_order INT(11) NOT NULL DEFAULT 0 AFTER default_enabled",
            'preference_keys_json' => "ALTER TABLE app_cookie_consent_options ADD COLUMN preference_keys_json LONGTEXT DEFAULT NULL AFTER sort_order",
            'is_active' => "ALTER TABLE app_cookie_consent_options ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER preference_keys_json",
            'created_at' => "ALTER TABLE app_cookie_consent_options ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER is_active",
            'updated_at' => "ALTER TABLE app_cookie_consent_options ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at",
        ];
        foreach ($optionColumns as $columnName => $sql) {
            if (!columnExists('app_cookie_consent_options', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('app_cookie_consent_records')) {
        $con->exec("
            CREATE TABLE app_cookie_consent_records (
                record_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                profile_key VARCHAR(120) NOT NULL,
                user_id INT(11) DEFAULT NULL,
                installation_key VARCHAR(160) NOT NULL,
                locale_code VARCHAR(8) NOT NULL DEFAULT 'ar',
                consent_mode VARCHAR(32) NOT NULL,
                preferences_json LONGTEXT NOT NULL,
                record_source VARCHAR(32) NOT NULL DEFAULT 'app',
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (record_id),
                UNIQUE KEY uniq_app_cookie_consent_records_installation (profile_key, installation_key),
                KEY idx_app_cookie_consent_records_user (user_id),
                KEY idx_app_cookie_consent_records_profile (profile_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $recordColumns = [
            'profile_key' => "ALTER TABLE app_cookie_consent_records ADD COLUMN profile_key VARCHAR(120) NOT NULL AFTER record_id",
            'user_id' => "ALTER TABLE app_cookie_consent_records ADD COLUMN user_id INT(11) DEFAULT NULL AFTER profile_key",
            'installation_key' => "ALTER TABLE app_cookie_consent_records ADD COLUMN installation_key VARCHAR(160) NOT NULL AFTER user_id",
            'locale_code' => "ALTER TABLE app_cookie_consent_records ADD COLUMN locale_code VARCHAR(8) NOT NULL DEFAULT 'ar' AFTER installation_key",
            'consent_mode' => "ALTER TABLE app_cookie_consent_records ADD COLUMN consent_mode VARCHAR(32) NOT NULL AFTER locale_code",
            'preferences_json' => "ALTER TABLE app_cookie_consent_records ADD COLUMN preferences_json LONGTEXT NOT NULL AFTER consent_mode",
            'record_source' => "ALTER TABLE app_cookie_consent_records ADD COLUMN record_source VARCHAR(32) NOT NULL DEFAULT 'app' AFTER preferences_json",
            'created_at' => "ALTER TABLE app_cookie_consent_records ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER record_source",
            'updated_at' => "ALTER TABLE app_cookie_consent_records ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP AFTER created_at",
        ];
        foreach ($recordColumns as $columnName => $sql) {
            if (!columnExists('app_cookie_consent_records', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    $schemaReady = true;
}
function getEnvValue($key, $default = '')
{
    $value = getenv($key);
    if ($value !== false && $value !== '') {
        return $value;
    }
    if (isset($_ENV[$key]) && $_ENV[$key] !== '') {
        return $_ENV[$key];
    }
    if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') {
        return $_SERVER[$key];
    }
    return $default;
}
function envFlagEnabled($key, $default = false)
{
    $value = strtolower(trim((string)getEnvValue($key, $default ? '1' : '0')));
    return in_array($value, ['1', 'true', 'yes', 'on'], true);
}
function appEnvironment()
{
    return strtolower(trim((string)getEnvValue('APP_ENV', 'development')));
}
function isProductionEnvironment()
{
    return in_array(appEnvironment(), ['prod', 'production'], true);
}
function getAuthorizationHeaderValue()
{
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        return trim($_SERVER['HTTP_AUTHORIZATION']);
    }
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        return trim($_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
    }
    if (function_exists('apache_request_headers')) {
        $headers = array_change_key_case(apache_request_headers(), CASE_LOWER);
        if (!empty($headers['authorization'])) {
            return trim($headers['authorization']);
        }
    }
    return '';
}
function getBearerToken()
{
    $header = getAuthorizationHeaderValue();
    if ($header === '' || stripos($header, 'Bearer ') !== 0) {
        return '';
    }
    return trim(substr($header, 7));
}
function generateStoreSlug($value)
{
    $value = strtolower(trim((string)$value));
    $value = preg_replace('/[^a-z0-9]+/i', '-', $value);
    $value = trim($value, '-');
    if ($value === '') {
        $value = 'store-' . bin2hex(random_bytes(4));
    }
    return $value;
}
function generateOtpCode($length = 5)
{
    $max = (10 ** max(1, (int)$length)) - 1;
    return str_pad((string)random_int(0, $max), (int)$length, '0', STR_PAD_LEFT);
}
function normalizeWhatsappPhone($value)
{
    $phone = trim((string)$value);
    if ($phone === '') {
        return '';
    }
    $phone = preg_replace('/[^\d+]/', '', $phone);
    if (strpos($phone, '00') === 0) {
        $phone = '+' . substr($phone, 2);
    }
    if (!preg_match('/^\+[1-9]\d{7,14}$/', $phone)) {
        return '';
    }
    return $phone;
}
function buildPlaceholderEmailFromPhone($phone)
{
    $digits = preg_replace('/\D+/', '', (string)$phone);
    if ($digits === '') {
        $digits = bin2hex(random_bytes(6));
    }
    return 'wa_' . $digits . '@wa.aleppoeats.local';
}
function userPublicData($user)
{
    return [
        'users_id' => isset($user['users_id']) ? (int)$user['users_id'] : 0,
        'users_name' => $user['users_name'] ?? '',
        'users_email' => $user['users_email'] ?? '',
        'users_phone' => $user['users_phone'] ?? '',
        'users_image' => $user['users_image'] ?? null,
        'users_locale' => $user['users_locale'] ?? null,
        'auth_provider' => $user['auth_provider'] ?? 'email',
        'profile_completed' => isset($user['profile_completed']) ? (int)$user['profile_completed'] : 0,
        'whatsapp_phone_verified_at' => $user['whatsapp_phone_verified_at'] ?? null,
    ];
}
function findUserByPhone($phone)
{
    global $con;
    $stmt = $con->prepare("
        SELECT *
        FROM users
        WHERE users_phone = :phone
        LIMIT 1
    ");
    $stmt->execute([':phone' => $phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    return $user ?: null;
}
function findUserByEmail($email)
{
    global $con;
    $email = strtolower(trim((string)$email));
    if ($email === '') {
        return null;
    }
    $stmt = $con->prepare("
        SELECT *
        FROM users
        WHERE LOWER(users_email) = :email
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    return $user ?: null;
}
function phoneVariantCandidates($value)
{
    $raw = trim((string)$value);
    if ($raw === '') {
        return array();
    }
    $digits = preg_replace('/\D+/', '', $raw);
    $candidates = array();
    $pushCandidate = function ($candidate) use (&$candidates) {
        $candidate = trim((string)$candidate);
        if ($candidate === '') {
            return;
        }
        if (!in_array($candidate, $candidates, true)) {
            $candidates[] = $candidate;
        }
    };
    $pushCandidate($raw);
    if ($digits !== '') {
        $pushCandidate($digits);
        $pushCandidate('+' . $digits);
    }
    if ($digits !== '' && strpos($digits, '00') === 0 && strlen($digits) > 2) {
        $pushCandidate('+' . substr($digits, 2));
    }
    if ($digits !== '' && strpos($digits, '20') === 0 && strlen($digits) > 2) {
        $pushCandidate('0' . substr($digits, 2));
        $pushCandidate('+20' . substr($digits, 2));
    }
    if ($digits !== '' && strpos($digits, '0') === 0 && strlen($digits) > 1) {
        $pushCandidate('20' . substr($digits, 1));
        $pushCandidate('+20' . substr($digits, 1));
    }
    return $candidates;
}
function normalizePhoneForStorage($value)
{
    $raw = trim((string)$value);
    if ($raw === '') {
        return '';
    }
    $normalized = normalizeWhatsappPhone($raw);
    if ($normalized !== '') {
        return $normalized;
    }
    $candidates = phoneVariantCandidates($raw);
    foreach ($candidates as $candidate) {
        $normalized = normalizeWhatsappPhone($candidate);
        if ($normalized !== '') {
            return $normalized;
        }
    }
    $digits = preg_replace('/\D+/', '', $raw);
    if ($digits !== '') {
        return $digits;
    }
    return $raw;
}
function findUserByPhoneFlexible($phone)
{
    global $con;
    $candidates = phoneVariantCandidates($phone);
    if (empty($candidates)) {
        return null;
    }
    $stmt = $con->prepare("
        SELECT *
        FROM users
        WHERE users_phone = :phone
        LIMIT 1
    ");
    foreach ($candidates as $candidate) {
        $stmt->execute(array(':phone' => $candidate));
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($user) {
            return $user;
        }
    }
    return null;
}
function ensureWhatsappUser($phone, $locale = null)
{
    global $con;
    $phone = normalizeWhatsappPhone($phone);
    if ($phone === '') {
        throw new InvalidArgumentException('Invalid phone number');
    }
    $existingUser = findUserByPhone($phone);
    if ($existingUser) {
        $displayName = trim((string)($existingUser['users_name'] ?? ''));
        $profileCompleted = (int)($existingUser['profile_completed'] ?? 0);
        if ($profileCompleted === 0 && $displayName !== '' && strtolower($displayName) !== 'new user') {
            $profileCompleted = 1;
        }
        $stmt = $con->prepare("
            UPDATE users
            SET users_approve = 1,
                whatsapp_phone_verified_at = NOW(),
                last_login_at = NOW(),
                auth_provider = CASE
                    WHEN auth_provider IS NULL OR auth_provider = '' OR auth_provider = 'email'
                    THEN 'whatsapp'
                    ELSE auth_provider
                END,
                profile_completed = :profile_completed,
                users_locale = COALESCE(:locale, users_locale)
            WHERE users_id = :user_id
        ");
        $stmt->execute([
            ':profile_completed' => $profileCompleted,
            ':locale' => $locale ?: null,
            ':user_id' => (int)$existingUser['users_id'],
        ]);
        return findUserByPhone($phone);
    }
    $placeholderEmail = buildPlaceholderEmailFromPhone($phone);
    $randomPassword = password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT);
    $stmt = $con->prepare("
        INSERT INTO users (
            users_name,
            users_password,
            users_email,
            users_phone,
            users_verfiycode,
            users_approve,
            password_hashed,
            auth_provider,
            profile_completed,
            whatsapp_phone_verified_at,
            last_login_at,
            users_locale
        ) VALUES (
            :users_name,
            :users_password,
            :users_email,
            :users_phone,
            0,
            1,
            1,
            'whatsapp',
            0,
            NOW(),
            NOW(),
            :users_locale
        )
    ");
    $stmt->execute([
        ':users_name' => 'New User',
        ':users_password' => $randomPassword,
        ':users_email' => $placeholderEmail,
        ':users_phone' => $phone,
        ':users_locale' => $locale ?: null,
    ]);
    return findUserByPhone($phone);
}
function createUserSession($userId, $ttlDays = 30, $refreshTtlDays = 90)
{
    global $con;
    $token = bin2hex(random_bytes(32));
    $refreshToken = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . (int)$ttlDays . ' days'));
    $refreshExpiresAt = date('Y-m-d H:i:s', strtotime('+' . (int)$refreshTtlDays . ' days'));
    $stmt = $con->prepare("
        INSERT INTO user_sessions (
            user_id,
            access_token,
            refresh_token,
            user_agent,
            ip_address,
            device_name,
            last_used_at,
            expires_at,
            refresh_expires_at
        ) VALUES (
            :user_id,
            :access_token,
            :refresh_token,
            :user_agent,
            :ip_address,
            :device_name,
            NOW(),
            :expires_at,
            :refresh_expires_at
        )
    ");
    $stmt->execute([
        ':user_id' => (int)$userId,
        ':access_token' => $token,
        ':refresh_token' => $refreshToken,
        ':user_agent' => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
        ':ip_address' => substr($_SERVER['REMOTE_ADDR'] ?? '', 0, 64),
        ':device_name' => substr((string)filterRequest('device_name'), 0, 120),
        ':expires_at' => $expiresAt,
        ':refresh_expires_at' => $refreshExpiresAt,
    ]);
    return [
        'token' => $token,
        'refresh_token' => $refreshToken,
        'expires_at' => $expiresAt,
        'refresh_expires_at' => $refreshExpiresAt,
    ];
}
function deleteUserSessionByToken($token)
{
    global $con;
    if (!$token) {
        return false;
    }
    $stmt = $con->prepare("DELETE FROM user_sessions WHERE access_token = :token");
    $stmt->execute([':token' => $token]);
    return $stmt->rowCount() > 0;
}
function getUserBySessionToken($token)
{
    global $con;
    if (!$token) {
        return null;
    }
    $stmt = $con->prepare("
        SELECT
            u.*,
            us.session_id,
            us.expires_at,
            us.refresh_expires_at
        FROM user_sessions us
        JOIN users u ON u.users_id = us.user_id
        WHERE us.access_token = :token
          AND us.revoked_at IS NULL
          AND us.expires_at > NOW()
        LIMIT 1
    ");
    $stmt->execute([':token' => $token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        return null;
    }
    $updateStmt = $con->prepare("
        UPDATE user_sessions
        SET last_used_at = NOW()
        WHERE session_id = :session_id
    ");
    $updateStmt->execute([':session_id' => $user['session_id']]);
    return $user;
}
function requireUserAuth()
{
    $token = getBearerToken();
    if ($token === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Unauthorized access',
        ], 401);
    }
    $user = getUserBySessionToken($token);
    if (!$user) {
        respondJson([
            'status' => 'error',
            'message' => 'Session expired or invalid',
        ], 401);
    }
    $user['_access_token'] = $token;
    return $user;
}
function isTwilioVerifyConfigured()
{
    return trim((string)getEnvValue('TWILIO_ACCOUNT_SID')) !== ''
        && trim((string)getEnvValue('TWILIO_AUTH_TOKEN')) !== ''
        && trim((string)getEnvValue('TWILIO_VERIFY_SERVICE_SID')) !== '';
}
function allowLocalOtpFallback()
{
    if (envFlagEnabled('ALEPPO_ALLOW_LOCAL_OTP_FALLBACK', false)) {
        return true;
    }
    return !isProductionEnvironment();
}
function sendTwilioVerifyRequest($path, $fields)
{
    $accountSid = trim((string)getEnvValue('TWILIO_ACCOUNT_SID'));
    $authToken = trim((string)getEnvValue('TWILIO_AUTH_TOKEN'));
    $serviceSid = trim((string)getEnvValue('TWILIO_VERIFY_SERVICE_SID'));
    if ($accountSid === '' || $authToken === '' || $serviceSid === '') {
        return [
            'success' => false,
            'message' => 'Twilio Verify credentials are missing',
        ];
    }
    $url = "https://verify.twilio.com/v2/Services/{$serviceSid}/{$path}";
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query($fields),
        CURLOPT_USERPWD => $accountSid . ':' . $authToken,
        CURLOPT_HTTPAUTH => CURLAUTH_BASIC,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/x-www-form-urlencoded',
        ],
    ]);
    $rawResponse = curl_exec($ch);
    $curlError = curl_error($ch);
    $statusCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($rawResponse === false) {
        return [
            'success' => false,
            'message' => $curlError !== '' ? $curlError : 'Twilio request failed',
        ];
    }
    $decoded = json_decode($rawResponse, true);
    if (!is_array($decoded)) {
        $decoded = [];
    }
    if ($statusCode < 200 || $statusCode >= 300) {
        return [
            'success' => false,
            'message' => $decoded['message'] ?? ('Twilio request failed with status ' . $statusCode),
            'data' => $decoded,
            'status_code' => $statusCode,
        ];
    }
    return [
        'success' => true,
        'data' => $decoded,
        'status_code' => $statusCode,
    ];
}
function sendWhatsAppVerificationCode($phone)
{
    $phone = normalizeWhatsappPhone($phone);
    if ($phone === '') {
        return [
            'success' => false,
            'message' => 'Invalid WhatsApp number',
        ];
    }
    if (!isTwilioVerifyConfigured()) {
        return [
            'success' => false,
            'message' => 'Twilio Verify is not configured',
        ];
    }
    $response = sendTwilioVerifyRequest('Verifications', [
        'To' => $phone,
        'Channel' => 'whatsapp',
    ]);
    if (!$response['success']) {
        return $response;
    }
    $data = $response['data'] ?? [];
    return [
        'success' => true,
        'provider' => 'twilio_verify',
        'provider_sid' => $data['sid'] ?? null,
        'status' => $data['status'] ?? 'pending',
        'channel' => $data['channel'] ?? 'whatsapp',
        'data' => $data,
    ];
}
function checkWhatsAppVerificationCode($phone, $code)
{
    $phone = normalizeWhatsappPhone($phone);
    $code = trim((string)$code);
    if ($phone === '' || !preg_match('/^\d{4,10}$/', $code)) {
        return [
            'success' => false,
            'message' => 'Invalid verification payload',
        ];
    }
    if (!isTwilioVerifyConfigured()) {
        return [
            'success' => false,
            'message' => 'Twilio Verify is not configured',
        ];
    }
    $response = sendTwilioVerifyRequest('VerificationCheck', [
        'To' => $phone,
        'Code' => $code,
    ]);
    if (!$response['success']) {
        return $response;
    }
    $data = $response['data'] ?? [];
    $approved = strtolower((string)($data['status'] ?? '')) === 'approved'
        || (bool)($data['valid'] ?? false) === true;
    return [
        'success' => $approved,
        'status' => $data['status'] ?? 'pending',
        'message' => $approved ? 'approved' : ($data['message'] ?? 'Verification code is not valid'),
        'provider_sid' => $data['sid'] ?? null,
        'data' => $data,
    ];
}
function vendorPublicData($vendor)
{
    return [
        'vendor_id' => isset($vendor['vendor_id']) ? (int)$vendor['vendor_id'] : 0,
        'vendor_name' => $vendor['vendor_name'] ?? '',
        'store_name' => $vendor['store_name'] ?? '',
        'store_slug' => $vendor['store_slug'] ?? '',
        'vendor_email' => $vendor['vendor_email'] ?? '',
        'vendor_phone' => $vendor['vendor_phone'] ?? '',
        'vendor_logo' => $vendor['vendor_logo'] ?? null,
        'vendor_description' => $vendor['vendor_description'] ?? null,
        'store_address' => $vendor['store_address'] ?? null,
        'store_latitude' => isset($vendor['store_latitude']) ? (float)$vendor['store_latitude'] : null,
        'store_longitude' => isset($vendor['store_longitude']) ? (float)$vendor['store_longitude'] : null,
        'vendor_status' => $vendor['vendor_status'] ?? 'pending',
        'vendor_is_verified' => isset($vendor['vendor_is_verified']) ? (int)$vendor['vendor_is_verified'] : 0,
        'vendor_type' => $vendor['vendor_type'] ?? 'restaurant',
        'store_category' => $vendor['store_category'] ?? null,
    ];
}
function createVendorSession($vendorId, $ttlDays = 30)
{
    global $con;
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . (int)$ttlDays . ' days'));
    $stmt = $con->prepare("
        INSERT INTO vendor_sessions (
            vendor_id,
            access_token,
            user_agent,
            ip_address,
            last_used_at,
            expires_at
        ) VALUES (
            :vendor_id,
            :access_token,
            :user_agent,
            :ip_address,
            NOW(),
            :expires_at
        )
    ");
    $stmt->execute([
        ':vendor_id' => (int)$vendorId,
        ':access_token' => $token,
        ':user_agent' => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
        ':ip_address' => substr($_SERVER['REMOTE_ADDR'] ?? '', 0, 64),
        ':expires_at' => $expiresAt,
    ]);
    return [
        'token' => $token,
        'expires_at' => $expiresAt,
    ];
}
function deleteVendorSessionByToken($token)
{
    global $con;
    if (!$token) {
        return false;
    }
    $stmt = $con->prepare("DELETE FROM vendor_sessions WHERE access_token = :token");
    $stmt->execute([':token' => $token]);
    return $stmt->rowCount() > 0;
}
function getVendorBySessionToken($token)
{
    global $con;
    if (!$token) {
        return null;
    }
    $stmt = $con->prepare("
        SELECT
            v.*,
            vs.session_id,
            vs.expires_at
        FROM vendor_sessions vs
        JOIN vendors v ON v.vendor_id = vs.vendor_id
        WHERE vs.access_token = :token
          AND vs.expires_at > NOW()
        LIMIT 1
    ");
    $stmt->execute([':token' => $token]);
    $vendor = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$vendor) {
        return null;
    }
    $updateStmt = $con->prepare("
        UPDATE vendor_sessions
        SET last_used_at = NOW()
        WHERE session_id = :session_id
    ");
    $updateStmt->execute([':session_id' => $vendor['session_id']]);
    return $vendor;
}
function requireVendorAuth()
{
    $token = getBearerToken();
    if ($token === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Unauthorized access',
        ], 401);
    }
    $vendor = getVendorBySessionToken($token);
    if (!$vendor) {
        respondJson([
            'status' => 'error',
            'message' => 'Session expired or invalid',
        ], 401);
    }
    if (($vendor['vendor_status'] ?? 'pending') !== 'active' || (int)($vendor['vendor_is_verified'] ?? 0) !== 1) {
        respondJson([
            'status' => 'error',
            'message' => 'Vendor account is not active',
        ], 403);
    }
    $vendor['_access_token'] = $token;
    return $vendor;
}
function createMasterSession($adminId, $ttlDays = 30)
{
    global $con;
    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+' . (int)$ttlDays . ' days'));
    $stmt = $con->prepare("
        INSERT INTO master_sessions (
            admin_id,
            access_token,
            user_agent,
            ip_address,
            last_used_at,
            expires_at
        ) VALUES (
            :admin_id,
            :access_token,
            :user_agent,
            :ip_address,
            NOW(),
            :expires_at
        )
    ");
    $stmt->execute([
        ':admin_id' => (int)$adminId,
        ':access_token' => $token,
        ':user_agent' => substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 255),
        ':ip_address' => substr($_SERVER['REMOTE_ADDR'] ?? '', 0, 64),
        ':expires_at' => $expiresAt,
    ]);
    return [
        'token' => $token,
        'expires_at' => $expiresAt,
    ];
}
function deleteMasterSessionByToken($token)
{
    global $con;
    if (!$token) {
        return false;
    }
    $stmt = $con->prepare("DELETE FROM master_sessions WHERE access_token = :token");
    $stmt->execute([':token' => $token]);
    return $stmt->rowCount() > 0;
}
function getMasterBySessionToken($token)
{
    global $con;
    if (!$token) {
        return null;
    }
    $stmt = $con->prepare("
        SELECT
            a.*,
            ms.session_id,
            ms.expires_at,
            rp.role_id AS master_role_id,
            rp.role_name AS master_role_name,
            rp.role_scope AS master_role_scope,
            rp.permissions_json AS master_role_permissions_json,
            rp.tint_hex AS master_role_tint_hex,
            rp.sort_order AS master_role_sort_order
        FROM master_sessions ms
        JOIN admin a ON a.admin_id = ms.admin_id
        LEFT JOIN master_role_profiles rp ON rp.role_id = a.admin_role_id
        WHERE ms.access_token = :token
          AND ms.expires_at > NOW()
        LIMIT 1
    ");
    $stmt->execute([':token' => $token]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$admin) {
        return null;
    }
    $updateStmt = $con->prepare("
        UPDATE master_sessions
        SET last_used_at = NOW()
        WHERE session_id = :session_id
    ");
    $updateStmt->execute([':session_id' => $admin['session_id']]);
    return $admin;
}
function masterRolePublicData($role)
{
    $permissions = $role['permissions_json'] ?? [];
    if (is_string($permissions)) {
        $decoded = json_decode($permissions, true);
        if (is_array($decoded)) {
            $permissions = $decoded;
        } elseif ($permissions === '') {
            $permissions = [];
        } else {
            $permissions = [$permissions];
        }
    }
    if (!is_array($permissions)) {
        $permissions = [];
    }
    return [
        'role_id' => isset($role['role_id']) ? (int)$role['role_id'] : 0,
        'role_name' => $role['role_name'] ?? '',
        'role_scope' => $role['role_scope'] ?? '',
        'permissions' => array_values($permissions),
        'tint_hex' => $role['tint_hex'] ?? '#3B82F6',
        'sort_order' => isset($role['sort_order']) ? (int)$role['sort_order'] : 0,
    ];
}
function masterPermissionKeysFromAdmin($admin): array
{
    global $con;
    $permissions = [];
    $rolePermissions = $admin['master_role_permissions_json'] ?? $admin['permissions_json'] ?? '[]';
    if (is_string($rolePermissions)) {
        $decoded = json_decode($rolePermissions, true);
        if (is_array($decoded)) {
            $permissions = array_merge($permissions, array_map('strval', $decoded));
        }
    } elseif (is_array($rolePermissions)) {
        $permissions = array_merge($permissions, array_map('strval', $rolePermissions));
    }
    $roleId = (int)($admin['admin_role_id'] ?? $admin['master_role_id'] ?? 0);
    $permissionRoleId = $roleId === 2 ? 10 : $roleId;
    if ($permissionRoleId > 0 && tableExists('master_role_permissions')) {
        try {
            $stmt = $con->prepare("SELECT permission_key FROM master_role_permissions WHERE role_id = :role_id");
            $stmt->execute([':role_id' => $permissionRoleId]);
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $permissions[] = (string)$row['permission_key'];
            }
        } catch (Throwable $ignored) {
        }
    }
    $adminId = (int)($admin['admin_id'] ?? 0);
    if ($adminId > 0 && tableExists('master_admin_permissions')) {
        try {
            $stmt = $con->prepare("SELECT permission_key, effect FROM master_admin_permissions WHERE admin_id = :admin_id");
            $stmt->execute([':admin_id' => $adminId]);
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $permissionKey = (string)$row['permission_key'];
                if (($row['effect'] ?? 'allow') === 'deny') {
                    $permissions = array_values(array_filter($permissions, static function ($key) use ($permissionKey) {
                        return $key !== $permissionKey;
                    }));
                } else {
                    $permissions[] = $permissionKey;
                }
            }
        } catch (Throwable $ignored) {
        }
    }
    // Employee portals are intentionally bounded to their department. This
    // prevents legacy role rows (especially the old finance role id 2) from
    // leaking unrelated modules into the unified Master dashboard.
    $accountType = strtolower(trim((string)($admin['master_account_type'] ?? '')));
    $roleId = (int)($admin['admin_role_id'] ?? $admin['master_role_id'] ?? 0);
    $portal = strtolower(trim((string)($admin['master_portal_key'] ?? '')));
    if ($portal === '' && $roleId === 2) {
        $portal = 'finance';
    }
    $portalByRole = [
        10 => 'finance',
        11 => 'support',
        12 => 'operations',
        13 => 'merchants',
        14 => 'analytics',
        15 => 'legal',
    ];
    $portal = $portal !== '' ? $portal : ($portalByRole[$roleId] ?? '');
    if ($accountType === 'employee' && $portal !== '') {
        $employeePermissionSets = [
            'finance' => [
                'dashboard.view', 'finance.view', 'finance.refund',
                'finance.withdrawals', 'finance.wallets', 'finance.fees',
                'finance.expenses', 'finance.settlements', 'coupons.view',
                'coupons.create', 'coupons.edit', 'coupons.delete',
            ],
            'support' => [
                'dashboard.view', 'support.view', 'support.reply',
                'support.assign', 'customers.view', 'drivers.view',
                'restaurants.view', 'orders.view',
            ],
            'operations' => [
                'dashboard.view', 'orders.view', 'orders.edit',
                'orders.cancel', 'orders.assign_driver', 'drivers.view',
                'drivers.edit', 'drivers.approve', 'drivers.reject',
                'drivers.suspend', 'restaurants.view', 'restaurants.approve',
                'restaurants.reject', 'customers.view', 'customers.block',
                'settings.view', 'settings.edit',
            ],
            'merchants' => [
                'dashboard.view', 'restaurants.view', 'restaurants.approve',
                'restaurants.reject', 'restaurants.suspend',
                'restaurants.delete', 'restaurants.edit', 'marketing.view',
                'marketing.create', 'marketing.edit', 'marketing.delete',
                'coupons.view', 'coupons.create', 'coupons.edit',
                'coupons.delete',
            ],
            'analytics' => [
                'dashboard.view', 'reports.view', 'reports.export',
                'orders.view', 'customers.view', 'drivers.view',
                'restaurants.view', 'finance.view', 'marketing.view',
            ],
            'legal' => [
                'dashboard.view', 'settings.view', 'settings.edit',
                'administration.view', 'reports.view',
            ],
        ];
        if (isset($employeePermissionSets[$portal])) {
            $allowed = array_fill_keys($employeePermissionSets[$portal], true);
            $permissions = array_values(array_filter(
                $permissions,
                static fn($key) => isset($allowed[(string)$key])
            ));
        }
    }
    return array_values(array_unique(array_filter($permissions, static function ($key) {
        return trim((string)$key) !== '';
    })));
}
function masterHasPermission($admin, $permissionKey): bool
{
    $permissionKey = trim((string)$permissionKey);
    if ($permissionKey === '') {
        return true;
    }
    $permissions = masterPermissionKeysFromAdmin($admin);
    return in_array('super_admin', $permissions, true)
        || in_array('*', $permissions, true)
        || in_array($permissionKey, $permissions, true);
}
function requireMasterPermission($admin, $permissionKey): void
{
    if (!masterHasPermission($admin, $permissionKey)) {
        respondJson([
            'status' => 'error',
            'message' => 'Permission denied',
            'required_permission' => $permissionKey,
        ], 403);
    }
}
function getMasterRoles()
{
    global $con;
    $stmt = $con->query("
        SELECT
            role_id,
            role_name,
            role_scope,
            permissions_json,
            tint_hex,
            sort_order
        FROM master_role_profiles
        ORDER BY sort_order ASC, role_id ASC
    ");
    $roles = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $roles[] = masterRolePublicData($row);
    }
    return $roles;
}
function masterPublicData($admin)
{
    $role = [];
    if (!empty($admin['master_role_id']) || !empty($admin['admin_role_id'])) {
        $role = masterRolePublicData([
            'role_id' => $admin['master_role_id'] ?? $admin['admin_role_id'] ?? 0,
            'role_name' => $admin['master_role_name'] ?? '',
            'role_scope' => $admin['master_role_scope'] ?? '',
            'permissions_json' => $admin['master_role_permissions_json'] ?? '[]',
            'tint_hex' => $admin['master_role_tint_hex'] ?? '#3B82F6',
            'sort_order' => $admin['master_role_sort_order'] ?? 0,
        ]);
        // Return the effective permissions, not the raw legacy role payload,
        // so the client sidebar matches the permissions enforced by APIs.
        $role['permissions'] = masterPermissionKeysFromAdmin($admin);
    }
    return [
        'admin_id' => isset($admin['admin_id']) ? (int)$admin['admin_id'] : 0,
        'admin_name' => $admin['admin_name'] ?? '',
        'admin_email' => $admin['admin_email'] ?? '',
        'admin_phone' => isset($admin['admin_phone']) ? (string)$admin['admin_phone'] : '',
        'admin_profile_image' => $admin['admin_profile_image'] ?? null,
        'admin_approve' => isset($admin['admin_approve']) ? (int)$admin['admin_approve'] : 0,
        'admin_role_id' => isset($admin['admin_role_id']) ? (int)$admin['admin_role_id'] : (isset($admin['master_role_id']) ? (int)$admin['master_role_id'] : 1),
        'admin_last_login_at' => $admin['admin_last_login_at'] ?? null,
        'admin_create' => $admin['admin_create'] ?? null,
        'role' => $role,
    ];
}
function requireMasterAuth()
{
    $token = getBearerToken();
    if ($token === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Unauthorized access',
        ], 401);
    }
    $admin = getMasterBySessionToken($token);
    if (!$admin) {
        respondJson([
            'status' => 'error',
            'message' => 'Session expired or invalid',
        ], 401);
    }
    $admin['_access_token'] = $token;
    return $admin;
}
function requireDashboardActor($allowedRoles = ['vendor', 'master'])
{
    $token = getBearerToken();
    if ($token === '') {
        respondJson([
            'status' => 'error',
            'message' => 'Unauthorized access',
        ], 401);
    }
    if (in_array('vendor', $allowedRoles, true)) {
        $vendor = getVendorBySessionToken($token);
        if ($vendor && ($vendor['vendor_status'] ?? 'pending') === 'active' && (int)($vendor['vendor_is_verified'] ?? 0) === 1) {
            $vendor['_access_token'] = $token;
            return [
                'role' => 'vendor',
                'vendor' => $vendor,
            ];
        }
    }
    if (in_array('master', $allowedRoles, true)) {
        $admin = getMasterBySessionToken($token);
        if ($admin) {
            $admin['_access_token'] = $token;
            return [
                'role' => 'master',
                'master' => $admin,
            ];
        }
    }
    respondJson([
        'status' => 'error',
        'message' => 'Session expired or invalid',
    ], 401);
}
function ensureVendorOrderDeliverySchema(): void
{
    global $con;
    static $schemaReady = false;
    if ($schemaReady || !tableExists('vendor_orders')) {
        return;
    }

    $columns = [
        'delivery_id' => "ALTER TABLE vendor_orders ADD COLUMN delivery_id INT(11) DEFAULT NULL AFTER vendor_status",
        'delivery_status' => "ALTER TABLE vendor_orders ADD COLUMN delivery_status VARCHAR(40) DEFAULT NULL AFTER delivery_id",
        'delivery_assigned_at' => "ALTER TABLE vendor_orders ADD COLUMN delivery_assigned_at DATETIME DEFAULT NULL AFTER delivery_status",
    ];
    foreach ($columns as $columnName => $sql) {
        if (!columnExists('vendor_orders', $columnName)) {
            $con->exec($sql);
        }
    }
    if (!indexExists('vendor_orders', 'idx_vendor_orders_delivery')) {
        $con->exec("ALTER TABLE vendor_orders ADD KEY idx_vendor_orders_delivery (delivery_id, delivery_status)");
    }
    $schemaReady = true;
}

function ensureVendorPrintingSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }
    if (!tableExists('vendor_printers')) {
        $con->exec("
            CREATE TABLE vendor_printers (
                printer_id INT(11) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL,
                printer_name VARCHAR(191) NOT NULL,
                printer_model VARCHAR(191) DEFAULT NULL,
                printer_type VARCHAR(40) NOT NULL DEFAULT 'invoice',
                printer_location VARCHAR(191) DEFAULT NULL,
                printer_sections_json LONGTEXT DEFAULT NULL,
                printer_ip VARCHAR(64) DEFAULT NULL,
                printer_port INT(11) DEFAULT NULL,
                is_connected TINYINT(1) NOT NULL DEFAULT 0,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                last_print_at DATETIME DEFAULT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (printer_id),
                KEY idx_vendor_printers_vendor (vendor_id),
                KEY idx_vendor_printers_active (vendor_id, is_active)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $printerColumns = [
            "printer_model" => "ALTER TABLE vendor_printers ADD COLUMN printer_model VARCHAR(191) DEFAULT NULL",
            "printer_type" => "ALTER TABLE vendor_printers ADD COLUMN printer_type VARCHAR(40) NOT NULL DEFAULT 'invoice'",
            "printer_location" => "ALTER TABLE vendor_printers ADD COLUMN printer_location VARCHAR(191) DEFAULT NULL",
            "printer_sections_json" => "ALTER TABLE vendor_printers ADD COLUMN printer_sections_json LONGTEXT DEFAULT NULL",
            "printer_ip" => "ALTER TABLE vendor_printers ADD COLUMN printer_ip VARCHAR(64) DEFAULT NULL",
            "printer_port" => "ALTER TABLE vendor_printers ADD COLUMN printer_port INT(11) DEFAULT NULL",
            "is_connected" => "ALTER TABLE vendor_printers ADD COLUMN is_connected TINYINT(1) NOT NULL DEFAULT 0",
            "is_active" => "ALTER TABLE vendor_printers ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1",
            "last_print_at" => "ALTER TABLE vendor_printers ADD COLUMN last_print_at DATETIME DEFAULT NULL",
            "created_at" => "ALTER TABLE vendor_printers ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
            "updated_at" => "ALTER TABLE vendor_printers ADD COLUMN updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
        ];
        foreach ($printerColumns as $columnName => $sql) {
            if (!columnExists('vendor_printers', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('vendor_invoice_templates')) {
        $con->exec("
            CREATE TABLE vendor_invoice_templates (
                template_id INT(11) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL,
                template_name VARCHAR(191) NOT NULL,
                template_type VARCHAR(40) NOT NULL DEFAULT 'invoice',
                paper_width_mm INT(11) DEFAULT 80,
                paper_height_mm INT(11) DEFAULT NULL,
                template_usage VARCHAR(191) DEFAULT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (template_id),
                KEY idx_vendor_invoice_templates_vendor (vendor_id),
                KEY idx_vendor_invoice_templates_active (vendor_id, is_active)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $templateColumns = [
            "template_type" => "ALTER TABLE vendor_invoice_templates ADD COLUMN template_type VARCHAR(40) NOT NULL DEFAULT 'invoice'",
            "paper_width_mm" => "ALTER TABLE vendor_invoice_templates ADD COLUMN paper_width_mm INT(11) DEFAULT 80",
            "paper_height_mm" => "ALTER TABLE vendor_invoice_templates ADD COLUMN paper_height_mm INT(11) DEFAULT NULL",
            "template_usage" => "ALTER TABLE vendor_invoice_templates ADD COLUMN template_usage VARCHAR(191) DEFAULT NULL",
            "is_active" => "ALTER TABLE vendor_invoice_templates ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1",
            "created_at" => "ALTER TABLE vendor_invoice_templates ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
            "updated_at" => "ALTER TABLE vendor_invoice_templates ADD COLUMN updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
        ];
        foreach ($templateColumns as $columnName => $sql) {
            if (!columnExists('vendor_invoice_templates', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('vendor_print_settings')) {
        $con->exec("
            CREATE TABLE vendor_print_settings (
                setting_id INT(11) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL,
                default_direction VARCHAR(24) NOT NULL DEFAULT 'rtl_ar',
                default_font_size VARCHAR(24) NOT NULL DEFAULT 'medium',
                invoice_copies INT(11) NOT NULL DEFAULT 1,
                print_logo TINYINT(1) NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (setting_id),
                UNIQUE KEY uniq_vendor_print_settings_vendor (vendor_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $settingsColumns = [
            "default_direction" => "ALTER TABLE vendor_print_settings ADD COLUMN default_direction VARCHAR(24) NOT NULL DEFAULT 'rtl_ar'",
            "default_font_size" => "ALTER TABLE vendor_print_settings ADD COLUMN default_font_size VARCHAR(24) NOT NULL DEFAULT 'medium'",
            "invoice_copies" => "ALTER TABLE vendor_print_settings ADD COLUMN invoice_copies INT(11) NOT NULL DEFAULT 1",
            "print_logo" => "ALTER TABLE vendor_print_settings ADD COLUMN print_logo TINYINT(1) NOT NULL DEFAULT 1",
            "created_at" => "ALTER TABLE vendor_print_settings ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
            "updated_at" => "ALTER TABLE vendor_print_settings ADD COLUMN updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
        ];
        foreach ($settingsColumns as $columnName => $sql) {
            if (!columnExists('vendor_print_settings', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    if (!tableExists('vendor_print_jobs')) {
        $con->exec("
            CREATE TABLE vendor_print_jobs (
                job_id BIGINT(20) NOT NULL AUTO_INCREMENT,
                vendor_id INT(11) NOT NULL,
                order_id INT(11) DEFAULT NULL,
                printer_id INT(11) DEFAULT NULL,
                template_id INT(11) DEFAULT NULL,
                job_type VARCHAR(40) NOT NULL DEFAULT 'invoice',
                job_status VARCHAR(40) NOT NULL DEFAULT 'printed',
                job_payload LONGTEXT DEFAULT NULL,
                printed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (job_id),
                KEY idx_vendor_print_jobs_vendor_date (vendor_id, printed_at),
                KEY idx_vendor_print_jobs_printer (printer_id),
                KEY idx_vendor_print_jobs_template (template_id),
                KEY idx_vendor_print_jobs_order (order_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ");
    } else {
        $jobColumns = [
            "order_id" => "ALTER TABLE vendor_print_jobs ADD COLUMN order_id INT(11) DEFAULT NULL",
            "printer_id" => "ALTER TABLE vendor_print_jobs ADD COLUMN printer_id INT(11) DEFAULT NULL",
            "template_id" => "ALTER TABLE vendor_print_jobs ADD COLUMN template_id INT(11) DEFAULT NULL",
            "job_type" => "ALTER TABLE vendor_print_jobs ADD COLUMN job_type VARCHAR(40) NOT NULL DEFAULT 'invoice'",
            "job_status" => "ALTER TABLE vendor_print_jobs ADD COLUMN job_status VARCHAR(40) NOT NULL DEFAULT 'printed'",
            "job_payload" => "ALTER TABLE vendor_print_jobs ADD COLUMN job_payload LONGTEXT DEFAULT NULL",
            "printed_at" => "ALTER TABLE vendor_print_jobs ADD COLUMN printed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
            "created_at" => "ALTER TABLE vendor_print_jobs ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP",
        ];
        foreach ($jobColumns as $columnName => $sql) {
            if (!columnExists('vendor_print_jobs', $columnName)) {
                $con->exec($sql);
            }
        }
    }
    $schemaReady = true;
}
