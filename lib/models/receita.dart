import 'dart:typed_data';

/// Enum que define o tipo de acesso da receita.
enum AcessoReceita { privada, publica }

/// Modelo que representa uma receita no aplicativo.
/// Contém todos os dados necessários para exibir e gerenciar uma receita.
class Receita {
  /// Identificador único da receita (gerado automaticamente)
  final String id;

  /// Nome da receita
  String nome;

  /// Lista de bytes das imagens da receita (máximo 5).
  /// Usamos Uint8List em vez de caminhos de arquivo para compatibilidade
  /// com todas as plataformas (Web, Android, iOS, Desktop).
  List<Uint8List> imagens;

  /// Texto com os ingredientes da receita
  String ingredientes;

  /// Texto com o modo de preparo da receita
  String modoPreparo;

  /// Tipo de acesso da receita (pública ou privada)
  AcessoReceita acesso;

  /// ID do usuário proprietário da receita
  final String proprietarioId;

  /// Construtor da classe Receita.
  /// O [id] é gerado automaticamente usando o timestamp atual caso não seja fornecido.
  Receita({
    String? id,
    required this.nome,
    List<Uint8List>? imagens,
    required this.ingredientes,
    required this.modoPreparo,
    this.acesso = AcessoReceita.privada,
    required this.proprietarioId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        imagens = imagens ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'ingredientes': ingredientes,
      'modo_preparo': modoPreparo,
      'acesso': acesso.name,
      'proprietario_id': proprietarioId,
    };
  }

  factory Receita.fromMap(Map<String, dynamic> map, List<Uint8List> imagens) {
    return Receita(
      id: map['id'] as String,
      nome: map['nome'] as String,
      imagens: imagens,
      ingredientes: map['ingredientes'] as String,
      modoPreparo: map['modo_preparo'] as String,
      acesso: AcessoReceita.values.firstWhere((e) => e.name == map['acesso']),
      proprietarioId: map['proprietario_id'] as String,
    );
  }

  /// Cria uma cópia da receita com a possibilidade de alterar campos específicos.
  /// Usado na tela de edição para não alterar a receita original antes de salvar.
  Receita copiar({
    String? nome,
    List<Uint8List>? imagens,
    String? ingredientes,
    String? modoPreparo,
    AcessoReceita? acesso,
  }) {
    return Receita(
      id: id,
      nome: nome ?? this.nome,
      imagens: imagens ?? List<Uint8List>.from(this.imagens),
      ingredientes: ingredientes ?? this.ingredientes,
      modoPreparo: modoPreparo ?? this.modoPreparo,
      acesso: acesso ?? this.acesso,
      proprietarioId: proprietarioId,
    );
  }
}
