import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

/// Tela de cadastro de novo usuário.
class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  String? _erroNome;
  String? _erroEmail;
  String? _erroSenha;

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_validarNomeTempoReal);
    _emailController.addListener(_validarEmailTempoReal);
    _senhaController.addListener(_validarSenhaTempoReal);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) {
      return 'Informe o nome.';
    }
    if (v.length < 3) {
      return 'O nome deve possuir pelo menos 3 caracteres.';
    }
    final apenasLetras = RegExp(r"^[A-Za-zÀ-ÿ\s'-]+$");
    if (!apenasLetras.hasMatch(v)) {
      return 'O nome deve conter apenas letras.';
    }
    return null;
  }

  String? _validarEmail(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) {
      return 'Informe um e-mail válido.';
    }
    final regexEmail = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!v.contains('@') || !regexEmail.hasMatch(v)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) {
      return 'Informe a senha.';
    }
    final temMaiuscula = RegExp(r'[A-Z]').hasMatch(v);
    final temNumero = RegExp(r'[0-9]').hasMatch(v);
    final temEspecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\\[\];`~]').hasMatch(v);
    if (v.length < 8 || !temMaiuscula || !temNumero || !temEspecial) {
      return 'A senha deve conter no mínimo 8 caracteres, incluindo letra maiúscula, número e caractere especial.';
    }
    return null;
  }

  void _validarNomeTempoReal() {
    setState(() => _erroNome = _validarNome(_nomeController.text));
  }

  void _validarEmailTempoReal() {
    setState(() => _erroEmail = _validarEmail(_emailController.text));
  }

  void _validarSenhaTempoReal() {
    setState(() => _erroSenha = _validarSenha(_senhaController.text));
  }

  bool get _formularioValido {
    return _validarNome(_nomeController.text) == null &&
        _validarEmail(_emailController.text) == null &&
        _validarSenha(_senhaController.text) == null;
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erroNome = _validarNome(_nomeController.text);
      _erroEmail = _validarEmail(_emailController.text);
      _erroSenha = _validarSenha(_senhaController.text);
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_formularioValido) return;

    setState(() => _carregando = true);

    final authProvider = context.read<AuthProvider>();
    final erro = await authProvider.cadastrarUsuario(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: AppColors.vermelho),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso! Faça login.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: AppColors.dourado),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? AppColors.vermelho : Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? AppColors.vermelho : AppColors.dourado,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeCadastrar = _formularioValido && !_carregando;

    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        title: const Text(
          'Cadastro',
          style: TextStyle(color: AppColors.branco, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.preto,
        iconTheme: const IconThemeData(color: AppColors.branco),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 60,
                  color: AppColors.vermelho,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Criar nova conta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 32),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracaoCampo(
                    label: 'Nome',
                    icone: Icons.person,
                    errorText: _erroNome,
                  ),
                  validator: _validarNome,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoracaoCampo(
                    label: 'E-mail',
                    icone: Icons.email,
                    errorText: _erroEmail,
                  ),
                  validator: _validarEmail,
                ),
                const SizedBox(height: 16),

                // Senha
                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  textInputAction: TextInputAction.done,
                  decoration: _decoracaoCampo(
                    label: 'Senha',
                    icone: Icons.lock,
                    errorText: _erroSenha,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.cinza,
                      ),
                      onPressed: () {
                        setState(() => _senhaVisivel = !_senhaVisivel);
                      },
                    ),
                  ),
                  validator: _validarSenha,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'A senha deve conter no mínimo 8 caracteres, incluindo letra maiúscula, número e caractere especial.',
                      style: TextStyle(fontSize: 12, color: AppColors.cinza),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Cadastrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: podeCadastrar ? _cadastrar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermelho,
                      disabledBackgroundColor: AppColors.vermelho.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.branco,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Cadastrar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.branco,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Link para login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem uma conta? ',
                      style: TextStyle(color: AppColors.cinza),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Faça login',
                        style: TextStyle(
                          color: AppColors.vermelho,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
