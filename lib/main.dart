import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_usuario_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'providers/auth_provider.dart';

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
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
