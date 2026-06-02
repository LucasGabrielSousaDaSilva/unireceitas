import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// NutritionService - Integra com API de alimentos/nutrição
/// Usa a API Ninjas Nutrition
class NutritionService {
  final http.Client _httpClient = http.Client();

  /// Busca informações nutricionais de um alimento
  Future<FoodInfo?> buscarAlimento(String nomeAlimento, {String? quantity}) async {
    try {
      // Apenas avisa se a chave estiver vazia ou ainda estiver no valor de exemplo
      if (ApiConfig.apiNinjasKey.trim().isEmpty || ApiConfig.apiNinjasKey.contains('YOUR')) {
        // ignore: avoid_print
        print('AVISO: Chave da API Ninjas não configurada em lib/config/api_config.dart. Defina ApiConfig.apiNinjasKey.');
      }

      // API Ninjas lida bem com espaços se estiver codificado na URL
      final query = Uri.encodeComponent(nomeAlimento);
      final response = await _httpClient.get(
        Uri.parse('${ApiConfig.apiNinjasBaseUrl}/nutrition?query=$query'),
        headers: {
          'X-Api-Key': ApiConfig.apiNinjasKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('Erro na API Ninjas: ${response.statusCode} - ${response.body}');
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(response.body);

      if (jsonList.isEmpty) {
        return null;
      }

      // Soma os valores caso a busca contenha vários itens (ex: "arroz e feijão")
      double calorias = 0;
      double proteina = 0;
      double carboidratos = 0;
      double gordura = 0;
      double fibra = 0;
      
      double gorduraSaturada = 0;
      double sodio = 0;
      double potassio = 0;
      double colesterol = 0;
      double acucar = 0;
      double tamanhoServindo = 0;
      
      List<String> nomes = [];

      // Conversão segura para evitar FormatException quando a API
      // retorna strings como "Only available for premium subscribers.".
      double _toDoubleSafe(dynamic v) {
        if (v == null) return 0.0;
        if (v is num) return v.toDouble();
        if (v is String) {
          // tenta converter strings numéricas (ex: "123.4" ou "123,4")
          final sanitized = v.replaceAll(',', '.');
          final parsed = double.tryParse(sanitized);
          if (parsed != null) return parsed;
          // se for texto (mensagem premium), ignora e retorna 0.0
          return 0.0;
        }
        return 0.0;
      }

      for (var item in jsonList) {
        nomes.add(item['name'] ?? '');
        calorias += _toDoubleSafe(item['calories']);
        proteina += _toDoubleSafe(item['protein_g']);
        carboidratos += _toDoubleSafe(item['carbohydrates_total_g']);
        gordura += _toDoubleSafe(item['fat_total_g']);
        fibra += _toDoubleSafe(item['fiber_g']);

        gorduraSaturada += _toDoubleSafe(item['fat_saturated_g']);
        sodio += _toDoubleSafe(item['sodium_mg']);
        potassio += _toDoubleSafe(item['potassium_mg']);
        colesterol += _toDoubleSafe(item['cholesterol_mg']);
        acucar += _toDoubleSafe(item['sugar_g']);
        tamanhoServindo += _toDoubleSafe(item['serving_size_g']);
      }

      String nomeFinal = nomes.where((n) => n.isNotEmpty).join(', ');
      if (nomeFinal.isEmpty) {
         nomeFinal = nomeAlimento;
      }

      // Capitalizar primeira letra
      if (nomeFinal.isNotEmpty) {
        nomeFinal = nomeFinal[0].toUpperCase() + nomeFinal.substring(1);
      }

      return FoodInfo(
        nome: nomeFinal,
        calorias: calorias,
        proteina: proteina,
        carboidratos: carboidratos,
        gordura: gordura,
        fibra: fibra,
        gorduraSaturada: gorduraSaturada,
        sodio: sodio,
        potassio: potassio,
        colesterol: colesterol,
        acucar: acucar,
        tamanhoServindo: tamanhoServindo > 0 ? tamanhoServindo : 100.0,
        fonte: 'API Ninjas',
        porcao: '${tamanhoServindo > 0 ? tamanhoServindo.toStringAsFixed(1) : 100}g',
        marca: 'Genérico',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao buscar alimento: $e');
      return null;
    }
  }

  /// Calcula informação nutricional para quantidade específica
  static FoodInfo? calcularPorQuantidade(
    FoodInfo? info,
    double gramas,
  ) {
    if (info == null) return null;

    final baseServindo = info.tamanhoServindo > 0 ? info.tamanhoServindo : 100.0;
    final multiplicador = gramas / baseServindo;

    return FoodInfo(
      nome: info.nome,
      calorias: info.calorias * multiplicador,
      proteina: info.proteina * multiplicador,
      carboidratos: info.carboidratos * multiplicador,
      gordura: info.gordura * multiplicador,
      fibra: info.fibra * multiplicador,
      gorduraSaturada: info.gorduraSaturada * multiplicador,
      sodio: info.sodio * multiplicador,
      potassio: info.potassio * multiplicador,
      colesterol: info.colesterol * multiplicador,
      acucar: info.acucar * multiplicador,
      tamanhoServindo: gramas,
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
    double calorias = 0;

    for (final alimento in alimentos) {
      proteina += alimento.proteina;
      carboidratos += alimento.carboidratos;
      gordura += alimento.gordura;
      calorias += alimento.calorias;
    }

    return NutrientesTotais(
      proteina: proteina,
      carboidratos: carboidratos,
      gordura: gordura,
      calorias: calorias,
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
  final double gorduraSaturada; // g
  final double sodio; // mg
  final double potassio; // mg
  final double colesterol; // mg
  final double acucar; // g
  final double tamanhoServindo; // g
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
    required this.gorduraSaturada,
    required this.sodio,
    required this.potassio,
    required this.colesterol,
    required this.acucar,
    required this.tamanhoServindo,
    required this.fonte,
    required this.porcao,
    required this.marca,
  });

  /// Retorna uma representação formatada em texto
  String obterFormatado() {
    return '''
$nome ($marca)
Porção: $porcao | Fonte: $fonte

Nutrientes (por $porcao):
• Calorias: ${calorias.toStringAsFixed(1)} kcal
• Proteína: ${proteina.toStringAsFixed(1)}g
• Carboidratos: ${carboidratos.toStringAsFixed(1)}g
• Açúcar: ${acucar.toStringAsFixed(1)}g
• Gorduras Totais: ${gordura.toStringAsFixed(1)}g
• Gorduras Saturadas: ${gorduraSaturada.toStringAsFixed(1)}g
• Fibra: ${fibra.toStringAsFixed(1)}g
• Sódio: ${sodio.toStringAsFixed(1)}mg
• Potássio: ${potassio.toStringAsFixed(1)}mg
• Colesterol: ${colesterol.toStringAsFixed(1)}mg
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

    if (totalCal <= 0) {
      return {
        'proteina': 0,
        'carboidratos': 0,
        'gordura': 0,
      };
    }

    return {
      'proteina': ((proteina * 4) / totalCal) * 100,
      'carboidratos': ((carboidratos * 4) / totalCal) * 100,
      'gordura': ((gordura * 9) / totalCal) * 100,
    };
  }

  @override
  String toString() {
    return '''
Total:
• Calorias: ${calorias.toStringAsFixed(1)} kcal
• Proteína: ${proteina.toStringAsFixed(1)}g
• Carboidratos: ${carboidratos.toStringAsFixed(1)}g
• Gordura: ${gordura.toStringAsFixed(1)}g
''';
  }
}

/// Exceção específica para erros retornados pela API Ninjas
class NutritionApiException implements Exception {
  final String message;
  NutritionApiException([this.message = 'Erro na API de nutrição']);

  @override
  String toString() => 'NutritionApiException: $message';
}
