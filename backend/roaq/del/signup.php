<?php

include "connect.php";

$name = filterRequest("username");
$password = filterRequest("password");
$phone = filterRequest("phone");

$stmt = $con->prepare("SELECT * FROM users WHERE users_email = ? OR users_phone = ? ");
$stmt->execute(array($name, $phone));
$count = $stmt->rowCount();
if ($count > 0) {
    printFailure("PHONE OR EMAIL");
} else {

    $data = array(
        "users_name" => $username,
        "users_password" =>  $password,
        "users_email" => $email,
        "users_phone" => $phone,
        "users_verfiycode" => $verfiycode ,
    );
    sendEmail($email , "Verfiy Code T.K.S_company" , "Verfiy Code $verfiycode") ; 
    insertData("users" , $data) ; 

}