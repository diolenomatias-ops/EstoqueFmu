import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

const String baseUrl = "https://innometrics.com.br/api";

class UserSession {
  static int? id;
  static String? username;
  static String? tipo;
  static bool isLoggedIn = false;

  static void logout() {
    id = null; username = null; tipo = null; isLoggedIn = false;
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

// --- 1. TELA DE LOGIN (ESTILO BLACK COM LOGO INNOMETRICS) ---
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        body: {"username": _userController.text, "senha": _passController.text},
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Credenciais incorretas")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro de conexão com o HostGator")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Image.asset('assets/icon.png', height: 220, fit: BoxFit.contain),
              const SizedBox(height: 10),
              const Text('ESTOQUE MASTER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Usuário',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF4299E1), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF4299E1), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF4299E1)) 
                : SizedBox(
                    width: double.infinity, 
                    height: 55, 
                    child: ElevatedButton(
                      onPressed: _login, 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4299E1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('ENTRAR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                    )
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. TELA DE ESTOQUE (COM BOTÃO ARRASTÁVEL) ---
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

  Offset _fabPosition = const Offset(0, 0);
  bool _isPositionInitialized = false;

  @override
  void initState() { super.initState(); _fetchProdutos(); }

  Future<void> _fetchProdutos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_produtos.php")).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { _produtos = data is List ? data : []; _filteredProdutos = _produtos; _isLoading = false; });
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  void _modalAcoes(dynamic produto) {
    final qtdController = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(produto['nome_produto'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (UserSession.tipo != 'cliente') ...[
            const SizedBox(height: 15),
            TextField(controller: qtdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantidade para retirar", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
              await http.post(Uri.parse("$baseUrl/baixa_estoque.php"), body: {"id": produto['id'].toString(), "quantidade": qtdController.text});
              _fetchProdutos(); Navigator.pop(context);
            }, child: const Text("Confirmar Baixa"))),
          ],
          if (UserSession.tipo == 'admin') TextButton(onPressed: () async {
            await http.post(Uri.parse("$baseUrl/excluir_produto.php"), body: {"id": produto['id'].toString()});
            _fetchProdutos(); Navigator.pop(context);
          }, child: const Text("Excluir Permanentemente", style: TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ESTOQUE: ${UserSession.username?.toUpperCase()}'), actions: [
        if (UserSession.tipo == 'admin') IconButton(icon: const Icon(Icons.group), onPressed: () => Navigator.pushNamed(context, '/usuarios')),
        IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/'))
      ]),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_isPositionInitialized) {
            _fabPosition = Offset(constraints.maxWidth - 80, constraints.maxHeight - 80);
            _isPositionInitialized = true;
          }

          return Stack(
            children: [
              Column(children: [
                Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, onChanged: (v) => setState(() => _filteredProdutos = _produtos.where((p) => p['nome_produto'].toString().toLowerCase().contains(v.toLowerCase())).toList()), decoration: const InputDecoration(hintText: 'Pesquisar produto...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))))),
                Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _filteredProdutos.length, itemBuilder: (context, index) { 
                  final p = _filteredProdutos[index]; 
                  return ListTile(leading: const Icon(Icons.inventory_2, color: Color(0xFF4299E1)), title: Text(p['nome_produto'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Qtd: ${p['quantidade']}'), trailing: UserSession.tipo != 'cliente' ? IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _modalAcoes(p)) : null); 
                }))
              ]),

              // BOTÃO REALMENTE ARRASTÁVEL
              if (UserSession.tipo != 'cliente')
                Positioned(
                  left: _fabPosition.dx,
                  top: _fabPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _fabPosition += details.delta;
                        // Limites para não sair da tela
                        _fabPosition = Offset(
                          _fabPosition.dx.clamp(0, constraints.maxWidth - 65),
                          _fabPosition.dy.clamp(0, constraints.maxHeight - 65),
                        );
                      });
                    },
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFF4299E1),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/cadastro_produto');
                        _fetchProdutos();
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                  ),
                ),
            ],
          );
        }
      ),
    );
  }
}

// --- 3. TELA DE CADASTRO PRODUTO ---
class CadastroProdutoScreen extends StatefulWidget {
  const CadastroProdutoScreen({super.key});
  @override State<CadastroProdutoScreen> createState() => _CadastroProdutoScreenState();
}
class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
  final nomeCtrl = TextEditingController(); final qtdCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Novo Produto')), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder())),
      const SizedBox(height: 15),
      TextField(controller: qtdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade Inicial', border: OutlineInputBorder())),
      const SizedBox(height: 30),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async { 
        await http.post(Uri.parse("$baseUrl/add_produto.php"), body: {"nome_produto": nomeCtrl.text, "quantidade": qtdCtrl.text, "usuario_id": UserSession.id.toString()}); 
        Navigator.pop(context); 
      }, child: const Text('Salvar no Banco')))
    ])));
  }
}

// --- 4. TELA GESTÃO DE EQUIPE (TAMBÉM COM BOTÃO ARRASTÁVEL) ---
class GerenciarUsuariosScreen extends StatefulWidget {
  const GerenciarUsuariosScreen({super.key});
  @override State<GerenciarUsuariosScreen> createState() => _GerenciarUsuariosScreenState();
}
class _GerenciarUsuariosScreenState extends State<GerenciarUsuariosScreen> {
  List<dynamic> _usuarios = []; bool _isLoading = true;
  Offset _fabPosition = const Offset(0, 0);
  bool _isPositionInitialized = false;

  @override void initState() { super.initState(); _fetchUsuarios(); }

  Future<void> _fetchUsuarios() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_usuarios.php"));
      if (response.statusCode == 200) setState(() { _usuarios = json.decode(response.body); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Equipe')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_isPositionInitialized) {
            _fabPosition = Offset(constraints.maxWidth - 80, constraints.maxHeight - 80);
            _isPositionInitialized = true;
          }
          return Stack(
            children: [
              _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _usuarios.length, itemBuilder: (context, index) {
                final user = _usuarios[index];
                return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Cargo: ${user['tipo_usuario']}'), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                  await http.post(Uri.parse("$baseUrl/excluir_usuario.php"), body: {"id": user['id'].toString()});
                  _fetchUsuarios();
                })));
              }),
              Positioned(
                left: _fabPosition.dx,
                top: _fabPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _fabPosition += details.delta;
                      _fabPosition = Offset(_fabPosition.dx.clamp(0, constraints.maxWidth - 65), _fabPosition.dy.clamp(0, constraints.maxHeight - 65));
                    });
                  },
                  child: FloatingActionButton(backgroundColor: const Color(0xFF4299E1), onPressed: () => _mostrarDialogoNovo(), child: const Icon(Icons.person_add, color: Colors.white)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  void _mostrarDialogoNovo() {
    final u = TextEditingController(); final s = TextEditingController(); final e = TextEditingController(); String c = 'cliente';
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Novo Usuário"), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: u, decoration: const InputDecoration(labelText: "Usuário")),
      TextField(controller: e, decoration: const InputDecoration(labelText: "Email")),
      TextField(controller: s, obscureText: true, decoration: const InputDecoration(labelText: "Senha")),
      DropdownButtonFormField<String>(value: c, items: ['cliente', 'funcionario', 'admin'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => c = v!),
    ]), actions: [ElevatedButton(onPressed: () async { await http.post(Uri.parse("$baseUrl/add_usuario.php"), body: {"username": u.text, "email": e.text, "senha": s.text, "tipo_usuario": c}); _fetchUsuarios(); Navigator.pop(ctx); }, child: const Text("Salvar"))]));
  }
}
