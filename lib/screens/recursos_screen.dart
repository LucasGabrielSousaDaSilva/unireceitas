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

class _RecursosScreenState extends State<RecursosScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ingredientesController = TextEditingController();
  final TextEditingController _alimentoController = TextEditingController();
  FoodInfo? _ultimoAlimentoEncontrado;
  bool _dadosIniciaisCarregados = false;

  late final AnimationController _entradaController;

  @override
  void initState() {
    super.initState();
    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entradaController.forward();
    });
  }

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
    _entradaController.dispose();
    _ingredientesController.dispose();
    _alimentoController.dispose();
    super.dispose();
  }

  Future<void> _buscarInfoNutricional() async {
    final input = _alimentoController.text.trim();
    if (input.isEmpty) return;

    String? quantity;
    String query = input;

    final regex = RegExp(
        r'(\d+[\d\.,]*\s*(?:kg|g|lbs?|lb|oz|ml|l|tbsp|tsp|cup|cups|xícara|xicaras|colher|colheres))',
        caseSensitive: false);
    final match = regex.firstMatch(input);
    if (match != null) {
      quantity = match.group(0)?.trim();
      query = input.replaceFirst(match.group(0)!, '').trim();
      if (query.isEmpty) {
        final parts = input.split(RegExp(r'\s+'));
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 720;
    final horizontalPadding = isWide ? 32.0 : 16.0;
    final maxContentWidth = isWide ? 880.0 : double.infinity;

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
              'Recursos',
              style: TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.branco),
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
                      _animar(0, _buildHeroHeader()),
                      const SizedBox(height: 20),
                      _animar(1, _buildSecaoIA()),
                      const SizedBox(height: 16),
                      _animar(2, _buildSecaoNutricional()),
                      const SizedBox(height: 24),
                    ],
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

  Widget _buildHeroHeader() {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.dourado, Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dourado.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.branco,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recursos inteligentes',
                  style: TextStyle(
                    color: AppColors.branco,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sugestões com IA e informações nutricionais',
                  style: TextStyle(
                    color: AppColors.branco.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    required String descricao,
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
              const SizedBox(height: 2),
              Text(
                descricao,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.cinza.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.cinza.withValues(alpha: 0.55),
        fontSize: 13,
      ),
      prefixIcon: Icon(icone, color: AppColors.dourado),
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
          color: AppColors.cinza.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.dourado, width: 2),
      ),
    );
  }

  Widget _botaoPrincipal({
    required String texto,
    required IconData icone,
    required VoidCallback? onPressed,
    bool carregando = false,
  }) {
    final habilitado = onPressed != null && !carregando;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: habilitado ? onPressed : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: habilitado
                  ? const [AppColors.vermelho, AppColors.vermelhoEscuro]
                  : [
                      AppColors.vermelho.withValues(alpha: 0.45),
                      AppColors.vermelhoEscuro.withValues(alpha: 0.45),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: habilitado
                ? [
                    BoxShadow(
                      color: AppColors.vermelho.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (carregando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.branco),
                    ),
                  )
                else
                  Icon(icone, color: AppColors.branco, size: 18),
                const SizedBox(width: 8),
                Text(
                  texto,
                  style: const TextStyle(
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
    );
  }

  Widget _botaoSecundario({
    required String texto,
    required IconData icone,
    required VoidCallback? onPressed,
  }) {
    final habilitado = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: habilitado ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            color: habilitado
                ? const Color(0xFFFAF8F3)
                : AppColors.cinza.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: habilitado
                  ? AppColors.cinza.withValues(alpha: 0.25)
                  : AppColors.cinza.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                color: habilitado
                    ? AppColors.cinza
                    : AppColors.cinza.withValues(alpha: 0.5),
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(
                  color: habilitado
                      ? AppColors.preto
                      : AppColors.cinza.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErroBox(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vermelho.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.vermelho.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.vermelho, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                color: AppColors.vermelho,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBarra() {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.dourado.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: const LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.dourado),
      ),
    );
  }

  // ============================ Seção IA ============================

  Widget _buildSecaoIA() {
    return Consumer<AIProvider>(
      builder: (context, provider, child) {
        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icone: Icons.psychology_alt_rounded,
                titulo: 'Sugestão de Receita por IA',
                descricao:
                    'Informe ingredientes e receba ideias inteligentes',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ingredientesController,
                style: const TextStyle(fontSize: 15, color: AppColors.preto),
                minLines: 2,
                maxLines: 4,
                decoration: _decoracaoCampo(
                  label: 'Ingredientes',
                  icone: Icons.kitchen_rounded,
                  hint: 'Ex: ovo, farinha, leite, açúcar',
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final acoes = [
                    Expanded(
                      child: _botaoPrincipal(
                        texto: 'Gerar sugestão',
                        icone: Icons.auto_awesome_rounded,
                        carregando: provider.carregando,
                        onPressed: provider.carregando
                            ? null
                            : () async {
                                final texto =
                                    _ingredientesController.text.trim();
                                final ingredientes = texto
                                    .split(',')
                                    .map((item) => item.trim())
                                    .where((item) => item.isNotEmpty)
                                    .toList();
                                await provider.sugerirReceitas(ingredientes);
                              },
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? 0 : 10,
                      height: isNarrow ? 10 : 0,
                    ),
                    Expanded(
                      child: _botaoSecundario(
                        texto: 'Limpar',
                        icone: Icons.cleaning_services_rounded,
                        onPressed: !provider.carregando
                            ? () {
                                _ingredientesController.clear();
                                provider.limparSugestao();
                                provider.limparErro();
                              }
                            : null,
                      ),
                    ),
                  ];
                  return isNarrow
                      ? Column(children: acoes)
                      : Row(children: acoes);
                },
              ),
              if (provider.carregando) ...[
                const SizedBox(height: 14),
                _buildLoadingBarra(),
              ],
              if (provider.temErro) ...[
                const SizedBox(height: 14),
                _buildErroBox(provider.erro ?? 'Erro desconhecido'),
              ],
              const SizedBox(height: 14),
              if (!provider.carregando && provider.ultimaSugestao != null)
                _buildResultadoIA(provider.ultimaSugestao!)
              else if (!provider.carregando && provider.ultimaSugestao == null)
                _buildPlaceholderIA(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultadoIA(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.douradoClaro.withValues(alpha: 0.65),
            AppColors.dourado.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dourado.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.dourado.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.dourado,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sugestão encontrada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFB8860B),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.preto,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cinza.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.dourado.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.dourado,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Use a IA para obter sugestões rápidas de receitas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.cinza,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ====================== Seção Informação Nutricional ======================

  Widget _buildSecaoNutricional() {
    return Consumer<NutritionProvider>(
      builder: (context, provider, child) {
        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icone: Icons.local_dining_rounded,
                titulo: 'Informação Nutricional',
                descricao:
                    'Consulte calorias e macronutrientes de alimentos',
                cor: AppColors.verde,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alimentoController,
                style: const TextStyle(fontSize: 15, color: AppColors.preto),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  if (!provider.carregando) _buscarInfoNutricional();
                },
                decoration: _decoracaoCampo(
                  label: 'Buscar alimento',
                  icone: Icons.search_rounded,
                  hint: 'Ex: 100g arroz, 2 ovos, 1 cup oats',
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final acoes = [
                    Expanded(
                      child: _botaoPrincipal(
                        texto: 'Buscar nutricional',
                        icone: Icons.bar_chart_rounded,
                        carregando: provider.carregando,
                        onPressed: provider.carregando
                            ? null
                            : _buscarInfoNutricional,
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? 0 : 10,
                      height: isNarrow ? 10 : 0,
                    ),
                    Expanded(
                      child: _botaoSecundario(
                        texto: 'Limpar',
                        icone: Icons.cleaning_services_rounded,
                        onPressed: provider.carregando
                            ? null
                            : () {
                                _alimentoController.clear();
                                setState(
                                    () => _ultimoAlimentoEncontrado = null);
                                provider.limparErro();
                              },
                      ),
                    ),
                  ];
                  return isNarrow
                      ? Column(children: acoes)
                      : Row(children: acoes);
                },
              ),
              if (provider.carregando) ...[
                const SizedBox(height: 14),
                _buildLoadingBarra(),
              ],
              if (provider.temErro) ...[
                const SizedBox(height: 14),
                _buildErroBox(provider.erro ?? 'Erro ao buscar nutriente'),
              ],
              if (_ultimoAlimentoEncontrado != null) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: NutritionTableWidget(
                      foodInfo: _ultimoAlimentoEncontrado!),
                ),
                const SizedBox(height: 14),
                _botaoPrincipal(
                  texto: 'Adicionar à lista',
                  icone: Icons.playlist_add_rounded,
                  onPressed: () {
                    provider.adicionarAlimento(_ultimoAlimentoEncontrado!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_ultimoAlimentoEncontrado!.nome} adicionado à lista',
                        ),
                        backgroundColor: AppColors.verde,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
              ],
              if (provider.alimentosSelecionados.isNotEmpty) ...[
                const SizedBox(height: 22),
                _buildResumoLista(provider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumoLista(NutritionProvider provider) {
    final totalKcal = provider.calcularCaloriasTotal();
    final totais = provider.obterTotalNutrientes();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.verde.withValues(alpha: 0.1),
            AppColors.verde.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.verde.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.verde.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.verde,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lista selecionada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.preto,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.verde.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.alimentosSelecionados.length} ${provider.alimentosSelecionados.length == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.verde,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.alimentosSelecionados
                .asMap()
                .entries
                .map(
                  (entry) => _ChipAlimento(
                    nome: entry.value.nome,
                    onRemove: () => provider.removerAlimento(entry.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.verde.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.verde, Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.verde.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.branco,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total de calorias',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.cinza.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${totalKcal.toStringAsFixed(1)} kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.preto,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (totais != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MacroBox(
                    rotulo: 'Proteína',
                    valor: '${totais.proteina.toStringAsFixed(1)}g',
                    cor: AppColors.vermelho,
                    icone: Icons.fitness_center_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroBox(
                    rotulo: 'Carboidratos',
                    valor: '${totais.carboidratos.toStringAsFixed(1)}g',
                    cor: AppColors.dourado,
                    icone: Icons.grain_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroBox(
                    rotulo: 'Gordura',
                    valor: '${totais.gordura.toStringAsFixed(1)}g',
                    cor: AppColors.verde,
                    icone: Icons.opacity_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipAlimento extends StatelessWidget {
  final String nome;
  final VoidCallback onRemove;

  const _ChipAlimento({required this.nome, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.verde.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.restaurant_rounded,
            color: AppColors.verde,
            size: 14,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              nome,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.preto,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.vermelho.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.vermelho,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color cor;
  final IconData icone;

  const _MacroBox({
    required this.rotulo,
    required this.valor,
    required this.cor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(height: 4),
          Text(
            rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.cinza.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
