import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/receita_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_usuario_screen.dart';
import 'screens/esqueci_senha_screen.dart';
import 'screens/home_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/detalhes_receita_screen.dart';
import 'screens/cadastro_receita_screen.dart';
import 'screens/editar_receita_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o SQLite para cada plataforma
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final authProvider = AuthProvider();
  final receitaProvider = ReceitaProvider();

  try {
    await DatabaseHelper.instance.database;
    await authProvider.carregarUsuarios();
    await receitaProvider.carregarReceitas();
  } catch (e) {
    debugPrint('Erro ao inicializar banco de dados: $e');
  }

  runApp(UniReceitasApp(authProvider: authProvider, receitaProvider: receitaProvider));
}

class UniReceitasApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ReceitaProvider receitaProvider;

  const UniReceitasApp({super.key, required this.authProvider, required this.receitaProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: receitaProvider),
      ],
      child: MaterialApp(
        title: 'UniReceitas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.vermelho,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.vermelho,
            primary: AppColors.vermelho,
            secondary: AppColors.dourado,
            surface: AppColors.branco,
          ),
          scaffoldBackgroundColor: AppColors.branco,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.preto,
            foregroundColor: AppColors.branco,
            elevation: 2,
            centerTitle: true,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/cadastro-usuario': (context) => const CadastroUsuarioScreen(),
          '/esqueci-senha': (context) => const EsqueciSenhaScreen(),
          '/home': (context) => const HomeScreen(),
          '/perfil': (context) => const PerfilScreen(),
          '/detalhes': (context) => const DetalhesReceitaScreen(),
          '/cadastro': (context) => const CadastroReceitaScreen(),
          '/editar': (context) => const EditarReceitaScreen(),
        },
      ),
    );
  }
}
