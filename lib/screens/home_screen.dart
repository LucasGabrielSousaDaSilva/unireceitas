import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/receita_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/receita_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';

  // Paginação
  int _paginaMinhas = 0;
  int _paginaCompartilhadas = 0;
  static const int _itensPorPagina = 10;

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
      appBar: AppBar(
        title: const Text(
          'UniReceitas',
          style: TextStyle(
            color: AppColors.branco,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: AppColors.preto,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Dropdown com opções de perfil e logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: AppColors.branco, size: 30),
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
                    const Icon(Icons.person, color: AppColors.dourado),
                    const SizedBox(width: 8),
                    Text('Perfil (${usuario.nome})'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.vermelho),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.dourado,
          labelColor: AppColors.dourado,
          unselectedLabelColor: AppColors.branco,
          tabs: const [
            Tab(text: 'Minhas Receitas'),
            Tab(text: 'Receitas Compartilhadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAbaMinhasReceitas(context, usuario.id),
          _buildAbaCompartilhadas(context),
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
            // Botão Nova Receita
            _buildBotaoCadastrar(context),
            // Lista
            Expanded(
              child: receitasPagina.isEmpty
                  ? _buildListaVazia('Nenhuma receita cadastrada', 'Toque em "Nova Receita" para começar!')
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: receitasPagina.length,
                      itemBuilder: (context, index) {
                        final receita = receitasPagina[index];
                        return ReceitaCard(
                          receita: receita,
                          onTap: () {
                            Navigator.pushNamed(context, '/detalhes', arguments: receita.id);
                          },
                        );
                      },
                    ),
            ),
            // Paginação
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
        final totalPaginas = (todasCompartilhadas.length / _itensPorPagina).ceil();
        if (_paginaCompartilhadas >= totalPaginas && totalPaginas > 0) {
          _paginaCompartilhadas = totalPaginas - 1;
        }
        final receitasPagina = provider.paginar(todasCompartilhadas, _paginaCompartilhadas);

        return Column(
          children: [
            // Barra de busca
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: 'Buscar receitas pelo nome...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.dourado),
                  suffixIcon: _termoBusca.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.cinza),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {
                              _termoBusca = '';
                              _paginaCompartilhadas = 0;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cinza),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dourado, width: 2),
                  ),
                ),
                onChanged: (valor) {
                  setState(() {
                    _termoBusca = valor;
                    _paginaCompartilhadas = 0;
                  });
                },
              ),
            ),
            // Lista
            Expanded(
              child: receitasPagina.isEmpty
                  ? _buildListaVazia(
                      _termoBusca.isNotEmpty
                          ? 'Nenhuma receita encontrada'
                          : 'Nenhuma receita compartilhada',
                      _termoBusca.isNotEmpty
                          ? 'Tente buscar por outro nome.'
                          : 'Receitas públicas aparecerão aqui.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: receitasPagina.length,
                      itemBuilder: (context, index) {
                        final receita = receitasPagina[index];
                        return ReceitaCard(
                          receita: receita,
                          onTap: () {
                            Navigator.pushNamed(context, '/detalhes', arguments: receita.id);
                          },
                        );
                      },
                    ),
            ),
            // Paginação
            if (totalPaginas > 1)
              _buildPaginacao(
                paginaAtual: _paginaCompartilhadas,
                totalPaginas: totalPaginas,
                onPaginaAlterada: (pagina) {
                  setState(() => _paginaCompartilhadas = pagina);
                },
              ),
          ],
        );
      },
    );
  }

  /// Botão de cadastrar nova receita
  Widget _buildBotaoCadastrar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/cadastro');
          },
          icon: const Icon(Icons.add, color: AppColors.branco),
          label: const Text(
            'Nova Receita',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.branco,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vermelho,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para lista vazia
  Widget _buildListaVazia(String titulo, String subtitulo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: AppColors.dourado.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, color: AppColors.cinza),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 14, color: AppColors.cinza),
          ),
        ],
      ),
    );
  }

  /// Widget de paginação
  Widget _buildPaginacao({
    required int paginaAtual,
    required int totalPaginas,
    required ValueChanged<int> onPaginaAlterada,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: paginaAtual > 0
                ? () => onPaginaAlterada(paginaAtual - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.vermelho,
          ),
          Text(
            'Página ${paginaAtual + 1} de $totalPaginas',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          IconButton(
            onPressed: paginaAtual < totalPaginas - 1
                ? () => onPaginaAlterada(paginaAtual + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.vermelho,
          ),
        ],
      ),
    );
  }
}
