import 'package:flutter/material.dart';
import '../models/receita.dart';
import '../utils/app_colors.dart';

class ReceitaCard extends StatelessWidget {
  final Receita receita;
  final VoidCallback onTap;

  const ReceitaCard({
    super.key,
    required this.receita,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _buildImagem(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receita.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.preto,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badge de acesso
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: receita.acesso == AcessoReceita.publica
                            ? Colors.green.withValues(alpha: 0.15)
                            : AppColors.cinza.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            receita.acesso == AcessoReceita.publica
                                ? Icons.public
                                : Icons.lock,
                            size: 12,
                            color: receita.acesso == AcessoReceita.publica
                                ? Colors.green
                                : AppColors.cinza,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            receita.acesso == AcessoReceita.publica
                                ? 'Pública'
                                : 'Privada',
                            style: TextStyle(
                              fontSize: 11,
                              color: receita.acesso == AcessoReceita.publica
                                  ? Colors.green
                                  : AppColors.cinza,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.dourado,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagem() {
    if (receita.imagens.isNotEmpty) {
      return SizedBox(
        width: 100,
        height: 100,
        child: Image.memory(
          receita.imagens.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.douradoClaro,
      child: const Icon(
        Icons.restaurant_menu,
        size: 40,
        color: AppColors.dourado,
      ),
    );
  }
}
