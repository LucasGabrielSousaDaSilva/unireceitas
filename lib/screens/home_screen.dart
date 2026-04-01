import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();

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
    );
  }

  /// Botão de cadastrar nova receita
  // Widget _buildBotaoCadastrar(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: SizedBox(
  //       width: double.infinity,
  //       height: 50,
  //       child: ElevatedButton.icon(
  //         onPressed: () {
  //           Navigator.pushNamed(context, '/cadastro');
  //         },
  //         icon: const Icon(Icons.add, color: AppColors.branco),
  //         label: const Text(
  //           'Nova Receita',
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: AppColors.branco,
  //           ),
  //         ),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: AppColors.vermelho,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// Widget para lista vazia
//   Widget _buildListaVazia(String titulo, String subtitulo) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.menu_book,
//             size: 80,
//             color: AppColors.dourado.withValues(alpha: 0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             titulo,
//             style: const TextStyle(fontSize: 18, color: AppColors.cinza),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitulo,
//             style: const TextStyle(fontSize: 14, color: AppColors.cinza),
//           ),
//         ],
//       ),
//     );
//   }
}
