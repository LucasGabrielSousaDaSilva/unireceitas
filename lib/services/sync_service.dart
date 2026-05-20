import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/usuario.dart';
import '../models/receita.dart';
import '../database/database_helper.dart';
import '../services/supabase_service.dart';

/// SyncService - Gerencia sincronização entre SQLite e Supabase
/// Implementa padrão Offline-First com sincronização automática
class SyncService {
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

  /// Sincroniza usuários
  Future<void> _sincronizarUsuarios() async {
    try {
      final usuariosLocais = await _localDb.getUsuarios();
      final usuariosRemoto = await _remoteDb.obterUsuarios();

      // Envia usuários novos para o servidor
      for (final usuario in usuariosLocais) {
        final existe = usuariosRemoto.any((u) => u.email == usuario.email);
        if (!existe) {
          await _remoteDb.criarUsuario(
            nome: usuario.nome,
            email: usuario.email,
            senha: usuario.senha,
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao sincronizar usuários: $e');
    }
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
          );
        }
      }

      // Adiciona localmente receitas do servidor que ainda não estão no banco local
      for (final receita in receitasRemoto) {
        final existe = receitasLocais.any((r) => r.id == receita.id);
        if (!existe) {
          await _localDb.insertReceita(receita);
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

  /// Insere usuário com sincronização automática
  Future<void> inserirUsuario(Usuario usuario) async {
    // Sempre salva localmente
    await _localDb.insertUsuario(usuario);

    // Tenta sincronizar se online
    if (_isOnline && supabaseDisponivel) {
      try {
        await _remoteDb.criarUsuario(
          nome: usuario.nome,
          email: usuario.email,
          senha: usuario.senha,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Aviso: não sincronizou com remoto: $e');
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
            await _localDb.updateReceita(remoto);
          } else {
            await _localDb.insertReceita(remoto);
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
          modopreparo: receita.modoPreparo,
          // tempoPreparacao: receita.tempoPreparacao,
          acesso: receita.acesso, modoPreparo: '',
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
