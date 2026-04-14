import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../database/database_helper.dart';

/// Provider responsável por gerenciar autenticação e usuários.
class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Lista de usuários cadastrados (fonte primária em memória)
  final List<Usuario> _usuarios = [];

  /// Usuário atualmente logado
  Usuario? _usuarioLogado;

  /// Getter para o usuário logado
  Usuario? get usuarioLogado => _usuarioLogado;

  /// Verifica se há um usuário logado
  bool get estaLogado => _usuarioLogado != null;

  /// Cadastra um novo usuário. Retorna mensagem de erro ou null se sucesso.
  Future<String?> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    // Verifica se já existe um usuário com o mesmo email
    final existente = _usuarios.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (existente) {
      return 'Já existe um usuário com este email.';
    }

    final novoUsuario = Usuario(nome: nome, email: email, senha: senha);
    _usuarios.add(novoUsuario);
    notifyListeners();

    try {
      await _db.insertUsuario(novoUsuario);
    } catch (_) {}

    return null;
  }

  /// Realiza o login. Retorna mensagem de erro ou null se sucesso.
  Future<String?> login({required String email, required String senha}) async {
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.senha == senha,
      );
      _usuarioLogado = usuario;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Email ou senha incorretos.';
    }
  }

  /// Realiza o logout
  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }

  /// Atualiza os dados do perfil do usuário logado.
  /// Retorna mensagem de erro ou null se sucesso.
  Future<String?> atualizarPerfil({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (_usuarioLogado == null) return 'Nenhum usuário logado.';

    // Verifica se o email já é usado por outro usuário
    final emailEmUso = _usuarios.any(
      (u) =>
          u.id != _usuarioLogado!.id &&
          u.email.toLowerCase() == email.toLowerCase(),
    );
    if (emailEmUso) {
      return 'Este email já está em uso por outro usuário.';
    }

    _usuarioLogado!.nome = nome;
    _usuarioLogado!.email = email;
    _usuarioLogado!.senha = senha;
    notifyListeners();

    try {
      await _db.updateUsuario(_usuarioLogado!);
    } catch (_) {}

    return null;
  }

  /// Redefine a senha de um usuário pelo email.
  /// Retorna mensagem de erro ou null se sucesso.
  Future<String?> redefinirSenha({required String email, required String novaSenha}) async {
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      usuario.senha = novaSenha;
      notifyListeners();

      try {
        await _db.updateUsuario(usuario);
      } catch (_) {}

      return null;
    } catch (e) {
      return 'Nenhum usuário encontrado com este email.';
    }
  }

  /// Carrega usuários do banco de dados para a lista em memória.
  Future<void> carregarUsuarios() async {
    try {
      final usuarios = await _db.getUsuarios();
      _usuarios.addAll(usuarios);
    } catch (_) {}
  }
}
