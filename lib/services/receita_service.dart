import '../models/receita.dart';
import '../database/database_helper.dart';

/// ReceitaService - Camada de Serviço de Receitas
/// Responsável pela lógica de negócio de gerenciamento de receitas
class ReceitaService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final List<Receita> _receitas = [];

  /// Inicializa o serviço carregando receitas do banco de dados
  Future<void> inicializar() async {
    try {
      final receitas = await _db.getReceitas();
      _receitas.clear();
      _receitas.addAll(receitas);
    } catch (e) {
      throw Exception('Erro ao inicializar ReceitaService: $e');
    }
  }

  /// Obtém todas as receitas
  List<Receita> obterTodas() {
    return List.unmodifiable(_receitas);
  }

  /// Busca uma receita pelo ID
  Receita? buscarPorId(String id) {
    try {
      return _receitas.firstWhere((receita) => receita.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtém receitas do usuário (minhas receitas)
  List<Receita> obterMinhasReceitas(String usuarioId) {
    return _receitas.where((r) => r.proprietarioId == usuarioId).toList();
  }

  /// Obtém receitas públicas/compartilhadas
  List<Receita> obterReceitasCompartilhadas() {
    return _receitas.where((r) => r.acesso == AcessoReceita.publica).toList();
  }

  /// Busca receitas por nome
  List<Receita> buscarPorNome(String termo) {
    if (termo.isEmpty) return [];
    return _receitas
        .where((r) => r.nome.toLowerCase().contains(termo.toLowerCase()))
        .toList();
  }

  /// Busca receitas por ingredientes
  List<Receita> buscarPorIngredientes(List<String> ingredientes) {
    return _receitas.where((r) {
      return ingredientes.any((ingrediente) =>
          r.ingredientes.toLowerCase().contains(ingrediente.toLowerCase()));
    }).toList();
  }

  /// Filtra receitas compartilhadas por nome
  List<Receita> filtrarCompartilhadasPorNome(String termo) {
    final compartilhadas = obterReceitasCompartilhadas();
    if (termo.isEmpty) return compartilhadas;
    return compartilhadas
        .where((r) => r.nome.toLowerCase().contains(termo.toLowerCase()))
        .toList();
  }

  /// Pagina uma lista de receitas
  List<Receita> paginar(
    List<Receita> lista,
    int pagina, {
    int itensPorPagina = 10,
  }) {
    final inicio = pagina * itensPorPagina;
    if (inicio >= lista.length) return [];
    final fim = (inicio + itensPorPagina).clamp(0, lista.length);
    return lista.sublist(inicio, fim);
  }

  /// Adiciona uma nova receita
  Future<Receita> adicionarReceita(Receita receita) async {
    _receitas.add(receita);
    try {
      await _db.insertReceita(receita);
    } catch (e) {
      _receitas.remove(receita);
      throw Exception('Erro ao adicionar receita: $e');
    }
    return receita;
  }

  /// Atualiza uma receita existente
  Future<Receita> atualizarReceita(Receita receitaAtualizada) async {
    final index = _receitas.indexWhere((r) => r.id == receitaAtualizada.id);
    if (index == -1) {
      throw Exception('Receita não encontrada.');
    }

    _receitas[index] = receitaAtualizada;
    try {
      await _db.updateReceita(receitaAtualizada);
    } catch (e) {
      // Reverte a mudança em caso de erro
      _receitas[index] = _receitas[index];
      throw Exception('Erro ao atualizar receita: $e');
    }
    return receitaAtualizada;
  }

  /// Exclui uma receita
  Future<void> excluirReceita(String id) async {
    final index = _receitas.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Receita não encontrada.');
    }

    final receitaRemovida = _receitas.removeAt(index);
    try {
      await _db.deleteReceita(id);
    } catch (e) {
      // Reverte a remoção em caso de erro
      _receitas.insert(index, receitaRemovida);
      throw Exception('Erro ao excluir receita: $e');
    }
  }

  /// Marca uma receita como favorita
  // Future<void> marcarFavorita(String receitaId, bool favorita) async {
  //   final receita = buscarPorId(receitaId);
  //   if (receita == null) {
  //     throw Exception('Receita não encontrada.');
  //   }

  //   receita.favorita = favorita;
  //   try {
  //     await _db.updateReceita(receita);
  //   } catch (e) {
  //     throw Exception('Erro ao marcar receita como favorita: $e');
  //   }
  // }

  /// Obtém receitas favoritas de um usuário
  // List<Receita> obterFavoritas(String usuarioId) {
  //   return _receitas.where((r) => r.favorita && r.proprietarioId == usuarioId).toList();
  // }

  /// Altera o acesso de uma receita
  Future<void> alterarAcesso(String receitaId, AcessoReceita novoAcesso) async {
    final receita = buscarPorId(receitaId);
    if (receita == null) {
      throw Exception('Receita não encontrada.');
    }

    receita.acesso = novoAcesso;
    try {
      await _db.updateReceita(receita);
    } catch (e) {
      throw Exception('Erro ao alterar acesso da receita: $e');
    }
  }
}
