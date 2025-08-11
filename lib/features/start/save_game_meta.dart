class SaveGameMeta {
  final String id;          // ex: 'slot-1'
  final String name;        // nom de l’agent/partie
  final int week;           // progression visible
  final DateTime updatedAt;

  SaveGameMeta({
    required this.id,
    required this.name,
    required this.week,
    required this.updatedAt,
  });

  SaveGameMeta copyWith({String? name, int? week, DateTime? updatedAt}) =>
      SaveGameMeta(
        id: id,
        name: name ?? this.name,
        week: week ?? this.week,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'week': week,
    'updatedAt': updatedAt.toIso8601String(),
  };

  static SaveGameMeta fromJson(Map<String, dynamic> j) => SaveGameMeta(
    id: j['id'] as String,
    name: j['name'] as String,
    week: j['week'] as int,
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}
