import 'package:flutter/material.dart';
import '../services/calendar_service.dart';
// import '../services/calendar_service.dart' show LembreteCompras;

/// CalendarProvider - Controller de Calendário
/// Gerencia lembretes e eventos
class CalendarProvider extends ChangeNotifier {
  final CalendarService _calendarService = CalendarService();

  final List<LembreteCompras> _lembretes = [];
  bool _carregando = false;
  String? _erro;
  bool _temAutorizacao = false;

  // ===================== GETTERS =====================

  /// Lista de lembretes
  List<LembreteCompras> get lembretes => List.unmodifiable(_lembretes);

  /// Total de lembretes
  int get totalLembretes => _lembretes.length;

  /// Está carregando?
  bool get carregando => _carregando;

  /// Última mensagem de erro
  String? get erro => _erro;

  /// Tem erro?
  bool get temErro => _erro != null;

  /// Tem autorização?
  bool get temAutorizacao => _temAutorizacao;

  // ===================== INICIALIZAÇÃO =====================

  /// Inicializa o provider com token de acesso
  Future<void> inicializar(String accessToken) async {
    try {
      await _calendarService.inicializar(accessToken);
      _temAutorizacao = true;
      notifyListeners();
    } catch (e) {
      _erro = e.toString();
      _temAutorizacao = false;
      notifyListeners();
    }
  }

  /// Verifica se Calendar está disponível
  bool get calendarDisponivel => _calendarService.isInitialized;

  // ===================== OPERAÇÕES =====================

  /// Cria novo lembrete de compras
  Future<void> criarLembreteCompras({
    required String titulo,
    required List<String> itens,
    required DateTime dataLembrete,
  }) async {
    if (!_temAutorizacao) {
      _erro = 'Sem autorização para acessar calendário';
      notifyListeners();
      return;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await _calendarService.criarLembreteCompras(
        titulo: titulo,
        itens: itens,
        dataLembrete: dataLembrete,
      );

      // Adiciona à lista local
      final lembrete = LembreteCompras(
        id: DateTime.now().toString(),
        titulo: titulo,
        itens: itens,
        dataLembrete: dataLembrete,
      );

      _lembretes.add(lembrete);
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao criar lembrete: $e';
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Lista lembretes próximos
  Future<void> carregarLembretes({int dias = 7}) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final eventos = await _calendarService.listarEventosProximos(dias: dias);

      _lembretes.clear();
      for (final evento in eventos) {
        if (evento.summary?.contains('Compras') ?? false) {
          final lembrete = LembreteCompras(
            id: evento.id ?? '',
            titulo: evento.summary ?? 'Sem título',
            itens: (evento.description ?? '').split('\n'),
            dataLembrete: evento.start?.dateTime ?? DateTime.now(),
          );
          _lembretes.add(lembrete);
        }
      }

      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao carregar lembretes: $e';
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Agendar lembrete para fim de semana
  Future<void> agendarLembreteFinDeSemana({
    required String titulo,
    required List<String> itens,
  }) async {
    // Calcula próximo sábado
    final agora = DateTime.now();
    int diasAteFinDeSemana = 6 - agora.weekday; // 6 = sábado
    if (diasAteFinDeSemana <= 0) {
      diasAteFinDeSemana += 7;
    }

    final sabado = agora.add(Duration(days: diasAteFinDeSemana));
    final horaLembrete = DateTime(sabado.year, sabado.month, sabado.day, 9, 0);

    await criarLembreteCompras(
      titulo: titulo,
      itens: itens,
      dataLembrete: horaLembrete,
    );
  }

  /// Remove um lembrete
  Future<void> removerLembrete(int index) async {
    if (index < 0 || index >= _lembretes.length) {
      return;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final lembreteId = _lembretes[index].id;
      await _calendarService.deletarEvento(lembreteId);

      _lembretes.removeAt(index);
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao remover lembrete: $e';
      notifyListeners();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Limpa todos os lembretes
  void limparLembretes() {
    _lembretes.clear();
    notifyListeners();
  }

  /// Limpa erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}

// Importar LembreteCompras

