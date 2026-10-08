<?php
include 'db_config.php';

try {
    $stmt = $conn->prepare("SELECT * FROM produtos");
    $stmt->execute();
    $produtos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Se não houver produtos, retorna um array vazio [] em vez de nada
    echo json_encode($produtos ?: []); 
} catch(Exception $e) {
    echo json_encode([]); // Retorna vazio em caso de erro para não travar o app
}
?>