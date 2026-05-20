import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/session_service.dart';

/// SessionProvider - Controller de Sessão
/// Gerencia estado de sessão e notifica listeners de mudanças
class SessionProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();

  SessionProvider();

  // ===================== INICIALIZAÇÃO =====================

  /// Inicializa o provider
  Future<void> inicializar() async {
    try {
      await _sessionService.inicializar();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao inicializar SessionProvider: $e');
    }
  }

  // ===================== GETTERS =====================

  /// Obtém o usuário logado
  Usuario? get usuarioLogado => _sessionService.usuarioLogado;

  /// Verifica se há usuário logado
  bool get estaLogado => _sessionService.estaLogado;

  /// Obtém minutos até expiração
  int get minutosAteExpiracao => _sessionService.minutosAteExpiracao;

  // ===================== OPERAÇÕES DE SESSÃO =====================

  /// Inicia uma nova sessão
  Future<void> iniciarSessao({
    required Usuario usuario,
  }) async {
    try {
      await _sessionService.iniciarSessao(
        usuario: usuario,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao iniciar sessão: $e');
    }
  }

  /// Registra atividade do usuário
  void registrarAtividade() {
    _sessionService.registrarAtividade();
    notifyListeners();
  }

  /// Valida se a sessão é válida
  bool validarSessao() {
    final valida = _sessionService.validarSessao();
    if (!valida) {
      notifyListeners();
    }
    return valida;
  }

  /// Define tempo de expiração
  void definirTempoExpiracao(Duration duracao) {
    _sessionService.definirTempoExpiracao(duracao);
    notifyListeners();
  }

  /// Encerra a sessão
  Future<void> encerrarSessao() async {
    try {
      await _sessionService.encerrarSessao();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao encerrar sessão: $e');
    }
  }

  /// Limpa recursos
  @override
  void dispose() {
    _sessionService.dispose();
    super.dispose();
  }
}
