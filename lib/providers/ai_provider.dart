import 'package:flutter/material.dart';
import '../services/ai_service.dart';

/// AIProvider - Controller de IA
/// Gerencia sugestões de receitas com IA
class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  String? _ultimaSugestao;
  bool _carregando = false;
  String? _erro;

  // ===================== GETTERS =====================

  /// Última sugestão de receita
  String? get ultimaSugestao => _ultimaSugestao;

  /// Está carregando?
  bool get carregando => _carregando;

  /// Última mensagem de erro
  String? get erro => _erro;

  /// Tem erro?
  bool get temErro => _erro != null;

  // ===================== INICIALIZAÇÃO =====================

  /// Inicializa o provider
  Future<void> inicializar() async {
    try {
      await _aiService.inicializar();
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    }
  }

  /// Verifica se IA está disponível
  bool get iaDisponivel => _aiService.isInitialized;

  // ===================== OPERAÇÕES =====================

  /// Sugere receitas baseado em ingredientes
  Future<void> sugerirReceitas(List<String> ingredientes) async {
    if (ingredientes.isEmpty) {
      _erro = 'Forneça pelo menos um ingrediente';
      notifyListeners();
      return;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _ultimaSugestao = await _aiService.sugerirReceitas(ingredientes);
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Obtém informações nutricionais
  Future<String?> obterInfoNutricional(String receita) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final info = await _aiService.obterInfoNutricional(receita);
      notifyListeners();
      return info;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Gera substituições de ingredientes
  Future<String?> gerarSubstituicoes(String ingrediente) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final substituicoes = await _aiService.gerarSubstituicoes(ingrediente);
      notifyListeners();
      return substituicoes;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Sugere variações de receita
  Future<String?> sugerirVariacoes(String receita) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final variacoes = await _aiService.sugerirVariacoes(receita);
      notifyListeners();
      return variacoes;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Obtém dicas de cozinha
  Future<String?> obterDicasCozinha(String tema) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final dicas = await _aiService.obterDicasCozinha(tema);
      notifyListeners();
      return dicas;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return null;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Limpa a última sugestão
  void limparSugestao() {
    _ultimaSugestao = null;
    notifyListeners();
  }

  /// Limpa erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
