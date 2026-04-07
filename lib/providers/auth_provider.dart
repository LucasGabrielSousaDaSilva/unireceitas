import 'package:flutter/material.dart';
import '../models/usuario.dart';


class AuthProvider extends ChangeNotifier {
  
  final List<Usuario> _usuarios = [];

  Usuario? _usuarioLogado;

  Usuario? get usuarioLogado => _usuarioLogado;

  bool get estaLogado => _usuarioLogado != null;

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

  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }

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
