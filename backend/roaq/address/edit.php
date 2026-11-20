<?php 

include '../connect.php';

$table = "address";

$usersid    = filterRequest("usersid");
$name       = filterRequest("name");
$city       = filterRequest("city");
$street     = filterRequest("street");
$phone        = filterRequest("phone");
$addressid   = filterRequest("addressid");
$addressLat  = filterRequest("address_lat");
$addressLong = filterRequest("address_long");

$data = array(  
"address_city" => $city,
"address_usersid" => $usersid,
"address_name"   => $name,
"address_street" => $street,
"address_phone" => $phone,
"address_lat" => $addressLat !== '' ? $addressLat : null,
"address_long" => $addressLong !== '' ? $addressLong : null,

);

updateData($table , $data , "address_id = $addressid");
