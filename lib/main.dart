import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

void main() {
  runApp(const UniReceitasApp());
}

class UniReceitasApp extends StatelessWidget {
  const UniReceitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReceitaProvider()),
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
