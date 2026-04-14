// Teste básico para verificar que o aplicativo UniReceitas abre sem erros.
import 'package:flutter_test/flutter_test.dart';
import 'package:unireceitas/main.dart';
import 'package:unireceitas/providers/auth_provider.dart';
import 'package:unireceitas/providers/receita_provider.dart';

void main() {
  testWidgets('App abre sem erros', (WidgetTester tester) async {
    // Constrói o app e renderiza um frame
    await tester.pumpWidget(UniReceitasApp(authProvider: AuthProvider(), receitaProvider: ReceitaProvider()));

    // Verifica que a tela home é exibida com o título correto
    expect(find.text('UniReceitas'), findsOneWidget);

    // Verifica que o botão de nova receita está presente
    expect(find.text('Nova Receita'), findsOneWidget);
  });
}
