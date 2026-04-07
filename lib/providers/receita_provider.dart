import 'package:flutter/material.dart';
import '../models/receita.dart';

class ReceitaProvider extends ChangeNotifier {
  /// Lista privada que armazena todas as receitas cadastradas.
  final List<Receita> _receitas = [];

  /// Getter que retorna uma cópia imutável da lista de receitas.
  List<Receita> get receitas => List.unmodifiable(_receitas);

  Receita? buscarPorId(String id) {
    try {
      return _receitas.firstWhere((receita) => receita.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Receita> minhasReceitas(String usuarioId) {
    return _receitas.where((r) => r.proprietarioId == usuarioId).toList();
  }

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

  List<Receita> paginar(List<Receita> lista, int pagina, {int itensPorPagina = 10}) {
    final inicio = pagina * itensPorPagina;
    if (inicio >= lista.length) return [];
    final fim = (inicio + itensPorPagina).clamp(0, lista.length);
    return lista.sublist(inicio, fim);
  }

  void adicionarReceita(Receita receita) {
    _receitas.add(receita);
    notifyListeners();
  }

  void editarReceita(Receita receitaAtualizada) {
    final index = _receitas.indexWhere((r) => r.id == receitaAtualizada.id);
    if (index != -1) {
      _receitas[index] = receitaAtualizada;
      notifyListeners();
    }
  }

  void excluirReceita(String id) {
    _receitas.removeWhere((receita) => receita.id == id);
    notifyListeners();
  }
}
