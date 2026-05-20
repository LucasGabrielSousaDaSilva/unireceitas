// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/calendar_provider.dart';
import '../services/nutrition_service.dart';
import '../utils/app_colors.dart';

class RecursosScreen extends StatefulWidget {
  const RecursosScreen({super.key});

  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  final TextEditingController _ingredientesController = TextEditingController();
  final TextEditingController _alimentoController = TextEditingController();
  final TextEditingController _accessTokenController = TextEditingController();
  final TextEditingController _tituloLembreteController = TextEditingController();
  final TextEditingController _itensLembreteController = TextEditingController();

  FoodInfo? _ultimoAlimentoEncontrado;
  bool _dadosIniciaisCarregados = false;
  DateTime _dataLembrete = DateTime.now().add(const Duration(days: 1));

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
    _accessTokenController.dispose();
    _tituloLembreteController.dispose();
    _itensLembreteController.dispose();
    super.dispose();
  }

  Future<void> _buscarInfoNutricional() async {
    final nome = _alimentoController.text.trim();
    if (nome.isEmpty) return;

    final provider = context.read<NutritionProvider>();
    final info = await provider.buscarAlimento(nome);
    setState(() {
      _ultimoAlimentoEncontrado = info;
    });
  }

  Future<void> _agendarLembreteFinDeSemana() async {
    final titulo = _tituloLembreteController.text.trim();
    final itens = _itensLembreteController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (titulo.isEmpty || itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe título e pelo menos um item para o lembrete.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }

    final provider = context.read<CalendarProvider>();
    await provider.agendarLembreteFinDeSemana(
      titulo: titulo,
      itens: itens,
    );
  }

  Future<void> _selecionarDataLembrete() async {
    final localContext = context;
    final dataSelecionada = await showDatePicker(
      context: localContext,
      initialDate: _dataLembrete,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || dataSelecionada == null) return;

    final horaSelecionada = await showTimePicker(
      context: localContext,
      initialTime: TimeOfDay(hour: _dataLembrete.hour, minute: _dataLembrete.minute),
    );

    if (!mounted || horaSelecionada == null) return;

    setState(() {
      _dataLembrete = DateTime(
        dataSelecionada.year,
        dataSelecionada.month,
        dataSelecionada.day,
        horaSelecionada.hour,
        horaSelecionada.minute,
      );
    });
  }

  String _formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
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
            const SizedBox(height: 24),
            _buildSecaoCalendario(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        _ultimoAlimentoEncontrado!.obterFormatado(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildSecaoCalendario() {
    return Consumer<CalendarProvider>(
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
                  'Calendário',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accessTokenController,
                  decoration: InputDecoration(
                    labelText: 'Access token do Google Calendar',
                    helperText: 'Use um token OAuth válido para acessar o calendário.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.carregando
                            ? null
                            : () async {
                                await provider.inicializar(_accessTokenController.text.trim());
                              },
                        child: const Text('Autorizar calendário'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.cinza),
                      onPressed: provider.carregando
                          ? null
                          : () {
                              _accessTokenController.clear();
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
                    provider.erro ?? 'Erro no calendário',
                    style: const TextStyle(color: AppColors.vermelho),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.temAutorizacao ? 'Calendário autorizado' : 'Ainda não autorizado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.temAutorizacao ? AppColors.verde : AppColors.cinza,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: provider.temAutorizacao && !provider.carregando
                          ? () => provider.carregarLembretes()
                          : null,
                      child: const Text('Carregar lembretes'),
                    ),
                  ],
                ),
                if (provider.temAutorizacao) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tituloLembreteController,
                    decoration: InputDecoration(
                      labelText: 'Título do lembrete',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itensLembreteController,
                    decoration: InputDecoration(
                      labelText: 'Itens (separados por vírgula)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selecionarDataLembrete,
                          child: Text('Data: ${_formatarDataHora(_dataLembrete)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: provider.carregando ? null : _agendarLembreteFinDeSemana,
                        child: const Text('Agendar fim de semana'),
                      ),
                    ],
                  ),
                  if (provider.lembretes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Lembretes carregados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...provider.lembretes.asMap().entries.map(
                          (entry) => ListTile(
                            tileColor: AppColors.douradoClaro.withValues(alpha: 0.4),
                            title: Text(entry.value.titulo),
                            subtitle: Text('Data: ${_formatarDataHora(entry.value.dataLembrete)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.vermelho),
                              onPressed: () => provider.removerLembrete(entry.key),
                            ),
                          ),
                        ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
