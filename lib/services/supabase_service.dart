import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/usuario.dart';
import '../models/receita.dart';

/// SupabaseService - Gerencia todas as operações com Supabase
class SupabaseService {
  /// Acessa o cliente global do Supabase.
  /// A inicialização real acontece uma única vez em [main] via
  /// `Supabase.initialize(...)`, então qualquer instância de
  /// [SupabaseService] compartilha o mesmo cliente.
  SupabaseClient get _usuario => Supabase.instance.client;

  /// Mantido por compatibilidade com chamadas existentes. A inicialização
  /// efetiva é feita no `main()`; aqui só validamos que o cliente já
  /// está disponível.
  Future<void> inicializar() async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception(
          'Supabase não está configurado. Defina as credenciais em lib/config/supabase_config.dart');
    }
    try {
      // Apenas força o acesso ao cliente para falhar cedo se não inicializado.
      Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase não foi inicializado em main(): $e');
    }
  }

  /// Verifica se está conectado ao Supabase
  bool get isConnected {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

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
        id: user.id,
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

  /// Envia o e-mail oficial de recuperação de senha do Supabase Auth.
  ///
  /// Não revela se o e-mail existe ou não — a própria API do Supabase
  /// é desenhada para evitar enumeração de usuários.
  Future<void> enviarEmailRecuperacaoSenha(String email) async {
    try {
      await _usuario.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordRecoveryRedirect,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao enviar e-mail de recuperação: $e');
    }
  }

  /// Atualiza a senha do usuário autenticado.
  ///
  /// Requer uma sessão ativa — normalmente estabelecida automaticamente
  /// pelo SDK quando o usuário abre o deep link de recuperação.
  Future<void> atualizarSenha(String novaSenha) async {
    try {
      final session = _usuario.auth.currentSession;
      if (session == null) {
        throw Exception(
            'Sessão de recuperação não encontrada. Abra o link enviado por e-mail novamente.');
      }
      await _usuario.auth.updateUser(UserAttributes(password: novaSenha));
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Erro ao redefinir senha: $e');
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

  /// Exclui a conta completa de um usuário:
  /// remove todas as receitas, o registro do usuário e encerra a sessão.
  Future<void> deletarUsuarioCompleto(String usuarioId) async {
    try {
      await _usuario
          .from(SupabaseConfig.receitasTable)
          .delete()
          .eq('proprietario_id', usuarioId);

      await _usuario
          .from(SupabaseConfig.usuariosTable)
          .delete()
          .eq('id', usuarioId);

      try {
        await _usuario.auth.signOut();
      } catch (_) {
        // Sessão pode já estar encerrada; ignora.
      }
    } catch (e) {
      throw Exception('Erro ao excluir conta: $e');
    }
  }

  // ===================== OPERAÇÕES DE RECEITAS =====================

  /// Baixa os bytes das imagens a partir da string CSV de URLs salva
  /// na coluna `imagens` da tabela de receitas. Imagens que falharem ao
  /// baixar são silenciosamente ignoradas — o restante segue.
  Future<List<Uint8List>> _baixarImagens(String? urlsCsv) async {
    if (urlsCsv == null || urlsCsv.trim().isEmpty) return [];
    final urls = urlsCsv
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    final List<Uint8List> bytes = [];
    for (final url in urls) {
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          bytes.add(resp.bodyBytes);
        }
      } catch (_) {
        // Ignora falhas individuais para não bloquear o carregamento.
      }
    }
    return bytes;
  }

  /// Cria uma nova receita
  Future<Receita> criarReceita({
    String? id,
    required String nome,
    required String ingredientes,
    required String modopreparo,
    required String proprietarioId,
    AcessoReceita acesso = AcessoReceita.privada,
    List<Uint8List>? imagens,
  }) async {
    try {
      String imagensUrls = '';
      
      // Upload das imagens para o Storage e geração das URLs
      if (imagens != null && imagens.isNotEmpty) {
        final List<String> urls = [];
        for (var i = 0; i < imagens.length; i++) {
          final imageData = imagens[i];
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '$proprietarioId/$fileName';

          try {
            await _usuario.storage.from('receitas-imagens').uploadBinary(
              filePath,
              imageData,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
            final imageUrl = _usuario.storage.from('receitas-imagens').getPublicUrl(filePath);
            urls.add(imageUrl);
          } catch (e) {
            // ignore: avoid_print
            print('Erro ao subir imagem: $e');
          }
        }
        imagensUrls = urls.join(',');
      }

      final receita = Receita(
        id: id,
        nome: nome,
        imagens: imagens ?? [],
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
        'imagens': imagensUrls,
        'created_at': DateTime.now().toIso8601String(),
      });

      return receita;
    } catch (e) {
      throw Exception('Erro ao criar receita: $e');
    }
  }

  /// Converte com segurança o valor `created_at` vindo do Supabase em DateTime.
  DateTime? _parseCreatedAt(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }

  /// Obtém todas as receitas
  Future<List<Receita>> obterReceitas() async {
    try {
      final response =
          await _usuario.from(SupabaseConfig.receitasTable).select();
      final List<Receita> receitas = [];
      for (final r in (response as List)) {
        final imagens = await _baixarImagens(r['imagens'] as String?);
        receitas.add(Receita(
          id: r['id'] ?? '',
          nome: r['nome'] ?? '',
          ingredientes: r['ingredientes'] ?? '',
          modoPreparo: r['modo_preparo'] ?? '',
          proprietarioId: r['proprietario_id'] ?? '',
          acesso: r['acesso'] == 'publica'
              ? AcessoReceita.publica
              : AcessoReceita.privada,
          imagens: imagens,
          createdAt: _parseCreatedAt(r['created_at']),
        ));
      }
      return receitas;
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
      final List<Receita> receitas = [];
      for (final r in (response as List)) {
        final imagens = await _baixarImagens(r['imagens'] as String?);
        receitas.add(Receita(
          id: r['id'] ?? '',
          nome: r['nome'] ?? '',
          ingredientes: r['ingredientes'] ?? '',
          modoPreparo: r['modo_preparo'] ?? '',
          proprietarioId: r['proprietario_id'] ?? '',
          acesso: r['acesso'] == 'publica'
              ? AcessoReceita.publica
              : AcessoReceita.privada,
          imagens: imagens,
          createdAt: _parseCreatedAt(r['created_at']),
        ));
      }
      return receitas;
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
      final List<Receita> receitas = [];
      for (final r in (response as List)) {
        final imagens = await _baixarImagens(r['imagens'] as String?);
        receitas.add(Receita(
          id: r['id'] ?? '',
          nome: r['nome'] ?? '',
          ingredientes: r['ingredientes'] ?? '',
          modoPreparo: r['modo_preparo'] ?? '',
          proprietarioId: r['proprietario_id'] ?? '',
          acesso: r['acesso'] == 'publica'
              ? AcessoReceita.publica
              : AcessoReceita.privada,
          imagens: imagens,
          createdAt: _parseCreatedAt(r['created_at']),
        ));
      }
      return receitas;
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
    required AcessoReceita acesso,
    required String proprietarioId,
    List<Uint8List>? imagens,
  }) async {
    try {
      String? imagensUrls;
      
      // Upload das imagens para o Storage e geração das URLs se houver imagens
      if (imagens != null && imagens.isNotEmpty) {
        final List<String> urls = [];
        for (var i = 0; i < imagens.length; i++) {
          final imageData = imagens[i];
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '$proprietarioId/$fileName';

          try {
            await _usuario.storage.from('receitas-imagens').uploadBinary(
              filePath,
              imageData,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
            final imageUrl = _usuario.storage.from('receitas-imagens').getPublicUrl(filePath);
            urls.add(imageUrl);
          } catch (e) {
            // ignore: avoid_print
            print('Erro ao subir imagem: $e');
          }
        }
        imagensUrls = urls.join(',');
      }

      final updateData = {
        'nome': nome,
        'ingredientes': ingredientes,
        'modo_preparo': modoPreparo,
        // 'tempo_preparo': tempoPreparacao,
        'acesso': acesso.toString().split('.').last,
      };

      if (imagensUrls != null) {
        updateData['imagens'] = imagensUrls;
      }

      await _usuario
          .from(SupabaseConfig.receitasTable)
          .update(updateData)
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
