import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'database/database_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/receita_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/calendar_provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_usuario_screen.dart';
import 'screens/esqueci_senha_screen.dart';
import 'screens/redefinir_senha_screen.dart';
import 'screens/home_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/detalhes_receita_screen.dart';
import 'screens/cadastro_receita_screen.dart';
import 'screens/editar_receita_screen.dart';
import 'screens/recursos_screen.dart';
import 'services/sync_service.dart';
import 'utils/app_colors.dart';
import 'config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await SyncService.instance.inicializar();
    await authProvider.inicializar();
    await receitaProvider.inicializar();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseKey,
    );
  } catch (e) {
    debugPrint('Erro ao inicializar aplicativo: $e');
  }

  runApp(
    UniReceitasApp(
      authProvider: authProvider,
      receitaProvider: receitaProvider,
    ),
  );
}

class UniReceitasApp extends StatefulWidget {
  final AuthProvider authProvider;
  final ReceitaProvider receitaProvider;

  const UniReceitasApp({
    super.key,
    required this.authProvider,
    required this.receitaProvider,
  });

  @override
  State<UniReceitasApp> createState() => _UniReceitasAppState();
}

class _UniReceitasAppState extends State<UniReceitasApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Escuta o fluxo oficial de recuperação de senha do Supabase.
    // Quando o usuário abre o deep link recebido por e-mail, o SDK
    // emite o evento [AuthChangeEvent.passwordRecovery] com uma sessão
    // temporária que autoriza a troca de senha.
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.passwordRecovery) {
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/redefinir-senha',
              (_) => false,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Falha ao registrar listener de auth do Supabase: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.receitaProvider),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: MaterialApp(
        title: 'UniReceitas',
        navigatorKey: _navigatorKey,
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
          '/redefinir-senha': (context) => const RedefinirSenhaScreen(),
          '/home': (context) => const HomeScreen(),
          '/perfil': (context) => const PerfilScreen(),
          '/detalhes': (context) => const DetalhesReceitaScreen(),
          '/cadastro': (context) => const CadastroReceitaScreen(),
          '/editar': (context) => const EditarReceitaScreen(),
          '/recursos': (context) => const RecursosScreen(),
        },
      ),
    );
  }
}
