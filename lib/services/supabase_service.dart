import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/usuario.dart';
import '../models/receita.dart';

/// SupabaseService - Gerencia todas as operações com Supabase
class SupabaseService {
  late final SupabaseClient _usuario;
  bool _isInitialized = false;

  /// Inicializa a conexão com Supabase
  Future<void> inicializar() async {
    if (_isInitialized) return;

    if (!SupabaseConfig.isConfigured) {
      throw Exception(
          'Supabase não está configurado. Defina as credenciais em lib/config/supabase_config.dart');
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseKey,
      );
      _usuario = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      throw Exception('Erro ao inicializar Supabase: $e');
    }
  }

  /// Verifica se está conectado ao Supabase
  bool get isConnected => _isInitialized;

  // ===================== OPERAÇÕES DE USUÁRIOS =====================

  /// Cria um novo usuário no Supabase
  Future<Usuario> criarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _usuario.auth.signUp(email: email, password: senha);
      final user = response.user;

      if (user == null) {
        throw Exception('Erro ao criar usuário de autenticação');
      }

      // Insere dados adicionais na tabela usuarios
      final usuario = Usuario(
        nome: nome,
        email: email,
        senha: senha,
      );

      await _usuario.from(SupabaseConfig.usuariosTable).insert({
        'id': user.id,
        'nome': nome,
        'email': email,
        'senha': senha,
        'created_at': DateTime.now().toIso8601String(),
      });

      return usuario;
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  /// Autentica um usuário
  Future<User?> autenticar({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _usuario.auth
          .signInWithPassword(email: email, password: senha);
      return response.user;
    } catch (e) {
      throw Exception('Erro ao autenticar usuário: $e');
    }
  }

  /// Obtém todos os usuários
  Future<List<Usuario>> obterUsuarios() async {
    try {
      final response =
          await _usuario.from(SupabaseConfig.usuariosTable).select();
      return (response as List)
          .map((u) => Usuario(
                id: u['id'] ?? '',
                nome: u['nome'] ?? '',
                email: u['email'] ?? '',
                senha: u['senha'] ?? '',
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao obter usuários: $e');
    }
  }

  /// Busca um usuário pelo email
  Future<Usuario?> buscarUsuarioPorEmail(String email) async {
    try {
      final response = await _usuario
          .from(SupabaseConfig.usuariosTable)
          .select()
          .eq('email', email);
      if ((response as List).isEmpty) return null;
      final u = response.first;
      return Usuario(
        id: u['id'] ?? '',
        nome: u['nome'] ?? '',
        email: u['email'] ?? '',
        senha: u['senha'] ?? '',
      );
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  /// Atualiza dados de um usuário
  Future<void> atualizarUsuario({
    required String usuarioId,
    required String nome,
    required String email,
  }) async {
    try {
      await _usuario
          .from(SupabaseConfig.usuariosTable)
          .update({'nome': nome, 'email': email}).eq('id', usuarioId);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  /// Faz logout do usuário
  Future<void> logout() async {
    try {
      await _usuario.auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  // ===================== OPERAÇÕES DE RECEITAS =====================

  /// Cria uma nova receita
  Future<Receita> criarReceita({
    String? id,
    required String nome,
    required String ingredientes,
    required String modopreparo,
    required String proprietarioId,
    AcessoReceita acesso = AcessoReceita.privada,
  }) async {
    try {
      final receita = Receita(
        id: id,
        nome: nome,
        ingredientes: ingredientes,
        modoPreparo: modopreparo,
        proprietarioId: proprietarioId,
        acesso: acesso,
      );

      await _usuario.from(SupabaseConfig.receitasTable).insert({
        'id': receita.id,
        'nome': nome,
        'ingredientes': ingredientes,
        'modo_preparo': modopreparo,
        'proprietario_id': proprietarioId,
        'acesso': acesso.toString().split('.').last,
        'favorita': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return receita;
    } catch (e) {
      throw Exception('Erro ao criar receita: $e');
    }
  }

  /// Obtém todas as receitas
  Future<List<Receita>> obterReceitas() async {
    try {
      final response =
          await _usuario.from(SupabaseConfig.receitasTable).select();
      return (response as List)
          .map((r) => Receita(
                id: r['id'] ?? '',
                nome: r['nome'] ?? '',
                ingredientes: r['ingredientes'] ?? '',
                modoPreparo: r['modo_preparo'] ?? '',
                proprietarioId: r['proprietario_id'] ?? '',
                acesso: r['acesso'] == 'publica'
                    ? AcessoReceita.publica
                    : AcessoReceita.privada,
                // favorita: r['favorita'] ?? false,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao obter receitas: $e');
    }
  }

  /// Busca receitas de um usuário
  Future<List<Receita>> buscarReceitasDoUsuario(String usuarioId) async {
    try {
      final response = await _usuario
          .from(SupabaseConfig.receitasTable)
          .select()
          .eq('proprietario_id', usuarioId);
      return (response as List)
          .map((r) => Receita(
                id: r['id'] ?? '',
                nome: r['nome'] ?? '',
                ingredientes: r['ingredientes'] ?? '',
                modoPreparo: r['modo_preparo'] ?? '',
                // tempoPreparacao: r['tempo_preparo'] ?? '',
                proprietarioId: r['proprietario_id'] ?? '',
                acesso: r['acesso'] == 'publica'
                    ? AcessoReceita.publica
                    : AcessoReceita.privada,
                // favorita: r['favorita'] ?? false,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar receitas do usuário: $e');
    }
  }

  /// Busca receitas públicas
  Future<List<Receita>> buscarReceitasPublicas() async {
    try {
      final response = await _usuario
          .from(SupabaseConfig.receitasTable)
          .select()
          .eq('acesso', 'publica');
      return (response as List)
          .map((r) => Receita(
                id: r['id'] ?? '',
                nome: r['nome'] ?? '',
                ingredientes: r['ingredientes'] ?? '',
                modoPreparo: r['modo_preparo'] ?? '',
                // tempoPreparacao: r['tempo_preparo'] ?? '',
                proprietarioId: r['proprietario_id'] ?? '',
                acesso: r['acesso'] == 'publica'
                    ? AcessoReceita.publica
                    : AcessoReceita.privada,
                // favorita: r['favorita'] ?? false,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar receitas públicas: $e');
    }
  }

  /// Atualiza uma receita
  Future<void> atualizarReceita({
    required String receitaId,
    required String nome,
    required String ingredientes,
    required String modoPreparo,
    // required String tempoPreparacao,
    required AcessoReceita acesso, required String modopreparo,
  }) async {
    try {
      await _usuario
          .from(SupabaseConfig.receitasTable)
          .update({
            'nome': nome,
            'ingredientes': ingredientes,
            'modo_preparo': modoPreparo,
            // 'tempo_preparo': tempoPreparacao,
            'acesso': acesso.toString().split('.').last,
          })
          .eq('id', receitaId);
    } catch (e) {
      throw Exception('Erro ao atualizar receita: $e');
    }
  }

  /// Deleta uma receita
  Future<void> deletarReceita(String receitaId) async {
    try {
      await _usuario
          .from(SupabaseConfig.receitasTable)
          .delete()
          .eq('id', receitaId);
    } catch (e) {
      throw Exception('Erro ao deletar receita: $e');
    }
  }

  /// Marca/desmarca uma receita como favorita
  Future<void> marcarFavorita(String receitaId, bool favorita) async {
    try {
      await _usuario
          .from(SupabaseConfig.receitasTable)
          .update({'favorita': favorita}).eq('id', receitaId);
    } catch (e) {
      throw Exception('Erro ao marcar receita como favorita: $e');
    }
  }
}
