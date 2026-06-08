<?php
include 'db_config.php';

$id = $_POST['id'];
$user = $_POST['username'];
$tipo = $_POST['tipo_usuario'];
$senha = $_POST['senha'] ?? '';

// Se a senha foi enviada, atualiza ela também. Se não, mantém a atual.
if (!empty($senha)) {
    $sql = "UPDATE usuarios SET username = '$user', tipo_usuario = '$tipo', senha = '$senha' WHERE id = $id";
} else {
    $sql = "UPDATE usuarios SET username = '$user', tipo_usuario = '$tipo' WHERE id = $id";
}

$conn->query($sql);
echo json_encode(["status" => "success"]);
?>