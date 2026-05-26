import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/usuario.dart';
import '../models/receita.dart';
import '../database/database_helper.dart';
import '../services/supabase_service.dart';

/// SyncService - Gerencia sincronização entre SQLite e Supabase
/// Implementa padrão Offline-First com sincronização automática
class SyncService {
  // Padrão Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static SyncService get instance => _instance;

  final DatabaseHelper _localDb = DatabaseHelper.instance;
  final SupabaseService _remoteDb = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = false;
  bool _isSyncing = false;

  /// Inicializa o serviço de sincronização
  Future<void> inicializar() async {
    try {
      // Inicializa Supabase (se configurado)
      try {
        await _remoteDb.inicializar();
      } catch (e) {
        // ignore: avoid_print
        print('Supabase não disponível: $e');
      }

      // Monitora conectividade
      _connectivity.onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
        if (_isOnline && !_isSyncing) {
          _sincronizar();
        }
      });

      // Verifica conectividade inicial
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      throw Exception('Erro ao inicializar SyncService: $e');
    }
  }

  /// Verifica se está online
  bool get isOnline => _isOnline;

  /// Verifica se Supabase está disponível
  bool get supabaseDisponivel => _remoteDb.isConnected;

  /// Sincroniza dados entre local e remoto
  Future<void> _sincronizar() async {
    if (_isSyncing || !_isOnline || !supabaseDisponivel) return;

    _isSyncing = true;
    try {
      // Sincroniza usuários
      await _sincronizarUsuarios();
      // Sincroniza receitas
      await _sincronizarReceitas();
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao sincronizar: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Valida formato de email (evita enviar emails inválidos para o Supabase Auth)
  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-\.]+$');
    return email.isNotEmpty && regex.hasMatch(email);
  }

  /// Sincroniza usuários (bidirecional)
  Future<void> _sincronizarUsuarios() async {
    try {
      final usuariosLocais = await _localDb.getUsuarios();
      final usuariosRemoto = await _remoteDb.obterUsuarios();

      // Puxa usuários remotos para o banco local (necessário para FK de receitas)
      for (final remoto in usuariosRemoto) {
        if (remoto.id.isEmpty) continue;
        final existeLocal =
            usuariosLocais.any((u) => u.id == remoto.id);
        if (!existeLocal) {
          await _localDb.insertUsuario(remoto);
        }
      }

      // Envia usuários novos para o servidor (pulando emails inválidos)
      for (final usuario in usuariosLocais) {
        if (!_emailValido(usuario.email)) {
          // ignore: avoid_print
          print('Pulando sync de usuário com email inválido: "${usuario.email}"');
          continue;
        }
        final existe = usuariosRemoto.any((u) => u.email == usuario.email);
        if (!existe) {
          try {
            await _remoteDb.criarUsuario(
              nome: usuario.nome,
              email: usuario.email,
              senha: usuario.senha,
            );
          } catch (e) {
            // ignore: avoid_print
            print('Falha ao enviar usuário ${usuario.email} ao remoto: $e');
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao sincronizar usuários: $e');
    }
  }

  /// Garante que o proprietário de uma receita exista localmente antes
  /// de salvar a receita (evita falha de FOREIGN KEY).
  Future<bool> _garantirProprietarioLocal(String proprietarioId) async {
    if (proprietarioId.isEmpty) return false;
    final existente = await _localDb.getUsuarioById(proprietarioId);
    if (existente != null) return true;

    try {
      final remotos = await _remoteDb.obterUsuarios();
      final dono = remotos.firstWhere(
        (u) => u.id == proprietarioId,
        orElse: () => Usuario(id: '', nome: '', email: '', senha: ''),
      );
      if (dono.id.isNotEmpty) {
        await _localDb.insertUsuario(dono);
        return true;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Falha ao buscar proprietário remoto $proprietarioId: $e');
    }
    return false;
  }

  /// Sincroniza receitas
  Future<void> _sincronizarReceitas() async {
    try {
      final receitasLocais = await _localDb.getReceitas();
      final receitasRemoto = await _remoteDb.obterReceitas();

      // Envia receitas novas para o servidor
      for (final receita in receitasLocais) {
        final existe = receitasRemoto.any((r) => r.id == receita.id);
        if (!existe) {
          await _remoteDb.criarReceita(
            id: receita.id,
            nome: receita.nome,
            ingredientes: receita.ingredientes,
            modopreparo: receita.modoPreparo,
            // tempo_preparo: receita.tempoPreparacao,
            proprietarioId: receita.proprietarioId,
            acesso: receita.acesso,
            imagens: receita.imagens,
          );
        }
      }

      // Adiciona localmente receitas do servidor que ainda não estão no banco local
      for (final receita in receitasRemoto) {
        final existe = receitasLocais.any((r) => r.id == receita.id);
        if (existe) continue;
        final donoOk = await _garantirProprietarioLocal(receita.proprietarioId);
        if (!donoOk) {
          // ignore: avoid_print
          print(
              'Pulando receita ${receita.id} (${receita.nome}): proprietário ${receita.proprietarioId} não existe localmente.');
          continue;
        }
        try {
          await _localDb.insertReceita(receita);
        } catch (e) {
          // ignore: avoid_print
          print('Falha ao inserir receita ${receita.id} localmente: $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao sincronizar receitas: $e');
    }
  }

  // ===================== OPERAÇÕES COM FALLBACK =====================

  /// Obtém usuários com fallback para local se offline
  Future<List<Usuario>> obterUsuarios() async {
    try {
      if (_isOnline && supabaseDisponivel) {
        return await _remoteDb.obterUsuarios();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao obter usuários do remoto: $e');
    }
    return await _localDb.getUsuarios();
  }

  /// Insere usuário com sincronização automática e retorna o usuário (com ID correto do Supabase se online)
  Future<Usuario> inserirUsuario(Usuario usuario) async {
    Usuario usuarioParaSalvar = usuario;

    // Tenta sincronizar se online PRIMEIRO para pegar o ID gerado pelo Supabase Auth
    if (_isOnline && supabaseDisponivel) {
      try {
        final usuarioRemoto = await _remoteDb.criarUsuario(
          nome: usuario.nome,
          email: usuario.email,
          senha: usuario.senha,
        );
        usuarioParaSalvar = usuarioRemoto;
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não sincronizou com remoto: $e');
      }
    }

    // Sempre salva localmente, mas com o ID correto (se conseguiu sincronizar)
    await _localDb.insertUsuario(usuarioParaSalvar);
    return usuarioParaSalvar;
  }

  /// Autentica usuário
  Future<void> autenticarUsuario(String email, String senha) async {
    if (_isOnline && supabaseDisponivel) {
      try {
        await _remoteDb.autenticar(email: email, senha: senha);
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não autenticou no remoto: $e');
      }
    }
  }

  /// Obtém receitas com fallback para local se offline
  Future<List<Receita>> obterReceitas() async {
    try {
      if (_isOnline && supabaseDisponivel) {
        final receitasRemoto = await _remoteDb.obterReceitas();
        final receitasLocais = await _localDb.getReceitas();
        
        for (final remoto in receitasRemoto) {
          final existe = receitasLocais.any((local) => local.id == remoto.id);
          if (existe) {
            try {
              await _localDb.updateReceita(remoto);
            } catch (e) {
              // ignore: avoid_print
              print('Falha ao atualizar receita ${remoto.id} localmente: $e');
            }
            continue;
          }
          final donoOk = await _garantirProprietarioLocal(remoto.proprietarioId);
          if (!donoOk) {
            // ignore: avoid_print
            print(
                'Pulando receita ${remoto.id} (${remoto.nome}): proprietário ${remoto.proprietarioId} não existe localmente.');
            continue;
          }
          try {
            await _localDb.insertReceita(remoto);
          } catch (e) {
            // ignore: avoid_print
            print('Falha ao inserir receita ${remoto.id} localmente: $e');
          }
        }
        return await _localDb.getReceitas();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao obter receitas do remoto: $e');
    }
    return await _localDb.getReceitas();
  }

  /// Insere receita com sincronização automática
  Future<void> inserirReceita(Receita receita) async {
    // Sempre salva localmente
    await _localDb.insertReceita(receita);

    // Tenta sincronizar se online
    if (_isOnline && supabaseDisponivel) {
      try {
        await _remoteDb.criarReceita(
          id: receita.id,
          nome: receita.nome,
          ingredientes: receita.ingredientes,
          modopreparo: receita.modoPreparo,
          // tempo_preparo: receita.tempoPreparacao,
          proprietarioId: receita.proprietarioId,
          acesso: receita.acesso,
          imagens: receita.imagens,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não sincronizou com remoto: $e');
      }
    }
  }

  /// Atualiza receita com sincronização automática
  Future<void> atualizarReceita(Receita receita) async {
    // Sempre atualiza localmente
    await _localDb.updateReceita(receita);

    // Tenta sincronizar se online
    if (_isOnline && supabaseDisponivel) {
      try {
        await _remoteDb.atualizarReceita(
          receitaId: receita.id,
          nome: receita.nome,
          ingredientes: receita.ingredientes,
          modoPreparo: receita.modoPreparo,
          // tempoPreparacao: receita.tempoPreparacao,
          acesso: receita.acesso,
          proprietarioId: receita.proprietarioId,
          imagens: receita.imagens,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não sincronizou com remoto: $e');
      }
    }
  }

  /// Deleta receita com sincronização automática
  Future<void> deletarReceita(String receitaId) async {
    // Sempre deleta localmente
    await _localDb.deleteReceita(receitaId);

    // Tenta sincronizar se online
    if (_isOnline && supabaseDisponivel) {
      try {
        await _remoteDb.deletarReceita(receitaId);
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não sincronizou com remoto: $e');
      }
    }
  }
}
