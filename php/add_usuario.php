<?php
include 'db_config.php';

$user = $_POST['username'] ?? '';
$email = $_POST['email'] ?? '';
$pass = $_POST['senha'] ?? '';
$tipo = $_POST['tipo_usuario'] ?? 'cliente';

if (empty($user) || empty($pass) || empty($email)) {
    echo json_encode(["status" => "error", "message" => "Preencha tudo"]);
    exit;
}

try {
    $stmt = $conn->prepare("INSERT INTO usuarios (username, email, senha, tipo_usuario) VALUES (?, ?, ?, ?)");
    $stmt->execute([$user, $email, $pass, $tipo]);
    echo json_encode(["status" => "success", "message" => "Usuário criado!"]);
} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => "Erro: " . $e->getMessage()]);
}
?>