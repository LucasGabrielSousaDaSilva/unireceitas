import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/receita_provider.dart';
import '../models/receita.dart';
import '../utils/app_colors.dart';
import '../widgets/receita_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum OrdenacaoReceitas {
  nomeAsc,
  nomeDesc,
  dataDesc,
  dataAsc,
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';
  String? _expandedRecipeId; // Controla qual receita está expandida

  // Paginação para aba de minhas receitas
  int _paginaMinhas = 0;
  static const int _itensPorPagina = 10;

  // Ordenação e filtros da aba "Compartilhadas"
  OrdenacaoReceitas _ordenacao = OrdenacaoReceitas.dataDesc;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuarioLogado;

    if (usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48),
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.dourado, Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dourado.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.branco,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'UniReceitas',
                  style: TextStyle(
                    color: AppColors.branco,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome,
                    color: AppColors.dourado, size: 26),
                tooltip: 'Recursos',
                onPressed: () => Navigator.pushNamed(context, '/recursos'),
              ),
              PopupMenuButton<String>(
                tooltip: 'Conta',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dourado.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    color: AppColors.branco,
                    size: 28,
                  ),
                ),
                onSelected: (valor) {
                  if (valor == 'perfil') {
                    Navigator.pushNamed(context, '/perfil');
                  } else if (valor == 'logout') {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'perfil',
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            color: AppColors.dourado),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Perfil (${usuario.nome})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.vermelho),
                        SizedBox(width: 10),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin:
                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.branco.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.branco.withValues(alpha: 0.1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.dourado, Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dourado.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.preto,
                  unselectedLabelColor:
                      AppColors.branco.withValues(alpha: 0.75),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  tabs: const [
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_rounded, size: 17),
                          SizedBox(width: 6),
                          Text('Minhas Receitas'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_rounded, size: 17),
                          SizedBox(width: 6),
                          Text('Compartilhadas'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Fundo decorativo sutil
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
                      AppColors.dourado.withValues(alpha: 0.16),
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
          TabBarView(
            controller: _tabController,
            children: [
              _buildAbaMinhasReceitas(context, usuario.id),
              _buildAbaCompartilhadas(context),
            ],
          ),
        ],
      ),
    );
  }

  /// Aba "Minhas Receitas"
  Widget _buildAbaMinhasReceitas(BuildContext context, String usuarioId) {
    return Consumer<ReceitaProvider>(
      builder: (context, provider, child) {
        final todasMinhas = provider.minhasReceitas(usuarioId);
        final totalPaginas = (todasMinhas.length / _itensPorPagina).ceil();
        if (_paginaMinhas >= totalPaginas && totalPaginas > 0) {
          _paginaMinhas = totalPaginas - 1;
        }
        final receitasPagina = provider.paginar(todasMinhas, _paginaMinhas);

        return Column(
          children: [
            _buildBotaoCadastrar(context),
            if (todasMinhas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded,
                        color: AppColors.dourado, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${todasMinhas.length} ${todasMinhas.length == 1 ? 'receita' : 'receitas'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.preto,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: receitasPagina.isEmpty
                  ? _buildListaVazia(
                      'Nenhuma receita cadastrada',
                      'Toque em "Nova Receita" para começar!',
                      icone: Icons.menu_book_rounded,
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: ListView.builder(
                        key: ValueKey(_paginaMinhas),
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: receitasPagina.length,
                        itemBuilder: (context, index) {
                          final receita = receitasPagina[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                                milliseconds: 250 + (index * 40).clamp(0, 250)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 12),
                                  child: child,
                                ),
                              );
                            },
                            child: ReceitaCard(
                              receita: receita,
                              onTap: () {
                                Navigator.pushNamed(context, '/detalhes',
                                    arguments: receita.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (totalPaginas > 1)
              _buildPaginacao(
                paginaAtual: _paginaMinhas,
                totalPaginas: totalPaginas,
                onPaginaAlterada: (pagina) {
                  setState(() => _paginaMinhas = pagina);
                },
              ),
          ],
        );
      },
    );
  }

  /// Aba "Receitas Compartilhadas"
  Widget _buildAbaCompartilhadas(BuildContext context) {
    return Consumer<ReceitaProvider>(
      builder: (context, provider, child) {
        final todasCompartilhadas = provider.buscarCompartilhadas(_termoBusca);

        return Column(
          children: [
            // Campo de pesquisa
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.branco,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.preto.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _buscaController,
                  style: const TextStyle(
                      fontSize: 14.5, color: AppColors.preto),
                  decoration: InputDecoration(
                    hintText: 'Procurar receita',
                    hintStyle: TextStyle(
                      color: AppColors.cinza.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.dourado,
                    ),
                    suffixIcon: _termoBusca.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.cinza,
                            ),
                            onPressed: () {
                              _buscaController.clear();
                              setState(() {
                                _termoBusca = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.dourado, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.branco,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _termoBusca = valor;
                    });
                  },
                ),
              ),
            ),
            // Barra de ordenação + filtro de período
            _buildBarraOrdenacaoFiltro(),
            // Chip do período ativo
            if (_dataInicio != null || _dataFim != null)
              _buildChipPeriodoAtivo(),
            const SizedBox(height: 4),
            // Grid de Receitas
            Expanded(
              child: Builder(
                builder: (context) {
                  final lista = _aplicarOrdenacaoFiltro(todasCompartilhadas);
                  if (lista.isEmpty) {
                    final temFiltro =
                        _dataInicio != null || _dataFim != null;
                    return _buildListaVazia(
                      _termoBusca.isNotEmpty
                          ? 'Nenhuma receita encontrada'
                          : temFiltro
                              ? 'Nenhuma receita no período'
                              : 'Nenhuma receita compartilhada',
                      _termoBusca.isNotEmpty
                          ? 'Tente buscar por outro nome.'
                          : temFiltro
                              ? 'Ajuste o filtro de datas para ver mais resultados.'
                              : 'Receitas públicas aparecerão aqui.',
                      icone: _termoBusca.isNotEmpty
                          ? Icons.search_off_rounded
                          : temFiltro
                              ? Icons.event_busy_rounded
                              : Icons.groups_rounded,
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxis = width >= 1100
                          ? 4
                          : width >= 760
                              ? 3
                              : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxis,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final receita = lista[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                                milliseconds:
                                    280 + (index * 40).clamp(0, 280)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 14),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildRecipeImageCard(context, receita),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // =================== ORDENAÇÃO E FILTROS DE PERÍODO ===================

  /// Aplica filtro de data e ordenação na lista de receitas.
  List<Receita> _aplicarOrdenacaoFiltro(List<Receita> receitas) {
    // Filtro por período (data de criação)
    final filtradas = receitas.where((r) {
      if (_dataInicio == null && _dataFim == null) return true;
      final data = r.createdAt;
      if (data == null) return false;
      final apenasData = DateTime(data.year, data.month, data.day);
      if (_dataInicio != null) {
        final inicio = DateTime(
          _dataInicio!.year,
          _dataInicio!.month,
          _dataInicio!.day,
        );
        if (apenasData.isBefore(inicio)) return false;
      }
      if (_dataFim != null) {
        final fim = DateTime(
          _dataFim!.year,
          _dataFim!.month,
          _dataFim!.day,
        );
        if (apenasData.isAfter(fim)) return false;
      }
      return true;
    }).toList();

    // Ordenação
    filtradas.sort((a, b) {
      switch (_ordenacao) {
        case OrdenacaoReceitas.nomeAsc:
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case OrdenacaoReceitas.nomeDesc:
          return b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
        case OrdenacaoReceitas.dataDesc:
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        case OrdenacaoReceitas.dataAsc:
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
      }
    });

    return filtradas;
  }

  String _rotuloOrdenacao(OrdenacaoReceitas o) {
    switch (o) {
      case OrdenacaoReceitas.nomeAsc:
        return 'Nome (A → Z)';
      case OrdenacaoReceitas.nomeDesc:
        return 'Nome (Z → A)';
      case OrdenacaoReceitas.dataDesc:
        return 'Mais recentes';
      case OrdenacaoReceitas.dataAsc:
        return 'Mais antigas';
    }
  }

  IconData _iconeOrdenacao(OrdenacaoReceitas o) {
    switch (o) {
      case OrdenacaoReceitas.nomeAsc:
        return Icons.sort_by_alpha_rounded;
      case OrdenacaoReceitas.nomeDesc:
        return Icons.sort_by_alpha_rounded;
      case OrdenacaoReceitas.dataDesc:
        return Icons.history_rounded;
      case OrdenacaoReceitas.dataAsc:
        return Icons.update_rounded;
    }
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  Future<void> _mostrarOpcoesOrdenacao() async {
    final escolha = await showModalBottomSheet<OrdenacaoReceitas>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cinza.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Ordenar por',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...OrdenacaoReceitas.values.map((o) {
                final selecionado = o == _ordenacao;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, o),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? AppColors.dourado.withValues(alpha: 0.1)
                              : const Color(0xFFFAF8F3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selecionado
                                ? AppColors.dourado
                                : AppColors.cinza.withValues(alpha: 0.15),
                            width: selecionado ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selecionado
                                    ? AppColors.dourado
                                        .withValues(alpha: 0.18)
                                    : AppColors.cinza.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconeOrdenacao(o),
                                color: selecionado
                                    ? AppColors.dourado
                                    : AppColors.cinza,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _rotuloOrdenacao(o),
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: selecionado
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: AppColors.preto,
                                ),
                              ),
                            ),
                            if (selecionado)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.dourado,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (escolha != null) {
      setState(() => _ordenacao = escolha);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year + 1, 12, 31),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
      helpText: 'Selecione o período',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.vermelho,
              onPrimary: AppColors.branco,
              surface: AppColors.branco,
              onSurface: AppColors.preto,
            ),
          ),
          child: child!,
        );
      },
    );

    if (intervalo != null) {
      setState(() {
        _dataInicio = intervalo.start;
        _dataFim = intervalo.end;
      });
    }
  }

  void _limparPeriodo() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
    });
  }

  Widget _buildBarraOrdenacaoFiltro() {
    final temPeriodo = _dataInicio != null || _dataFim != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _BotaoBarra(
              icone: _iconeOrdenacao(_ordenacao),
              titulo: 'Ordenar',
              valor: _rotuloOrdenacao(_ordenacao),
              destaque: false,
              onTap: _mostrarOpcoesOrdenacao,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BotaoBarra(
              icone: Icons.date_range_rounded,
              titulo: 'Período',
              valor: temPeriodo
                  ? '${_dataInicio != null ? _formatarData(_dataInicio!) : '—'} → ${_dataFim != null ? _formatarData(_dataFim!) : '—'}'
                  : 'Selecionar datas',
              destaque: temPeriodo,
              onTap: _selecionarPeriodo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipPeriodoAtivo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _limparPeriodo,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.dourado.withValues(alpha: 0.18),
                    AppColors.douradoClaro.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.dourado.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: AppColors.dourado,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_dataInicio != null ? _formatarData(_dataInicio!) : '—'}  →  ${_dataFim != null ? _formatarData(_dataFim!) : '—'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.dourado.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.dourado,
                      size: 12,
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

  /// Widget para card de receita com imagem expandível
  Widget _buildRecipeImageCard(BuildContext context, dynamic receita) {
    final isExpanded = _expandedRecipeId == receita.id;
    final temImagem = receita.imagens != null && receita.imagens!.isNotEmpty;
    final isPublica = receita.acesso == AcessoReceita.publica;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedRecipeId = isExpanded ? null : receita.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded
                ? AppColors.dourado.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto
                  .withValues(alpha: isExpanded ? 0.18 : 0.1),
              blurRadius: isExpanded ? 18 : 10,
              offset: Offset(0, isExpanded ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem ou placeholder
              if (temImagem)
                Image.memory(
                  receita.imagens![0],
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.douradoClaro,
                        AppColors.dourado.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 56,
                      color: AppColors.branco,
                    ),
                  ),
                ),
              // Gradiente
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              // Badge de acesso (canto superior)
              Positioned(
                top: 10,
                left: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.preto.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.branco.withValues(alpha: 0.18),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPublica
                              ? Icons.public_rounded
                              : Icons.lock_outline_rounded,
                          color: AppColors.dourado,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPublica ? 'Pública' : 'Privada',
                          style: const TextStyle(
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
              // Conteúdo inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 280),
                  padding: EdgeInsets.all(isExpanded ? 14 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receita.nome,
                        maxLines: isExpanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.branco,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1,
                          shadows: [
                            Shadow(
                              color: Color(0x88000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: isExpanded
                            ? Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/detalhes',
                                          arguments: receita.id,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility_rounded,
                                        size: 16,
                                        color: AppColors.branco,
                                      ),
                                      label: const Text(
                                        'Ver receita',
                                        style: TextStyle(
                                          color: AppColors.branco,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.vermelho,
                                        elevation: 4,
                                        shadowColor: AppColors.vermelho
                                            .withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão de cadastrar nova receita
  Widget _buildBotaoCadastrar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/cadastro');
          },
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.vermelho.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.branco.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.branco,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nova Receita',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.branco,
                      letterSpacing: 0.3,
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

  /// Widget para lista vazia
  Widget _buildListaVazia(
    String titulo,
    String subtitulo, {
    IconData icone = Icons.menu_book_rounded,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.douradoClaro.withValues(alpha: 0.7),
                    AppColors.dourado.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                icone,
                size: 56,
                color: AppColors.dourado.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.preto,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.cinza.withValues(alpha: 0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de paginação
  Widget _buildPaginacao({
    required int paginaAtual,
    required int totalPaginas,
    required ValueChanged<int> onPaginaAlterada,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cinza.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPaginacaoBotao(
            icone: Icons.chevron_left_rounded,
            habilitado: paginaAtual > 0,
            onTap: () => onPaginaAlterada(paginaAtual - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${paginaAtual + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.vermelho,
                  ),
                ),
                Text(
                  ' / $totalPaginas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cinza.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          _buildPaginacaoBotao(
            icone: Icons.chevron_right_rounded,
            habilitado: paginaAtual < totalPaginas - 1,
            onTap: () => onPaginaAlterada(paginaAtual + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacaoBotao({
    required IconData icone,
    required bool habilitado,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: habilitado ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: habilitado
                ? AppColors.vermelho.withValues(alpha: 0.1)
                : AppColors.cinza.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icone,
            color: habilitado
                ? AppColors.vermelho
                : AppColors.cinza.withValues(alpha: 0.5),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _BotaoBarra extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final bool destaque;
  final VoidCallback onTap;

  const _BotaoBarra({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.destaque,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: destaque
                  ? AppColors.dourado.withValues(alpha: 0.55)
                  : AppColors.cinza.withValues(alpha: 0.18),
              width: destaque ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.preto.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: destaque
                        ? [
                            AppColors.dourado.withValues(alpha: 0.25),
                            AppColors.douradoClaro.withValues(alpha: 0.55),
                          ]
                        : [
                            AppColors.dourado.withValues(alpha: 0.18),
                            AppColors.douradoClaro.withValues(alpha: 0.5),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: AppColors.dourado, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.cinza.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: destaque
                            ? const Color(0xFFB8860B)
                            : AppColors.preto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.cinza.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
