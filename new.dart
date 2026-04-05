Future<void> _login() async {
  setState(() => _isLoading = true);

  try {
    var response = await http.post(
      Uri.parse("$baseUrl/login.php"),
      body: {
        "username": _userController.text, "senha": _passController.text,
      },
    );

    var data = json.decode(response.body);

    if (data['status'] == "success") {
      UserSession.id = int.parse(data['data']['id'].toString());
      UserSession.username = data['data']['username'];
      UserSession.tipo =
      data['data']['tipo_usuario']; // cliente, funcionario ou admin
      UserSession.isLoggedIn = true;
      Navigator.pushReplacementNamed(context, '/estoque');
    } else {
      _showError("Usuário ou senha inválidos");
    }
  } catch (e) {
    _showError("Erro de conexão com o servidor");
  } finally {
    setState(() => _isLoading = false);
  }
}