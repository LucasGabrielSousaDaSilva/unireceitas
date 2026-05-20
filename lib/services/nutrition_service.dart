import 'package:http/http.dart' as http;
import 'dart:convert';

/// NutritionService - Integra com API de alimentos/nutrição
/// Usa a API pública OpenFoodFacts como principal
class NutritionService {
  static const String _openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v0';
  static const String _usdaUrl = 'https://fdc.nal.usda.gov/api/foods';

  // IMPORTANTE: Configurar sua API key do USDA
  // Obter em: https://fdc.nal.usda.gov/api-key-signup
  static const String _usdaApiKey = 'YOUR_USDA_API_KEY';

  final http.Client _httpClient = http.Client();

  /// Busca informações nutricionais de um alimento
  Future<FoodInfo?> buscarAlimento(String nomeAlimento) async {
    try {
      // Tenta buscar no OpenFoodFacts primeiro
      final resultado = await _buscarOpenFoodFacts(nomeAlimento);
      if (resultado != null) {
        return resultado;
      }

      // Se não encontrar, tenta USDA
      if (_usdaApiKey != 'YOUR_USDA_API_KEY') {
        return await _buscarUSDA(nomeAlimento);
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar alimento: $e');
      return null;
    }
  }

  /// Busca em OpenFoodFacts
  Future<FoodInfo?> _buscarOpenFoodFacts(String nomeAlimento) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
          '$_openFoodFactsUrl/search?q=$nomeAlimento&action=process&json=1',
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);
      final produtos = json['products'] as List?;

      if (produtos == null || produtos.isEmpty) {
        return null;
      }

      // Pega o primeiro resultado
      final produto = produtos.first as Map<String, dynamic>;

      return FoodInfo(
        nome: produto['product_name'] ?? nomeAlimento,
        calorias: (produto['nutriments']?['energy-kcal'] ?? 0).toDouble(),
        proteina: (produto['nutriments']?['proteins'] ?? 0).toDouble(),
        carboidratos: (produto['nutriments']?['carbohydrates'] ?? 0).toDouble(),
        gordura: (produto['nutriments']?['fat'] ?? 0).toDouble(),
        fibra: (produto['nutriments']?['fiber'] ?? 0).toDouble(),
        fonte: 'OpenFoodFacts',
        porcao: '100g',
        marca: produto['brands'] ?? 'Não informada',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar OpenFoodFacts: $e');
      return null;
    }
  }

  /// Busca na API USDA
  Future<FoodInfo?> _buscarUSDA(String nomeAlimento) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(
          '$_usdaUrl/search?query=$nomeAlimento&apiKey=$_usdaApiKey&pageSize=1',
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body);
      final alimentos = json['foods'] as List?;

      if (alimentos == null || alimentos.isEmpty) {
        return null;
      }

      final alimento = alimentos.first as Map<String, dynamic>;
      final nutrientes = alimento['foodNutrients'] as List?;

      // Extrai nutrientes
      double calorias = 0;
      double proteina = 0;
      double carboidratos = 0;
      double gordura = 0;
      double fibra = 0;

      if (nutrientes != null) {
        for (final n in nutrientes) {
          final nutrienteName =
              n['nutrient']?['name']?.toString().toLowerCase() ?? '';
          final valor = (n['value'] ?? 0).toDouble();

          if (nutrienteName.contains('energy')) calorias = valor;
          if (nutrienteName.contains('protein')) proteina = valor;
          if (nutrienteName.contains('carbohydrate')) carboidratos = valor;
          if (nutrienteName.contains('fat') && !nutrienteName.contains('saturated')) {
            gordura = valor;
          }
          if (nutrienteName.contains('fiber')) fibra = valor;
        }
      }

      return FoodInfo(
        nome: alimento['description'] ?? nomeAlimento,
        calorias: calorias,
        proteina: proteina,
        carboidratos: carboidratos,
        gordura: gordura,
        fibra: fibra,
        fonte: 'USDA FoodData Central',
        porcao: '100g',
        marca: alimento['brandName'] ?? 'Não informada',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar USDA: $e');
      return null;
    }
  }

  /// Calcula informação nutricional para quantidade específica
  static FoodInfo? calcularPorQuantidade(
    FoodInfo? info,
    double gramas,
  ) {
    if (info == null) return null;

    final multiplicador = gramas / 100;

    return FoodInfo(
      nome: info.nome,
      calorias: info.calorias * multiplicador,
      proteina: info.proteina * multiplicador,
      carboidratos: info.carboidratos * multiplicador,
      gordura: info.gordura * multiplicador,
      fibra: info.fibra * multiplicador,
      fonte: info.fonte,
      porcao: '${gramas.toStringAsFixed(0)}g',
      marca: info.marca,
    );
  }

  /// Calcula valor calórico total de uma lista de ingredientes
  static double calcularCaloriasTotal(List<FoodInfo> alimentos) {
    return alimentos.fold(0, (sum, item) => sum + item.calorias);
  }

  /// Calcula macronutrientes totais
  static NutrientesTotais calcularMacronutrientesTotais(
    List<FoodInfo> alimentos,
  ) {
    double proteina = 0;
    double carboidratos = 0;
    double gordura = 0;

    for (final alimento in alimentos) {
      proteina += alimento.proteina;
      carboidratos += alimento.carboidratos;
      gordura += alimento.gordura;
    }

    return NutrientesTotais(
      proteina: proteina,
      carboidratos: carboidratos,
      gordura: gordura,
      calorias: calcularCaloriasTotal(alimentos),
    );
  }
}

/// Informações de um alimento
class FoodInfo {
  final String nome;
  final double calorias; // kcal
  final double proteina; // g
  final double carboidratos; // g
  final double gordura; // g
  final double fibra; // g
  final String fonte;
  final String porcao;
  final String marca;

  FoodInfo({
    required this.nome,
    required this.calorias,
    required this.proteina,
    required this.carboidratos,
    required this.gordura,
    required this.fibra,
    required this.fonte,
    required this.porcao,
    required this.marca,
  });

  /// Retorna uma representação formatada
  String obterFormatado() {
    return '''
$nome ($marca)
Porção: $porcao | Fonte: $fonte

Nutrientes (por $porcao):
• Calorias: ${calorias.toStringAsFixed(1)} kcal
• Proteína: ${proteina.toStringAsFixed(1)}g
• Carboidratos: ${carboidratos.toStringAsFixed(1)}g
• Gordura: ${gordura.toStringAsFixed(1)}g
• Fibra: ${fibra.toStringAsFixed(1)}g
''';
  }

  @override
  String toString() => '$nome - ${calorias.toStringAsFixed(1)} kcal';
}

/// Macronutrientes totais
class NutrientesTotais {
  final double proteina;
  final double carboidratos;
  final double gordura;
  final double calorias;

  NutrientesTotais({
    required this.proteina,
    required this.carboidratos,
    required this.gordura,
    required this.calorias,
  });

  /// Calcula percentual de macronutrientes
  Map<String, double> obterPercentuaisCaloricas() {
    final totalCal = (proteina * 4) + (carboidratos * 4) + (gordura * 9);

    return {
      'proteina': ((proteina * 4) / totalCal) * 100,
      'carboidratos': ((carboidratos * 4) / totalCal) * 100,
      'gordura': ((gordura * 9) / totalCal) * 100,
    };
  }

  @override
  String toString() {
    return '''
Total por porção:
• Calorias: ${calorias.toStringAsFixed(1)} kcal
• Proteína: ${proteina.toStringAsFixed(1)}g
• Carboidratos: ${carboidratos.toStringAsFixed(1)}g
• Gordura: ${gordura.toStringAsFixed(1)}g
''';
  }
}
