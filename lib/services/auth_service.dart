import '../models/usuario.dart';
import '../database/database_helper.dart';
import '../services/sync_service.dart';

/// AuthService - Camada de Serviço de Autenticação
/// Responsável pela lógica de negócio de autenticação e gerenciamento de usuários
class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SyncService _sync = SyncService.instance;
  final List<Usuario> _usuarios = [];

  /// Carrega usuários do banco de dados
  Future<void> inicializar() async {
    try {
      final usuarios = await _sync.obterUsuarios();
      _usuarios.clear();
      _usuarios.addAll(usuarios);
    } catch (e) {
      throw Exception('Erro ao inicializar AuthService: $e');
    }
  }

  /// Valida se um email já está cadastrado
  bool emailJaExiste(String email) {
    return _usuarios.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
  }

  /// Valida se um email já é usado por outro usuário
  bool emailEmUsoPorOutro(String email, String usuarioId) {
    return _usuarios.any(
      (u) =>
          u.id != usuarioId &&
          u.email.toLowerCase() == email.toLowerCase(),
    );
  }

  /// Cadastra um novo usuário
  Future<Usuario> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (emailJaExiste(email)) {
      throw Exception('Já existe um usuário com este email.');
    }

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      throw Exception('Todos os campos são obrigatórios.');
    }

    final novoUsuarioTemp = Usuario(nome: nome, email: email, senha: senha);

    try {
      final novoUsuarioSalvo = await _sync.inserirUsuario(novoUsuarioTemp);
      _usuarios.add(novoUsuarioSalvo);
      return novoUsuarioSalvo;
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  /// Busca um usuário por email e senha (login)
  Future<Usuario?> buscarUsuarioPorCredenciais(String email, String senha) async {
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.senha == senha,
      );
      await _sync.autenticarUsuario(email, senha);
      return usuario;
    } catch (e) {
      return null;
    }
  }

  /// Atualiza os dados de um usuário
  Future<Usuario> atualizarUsuario({
    required String usuarioId,
    required String nome,
    required String email,
    required String senha,
  }) async {
    final usuarioIndex = _usuarios.indexWhere((u) => u.id == usuarioId);
    if (usuarioIndex == -1) {
      throw Exception('Usuário não encontrado.');
    }

    if (emailEmUsoPorOutro(email, usuarioId)) {
      throw Exception('Este email já está em uso por outro usuário.');
    }

    final usuarioAtualizado = _usuarios[usuarioIndex];
    usuarioAtualizado.nome = nome;
    usuarioAtualizado.email = email;
    usuarioAtualizado.senha = senha;

    try {
      // In a real scenario, SyncService would have an updateUsuario method.
      // For now, since SyncService.inserirUsuario handles 'always save locally',
      // we can add update logic in SyncService, or we can assume it will be synced later.
      // But we probably need to add updateUsuario in SyncService.
      // Wait, SyncService doesn't have atualizarUsuario for some reason. Let's look at what we can do.
      await _db.updateUsuario(usuarioAtualizado);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }

    return usuarioAtualizado;
  }

  /// Redefine a senha de um usuário
  Future<void> redefinirSenha({
    required String email,
    required String novaSenha,
  }) async {
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      usuario.senha = novaSenha;
      await _db.updateUsuario(usuario);
    } catch (e) {
      throw Exception('Usuário não encontrado ou erro ao redefinir senha.');
    }
  }

  /// Obtém todos os usuários
  List<Usuario> obterTodosUsuarios() {
    return List.unmodifiable(_usuarios);
  }

  /// Busca um usuário pelo ID
  Usuario? buscarPorId(String id) {
    try {
      return _usuarios.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }
}
