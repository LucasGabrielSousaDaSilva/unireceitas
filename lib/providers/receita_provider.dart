import 'package:flutter/material.dart';
import '../models/receita.dart';
import '../services/receita_service.dart';

/// ReceitaProvider (Controller) - Gerencia o estado de receitas
/// Usa ReceitaService para lógica de negócio
class ReceitaProvider extends ChangeNotifier {
  final ReceitaService _receitaService = ReceitaService();

  /// Inicializa o provider
  Future<void> inicializar() async {
    try {
      await _receitaService.inicializar();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao inicializar ReceitaProvider: $e');
    }
  }

  /// Getter que retorna uma cópia imutável da lista de receitas
  List<Receita> get receitas => _receitaService.obterTodas();

  /// Busca uma receita pelo seu identificador único
  Receita? buscarPorId(String id) {
    return _receitaService.buscarPorId(id);
  }

  /// Retorna as receitas do usuário (minhas receitas)
  List<Receita> minhasReceitas(String usuarioId) {
    return _receitaService.obterMinhasReceitas(usuarioId);
  }

  /// Retorna as receitas compartilhadas (públicas de todos os usuários)
  List<Receita> receitasCompartilhadas() {
    return _receitaService.obterReceitasCompartilhadas();
  }

  /// Retorna receitas compartilhadas filtradas por nome (busca)
  List<Receita> buscarCompartilhadas(String termo) {
    return _receitaService.filtrarCompartilhadasPorNome(termo);
  }

  /// Busca receitas por ingredientes
  List<Receita> buscarPorIngredientes(List<String> ingredientes) {
    return _receitaService.buscarPorIngredientes(ingredientes);
  }

  /// Retorna uma página de receitas a partir de uma lista
  List<Receita> paginar(List<Receita> lista, int pagina, {int itensPorPagina = 10}) {
    return _receitaService.paginar(lista, pagina, itensPorPagina: itensPorPagina);
  }

  /// Adiciona uma nova receita à lista e persiste no banco de dados
  Future<String?> adicionarReceita(Receita receita) async {
    try {
      await _receitaService.adicionarReceita(receita);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Atualiza uma receita existente na lista e persiste no banco de dados
  Future<String?> editarReceita(Receita receitaAtualizada) async {
    try {
      await _receitaService.atualizarReceita(receitaAtualizada);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Remove uma receita da lista pelo seu [id] e deleta do banco de dados
  Future<String?> excluirReceita(String id) async {
    try {
      await _receitaService.excluirReceita(id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Marca uma receita como favorita
  // Future<String?> marcarFavorita(String receitaId, bool favorita) async {
  //   try {
  //     await _receitaService.marcarFavorita(receitaId, favorita);
  //     notifyListeners();
  //     return null;
  //   } catch (e) {
  //     return e.toString().replaceAll('Exception: ', '');
  //   }
  // }

  /// Obtém receitas favoritas de um usuário
  // List<Receita> obterFavoritas(String usuarioId) {
  //   return _receitaService.obterFavoritas(usuarioId);
  // }

  /// Altera o acesso de uma receita
  Future<String?> alterarAcesso(String receitaId, AcessoReceita novoAcesso) async {
    try {
      await _receitaService.alterarAcesso(receitaId, novoAcesso);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Carrega todas as receitas do banco de dados
  Future<void> carregarReceitas() async {
    try {
      await _receitaService.inicializar();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar receitas: $e');
    }
  }
}
