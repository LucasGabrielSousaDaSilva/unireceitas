import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

/// AuthProvider (Controller) - Gerencia o estado de autenticação
/// Usa AuthService para lógica de negócio
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  /// Usuário atualmente logado
  Usuario? _usuarioLogado;

  /// Getter para o usuário logado
  Usuario? get usuarioLogado => _usuarioLogado;

  /// Verifica se há um usuário logado
  bool get estaLogado => _usuarioLogado != null;

  /// Inicializa o provider
  Future<void> inicializar() async {
    try {
      await _authService.inicializar();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao inicializar AuthProvider: $e');
    }
  }

  /// Cadastra um novo usuário
  Future<String?> cadastrarUsuario({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      await _authService.cadastrarUsuario(
        nome: nome,
        email: email,
        senha: senha,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Realiza o login
  Future<String?> login({required String email, required String senha}) async {
    try {
      _usuarioLogado = await _authService.buscarUsuarioPorCredenciais(email, senha);
      if (_usuarioLogado == null) {
        return 'Email ou senha incorretos.';
      }
      notifyListeners();
      return null;
    } catch (e) {
      return 'Erro ao fazer login: ${e.toString()}';
    }
  }

  /// Realiza o logout
  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }

  /// Atualiza os dados do perfil do usuário logado
  Future<String?> atualizarPerfil({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (_usuarioLogado == null) return 'Nenhum usuário logado.';

    try {
      _usuarioLogado = await _authService.atualizarUsuario(
        usuarioId: _usuarioLogado!.id,
        nome: nome,
        email: email,
        senha: senha,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Envia o e-mail de recuperação de senha via Supabase Auth.
  /// Retorna `null` em sucesso ou a mensagem de erro.
  Future<String?> enviarEmailRecuperacao(String email) async {
    try {
      await _authService.enviarEmailRecuperacao(email);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Redefine a senha do usuário autenticado pela sessão de recuperação
  /// estabelecida pelo deep link recebido por e-mail.
  /// Retorna `null` em sucesso ou a mensagem de erro.
  Future<String?> redefinirSenhaAutenticada(String novaSenha) async {
    try {
      await _authService.redefinirSenhaAutenticada(novaSenha);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Obtém todos os usuários
  List<Usuario> obterTodosUsuarios() {
    return _authService.obterTodosUsuarios();
  }

  /// Carrega usuários do banco de dados
  Future<void> carregarUsuarios() async {
    try {
      await _authService.inicializar();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
    }
  }
}
