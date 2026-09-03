import 'package:flutter/material.dart';
import 'main.dart';

class UsuarioModel {
  String usuario;
  String senha;
  String tipo;
  String cargo;
  int jornada;
  bool primeiroAcesso;

  UsuarioModel({
    required this.usuario,
    required this.senha,
    required this.tipo,
    required this.cargo,
    required this.jornada,
    this.primeiroAcesso = false,
  });
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _exibirSplash = true;
  double _progressoSplash = 0.0;
  bool _mostrarSenha = false;

  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  // Banco de dados em memória
  static final List<UsuarioModel> _bancoUsuarios = [
    UsuarioModel(
      usuario: 'jefferson.espanha',
      senha: 'odio',
      tipo: 'admin',
      cargo: 'Diretor',
      jornada: 8,
      primeiroAcesso: false,
    ),
  ];

  final List<String> _listaCargos = const [
    "Oficial Administrativo",
    "Assessor I",
    "Assessor II",
    "Diretor",
    "Diretora",
    "Chefe de Divisão",
    "Estagiário",
    "Estagiária",
    "Adjunto Procurador-Geral",
    "Procurador-Geral",
  ];

  @override
  void initState() {
    super.initState();
    _iniciarSplash();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _iniciarSplash() async {
    for (int i = 1; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (mounted) {
        setState(() {
          _progressoSplash = i / 100;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _exibirSplash = false;
      });
    }
  }

  void _validarAcesso() {
    final String u = _userCtrl.text.trim().toLowerCase();
    final String s = _passCtrl.text.trim();

    if (u.isEmpty || s.isEmpty) {
      _mostrarAlerta("Erro", "Preencha o usuário e a senha.");
      return;
    }

    try {
      final userEncontrado = _bancoUsuarios.firstWhere(
        (element) => element.usuario.toLowerCase() == u && element.senha == s,
      );

      if (userEncontrado.primeiroAcesso) {
        _janelaTrocarSenha(userEncontrado);
      } else {
        _redirecionarParaSistema(userEncontrado);
      }
    } catch (_) {
      _mostrarAlerta("Erro", "Login ou Senha Incorretos!");
    }
  }

  void _redirecionarParaSistema(UsuarioModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPontoPrincipal(
          usuario: user.usuario.toUpperCase(),
          cargoInicial: user.cargo.toUpperCase(),
          tipoUsuario: user.tipo,
        ),
      ),
    );
  }

  void _janelaTrocarSenha(UsuarioModel user) {
    final TextEditingController novaSenhaCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Olá, ${user.usuario}!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Primeiro acesso detectado.\nCrie sua senha definitiva:",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: novaSenhaCtrl,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: "Nova Senha",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final String senhaTxt = novaSenhaCtrl.text.trim();
              if (senhaTxt.length < 3) {
                _mostrarAlerta("Aviso", "A senha deve ter pelo menos 3 caracteres.");
                return;
              }

              setState(() {
                user.senha = senhaTxt;
                user.primeiroAcesso = false;
              });

              Navigator.pop(context);
              _passCtrl.clear();
              _mostrarAlerta("Sucesso", "Senha atualizada com sucesso!\nFaça login novamente.");
            },
            child: const Text("SALVAR NOVA SENHA"),
          ),
        ],
      ),
    );
  }

  void _verificarCadastro() {
    _pedirChaveAdmin((autorizado) {
      if (autorizado) _janelaCadastro();
    });
  }

  void _verificarExclusao() {
    _pedirChaveAdmin((autorizado) {
      if (autorizado) _janelaExcluir();
    });
  }

  void _pedirChaveAdmin(ValueChanged<bool> onSuccess) {
    final TextEditingController ctrlChave = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Segurança"),
        content: TextField(
          controller: ctrlChave,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Chave Administrativa:",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrlChave.text.trim() == "odio") {
                onSuccess(true);
              } else {
                _mostrarAlerta("Erro", "Chave Incorreta!");
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _janelaCadastro() {
    final TextEditingController uCad = TextEditingController();
    final TextEditingController sCad = TextEditingController();
    String cargoSel = _listaCargos[0];
    String tipoSel = "user";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Novo Servidor"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: uCad,
                    decoration: const InputDecoration(
                      labelText: "Nome de Usuário (Login)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sCad,
                    decoration: const InputDecoration(
                      labelText: "Senha Provisória",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: cargoSel,
                    decoration: const InputDecoration(
                      labelText: "Cargo",
                      border: OutlineInputBorder(),
                    ),
                    items: _listaCargos
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => cargoSel = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tipoSel,
                    decoration: const InputDecoration(
                      labelText: "Nível de Acesso",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("user")),
                      DropdownMenuItem(value: "admin", child: Text("admin")),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => tipoSel = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final String u = uCad.text.trim().toLowerCase();
                  final String s = sCad.text.trim();

                  if (u.isEmpty || s.isEmpty) {
                    _mostrarAlerta("Erro", "Preencha usuário e senha!");
                    return;
                  }

                  if (_bancoUsuarios.any((element) => element.usuario == u)) {
                    _mostrarAlerta("Erro", "Este nome de usuário já existe!");
                    return;
                  }

                  final int jor = cargoSel.toLowerCase().contains("estagiári") ? 6 : 8;

                  setState(() {
                    _bancoUsuarios.add(
                      UsuarioModel(
                        usuario: u,
                        senha: s,
                        tipo: tipoSel,
                        cargo: cargoSel,
                        jornada: jor,
                        primeiroAcesso: true,
                      ),
                    );
                  });

                  Navigator.pop(context);
                  _mostrarAlerta(
                    "Sucesso",
                    "Usuário '$u' cadastrado!\nSenha provisória: $s",
                  );
                },
                child: const Text("CADASTRAR SERVIDOR"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _janelaExcluir() {
    final List<String> opcExcluir = _bancoUsuarios
        .where((u) => u.usuario != 'jefferson.espanha')
        .map((u) => u.usuario)
        .toList();

    if (opcExcluir.isEmpty) {
      _mostrarAlerta("Aviso", "Nenhum usuário disponível para exclusão.");
      return;
    }

    String userSel = opcExcluir[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Excluir Usuário"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Selecione o usuário para excluir:"),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: userSel,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: opcExcluir
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => userSel = v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _bancoUsuarios.removeWhere((element) => element.usuario == userSel);
                  });
                  Navigator.pop(context);
                  _mostrarAlerta("Sucesso", "Usuário removido com sucesso!");
                },
                child: const Text("EXCLUIR AGORA"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarAlerta(String titulo, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exibirSplash) {
      return Scaffold(
        backgroundColor: const Color(0xFF2C3E50),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/ponto.png',
                height: 120,
                errorBuilder: (_, __, ___) => const Text(
                  "SISTEMA DE PONTO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: _progressoSplash,
                  backgroundColor: Colors.white24,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/ponto.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => const Text(
                        "SISTEMA DE PONTO",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "USUÁRIO:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _userCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "SENHA:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passCtrl,
                            obscureText: !_mostrarSenha,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: Text(
                            _mostrarSenha ? "🔒" : "👁",
                            style: const TextStyle(fontSize: 18),
                          ),
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _validarAcesso,
                        child: const Text(
                          "ENTRAR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2980B9),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _verificarCadastro,
                            child: const Text(
                              "CADASTRAR",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _verificarExclusao,
                            child: const Text(
                              "EXCLUIR",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Text(
              "Created by: Jefferson Satile Espanha",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Color(0xFF7F8C8D),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}