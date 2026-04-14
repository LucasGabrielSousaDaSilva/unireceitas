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
    final String receitaId = ModalRoute.of(context)!.settings.arguments as String;
    final usuarioLogado = context.watch<AuthProvider>().usuarioLogado;

    return Consumer<ReceitaProvider>(
      builder: (context, provider, child) {
        final receita = provider.buscarPorId(receitaId);

        if (receita == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verifica se o usuário logado é o proprietário da receita
        final bool ehProprietario =
            usuarioLogado != null && receita.proprietarioId == usuarioLogado.id;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Detalhes da Receita',
              style: TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.preto,
            iconTheme: const IconThemeData(color: AppColors.branco),
            actions: [
              // Só mostra editar/excluir se for o proprietário
              if (ehProprietario) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.dourado),
                  tooltip: 'Editar receita',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/editar',
                      arguments: receita.id,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.vermelho),
                  tooltip: 'Excluir receita',
                  onPressed: () {
                    _mostrarDialogoExclusao(context, provider, receita.id);
                  },
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrossel de imagens
                CarrosselImagens(imagens: receita.imagens),

                // Nome da receita
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          receita.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.preto,
                          ),
                        ),
                      ),
                      // Badge de acesso
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: receita.acesso == AcessoReceita.publica
                              ? Colors.green.withValues(alpha: 0.15)
                              : AppColors.cinza.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: receita.acesso == AcessoReceita.publica
                                ? Colors.green
                                : AppColors.cinza,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              receita.acesso == AcessoReceita.publica
                                  ? Icons.public
                                  : Icons.lock,
                              size: 14,
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

                // Aviso para não proprietários
                if (!ehProprietario)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.douradoClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility, color: AppColors.dourado, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Você está visualizando uma receita compartilhada.',
                            style: TextStyle(fontSize: 13, color: AppColors.cinza),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(color: AppColors.dourado, thickness: 1, indent: 16, endIndent: 16),

                // Ingredientes
                _buildSecao(
                  titulo: 'Ingredientes',
                  conteudo: receita.ingredientes,
                  icone: Icons.shopping_basket,
                ),

                const Divider(color: AppColors.dourado, thickness: 1, indent: 16, endIndent: 16),

                // Modo de preparo
                _buildSecao(
                  titulo: 'Modo de Preparo',
                  conteudo: receita.modoPreparo,
                  icone: Icons.restaurant,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecao({
    required String titulo,
    required String conteudo,
    required IconData icone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppColors.dourado, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.vermelho,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conteudo,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.preto,
            ),
          ),
        ],
      ),
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
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.vermelho),
              SizedBox(width: 8),
              Text(
                'Confirmar Exclusão',
                style: TextStyle(
                  color: AppColors.preto,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Tem certeza que deseja excluir esta receita? Esta ação não pode ser desfeita.',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.cinza, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final dialogNav = Navigator.of(dialogContext);
                final mainNav = Navigator.of(context);
                dialogNav.pop();
                mainNav.pop();
                await provider.excluirReceita(receitaId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vermelho,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppColors.branco, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
