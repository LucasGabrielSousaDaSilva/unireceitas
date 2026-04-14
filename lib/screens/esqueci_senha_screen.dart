import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

/// Tela de redefinição de senha.
/// O usuário digita o email e a nova senha.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _novaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _redefinirSenha() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final erro = await authProvider.redefinirSenha(
        email: _emailController.text.trim(),
        novaSenha: _novaSenhaController.text,
      );

      if (!mounted) return;
      if (erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: AppColors.vermelho),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha redefinida com sucesso! Faça login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        title: const Text(
          'Redefinir Senha',
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
            child: Column(
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: AppColors.vermelho,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe seu email e a nova senha desejada.',
                  style: TextStyle(fontSize: 14, color: AppColors.cinza),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: AppColors.dourado),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.dourado, width: 2),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe o email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nova Senha
                TextFormField(
                  controller: _novaSenhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    prefixIcon: const Icon(Icons.lock, color: AppColors.dourado),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.cinza,
                      ),
                      onPressed: () {
                        setState(() => _senhaVisivel = !_senhaVisivel);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.dourado, width: 2),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Informe a nova senha';
                    }
                    if (valor.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botão Redefinir
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _redefinirSenha,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermelho,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Redefinir Senha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
