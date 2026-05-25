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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  String _termoBusca = '';
  String? _expandedRecipeId; // Controla qual receita está expandida

  // Paginação para aba de minhas receitas
  int _paginaMinhas = 0;
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
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.branco, size: 28),
            tooltip: 'Recursos',
            onPressed: () => Navigator.pushNamed(context, '/recursos'),
          ),
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
        
        return Column(
          children: [
            // Seção de Pesquisa
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: 'Procurar receita',
                  hintStyle: const TextStyle(color: AppColors.cinza),
                  prefixIcon: const Icon(Icons.search, color: AppColors.dourado),
                  suffixIcon: _termoBusca.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.cinza),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {
                              _termoBusca = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cinzaClaro),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dourado, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.cinzaClaro,
                ),
                onChanged: (valor) {
                  setState(() {
                    _termoBusca = valor;
                  });
                },
              ),
            ),
            // Seção de Seleção/Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos'),
                    _buildFilterChip('Rápidas'),
                    _buildFilterChip('Fáceis'),
                    _buildFilterChip('Saudáveis'),
                    _buildFilterChip('Festas'),
                  ],
                ),
              ),
            ),
            // Grid de Receitas
            Expanded(
              child: todasCompartilhadas.isEmpty
                  ? _buildListaVazia(
                      _termoBusca.isNotEmpty
                          ? 'Nenhuma receita encontrada'
                          : 'Nenhuma receita compartilhada',
                      _termoBusca.isNotEmpty
                          ? 'Tente buscar por outro nome.'
                          : 'Receitas públicas aparecerão aqui.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: todasCompartilhadas.length,
                      itemBuilder: (context, index) {
                        final receita = todasCompartilhadas[index];
                        return _buildRecipeImageCard(context, receita);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Widget para o chip de filtro
  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        onSelected: (selected) {
          // Implementar filtros aqui
        },
        backgroundColor: AppColors.cinzaClaro,
        labelStyle: const TextStyle(color: AppColors.preto),
      ),
    );
  }

  /// Widget para card de receita com imagem expandível
  Widget _buildRecipeImageCard(BuildContext context, dynamic receita) {
    final isExpanded = _expandedRecipeId == receita.id;
    final temImagem = receita.imagens != null && receita.imagens!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedRecipeId = isExpanded ? null : receita.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: isExpanded ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Imagem de fundo
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: temImagem
                    ? DecorationImage(
                        image: MemoryImage(receita.imagens![0]),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: temImagem ? null : AppColors.cinzaClaro,
              ),
              child: !temImagem
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.cinzaClaro,
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: AppColors.cinza,
                      ),
                    )
                  : null,
            ),
            // Overlay com gradiente
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Conteúdo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isExpanded ? 16 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da receita
                    Text(
                      receita.nome,
                      maxLines: isExpanded ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      // Informações adicionais - exibir tipo de acesso
                      Row(
                        children: [
                          Icon(
                            receita.acesso == AcessoReceita.publica 
                                ? Icons.public 
                                : Icons.lock,
                            color: AppColors.dourado,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            receita.acesso == AcessoReceita.publica ? 'Pública' : 'Privada',
                            style: const TextStyle(
                              color: AppColors.branco,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Botão de detalhes
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/detalhes', arguments: receita.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.vermelho,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Ver receita',
                            style: TextStyle(
                              color: AppColors.branco,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
