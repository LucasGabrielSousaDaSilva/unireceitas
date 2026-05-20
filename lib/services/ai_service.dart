import 'package:google_generative_ai/google_generative_ai.dart';

/// AIService - Serviço de sugestão de receitas com IA
class AIService {
  late GenerativeModel _model;
  bool _isInitialized = false;

  // IMPORTANTE: Configure sua chave de API
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  /// Inicializa o serviço de IA
  Future<void> inicializar() async {
    if (_isInitialized) return;

    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception(
        'API Key do Google Generative AI não configurada. '
        'Configure em lib/services/ai_service.dart',
      );
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Erro ao inicializar IA: $e');
    }
  }

  /// Verifica se está inicializado
  bool get isInitialized => _isInitialized;

  /// Sugere receitas baseado em ingredientes
  Future<String> sugerirReceitas(List<String> ingredientes) async {
    if (!_isInitialized) {
      throw Exception('Serviço de IA não foi inicializado');
    }

    if (ingredientes.isEmpty) {
      throw Exception('Forneça pelo menos um ingrediente');
    }

    try {
      final prompt = _construirPromptReceita(ingredientes);

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Nenhuma sugestão de receita encontrada');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Erro ao sugerir receitas: $e');
    }
  }

  /// Obtém informações nutricionais
  Future<String> obterInfoNutricional(String receita) async {
    if (!_isInitialized) {
      throw Exception('Serviço de IA não foi inicializado');
    }

    try {
      final prompt = '''
Analise a seguinte receita e forneça informações nutricionais estimadas:

$receita

Por favor, forneça:
- Calorias aproximadas (por porção)
- Proteínas (g)
- Carboidratos (g)
- Gorduras (g)
- Fibras (g)
- Vitaminas e minerais principais
- Dicas de saúde
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Não foi possível obter informações nutricionais');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Erro ao obter informações nutricionais: $e');
    }
  }

  /// Gera substituições de ingredientes
  Future<String> gerarSubstituicoes(String ingrediente) async {
    if (!_isInitialized) {
      throw Exception('Serviço de IA não foi inicializado');
    }

    try {
      final prompt = '''
Forneça sugestões de ingredientes substitutos para "$ingrediente" em receitas.

Para cada substituto, forneça:
- Nome do ingrediente
- Razão pela qual funciona como substituto
- Como usar (quantidade/proporção)
- Melhores usos (tipos de receitas)

Mantenha a resposta concisa e prática.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Não foi possível gerar substituições');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Erro ao gerar substituições: $e');
    }
  }

  /// Propõe variações de receita
  Future<String> sugerirVariacoes(String receita) async {
    if (!_isInitialized) {
      throw Exception('Serviço de IA não foi inicializado');
    }

    try {
      final prompt = '''
Baseado na seguinte receita, sugira 3 variações criativas:

$receita

Para cada variação, forneça:
- Nome da variação
- Modificações nos ingredientes
- Alterações no modo de preparo
- Tempo de preparo
- Dificuldade

Seja criativo e mantenha a essência da receita original.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Não foi possível sugerir variações');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Erro ao sugerir variações: $e');
    }
  }

  /// Oferece dicas de cozinha
  Future<String> obterDicasCozinha(String temaOuTecnica) async {
    if (!_isInitialized) {
      throw Exception('Serviço de IA não foi inicializado');
    }

    try {
      final prompt = '''
Forneça dicas práticas de cozinha sobre: $temaOuTecnica

Inclua:
- 3-5 dicas principais
- Ingredientes ou ferramentas necessárias
- Tempo estimado
- Nível de dificuldade
- Possíveis erros comuns e como evitá-los

Mantenha um tom amigável e prático.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Não foi possível obter dicas');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Erro ao obter dicas: $e');
    }
  }

  /// Constrói o prompt para sugestão de receita
  String _construirPromptReceita(List<String> ingredientes) {
    final ingredientesStr = ingredientes.join(', ');

    return '''
Você é um chef profissional e assistente de culinária. 
Baseado nos seguintes ingredientes que possuo em casa, sugira uma receita rápida e deliciosa.

Ingredientes disponíveis: $ingredientesStr

Por favor, forneça:
1. Nome da Receita
2. Tempo de preparo (em minutos)
3. Dificuldade (Fácil/Média/Difícil)
4. Ingredientes completos (incluindo temperos básicos como sal, óleo)
5. Modo de Preparo (passo a passo)
6. Dicas para melhorar o resultado
7. Sugestões de acompanhamentos

Priorize receitas que usem a maioria dos ingredientes fornecidos.
Mantenha a resposta prática e fácil de seguir.
''';
  }

  /// Cancela requisições pendentes (se houver suporte)
  Future<void> cancelar() async {
    // Implementar se necessário
  }
}
