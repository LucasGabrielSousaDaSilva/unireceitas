import 'package:flutter/material.dart';
import '../models/receita.dart';
import '../utils/app_colors.dart';

class ReceitaCard extends StatefulWidget {
  final Receita receita;
  final VoidCallback onTap;

  const ReceitaCard({
    super.key,
    required this.receita,
    required this.onTap,
  });

  @override
  State<ReceitaCard> createState() => _ReceitaCardState();
}

class _ReceitaCardState extends State<ReceitaCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isPublica = widget.receita.acesso == AcessoReceita.publica;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        transform: Matrix4.identity()
          ..translateByDouble(0.0, _hovering ? -2.0 : 0.0, 0.0, 1.0),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovering
                ? AppColors.dourado.withValues(alpha: 0.45)
                : AppColors.cinza.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto
                  .withValues(alpha: _hovering ? 0.1 : 0.05),
              blurRadius: _hovering ? 18 : 10,
              offset: Offset(0, _hovering ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _buildImagem(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receita.nome,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.preto,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPublica
                                  ? [
                                      AppColors.verde.withValues(alpha: 0.18),
                                      AppColors.verde.withValues(alpha: 0.08),
                                    ]
                                  : [
                                      AppColors.cinza.withValues(alpha: 0.18),
                                      AppColors.cinza.withValues(alpha: 0.08),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPublica
                                  ? AppColors.verde.withValues(alpha: 0.4)
                                  : AppColors.cinza.withValues(alpha: 0.3),
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
                                size: 12,
                                color: isPublica
                                    ? AppColors.verde
                                    : AppColors.cinza,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isPublica ? 'Pública' : 'Privada',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isPublica
                                      ? AppColors.verde
                                      : AppColors.cinza,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 6),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _hovering
                          ? AppColors.dourado.withValues(alpha: 0.18)
                          : AppColors.dourado.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.dourado,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagem() {
    if (widget.receita.imagens.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Image.memory(
            widget.receita.imagens.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.douradoClaro,
            AppColors.dourado.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        size: 38,
        color: AppColors.branco,
      ),
    );
  }
}
