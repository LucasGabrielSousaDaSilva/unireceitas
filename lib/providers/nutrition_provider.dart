import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';

/// NutritionProvider - Controller de Nutrição
/// Gerencia buscas de informações nutricionais
class NutritionProvider extends ChangeNotifier {
  final NutritionService _nutritionService = NutritionService();

  final Map<String, FoodInfo?> _cache = {}; // Cache de buscas
  bool _carregando = false;
  String? _erro;
  final List<FoodInfo> _alimentosSelecionados = [];

  // ===================== GETTERS =====================

  /// Está carregando?
  bool get carregando => _carregando;

  /// Última mensagem de erro
  String? get erro => _erro;

  /// Tem erro?
  bool get temErro => _erro != null;

  /// Alimentos selecionados
  List<FoodInfo> get alimentosSelecionados =>
      List.unmodifiable(_alimentosSelecionados);

  /// Total de alimentos selecionados
  int get totalAlimentos => _alimentosSelecionados.length;

  // ===================== OPERAÇÕES =====================

  /// Busca informações nutricionais de um alimento
  Future<FoodInfo?> buscarAlimento(String nomeAlimento, {String? quantity}) async {
    // Verifica cache primeiro
    final cacheKey = quantity == null || quantity.isEmpty ? nomeAlimento : '$nomeAlimento|$quantity';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final info = await _nutritionService.buscarAlimento(nomeAlimento, quantity: quantity);

      if (info != null) {
        _cache[cacheKey] = info;
      } else {
        _erro = 'Alimento "${nomeAlimento}" não encontrado';
      }

      notifyListeners();
      return info;
    } on NutritionApiException catch (e) {
      _erro = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _erro = 'Erro ao buscar alimento: $e';
      notifyListeners();
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Adiciona alimento à lista selecionada
  void adicionarAlimento(FoodInfo alimento) {
    _alimentosSelecionados.add(alimento);
    notifyListeners();
  }

  /// Remove alimento da lista selecionada
  void removerAlimento(int index) {
    if (index >= 0 && index < _alimentosSelecionados.length) {
      _alimentosSelecionados.removeAt(index);
      notifyListeners();
    }
  }

  /// Limpa todos os alimentos selecionados
  void limparAlimentos() {
    _alimentosSelecionados.clear();
    notifyListeners();
  }

  /// Calcula macronutrientes totais
  NutrientesTotais? obterTotalNutrientes() {
    if (_alimentosSelecionados.isEmpty) return null;

    return NutritionService.calcularMacronutrientesTotais(
      _alimentosSelecionados,
    );
  }

  /// Calcula calorias totais
  double calcularCaloriasTotal() {
    return NutritionService.calcularCaloriasTotal(_alimentosSelecionados);
  }

  /// Limpa erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  /// Limpa cache
  void limparCache() {
    _cache.clear();
  }

  /// Calcula informação nutricional para quantidade específica
  FoodInfo? calcularPorQuantidade(FoodInfo alimento, double gramas) {
    return NutritionService.calcularPorQuantidade(alimento, gramas);
  }
}
