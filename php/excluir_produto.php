<?php
include 'db_config.php';
$id = $_POST['id'];
$conn->query("DELETE FROM produtos WHERE id = $id");
echo json_encode(["status" => "success"]);
?>