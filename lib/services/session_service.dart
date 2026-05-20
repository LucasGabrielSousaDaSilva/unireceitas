import 'package:flutter/material.dart';
import 'dart:async';
import '../models/usuario.dart';

/// SessionManager - Gerencia a sessão do usuário
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  late Usuario? _usuarioLogado;
  late DateTime _ultimaAtividade;
  late Duration _tempoExpiracao;

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal() {
    _usuarioLogado = null;
    _ultimaAtividade = DateTime.now();
    _tempoExpiracao = Duration(hours: 24);
  }

  // ===================== GETTERS =====================

  /// Obtém o usuário atual
  Usuario? get usuarioLogado => _usuarioLogado;

  /// Verifica se há usuário logado
  bool get estaLogado => _usuarioLogado != null && !_sessaoExpirada();

  /// Verifica se a sessão expirou
  bool _sessaoExpirada() {
    return DateTime.now().difference(_ultimaAtividade) > _tempoExpiracao;
  }

  /// Tempo até expiração (em minutos)
  int get minutosAteExpiracao {
    if (!estaLogado) return 0;
    final diferenca = _tempoExpiracao -
        DateTime.now().difference(_ultimaAtividade);
    return diferenca.inMinutes;
  }

  // ===================== OPERAÇÕES DE SESSÃO =====================

  /// Inicializa uma nova sessão
  Future<void> iniciarSessao({
    required Usuario usuario,
  }) async {
    _usuarioLogado = usuario;
    _ultimaAtividade = DateTime.now();
  }

  /// Atualiza a última atividade (prolonga sessão)
  void atualizarAtividade() {
    if (estaLogado) {
      _ultimaAtividade = DateTime.now();
    }
  }

  /// Encerra a sessão
  Future<void> encerrarSessao() async {
    _usuarioLogado = null;
    _ultimaAtividade = DateTime.now();
  }

  /// Reinicia a sessão (força reautenticação)
  Future<void> reiniciarSessao() async {
    await encerrarSessao();
  }

  /// Define o tempo de expiração
  void definirTempoExpiracao(Duration duracao) {
    _tempoExpiracao = duracao;
  }

  /// Valida se a sessão ainda é válida
  bool validarSessao() {
    if (!estaLogado) return false;
    
    // Se sessão expirou, encerra
    if (_sessaoExpirada()) {
      encerrarSessao();
      return false;
    }

    // Atualiza atividade
    atualizarAtividade();
    return true;
  }

  /// Força logout por segurança
  Future<void> logoutPorSeguranca({String? motivo}) async {
    debugPrint('Logout por segurança: ${motivo ?? 'motivo não informado'}');
    await encerrarSessao();
  }
}

/// SessionService - Serviço de gerenciamento de sessão
class SessionService {
  final SessionManager _sessionManager = SessionManager();
  
  // Timers para monitoramento
  static Timer? _activityTimer;
  static const _activityCheckInterval = Duration(minutes: 1);

  /// Inicializa o serviço de sessão
  Future<void> inicializar() async {
    // Inicia monitoramento de atividade
    _iniciarMonitoramentoAtividade();
  }

  /// Inicia monitoramento periódico de expiração
  void _iniciarMonitoramentoAtividade() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(_activityCheckInterval, (_) {
      _verificarExpiracao();
    });
  }

  /// Verifica se a sessão expirou
  void _verificarExpiracao() {
    if (_sessionManager.estaLogado && !_sessionManager.validarSessao()) {
      // ignore: avoid_print
      print('Sessão expirada. Faça login novamente.');
    }
  }

  // ===================== MÉTODOS PÚBLICOS =====================

  /// Obtém o usuário logado
  Usuario? get usuarioLogado => _sessionManager.usuarioLogado;

  /// Verifica se está logado
  bool get estaLogado => _sessionManager.estaLogado;

  /// Registra atividade do usuário
  void registrarAtividade() {
    _sessionManager.atualizarAtividade();
  }

  /// Inicia nova sessão
  Future<void> iniciarSessao({
    required Usuario usuario,
  }) async {
    await _sessionManager.iniciarSessao(
      usuario: usuario,
    );
  }

  /// Encerra sessão
  Future<void> encerrarSessao() async {
    await _sessionManager.encerrarSessao();
  }

  /// Verifica se sessão é válida
  bool validarSessao() {
    return _sessionManager.validarSessao();
  }

  /// Obtém minutos até expiração
  int get minutosAteExpiracao => _sessionManager.minutosAteExpiracao;

  /// Define tempo de expiração
  void definirTempoExpiracao(Duration duracao) {
    _sessionManager.definirTempoExpiracao(duracao);
  }

  /// Limpa recursos
  void dispose() {
    _activityTimer?.cancel();
  }
}

// Importar Timer

