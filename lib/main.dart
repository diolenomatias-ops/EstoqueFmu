import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

// IMPORTANTE: Altere para a URL real da sua pasta 'api' no HostGator
const String baseUrl = "https://innometrics.com.br/api";

class UserSession {
  static int? id;
  static String? username;
  static String? tipo; // 'admin', 'funcionario', 'cliente'
  static bool isLoggedIn = false;

  static void logout() {
    id = null;
    username = null;
    tipo = null;
    isLoggedIn = false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Estoque Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4299E1)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/estoque': (context) => const EstoqueScreen(),
        '/usuarios': (context) => const GerenciarUsuariosScreen(),
        '/cadastro_produto': (context) => const CadastroProdutoScreen(),
      },
    );
  }
}

// --- 1. TELA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Preencha todos os campos");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        body: {
          "username": _userController.text,
          "senha": _passController.text,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == "success") {
          setState(() {
            UserSession.id = int.parse(data['data']['id'].toString());
            UserSession.username = data['data']['username'];
            UserSession.tipo = data['data']['tipo_usuario'];
            UserSession.isLoggedIn = true;
          });
          Navigator.pushReplacementNamed(context, '/estoque');
        } else {
          _showError(data['message'] ?? "Dados incorretos");
        }
      } else {
        _showError("Erro no servidor");
      }
    } catch (e) {
      _showError("Erro de conexão. Verifique o HostGator.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.home_work_rounded, size: 100, color: Color(0xFF4299E1)),
              const SizedBox(height: 10),
              const Text('Estoque Master', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: 'Usuário',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4299E1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Entrar', style: TextStyle(fontSize: 22, color: Colors.white)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. TELA DE ESTOQUE ---
class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  List<dynamic> _produtos = [];
  List<dynamic> _filteredProdutos = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProdutos();
  }

  Future<void> _fetchProdutos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_produtos.php"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _produtos = data is List ? data : [];
          _filteredProdutos = _produtos;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _darBaixaEstoque(int id, int qtdSubtrair) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/baixa_estoque.php"),
        body: {"id": id.toString(), "quantidade": qtdSubtrair.toString()},
      );
      _fetchProdutos();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estoque atualizado!")));
    } catch (e) {
      print("Erro: $e");
    }
  }

  Future<void> _excluirProduto(int id) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/excluir_produto.php"),
        body: {"id": id.toString()},
      );
      _fetchProdutos();
      Navigator.pop(context);
    } catch (e) {
      print("Erro: $e");
    }
  }

  void _filter(String query) {
    setState(() {
      _filteredProdutos = _produtos
          .where((p) => p['nome_produto'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel ${UserSession.username?.toUpperCase()} (${UserSession.tipo?.toUpperCase()})'),
        actions: [
          if (UserSession.tipo == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, '/usuarios'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              UserSession.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Pesquisar produto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchProdutos,
                  child: ListView.builder(
                    itemCount: _filteredProdutos.length,
                    itemBuilder: (context, index) {
                      final p = _filteredProdutos[index];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2, color: Color(0xFF4299E1)),
                        title: Text(p['nome_produto'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Quantidade: ${p['quantidade']}'),
                        trailing: UserSession.tipo != 'cliente' 
                          ? IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _modalAcoes(p),
                            )
                          : null,
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: (UserSession.tipo == 'admin' || UserSession.tipo == 'funcionario')
        ? FloatingActionButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/cadastro_produto');
              _fetchProdutos();
            },
            child: const Icon(Icons.add),
          )
        : null,
    );
  }

  void _modalAcoes(dynamic produto) {
    final qtdController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(produto['nome_produto'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (UserSession.tipo != 'cliente') ...[
              TextField(
                controller: qtdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantidade para retirar", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.remove_circle),
                  label: const Text("Confirmar Baixa"),
                  onPressed: () {
                    if (qtdController.text.isNotEmpty) {
                      _darBaixaEstoque(int.parse(produto['id'].toString()), int.parse(qtdController.text));
                    }
                  },
                ),
              ),
            ],
            if (UserSession.tipo == 'admin')
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text("Excluir Produto Permanentemente"),
                onPressed: () => _excluirProduto(int.parse(produto['id'].toString())),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 3. TELA DE CADASTRO DE PRODUTO ---
class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({super.key});
  @override
  State<CadastroProdutoScreen> createState() => _CadastroProdutoScreenState();
}

class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  final nomeCtrl = TextEditingController();
  final qtdCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _salvarNoBanco() async {
    if (nomeCtrl.text.isEmpty || qtdCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await http.post(
        Uri.parse("$baseUrl/add_produto.php"),
        body: {
          "nome_produto": nomeCtrl.text,
          "quantidade": qtdCtrl.text,
          "usuario_id": UserSession.id.toString(),
        },
      );
      Navigator.pop(context);
    } catch (e) {
      print("Erro: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Novo Produto')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto')),
            const SizedBox(height: 10),
            TextField(controller: qtdCtrl, decoration: const InputDecoration(labelText: 'Quantidade Inicial'), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            _isSaving 
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _salvarNoBanco, 
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4299E1)),
                    child: const Text('Salvar no Estoque', style: TextStyle(color: Colors.white)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// --- 4. TELA DE GERENCIAR USUÁRIOS ---
class GerenciarUsuariosScreen extends StatefulWidget {
  const GerenciarUsuariosScreen({super.key});

  @override
  State<GerenciarUsuariosScreen> createState() => _GerenciarUsuariosScreenState();
}

class _GerenciarUsuariosScreenState extends State<GerenciarUsuariosScreen> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_usuarios.php"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _usuarios = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirUsuario(int id) async {
    try {
      await http.post(Uri.parse("$baseUrl/excluir_usuario.php"), body: {"id": id.toString()});
      _fetchUsuarios();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _editarUsuario(int id, String nome, String tipo, String senha) async {
    try {
      Map<String, String> body = {
        "id": id.toString(), 
        "username": nome, 
        "tipo_usuario": tipo
      };
      if (senha.isNotEmpty) {
        body["senha"] = senha;
      }

      await http.post(
        Uri.parse("$baseUrl/editar_usuario.php"),
        body: body,
      );
      _fetchUsuarios();
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  void _mostrarDialogoEditar(dynamic user) {
    final nomeCtrl = TextEditingController(text: user['username']);
    final senhaCtrl = TextEditingController();
    String cargo = user['tipo_usuario'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Usuário"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome")),
              TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Nova Senha (deixe em branco para manter)")),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: cargo,
                items: ['cliente', 'funcionario', 'admin'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => cargo = v!,
                decoration: const InputDecoration(labelText: "Cargo"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => _editarUsuario(int.parse(user['id'].toString()), nomeCtrl.text, cargo, senhaCtrl.text),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _addUsuario(String user, String email, String senha, String tipo) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_usuario.php"),
        body: {
          "username": user,
          "email": email,
          "senha": senha,
          "tipo_usuario": tipo,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        _fetchUsuarios();
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao conectar")));
    }
  }

  void _mostrarDialogoNovoUsuario() {
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    String tipoSelecionado = 'cliente';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Usuário"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Usuário")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Senha")),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                items: ['cliente', 'funcionario', 'admin'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => tipoSelecionado = v!,
                decoration: const InputDecoration(labelText: "Cargo / Permissão"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (userCtrl.text.isNotEmpty && senhaCtrl.text.isNotEmpty) {
                _addUsuario(userCtrl.text, emailCtrl.text, senhaCtrl.text, tipoSelecionado);
              }
            },
            child: const Text("Cadastrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Equipe')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['username'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cargo: ${user['tipo_usuario']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarDialogoEditar(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _excluirUsuario(int.parse(user['id'].toString())),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoUsuario,
        label: const Text('Novo Usuário'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
