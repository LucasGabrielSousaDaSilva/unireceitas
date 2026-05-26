import '../models/receita.dart';
import '../services/supabase_service.dart';

/// ReceitaService - Camada de Serviço de Receitas
/// Persistência feita exclusivamente no Supabase.
class ReceitaService {
  final SupabaseService _supabase = SupabaseService();
  final List<Receita> _receitas = [];

  /// Inicializa o serviço carregando receitas do Supabase
  Future<void> inicializar() async {
    try {
      final receitas = await _supabase.obterReceitas();
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
    try {
      final nova = await _supabase.criarReceita(
        id: receita.id,
        nome: receita.nome,
        ingredientes: receita.ingredientes,
        modopreparo: receita.modoPreparo,
        proprietarioId: receita.proprietarioId,
        acesso: receita.acesso,
        imagens: receita.imagens,
      );
      _receitas.add(nova);
      return nova;
    } catch (e) {
      throw Exception('Erro ao adicionar receita: $e');
    }
  }

  /// Atualiza uma receita existente
  Future<Receita> atualizarReceita(Receita receitaAtualizada) async {
    final index = _receitas.indexWhere((r) => r.id == receitaAtualizada.id);
    if (index == -1) {
      throw Exception('Receita não encontrada.');
    }

    try {
      await _supabase.atualizarReceita(
        receitaId: receitaAtualizada.id,
        nome: receitaAtualizada.nome,
        ingredientes: receitaAtualizada.ingredientes,
        modoPreparo: receitaAtualizada.modoPreparo,
        acesso: receitaAtualizada.acesso,
        proprietarioId: receitaAtualizada.proprietarioId,
        imagens: receitaAtualizada.imagens,
      );
      _receitas[index] = receitaAtualizada;
      return receitaAtualizada;
    } catch (e) {
      throw Exception('Erro ao atualizar receita: $e');
    }
  }

  /// Exclui uma receita
  Future<void> excluirReceita(String id) async {
    final index = _receitas.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Receita não encontrada.');
    }

    try {
      await _supabase.deletarReceita(id);
      _receitas.removeAt(index);
    } catch (e) {
      throw Exception('Erro ao excluir receita: $e');
    }
  }

  /// Altera o acesso de uma receita
  Future<void> alterarAcesso(String receitaId, AcessoReceita novoAcesso) async {
    final receita = buscarPorId(receitaId);
    if (receita == null) {
      throw Exception('Receita não encontrada.');
    }

    receita.acesso = novoAcesso;
    try {
      await _supabase.atualizarReceita(
        receitaId: receita.id,
        nome: receita.nome,
        ingredientes: receita.ingredientes,
        modoPreparo: receita.modoPreparo,
        acesso: receita.acesso,
        proprietarioId: receita.proprietarioId,
      );
    } catch (e) {
      throw Exception('Erro ao alterar acesso da receita: $e');
    }
  }
}
