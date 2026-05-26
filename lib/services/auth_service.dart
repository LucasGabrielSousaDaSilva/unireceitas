import '../models/usuario.dart';
import '../services/supabase_service.dart';

/// AuthService - Camada de Serviço de Autenticação
/// Responsável pela lógica de negócio de autenticação e gerenciamento de usuários.
/// Persistência feita exclusivamente no Supabase.
class AuthService {
  final SupabaseService _supabase = SupabaseService();
  final List<Usuario> _usuarios = [];

  /// Carrega usuários do Supabase
  Future<void> inicializar() async {
    try {
      final usuarios = await _supabase.obterUsuarios();
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

  /// Cadastra um novo usuário no Supabase
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

    try {
      final novoUsuario = await _supabase.criarUsuario(
        nome: nome,
        email: email,
        senha: senha,
      );
      _usuarios.add(novoUsuario);
      return novoUsuario;
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  /// Autentica um usuário via Supabase Auth.
  ///
  /// O Supabase é a fonte da verdade da senha (armazenada como hash).
  /// Em sucesso, busca o restante dos dados (nome) na tabela `usuarios`
  /// e atualiza o cache local em memória.
  Future<Usuario?> buscarUsuarioPorCredenciais(
      String email, String senha) async {
    final authUser =
        await _supabase.autenticar(email: email, senha: senha);
    if (authUser == null) return null;

    Usuario? usuario;
    try {
      usuario = await _supabase.buscarUsuarioPorEmail(email);
    } catch (_) {
      usuario = null;
    }
    usuario ??= Usuario(
      id: authUser.id,
      nome: authUser.email ?? email,
      email: email,
      senha: senha,
    );

    final idx = _usuarios.indexWhere((u) => u.id == usuario!.id);
    if (idx >= 0) {
      _usuarios[idx] = usuario;
    } else {
      _usuarios.add(usuario);
    }

    return usuario;
  }

  /// Atualiza os dados de um usuário no Supabase
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
      await _supabase.atualizarUsuario(
        usuarioId: usuarioId,
        nome: nome,
        email: email,
      );
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }

    return usuarioAtualizado;
  }

  /// Envia o e-mail oficial de recuperação de senha via Supabase Auth.
  ///
  /// Por segurança, não diferencia "usuário não existe" de "e-mail enviado":
  /// a API do Supabase é desenhada para não permitir enumeração de usuários,
  /// então a UI deve sempre exibir mensagem genérica de sucesso.
  Future<void> enviarEmailRecuperacao(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Informe um e-mail válido.');
    }
    await _supabase.enviarEmailRecuperacaoSenha(email.trim());
  }

  /// Atualiza a senha do usuário autenticado pela sessão de recuperação
  /// (a sessão é estabelecida automaticamente pelo SDK quando o usuário
  /// abre o deep link recebido por e-mail).
  Future<void> redefinirSenhaAutenticada(String novaSenha) async {
    if (novaSenha.length < 6) {
      throw Exception('A senha deve ter pelo menos 6 caracteres.');
    }
    await _supabase.atualizarSenha(novaSenha);
  }

  /// Altera a senha do usuário autenticado.
  /// Verifica a senha atual reautenticando no Supabase Auth antes de aplicar
  /// a nova senha.
  Future<void> alterarSenha({
    required String email,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    try {
      final authUser =
          await _supabase.autenticar(email: email, senha: senhaAtual);
      if (authUser == null) {
        throw Exception('Senha atual incorreta.');
      }
    } catch (e) {
      throw Exception('Senha atual incorreta.');
    }

    try {
      await _supabase.atualizarSenha(novaSenha);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }

    final idx = _usuarios.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (idx >= 0) {
      _usuarios[idx].senha = novaSenha;
    }
  }

  /// Exclui a conta do usuário (dados, receitas e sessão).
  /// Valida a senha informada antes de excluir.
  Future<void> excluirConta({
    required String usuarioId,
    required String email,
    required String senhaConfirmacao,
  }) async {
    try {
      final authUser = await _supabase.autenticar(
        email: email,
        senha: senhaConfirmacao,
      );
      if (authUser == null) {
        throw Exception('Senha incorreta.');
      }
    } catch (e) {
      throw Exception('Senha incorreta.');
    }

    try {
      await _supabase.deletarUsuarioCompleto(usuarioId);
      _usuarios.removeWhere((u) => u.id == usuarioId);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
