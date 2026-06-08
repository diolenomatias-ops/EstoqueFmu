<?php
include 'db_config.php';
$id = $_POST['id'];
$qtdSubtrair = $_POST['quantidade'];
// Diminui a quantidade atual no banco
$conn->query("UPDATE produtos SET quantidade = quantidade - $qtdSubtrair WHERE id = $id");
echo json_encode(["status" => "success"]);
?>