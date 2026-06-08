<?php
include 'db_config.php';
$nome = $_POST['nome_produto'];
$qtd = $_POST['quantidade'];
$user_id = $_POST['usuario_id'];
$conn->query("INSERT INTO produtos (nome_produto, quantidade, usuario_id) VALUES ('$nome', $qtd, $user_id)");
echo json_encode(["status" => "success"]);
?>