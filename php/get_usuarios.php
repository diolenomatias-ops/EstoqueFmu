<?php
include 'db_config.php';

try {
    $stmt = $conn->prepare("SELECT id, username, email, tipo_usuario FROM usuarios");
    $stmt->execute();
    $usuarios = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($usuarios);
} catch(Exception $e) {
    echo json_encode([]);
}
?>