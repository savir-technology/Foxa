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









function deleteFile($dir, $imagename)
{
    if (file_exists($dir . "/" . $imagename)) {
        unlink($dir . "/" . $imagename);
    }
}

function checkAuthenticate()
{
    if (isset($_SERVER['PHP_AUTH_USER'])  && isset($_SERVER['PHP_AUTH_PW'])) {
        if ($_SERVER['PHP_AUTH_USER'] != "wael" ||  $_SERVER['PHP_AUTH_PW'] != "wael12345") {
            header('WWW-Authenticate: Basic realm="My Realm"');
            header('HTTP/1.0 401 Unauthorized');
            echo 'Page Not Found';
            exit;
        }
    } else {
        exit;
    }

    // End 
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

function sendEmailWithFallback($to, $subject, $message)
{
    if (sendEmail($to, $subject, $message)) {
        return true;
    }

    try {
        $mail = new PHPMailer(true);
        $mail->isMail();
        $mail->CharSet = 'UTF-8';
        $mail->setFrom('no-reply@aleppoeats.com', 'FOXA');
        $mail->addAddress($to);
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body = $message;
        $mail->AltBody = strip_tags($message);
        $mail->send();

        return true;
    } catch (Throwable $mailError) {
        error_log('Fallback mail() sending failed: ' . $mailError->getMessage());
        return false;
    }
}

function respondJson($payload, $statusCode = 200)
{
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
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
    if (!is_array($payload)) {
        $payload = $_GET;
    }
    return is_array($payload) ? $payload : [];
}

function isProductionEnvironment()
{
    $envValue = strtolower((string)(
        getenv('APP_ENV') ?:
        getenv('ENVIRONMENT') ?:
        getenv('SERVER_ENV') ?:
        'production'
    ));

    return !in_array($envValue, ['local', 'local-dev', 'development', 'dev', 'testing', 'test'], true);
}

function generateOtpCode($length = 5)
{
    $length = max(4, (int)$length);
    $min = (int)pow(10, $length - 1);
    $max = (int)pow(10, $length) - 1;

    return str_pad((string)random_int($min, $max), $length, '0', STR_PAD_LEFT);
}

function driverTableExists($tableName)
{
    global $con;

    try {
        $stmt = $con->prepare("
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = DATABASE()
              AND table_name = :table_name
        ");
        $stmt->execute([':table_name' => $tableName]);

        return (int)$stmt->fetchColumn() > 0;
    } catch (Throwable $e) {
        error_log('driverTableExists failed for ' . $tableName . ': ' . $e->getMessage());
        return false;
    }
}

function driverColumnExists($tableName, $columnName)
{
    global $con;

    try {
        $stmt = $con->prepare("
            SELECT COUNT(*)
            FROM information_schema.columns
            WHERE table_schema = DATABASE()
              AND table_name = :table_name
              AND column_name = :column_name
        ");
        $stmt->execute([
            ':table_name' => $tableName,
            ':column_name' => $columnName,
        ]);

        return (int)$stmt->fetchColumn() > 0;
    } catch (Throwable $e) {
        error_log('driverColumnExists failed for ' . $tableName . '.' . $columnName . ': ' . $e->getMessage());
        return false;
    }
}

function ensureDriverOtpSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }

    if (!driverTableExists('driver_email_otp_requests')) {
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

    if (driverTableExists('delivery_users')) {
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
            'approval_status' => "ALTER TABLE delivery_users ADD COLUMN approval_status ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending' AFTER status",
        ];

        foreach ($driverColumns as $columnName => $sql) {
            try {
                if (!driverColumnExists('delivery_users', $columnName)) {
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
    }

    $schemaReady = true;
}

function ensureDriverSupportSchema()
{
    global $con;
    static $schemaReady = false;

    if ($schemaReady) {
        return;
    }

    $con->exec("
        CREATE TABLE IF NOT EXISTS driver_support_messages (
            support_message_id BIGINT(20) NOT NULL AUTO_INCREMENT,
            driver_id INT(11) NOT NULL,
            sender_role VARCHAR(32) NOT NULL DEFAULT 'driver',
            message TEXT NOT NULL,
            audio_url VARCHAR(255) DEFAULT NULL,
            is_read_by_driver TINYINT(1) NOT NULL DEFAULT 0,
            is_read_by_admin TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (support_message_id),
            KEY idx_driver_support_driver_created (driver_id, created_at, support_message_id),
            KEY idx_driver_support_sender (sender_role, driver_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    $schemaReady = true;
}

function sendEmail($to, $subject, $message)
{
    $mail = new PHPMailer(true);
    try {
        // إعدادات السيرفر
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com';
        $mail->SMTPAuth = true;
        $mail->Username = 'emtkatof@gmail.com'; // بريدك الإلكتروني
        $mail->Password = 'ozvo omup hfsl kyxv'; // كلمة مرور التطبيق
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;

        // إعدادات البريد الإلكتروني
        $mail->setFrom('emtkatof@gmail.com', 'T.K.S.company');
        $mail->addAddress($to); // تغيير العنوان إلى العنوان الذي تريد الإرسال إليه
        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body = $message;
        $mail->AltBody = strip_tags($message); // نص بديل للحالة التي لا يدعم فيها البريد الإلكتروني HTML

        $mail->send();
        return true; // إعادة قيمة تعبر عن نجاح العملية
    } catch (Exception $e) {
        error_log("Email sending failed: " . $mail->ErrorInfo); // تسجيل الخطأ في ملف السجلات
        return false; // إعادة قيمة تعبر عن فشل العملية
    }
}
