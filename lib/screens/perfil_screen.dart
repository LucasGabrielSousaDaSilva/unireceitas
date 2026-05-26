import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/receita_provider.dart';
import '../utils/app_colors.dart';

/// Tela de perfil do usuário.
/// Permite editar nome, email e senha.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _dadosCarregados = false;
  bool _salvando = false;

  String? _erroNome;
  String? _erroEmail;
  String? _erroSenhaAtual;
  String? _erroNovaSenha;
  String? _erroConfirmarSenha;

  late final AnimationController _entradaController;

  @override
  void initState() {
    super.initState();
    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _nomeController.addListener(_validarNomeTempoReal);
    _emailController.addListener(_validarEmailTempoReal);
    _novaSenhaController.addListener(_validarNovaSenhaTempoReal);
    _confirmarSenhaController.addListener(_validarConfirmarSenhaTempoReal);
    _senhaAtualController.addListener(_limparErroSenhaAtual);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entradaController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosCarregados) {
      final usuario = context.read<AuthProvider>().usuarioLogado;
      if (usuario != null) {
        _nomeController.text = usuario.nome;
        _emailController.text = usuario.email;
      }
      _dadosCarregados = true;
    }
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // ============ Validações (espelham cadastro_usuario_screen) ============

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

  String? _validarSenhaForte(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) {
      return 'Informe a senha.';
    }
    final temMaiuscula = RegExp(r'[A-Z]').hasMatch(v);
    final temNumero = RegExp(r'[0-9]').hasMatch(v);
    final temEspecial =
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\\[\];`~]').hasMatch(v);
    if (v.length < 8 || !temMaiuscula || !temNumero || !temEspecial) {
      return 'A senha deve conter no mínimo 8 caracteres, incluindo letra maiúscula, número e caractere especial.';
    }
    return null;
  }

  bool get _querAlterarSenha {
    return _senhaAtualController.text.isNotEmpty ||
        _novaSenhaController.text.isNotEmpty ||
        _confirmarSenhaController.text.isNotEmpty;
  }

  void _validarNomeTempoReal() {
    setState(() => _erroNome = _validarNome(_nomeController.text));
  }

  void _validarEmailTempoReal() {
    setState(() => _erroEmail = _validarEmail(_emailController.text));
  }

  void _validarNovaSenhaTempoReal() {
    setState(() {
      if (_querAlterarSenha) {
        _erroNovaSenha = _validarSenhaForte(_novaSenhaController.text);
        // Revalida o confirmar sempre que a nova senha muda
        _erroConfirmarSenha = _validarConfirmacao();
      } else {
        _erroNovaSenha = null;
        _erroConfirmarSenha = null;
      }
    });
  }

  void _validarConfirmarSenhaTempoReal() {
    setState(() {
      if (_querAlterarSenha) {
        _erroConfirmarSenha = _validarConfirmacao();
      } else {
        _erroConfirmarSenha = null;
      }
    });
  }

  void _limparErroSenhaAtual() {
    if (_erroSenhaAtual != null) {
      setState(() => _erroSenhaAtual = null);
    }
  }

  String? _validarConfirmacao() {
    if (_confirmarSenhaController.text.isEmpty) {
      return 'Confirme a nova senha.';
    }
    if (_confirmarSenhaController.text != _novaSenhaController.text) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  bool get _formularioValido {
    final nomeOk = _validarNome(_nomeController.text) == null;
    final emailOk = _validarEmail(_emailController.text) == null;
    if (!_querAlterarSenha) return nomeOk && emailOk;

    final senhaAtualOk = _senhaAtualController.text.isNotEmpty;
    final novaSenhaOk = _validarSenhaForte(_novaSenhaController.text) == null;
    final confirmOk = _validarConfirmacao() == null;
    return nomeOk && emailOk && senhaAtualOk && novaSenhaOk && confirmOk;
  }

  // ============ Ações ============

  Future<void> _salvarPerfil() async {
    setState(() {
      _erroNome = _validarNome(_nomeController.text);
      _erroEmail = _validarEmail(_emailController.text);
      if (_querAlterarSenha) {
        _erroSenhaAtual = _senhaAtualController.text.isEmpty
            ? 'Informe a senha atual.'
            : null;
        _erroNovaSenha = _validarSenhaForte(_novaSenhaController.text);
        _erroConfirmarSenha = _validarConfirmacao();
      }
    });

    if (!_formularioValido) return;

    setState(() => _salvando = true);

    final authProvider = context.read<AuthProvider>();
    final usuarioAtual = authProvider.usuarioLogado;
    if (usuarioAtual == null) {
      setState(() => _salvando = false);
      return;
    }

    String? erro;

    // Atualiza nome/email (mantém a senha atual armazenada caso não vá alterar)
    erro = await authProvider.atualizarPerfil(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: usuarioAtual.senha,
    );

    // Se solicitado, altera a senha (valida senha atual via Supabase)
    if (erro == null && _querAlterarSenha) {
      erro = await authProvider.alterarSenha(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
      );
    }

    if (!mounted) return;
    setState(() => _salvando = false);

    if (erro != null) {
      // Se o erro veio da senha atual, marca o campo
      if (erro.toLowerCase().contains('senha')) {
        setState(() => _erroSenhaAtual = erro);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        _snack(erro, cor: AppColors.vermelho),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      _snack('Perfil atualizado com sucesso!', cor: AppColors.verde),
    );
    Navigator.pop(context);
  }

  SnackBar _snack(String mensagem, {required Color cor}) {
    return SnackBar(
      content: Text(mensagem),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _confirmarExclusaoConta() async {
    final senhaController = TextEditingController();
    final senhaVisivelNotifier = ValueNotifier<bool>(false);
    final erroSenhaNotifier = ValueNotifier<String?>(null);
    final processandoNotifier = ValueNotifier<bool>(false);

    final confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: processandoNotifier,
          builder: (context, processando, _) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: AppColors.branco,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.vermelho.withValues(alpha: 0.22),
                                AppColors.vermelho.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: AppColors.vermelho,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Excluir conta',
                            style: TextStyle(
                              color: AppColors.preto,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Esta ação é permanente. Todas as suas receitas e dados serão excluídos. Para confirmar, informe sua senha de acesso.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.cinza.withValues(alpha: 0.95),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<bool>(
                      valueListenable: senhaVisivelNotifier,
                      builder: (context, visivel, _) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: erroSenhaNotifier,
                          builder: (context, erro, _) {
                            return TextField(
                              controller: senhaController,
                              obscureText: !visivel,
                              autofocus: true,
                              enabled: !processando,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.dourado,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => senhaVisivelNotifier.value =
                                      !senhaVisivelNotifier.value,
                                  icon: Icon(
                                    visivel
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppColors.cinza,
                                  ),
                                ),
                                errorText: erro,
                                errorMaxLines: 3,
                                filled: true,
                                fillColor: const Color(0xFFFAF8F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: AppColors.cinza
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.dourado,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.vermelho,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.vermelho,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (_) {
                                if (erroSenhaNotifier.value != null) {
                                  erroSenhaNotifier.value = null;
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: processando
                                ? null
                                : () =>
                                    Navigator.of(dialogContext).pop(false),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      AppColors.cinza.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: AppColors.cinza,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: processando
                                ? null
                                : () async {
                                    if (senhaController.text.isEmpty) {
                                      erroSenhaNotifier.value =
                                          'Informe a senha.';
                                      return;
                                    }
                                    processandoNotifier.value = true;
                                    erroSenhaNotifier.value = null;

                                    final authProvider =
                                        context.read<AuthProvider>();
                                    final erro =
                                        await authProvider.excluirConta(
                                      senha: senhaController.text,
                                    );

                                    processandoNotifier.value = false;

                                    if (erro != null) {
                                      erroSenhaNotifier.value = erro;
                                      return;
                                    }
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop(true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.vermelho,
                              disabledBackgroundColor: AppColors.vermelho
                                  .withValues(alpha: 0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              elevation: 4,
                              shadowColor:
                                  AppColors.vermelho.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: processando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.branco,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_forever_rounded,
                                          color: AppColors.branco, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Excluir',
                                        style: TextStyle(
                                          color: AppColors.branco,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    senhaController.dispose();
    senhaVisivelNotifier.dispose();
    erroSenhaNotifier.dispose();
    processandoNotifier.dispose();

    if (confirmou == true && mounted) {
      // Recarrega receitas para limpar o cache local
      try {
        await context.read<ReceitaProvider>().carregarReceitas();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Conta excluída com sucesso.', cor: AppColors.verde),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 720;
    final horizontalPadding = isWide ? 32.0 : 16.0;
    final maxContentWidth = isWide ? 720.0 : double.infinity;
    final usuario = context.watch<AuthProvider>().usuarioLogado;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.preto,
                Color(0xFF2E1B1B),
                AppColors.vermelhoEscuro,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Meu Perfil',
              style: TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.branco),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: TextButton(
                  onPressed: _salvando ? null : _salvarPerfil,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.dourado,
                    foregroundColor: AppColors.preto,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.preto,
                            ),
                          ),
                        )
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.dourado.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.vermelho.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _animar(0, _buildHeroHeader(usuario)),
                        const SizedBox(height: 20),
                        _animar(
                          1,
                          _buildCard(child: _buildInformacoesPessoais()),
                        ),
                        const SizedBox(height: 16),
                        _animar(2, _buildCard(child: _buildAlterarSenha())),
                        const SizedBox(height: 16),
                        _animar(3, _buildZonaPerigo()),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animar(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.9);
    final end = (start + 0.55).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entradaController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 18),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHeroHeader(dynamic usuario) {
    final iniciais = _extrairIniciais(usuario?.nome ?? '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.preto,
            Color(0xFF3A2222),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.dourado, Color(0xFFB8860B)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dourado.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: iniciais.isNotEmpty
                  ? Text(
                      iniciais,
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.branco,
                      size: 36,
                    ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (usuario?.nome ?? 'Usuário').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: AppColors.dourado.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        (usuario?.email ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.branco.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extrairIniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cinza.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icone,
    required String titulo,
    String? descricao,
    Color cor = AppColors.dourado,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cor.withValues(alpha: 0.2),
                cor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icone, color: cor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.preto,
                  letterSpacing: 0.2,
                ),
              ),
              if (descricao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.cinza.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformacoesPessoais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.badge_outlined,
          titulo: 'Informações pessoais',
          descricao: 'Atualize seu nome e e-mail',
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _decoracaoCampo(
            label: 'Nome',
            icone: Icons.person_outline_rounded,
            errorText: _erroNome,
          ),
          validator: _validarNome,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _decoracaoCampo(
            label: 'E-mail',
            icone: Icons.email_outlined,
            errorText: _erroEmail,
          ),
          validator: _validarEmail,
        ),
      ],
    );
  }

  Widget _buildAlterarSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icone: Icons.lock_outline_rounded,
          titulo: 'Alterar senha',
          descricao: 'Preencha apenas se desejar alterar a senha',
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _senhaAtualController,
          obscureText: !_senhaAtualVisivel,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _decoracaoCampo(
            label: 'Senha atual',
            icone: Icons.lock_outline_rounded,
            errorText: _erroSenhaAtual,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _senhaAtualVisivel = !_senhaAtualVisivel),
              icon: Icon(
                _senhaAtualVisivel
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.cinza,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _novaSenhaController,
          obscureText: !_novaSenhaVisivel,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _decoracaoCampo(
            label: 'Nova senha',
            icone: Icons.lock_reset_rounded,
            errorText: _erroNovaSenha,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _novaSenhaVisivel = !_novaSenhaVisivel),
              icon: Icon(
                _novaSenhaVisivel
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.cinza,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: !_confirmarSenhaVisivel,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 15, color: AppColors.preto),
          decoration: _decoracaoCampo(
            label: 'Confirmar nova senha',
            icone: Icons.check_circle_outline_rounded,
            errorText: _erroConfirmarSenha,
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel,
              ),
              icon: Icon(
                _confirmarSenhaVisivel
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.cinza,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.douradoClaro.withValues(alpha: 0.55),
                AppColors.dourado.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.dourado.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.dourado,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A senha deve conter no mínimo 8 caracteres, incluindo letra maiúscula, número e caractere especial.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.preto.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZonaPerigo() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.vermelho.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.vermelho.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icone: Icons.warning_amber_rounded,
            titulo: 'Zona de perigo',
            descricao:
                'Ações irreversíveis que afetam permanentemente sua conta',
            cor: AppColors.vermelho,
          ),
          const SizedBox(height: 18),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.vermelho.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.vermelho.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Excluir conta',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Todas as suas receitas e dados pessoais serão removidos. Esta ação não pode ser desfeita.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.cinza.withValues(alpha: 0.95),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _salvando ? null : _confirmarExclusaoConta,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.vermelho,
                              AppColors.vermelhoEscuro,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.vermelho.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_forever_rounded,
                                color: AppColors.branco,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Excluir minha conta',
                                style: TextStyle(
                                  color: AppColors.branco,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final temErro = errorText != null;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: temErro
            ? AppColors.vermelho
            : AppColors.cinza.withValues(alpha: 0.9),
      ),
      prefixIcon: Icon(
        icone,
        color: temErro ? AppColors.vermelho : AppColors.dourado,
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 3,
      filled: true,
      fillColor: const Color(0xFFFAF8F3),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: temErro
              ? AppColors.vermelho
              : AppColors.cinza.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: temErro ? AppColors.vermelho : AppColors.dourado,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.vermelho, width: 2),
      ),
    );
  }
}
