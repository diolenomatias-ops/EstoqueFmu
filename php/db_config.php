<?php
// Configurações do Banco de Dados 
$host = "localhost";
$db_user = ""; // Substitua pelo usuário que você criou no MySQL do cPanel
$db_pass = "";        // Substitua pela senha que você definiu para esse usuário
$db_name = "";

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // IMPORTANTE: Permite que o App Flutter acesse o servidor
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");
    header("Content-Type: application/json; charset=UTF-8");
    
} catch(PDOException $e) {
    die(json_encode(["status" => "error", "message" => "Erro: " . $e->getMessage()]));
}
?>