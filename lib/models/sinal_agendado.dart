// Modelo para representar um sinal agendado
class SinalAgendado {
  final String id;
  final String nome;
  final DateTime dataHora;
  final int duracao; // em segundos
  final String musicaPath;
  final bool ativo;
  final bool repetir;
  final List<int> diasSemana; // 1-7 (segunda a domingo)

  SinalAgendado({
    required this.id,
    required this.nome,
    required this.dataHora,
    required this.duracao,
    required this.musicaPath,
    this.ativo = true,
    this.repetir = false,
    this.diasSemana = const [],
  });

  // Converter para JSON para armazenamento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'dataHora': dataHora.toIso8601String(),
      'duracao': duracao,
      'musicaPath': musicaPath,
      'ativo': ativo,
      'repetir': repetir,
      'diasSemana': diasSemana,
    };
  }

  // Criar a partir de JSON
  factory SinalAgendado.fromJson(Map<String, dynamic> json) {
    return SinalAgendado(
      id: json['id'],
      nome: json['nome'],
      dataHora: DateTime.parse(json['dataHora']),
      duracao: json['duracao'],
      musicaPath: json['musicaPath'],
      ativo: json['ativo'] ?? true,
      repetir: json['repetir'] ?? false,
      diasSemana: List<int>.from(json['diasSemana'] ?? []),
    );
  }

  // Criar uma cópia com modificações
  SinalAgendado copyWith({
    String? id,
    String? nome,
    DateTime? dataHora,
    int? duracao,
    String? musicaPath,
    bool? ativo,
    bool? repetir,
    List<int>? diasSemana,
  }) {
    return SinalAgendado(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataHora: dataHora ?? this.dataHora,
      duracao: duracao ?? this.duracao,
      musicaPath: musicaPath ?? this.musicaPath,
      ativo: ativo ?? this.ativo,
      repetir: repetir ?? this.repetir,
      diasSemana: diasSemana ?? this.diasSemana,
    );
  }

  @override
  String toString() {
    return 'SinalAgendado{id: $id, nome: $nome, dataHora: $dataHora, duracao: $duracao, ativo: $ativo}';
  }
}
