import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

/// Tela acionada quando o usuário abre o link de recuperação de senha
/// recebido por e-mail.
///
/// O SDK do Supabase processa o deep link e emite
/// [AuthChangeEvent.passwordRecovery]; nesse momento existe uma sessão
/// temporária que autoriza chamar `auth.updateUser(password: ...)`.
class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _senhaVisivel = false;
  bool _confirmarVisivel = false;
  bool _salvando = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  bool get _temSessaoRecuperacao =>
      Supabase.instance.client.auth.currentSession != null;

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final authProvider = context.read<AuthProvider>();
    final erro = await authProvider
        .redefinirSenhaAutenticada(_senhaController.text);

    if (!mounted) return;
    setState(() => _salvando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: AppColors.vermelho,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Garante que o usuário faça login com a nova senha.
    await Supabase.instance.client.auth.signOut();
    authProvider.logout();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida com sucesso! Faça login novamente.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        title: const Text(
          'Nova senha',
          style:
              TextStyle(color: AppColors.branco, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.preto,
        iconTheme: const IconThemeData(color: AppColors.branco),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child:
              _temSessaoRecuperacao ? _buildFormulario() : _buildLinkInvalido(),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.password,
              size: 64, color: AppColors.vermelho),
          const SizedBox(height: 16),
          const Text(
            'Defina sua nova senha',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use uma senha com pelo menos 6 caracteres. Após salvar, '
            'você precisará entrar novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.cinza),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _senhaController,
            obscureText: !_senhaVisivel,
            enabled: !_salvando,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              prefixIcon: const Icon(Icons.lock, color: AppColors.dourado),
              suffixIcon: IconButton(
                icon: Icon(
                  _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.cinza,
                ),
                onPressed: () =>
                    setState(() => _senhaVisivel = !_senhaVisivel),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.dourado, width: 2),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmarController,
            obscureText: !_confirmarVisivel,
            enabled: !_salvando,
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.dourado),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmarVisivel
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.cinza,
                ),
                onPressed: () => setState(
                    () => _confirmarVisivel = !_confirmarVisivel),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.dourado, width: 2),
              ),
            ),
            validator: (valor) {
              if (valor != _senhaController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vermelho,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.branco),
                      ),
                    )
                  : const Text(
                      'Salvar nova senha',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkInvalido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.link_off, size: 72, color: AppColors.vermelho),
        const SizedBox(height: 16),
        const Text(
          'Link expirado ou inválido',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'O link de recuperação não pôde ser validado. Solicite um '
          'novo e-mail de redefinição.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.cinza),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/esqueci-senha', (_) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelho,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Solicitar novo link',
              style: TextStyle(color: AppColors.branco),
            ),
          ),
        ),
      ],
    );
  }
}
