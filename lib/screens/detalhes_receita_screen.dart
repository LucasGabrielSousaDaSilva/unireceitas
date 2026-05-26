import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/receita_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/carrossel_imagens.dart';
import '../models/receita.dart';

/// Tela de detalhes da receita.
/// Exibe todas as informações da receita selecionada.
/// Botões de edição e exclusão só aparecem para o proprietário.
class DetalhesReceitaScreen extends StatelessWidget {
  const DetalhesReceitaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String receitaId =
        ModalRoute.of(context)!.settings.arguments as String;
    final usuarioLogado = context.watch<AuthProvider>().usuarioLogado;

    return Consumer<ReceitaProvider>(
      builder: (context, provider, child) {
        final receita = provider.buscarPorId(receitaId);

        if (receita == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F5F0),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool ehProprietario = usuarioLogado != null &&
            receita.proprietarioId == usuarioLogado.id;
        final bool isPublica = receita.acesso == AcessoReceita.publica;
        final size = MediaQuery.of(context).size;
        final isWide = size.width >= 720;
        final maxContentWidth = isWide ? 880.0 : double.infinity;
        final horizontalPadding = isWide ? 32.0 : 16.0;

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
                  'Detalhes da Receita',
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
                  if (ehProprietario) ...[
                    _AppBarIconButton(
                      icone: Icons.edit_rounded,
                      cor: AppColors.dourado,
                      tooltip: 'Editar receita',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/editar',
                          arguments: receita.id,
                        );
                      },
                    ),
                    _AppBarIconButton(
                      icone: Icons.delete_outline_rounded,
                      cor: AppColors.vermelho,
                      tooltip: 'Excluir receita',
                      onPressed: () {
                        _mostrarDialogoExclusao(context, provider, receita.id);
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
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
                          AppColors.vermelho.withValues(alpha: 0.07),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Carrossel encapsulado em card
                          _AnimatedEntrada(
                            delay: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.branco,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.preto
                                        .withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CarrosselImagens(imagens: receita.imagens),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Header com nome + badge
                          _AnimatedEntrada(
                            delay: 1,
                            child: _buildHeaderInfo(
                              receita: receita,
                              isPublica: isPublica,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!ehProprietario)
                            _AnimatedEntrada(
                              delay: 2,
                              child: _buildAvisoCompartilhada(),
                            ),
                          if (!ehProprietario) const SizedBox(height: 16),
                          // Ingredientes
                          _AnimatedEntrada(
                            delay: 3,
                            child: _buildSecao(
                              titulo: 'Ingredientes',
                              conteudo: receita.ingredientes,
                              icone: Icons.shopping_basket_rounded,
                              corAcento: AppColors.vermelho,
                              estiloLista: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Modo de preparo
                          _AnimatedEntrada(
                            delay: 4,
                            child: _buildSecao(
                              titulo: 'Modo de Preparo',
                              conteudo: receita.modoPreparo,
                              icone: Icons.menu_book_rounded,
                              corAcento: AppColors.dourado,
                              estiloLista: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo({
    required dynamic receita,
    required bool isPublica,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPublica
                      ? AppColors.verde.withValues(alpha: 0.2)
                      : AppColors.dourado.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPublica
                        ? AppColors.verde.withValues(alpha: 0.5)
                        : AppColors.dourado.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPublica
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      size: 13,
                      color: isPublica ? AppColors.verde : AppColors.dourado,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPublica ? 'Pública' : 'Privada',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isPublica
                            ? AppColors.verde
                            : AppColors.dourado,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            receita.nome,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.branco,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoCompartilhada() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.douradoClaro.withValues(alpha: 0.8),
            AppColors.dourado.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dourado.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.dourado.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.visibility_rounded,
              color: AppColors.dourado,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Você está visualizando uma receita compartilhada.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B5410),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required String conteudo,
    required IconData icone,
    required Color corAcento,
    required bool estiloLista,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      corAcento.withValues(alpha: 0.2),
                      corAcento.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: corAcento, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: corAcento,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cinza.withValues(alpha: 0.08),
              ),
            ),
            child: estiloLista
                ? _buildListaIngredientes(conteudo)
                : _buildPassos(conteudo),
          ),
        ],
      ),
    );
  }

  Widget _buildListaIngredientes(String conteudo) {
    final linhas = conteudo
        .split('\n')
        .where((linha) => linha.trim().isNotEmpty)
        .toList();
    if (linhas.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 15, color: AppColors.cinza),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: linhas.map((linha) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 12),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.vermelho,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  linha.trim(),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.preto,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPassos(String conteudo) {
    final linhas = conteudo
        .split('\n')
        .where((linha) => linha.trim().isNotEmpty)
        .toList();
    if (linhas.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 15, color: AppColors.cinza),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: linhas.asMap().entries.map((entry) {
        final linha = entry.value.trim();
        // Tenta extrair o número do começo "1. ..."
        String texto = linha;
        String numero = '${entry.key + 1}';
        final match = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(linha);
        if (match != null) {
          numero = match.group(1)!;
          texto = match.group(2)!.trim();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.dourado, Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dourado.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: const TextStyle(
                      color: AppColors.branco,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.preto,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _mostrarDialogoExclusao(
    BuildContext context,
    ReceitaProvider provider,
    String receitaId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                            AppColors.vermelho.withValues(alpha: 0.2),
                            AppColors.vermelho.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.vermelho,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Confirmar Exclusão',
                        style: TextStyle(
                          color: AppColors.preto,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.cinza.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.cinza.withValues(alpha: 0.3),
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
                        onPressed: () async {
                          final dialogNav = Navigator.of(dialogContext);
                          final mainNav = Navigator.of(context);
                          dialogNav.pop();
                          mainNav.pop();
                          await provider.excluirReceita(receitaId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vermelho,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          elevation: 4,
                          shadowColor:
                              AppColors.vermelho.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded,
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
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconButton({
    required this.icone,
    required this.cor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(icone, color: cor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntrada extends StatefulWidget {
  final int delay;
  final Widget child;
  const _AnimatedEntrada({required this.delay, required this.child});

  @override
  State<_AnimatedEntrada> createState() => _AnimatedEntradaState();
}

class _AnimatedEntradaState extends State<_AnimatedEntrada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delay * 90), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 18),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
