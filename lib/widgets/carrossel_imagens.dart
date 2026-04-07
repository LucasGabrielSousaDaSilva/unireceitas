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
                  return Image.memory(
                    widget.imagens[index],
                    fit: BoxFit.cover, // Preenche toda a área disponível
                    width: double.infinity,
                    // Caso a imagem não possa ser carregada, exibe placeholder
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  );
                },
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
