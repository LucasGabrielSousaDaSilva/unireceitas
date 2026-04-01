import 'package:flutter/material.dart';
import '../models/usuario.dart';

/// Provider responsável por gerenciar autenticação e usuários.
class AuthProvider extends ChangeNotifier {
  /// Lista de usuários cadastrados (em memória)
  final List<Usuario> _usuarios = [];

  /// Usuário atualmente logado
  Usuario? _usuarioLogado;

  /// Getter para o usuário logado
  Usuario? get usuarioLogado => _usuarioLogado;

  /// Verifica se há um usuário logado
  bool get estaLogado => _usuarioLogado != null;

  /// Cadastra um novo usuário. Retorna mensagem de erro ou null se sucesso.
  String? cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) {
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
    return null;
  }

  /// Realiza o login. Retorna mensagem de erro ou null se sucesso.
  String? login({required String email, required String senha}) {
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
  String? atualizarPerfil({
    required String nome,
    required String email,
    required String senha,
  }) {
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
    return null;
  }

  /// Redefine a senha de um usuário pelo email.
  /// Retorna mensagem de erro ou null se sucesso.
  String? redefinirSenha({required String email, required String novaSenha}) {
    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      usuario.senha = novaSenha;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Nenhum usuário encontrado com este email.';
    }
  }
}
