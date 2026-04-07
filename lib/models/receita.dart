import 'dart:typed_data';

enum AcessoReceita { privada, publica }

class Receita {

  final String id;

  String nome;
  List<Uint8List> imagens;
  String ingredientes;
  String modoPreparo;
  AcessoReceita acesso;

  final String proprietarioId;

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
