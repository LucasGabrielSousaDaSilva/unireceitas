import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

/// CalendarService - Integra com Google Calendar
class CalendarService {
  late calendar.CalendarApi _calendarApi;
  bool _isInitialized = false;

  /// Inicializa a conexão com Google Calendar
  /// Requer autenticação OAuth2
  Future<void> inicializar(String accessToken) async {
    try {
      final httpClient = _GoogleHttpClient(accessToken);
      _calendarApi = calendar.CalendarApi(httpClient);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Erro ao inicializar Calendar API: $e');
    }
  }

  /// Verifica se está inicializado
  bool get isInitialized => _isInitialized;

  /// Cria evento de lembrete de compras
  Future<calendar.Event?> criarLembreteCompras({
    required String titulo,
    required List<String> itens,
    required DateTime dataLembrete,
  }) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      final descricao = 'Itens para comprar:\n${itens.join('\n')}';

      final event = calendar.Event()
        ..summary = titulo
        ..description = descricao
        ..start = calendar.EventDateTime(dateTime: dataLembrete)
        ..end = calendar.EventDateTime(
          dateTime: dataLembrete.add(Duration(minutes: 30)),
        )
        ..reminders = [
          calendar.EventReminder()
            ..method = 'notification'
            ..minutes = 0,
          calendar.EventReminder()
            ..method = 'email'
            ..minutes = 60, // Email 1 hora antes
        ] as calendar.EventReminders?;

      final criadoEvent = await _calendarApi.events.insert(
        event,
        'primary', // Calendário principal
      );

      return criadoEvent;
    } catch (e) {
      throw Exception('Erro ao criar lembrete de compras: $e');
    }
  }

  /// Cria evento genérico
  Future<calendar.Event?> criarEvento({
    required String titulo,
    required String descricao,
    required DateTime dataInicio,
    required DateTime dataFim,
    List<String>? emails,
  }) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      final event = calendar.Event()
        ..summary = titulo
        ..description = descricao
        ..start = calendar.EventDateTime(dateTime: dataInicio)
        ..end = calendar.EventDateTime(dateTime: dataFim);

      // Adiciona convidados se houver
      if (emails != null && emails.isNotEmpty) {
        event.attendees = emails
            .map((email) => calendar.EventAttendee()..email = email)
            .toList();
      }

      final criadoEvent = await _calendarApi.events.insert(
        event,
        'primary',
      );

      return criadoEvent;
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
    }
  }

  /// Lista eventos próximos
  Future<List<calendar.Event>> listarEventosProximos({
    int dias = 7,
    int maxResultados = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      final now = DateTime.now();
      final futuro = now.add(Duration(days: dias));

      final eventos = await _calendarApi.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: futuro.toUtc(),
        maxResults: maxResultados,
        singleEvents: true,
      );

      return eventos.items ?? [];
    } catch (e) {
      throw Exception('Erro ao listar eventos: $e');
    }
  }

  /// Atualiza um evento
  Future<calendar.Event?> atualizarEvento({
    required String eventoId,
    required String titulo,
    required String descricao,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      final event = calendar.Event()
        ..id = eventoId
        ..summary = titulo
        ..description = descricao
        ..start = calendar.EventDateTime(dateTime: dataInicio)
        ..end = calendar.EventDateTime(dateTime: dataFim);

      final atualizado = await _calendarApi.events.update(
        event,
        'primary',
        eventoId,
      );

      return atualizado;
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  /// Deleta um evento
  Future<void> deletarEvento(String eventoId) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      await _calendarApi.events.delete('primary', eventoId);
    } catch (e) {
      throw Exception('Erro ao deletar evento: $e');
    }
  }

  /// Obter detalhes de um evento
  Future<calendar.Event?> obterEvento(String eventoId) async {
    if (!_isInitialized) {
      throw Exception('Calendar API não foi inicializada');
    }

    try {
      final evento = await _calendarApi.events.get('primary', eventoId);
      return evento;
    } catch (e) {
      throw Exception('Erro ao obter evento: $e');
    }
  }
}

/// Classe auxiliar para autenticação HTTP com Google
class _GoogleHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _GoogleHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// Modelo para representar lembrete de compras
class LembreteCompras {
  final String id;
  final String titulo;
  final List<String> itens;
  final DateTime dataLembrete;
  final bool concluido;

  LembreteCompras({
    required this.id,
    required this.titulo,
    required this.itens,
    required this.dataLembrete,
    this.concluido = false,
  });

  /// Converte para evento do Google Calendar
  calendar.Event toGoogleEvent() {
    final descricao = 'Itens para comprar:\n${itens.join('\n')}';

    return calendar.Event()
      ..summary = titulo
      ..description = descricao
      ..start = calendar.EventDateTime(dateTime: dataLembrete)
      ..end = calendar.EventDateTime(
        dateTime: dataLembrete.add(Duration(minutes: 30)),
      );
  }

  @override
  String toString() => '$titulo - ${itens.length} itens';
}
