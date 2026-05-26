import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

/// Tela inicial do fluxo oficial de recuperação de senha (Supabase Auth).
///
/// O usuário informa apenas o e-mail. O Supabase envia o link oficial
/// de redefinição; ao abrir o link, o app captura o evento
/// [AuthChangeEvent.passwordRecovery] e navega para a tela onde a nova
/// senha é definida.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _enviando = false;
  bool _enviado = false;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-\.]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    final authProvider = context.read<AuthProvider>();
    final erro =
        await authProvider.enviarEmailRecuperacao(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _enviando = false);

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

    // Mensagem genérica para evitar enumeração de usuários.
    setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        title: const Text(
          'Recuperar senha',
          style:
              TextStyle(color: AppColors.branco, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.preto,
        iconTheme: const IconThemeData(color: AppColors.branco),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _enviado ? _buildSucesso() : _buildFormulario(),
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
          const Icon(Icons.lock_reset,
              size: 64, color: AppColors.vermelho),
          const SizedBox(height: 16),
          const Text(
            'Esqueci minha senha',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Informe o e-mail cadastrado. Enviaremos um link seguro '
            'para você criar uma nova senha.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.cinza),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_enviando,
            decoration: InputDecoration(
              labelText: 'E-mail',
              prefixIcon:
                  const Icon(Icons.email, color: AppColors.dourado),
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
              final v = valor?.trim() ?? '';
              if (v.isEmpty) return 'Informe o e-mail';
              if (!_emailRegex.hasMatch(v)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviarLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vermelho,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _enviando
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
                      'Enviar link de recuperação',
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

  Widget _buildSucesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read,
            size: 72, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Confira seu e-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Se houver uma conta associada a este e-mail, você receberá '
          'um link para redefinir a senha em alguns instantes. '
          'O link expira por segurança — abra-o no mesmo dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.cinza),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _enviado = false;
                _emailController.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.vermelho, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enviar para outro e-mail',
              style: TextStyle(color: AppColors.vermelho),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.preto,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Voltar para login',
              style: TextStyle(color: AppColors.branco),
            ),
          ),
        ),
      ],
    );
  }
}
