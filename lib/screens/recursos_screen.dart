// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/nutrition_provider.dart';
import '../services/nutrition_service.dart';
import '../utils/app_colors.dart';
import '../widgets/nutrition_table_widget.dart';

class RecursosScreen extends StatefulWidget {
  const RecursosScreen({super.key});

  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  final TextEditingController _ingredientesController = TextEditingController();
  final TextEditingController _alimentoController = TextEditingController();
  FoodInfo? _ultimoAlimentoEncontrado;
  bool _dadosIniciaisCarregados = false;
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dadosIniciaisCarregados) {
      final aiProvider = context.read<AIProvider>();
      if (!aiProvider.iaDisponivel) {
        aiProvider.inicializar();
      }
      _dadosIniciaisCarregados = true;
    }
  }

  @override
  void dispose() {
    _ingredientesController.dispose();
    _alimentoController.dispose();
    super.dispose();
  }

  Future<void> _buscarInfoNutricional() async {
    final input = _alimentoController.text.trim();
    if (input.isEmpty) return;

    // Tenta separar quantidade (ex: "2lbs chicken", "chicken 2 lbs", "100 g arroz")
    String? quantity;
    String query = input;

    final regex = RegExp(r'(\d+[\d\.,]*\s*(?:kg|g|lbs?|lb|oz|ml|l|tbsp|tsp|cup|cups|xícara|xicaras|colher|colheres))', caseSensitive: false);
    final match = regex.firstMatch(input);
    if (match != null) {
      quantity = match.group(0)?.trim();
      query = input.replaceFirst(match.group(0)!, '').trim();
      if (query.isEmpty) {
        // se o input era apenas quantidade + alimento e a ordem estava invertida, tente buscar palavra restante
        final parts = input.split(RegExp(r'\s+'));
        // remove o trecho da quantidade
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].contains(RegExp(r'\d'))) continue;
        }
      }
    }

    final provider = context.read<NutritionProvider>();
    final info = await provider.buscarAlimento(query, quantity: quantity);
    setState(() {
      _ultimoAlimentoEncontrado = info;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos'),
        backgroundColor: AppColors.preto,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildSecaoIA(),
            const SizedBox(height: 24),
            _buildSecaoNutricional(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoIA() {
    return Consumer<AIProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sugestão de Receita por IA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ingredientesController,
                  decoration: InputDecoration(
                    labelText: 'Ingredientes (vírgula separados)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                if (provider.carregando) const LinearProgressIndicator(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.carregando
                            ? null
                            : () async {
                                final texto = _ingredientesController.text.trim();
                                final ingredientes = texto
                                    .split(',')
                                    .map((item) => item.trim())
                                    .where((item) => item.isNotEmpty)
                                    .toList();
                                await provider.sugerirReceitas(ingredientes);
                              },
                        child: const Text('Gerar sugestão'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.cinza),
                      onPressed: !provider.carregando
                          ? () {
                              _ingredientesController.clear();
                              provider.limparSugestao();
                              provider.limparErro();
                            }
                          : null,
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.temErro)
                  Text(
                    provider.erro ?? 'Erro desconhecido',
                    style: const TextStyle(color: AppColors.vermelho),
                  ),
                if (!provider.carregando && provider.ultimaSugestao != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sugestão encontrada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(provider.ultimaSugestao!),
                    ],
                  )
                else if (!provider.carregando && provider.ultimaSugestao == null)
                  const Text('Use IA para obter sugestões rápidas de receitas.'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecaoNutricional() {
    return Consumer<NutritionProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informação Nutricional',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alimentoController,
                  decoration: InputDecoration(
                    labelText: 'Buscar alimento',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.carregando ? null : _buscarInfoNutricional,
                        child: const Text('Buscar nutricional'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.cinza),
                      onPressed: provider.carregando
                          ? null
                          : () {
                              _alimentoController.clear();
                              setState(() => _ultimoAlimentoEncontrado = null);
                              provider.limparErro();
                            },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.carregando) const LinearProgressIndicator(),
                if (provider.temErro)
                  Text(
                    provider.erro ?? 'Erro ao buscar nutriente',
                    style: const TextStyle(color: AppColors.vermelho),
                  ),
                if (_ultimoAlimentoEncontrado != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      NutritionTableWidget(foodInfo: _ultimoAlimentoEncontrado!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          provider.adicionarAlimento(_ultimoAlimentoEncontrado!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_ultimoAlimentoEncontrado!.nome} adicionado à lista'),
                              backgroundColor: AppColors.verde,
                            ),
                          );
                        },
                        child: const Text('Adicionar à lista'),
                      ),
                    ],
                  ),
                if (provider.alimentosSelecionados.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Lista selecionada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.alimentosSelecionados
                        .asMap()
                        .entries
                        .map(
                          (entry) => Chip(
                            label: Text(entry.value.nome),
                            onDeleted: () => provider.removerAlimento(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Total calorias: ${provider.calcularCaloriasTotal().toStringAsFixed(1)} kcal'),
                  if (provider.obterTotalNutrientes() != null)
                    Text(
                      'Proteína: ${provider.obterTotalNutrientes()!.proteina.toStringAsFixed(1)}g • Carboidratos: ${provider.obterTotalNutrientes()!.carboidratos.toStringAsFixed(1)}g • Gordura: ${provider.obterTotalNutrientes()!.gordura.toStringAsFixed(1)}g',
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  
}
