import 'package:flutter/material.dart';
import '../models/receita.dart';
import '../database/database_helper.dart';

/// Provider responsável por gerenciar o estado das receitas no aplicativo.
class ReceitaProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Lista privada que armazena todas as receitas cadastradas (cache em memória).
  List<Receita> _receitas = [];

  /// Getter que retorna uma cópia imutável da lista de receitas.
  List<Receita> get receitas => List.unmodifiable(_receitas);

  /// Carrega todas as receitas do banco de dados para o cache em memória.
  Future<void> carregarReceitas() async {
    _receitas = await _db.getReceitas();
    notifyListeners();
  }

  /// Busca uma receita pelo seu identificador único.
  Receita? buscarPorId(String id) {
    try {
      return _receitas.firstWhere((receita) => receita.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Retorna as receitas do usuário (minhas receitas).
  /// Inclui todas as receitas que pertencem ao usuário (privadas e públicas).
  List<Receita> minhasReceitas(String usuarioId) {
    return _receitas.where((r) => r.proprietarioId == usuarioId).toList();
  }

  /// Retorna as receitas compartilhadas (públicas de todos os usuários).
  List<Receita> receitasCompartilhadas() {
    return _receitas.where((r) => r.acesso == AcessoReceita.publica).toList();
  }

  /// Retorna receitas compartilhadas filtradas por nome (busca).
  List<Receita> buscarCompartilhadas(String termo) {
    if (termo.isEmpty) return receitasCompartilhadas();
    return receitasCompartilhadas()
        .where((r) => r.nome.toLowerCase().contains(termo.toLowerCase()))
        .toList();
  }

  /// Retorna uma página de receitas a partir de uma lista.
  /// [pagina] começa em 0. [itensPorPagina] padrão é 10.
  List<Receita> paginar(List<Receita> lista, int pagina, {int itensPorPagina = 10}) {
    final inicio = pagina * itensPorPagina;
    if (inicio >= lista.length) return [];
    final fim = (inicio + itensPorPagina).clamp(0, lista.length);
    return lista.sublist(inicio, fim);
  }

  /// Adiciona uma nova receita à lista e persiste no banco de dados.
  Future<void> adicionarReceita(Receita receita) async {
    _receitas.add(receita);
    notifyListeners();
    try {
      await _db.insertReceita(receita);
    } catch (_) {}
  }

  /// Atualiza uma receita existente na lista e persiste no banco de dados.
  Future<void> editarReceita(Receita receitaAtualizada) async {
    final index = _receitas.indexWhere((r) => r.id == receitaAtualizada.id);
    if (index != -1) {
      _receitas[index] = receitaAtualizada;
      notifyListeners();
      try {
        await _db.updateReceita(receitaAtualizada);
      } catch (_) {}
    }
  }

  /// Remove uma receita da lista pelo seu [id] e deleta do banco de dados.
  Future<void> excluirReceita(String id) async {
    _receitas.removeWhere((receita) => receita.id == id);
    notifyListeners();
    try {
      await _db.deleteReceita(id);
    } catch (_) {}
  }
}
