import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CarrosselImagens extends StatefulWidget {
  final List<Uint8List> imagens;

  const CarrosselImagens({
    super.key,
    required this.imagens,
  });

  @override
  State<CarrosselImagens> createState() => _CarrosselImagensState();
}

class _CarrosselImagensState extends State<CarrosselImagens> {
  /// Controller do PageView para controlar a navegação entre imagens
  final PageController _pageController = PageController();

  int _paginaAtual = 0;

  @override
  void dispose() {
    // Libera o controller quando o widget é removido da árvore
    _pageController.dispose();
    super.dispose();
  }

  /// Abre a imagem em tela cheia com fundo escurecido para melhor visualização.
  void _abrirVisualizadorImagens(int indiceInicial) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _VisualizadorImagens(
              imagens: widget.imagens,
              indiceInicial: indiceInicial,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se não houver imagens, exibe um placeholder grande
    if (widget.imagens.isEmpty) {
      return _buildPlaceholder();
    }

    return Column(
      children: [
        // Área do carrossel de imagens com setas de navegação
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // PageView com as imagens
              PageView.builder(
                controller: _pageController,
                itemCount: widget.imagens.length,
                // Callback chamado quando o usuário muda de página
                onPageChanged: (index) {
                  setState(() {
                    _paginaAtual = index;
                  });
                },
                // Constrói cada página/imagem do carrossel usando Image.memory (bytes)
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _abrirVisualizadorImagens(index),
                    child: Hero(
                      tag: 'receita_imagem_$index',
                      child: Image.memory(
                        widget.imagens[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      ),
                    ),
                  );
                },
              ),

              // Indicador "Toque para ampliar" (canto superior direito)
              Positioned(
                top: 10,
                right: 10,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.preto.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.branco.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          color: AppColors.dourado,
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Toque para ampliar',
                          style: TextStyle(
                            color: AppColors.branco,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Seta esquerda - só exibe se não estiver na primeira imagem
              if (widget.imagens.length > 1 && _paginaAtual > 0)
                Positioned(
                  left: 8,
                  child: _buildBotaoSeta(
                    icone: Icons.arrow_back_ios_rounded,
                    onTap: () {
                      // Navega para a imagem anterior com animação
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),

              // Seta direita - só exibe se não estiver na última imagem
              if (widget.imagens.length > 1 && _paginaAtual < widget.imagens.length - 1)
                Positioned(
                  right: 8,
                  child: _buildBotaoSeta(
                    icone: Icons.arrow_forward_ios_rounded,
                    onTap: () {
                      // Navega para a próxima imagem com animação
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Indicadores de página (bolinhas) - só exibe se houver mais de 1 imagem
        if (widget.imagens.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imagens.length,
                (index) => _buildIndicador(index),
              ),
            ),
          ),
      ],
    );
  }

  /// Constrói o botão circular com seta para navegação do carrossel.
  /// [icone] - Ícone da seta (esquerda ou direita).
  /// [onTap] - Callback executado ao clicar na seta.
  Widget _buildBotaoSeta({
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.preto.withValues(alpha: 0.5), // Fundo semitransparente
          shape: BoxShape.circle,
        ),
        child: Icon(
          icone,
          color: AppColors.branco,
          size: 24,
        ),
      ),
    );
  }

  /// Constrói um indicador individual (bolinha) para cada imagem.
  Widget _buildIndicador(int index) {
    // Verifica se este indicador corresponde à página atual
    final bool ativo = index == _paginaAtual;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Animação suave
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: ativo ? 12 : 8, // Maior quando ativo
      height: ativo ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Dourado quando ativo, cinza quando inativo
        color: ativo ? AppColors.dourado : AppColors.cinza.withValues(alpha: 0.4),
      ),
    );
  }

  /// Placeholder exibido quando não há imagens ou quando uma imagem falha ao carregar.
  Widget _buildPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: AppColors.douradoClaro,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 60,
            color: AppColors.dourado,
          ),
          SizedBox(height: 8),
          Text(
            'Sem imagens',
            style: TextStyle(
              color: AppColors.cinza,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visualizador em tela cheia das imagens da receita.
/// Permite navegação entre imagens, zoom (pinch/duplo toque) e fechar
/// com botão ou arrastando para baixo.
class _VisualizadorImagens extends StatefulWidget {
  final List<Uint8List> imagens;
  final int indiceInicial;

  const _VisualizadorImagens({
    required this.imagens,
    required this.indiceInicial,
  });

  @override
  State<_VisualizadorImagens> createState() => _VisualizadorImagensState();
}

class _VisualizadorImagensState extends State<_VisualizadorImagens> {
  late final PageController _pageController;
  late int _paginaAtual;
  double _arrastoVertical = 0;

  @override
  void initState() {
    super.initState();
    _paginaAtual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fechar() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalImagens = widget.imagens.length;
    final opacidadeFundo =
        (1.0 - (_arrastoVertical.abs() / 400).clamp(0.0, 0.85)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacidadeFundo),
      body: SafeArea(
        child: Stack(
          children: [
            // Imagens com PageView (swipe horizontal entre elas)
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _arrastoVertical += details.delta.dy;
                });
              },
              onVerticalDragEnd: (details) {
                if (_arrastoVertical.abs() > 120) {
                  _fechar();
                } else {
                  setState(() => _arrastoVertical = 0);
                }
              },
              child: Transform.translate(
                offset: Offset(0, _arrastoVertical),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: totalImagens,
                  onPageChanged: (index) {
                    setState(() => _paginaAtual = index);
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: Hero(
                        tag: 'receita_imagem_$index',
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 5,
                          child: Image.memory(
                            widget.imagens[index],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.branco,
                                size: 60,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Topo: contador + botão fechar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (totalImagens > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.branco.withValues(alpha: 0.18),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        '${_paginaAtual + 1} / $totalImagens',
                        style: const TextStyle(
                          color: AppColors.branco,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _fechar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.branco.withValues(alpha: 0.2),
                            width: 0.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.branco,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Setas de navegação
            if (totalImagens > 1 && _paginaAtual > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildBotaoSetaModal(
                    icone: Icons.arrow_back_ios_rounded,
                    onTap: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
            if (totalImagens > 1 && _paginaAtual < totalImagens - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildBotaoSetaModal(
                    icone: Icons.arrow_forward_ios_rounded,
                    onTap: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),

            // Indicadores na base (bolinhas)
            if (totalImagens > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalImagens, (index) {
                    final ativo = index == _paginaAtual;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: ativo ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: ativo
                            ? AppColors.dourado
                            : AppColors.branco.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSetaModal({
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.branco.withValues(alpha: 0.18),
              width: 0.6,
            ),
          ),
          child: Icon(icone, color: AppColors.branco, size: 22),
        ),
      ),
    );
  }
}
