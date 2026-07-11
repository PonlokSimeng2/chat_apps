class EmojiModel {
  final int id;
  final String emoji;
  final String label;
  final String category;
  final int sortOrder;
  final DateTime createdAt;

  const EmojiModel({
    required this.id,
    required this.emoji,
    required this.label,
    required this.category,
    required this.sortOrder,
    required this.createdAt,
  });

  factory EmojiModel.fromJson(Map<String, dynamic> json) {
    return EmojiModel(
      id: json['id'] as int,
      emoji: json['emoji'] as String,
      label: json['label'] as String,
      category: json['category'] as String? ?? 'reaction',
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'label': label,
      'category': category,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with new values
  EmojiModel copyWith({
    int? id,
    String? emoji,
    String? label,
    String? category,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return EmojiModel(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Compare two EmojiModel objects
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiModel && other.id == id && other.emoji == emoji;

  @override
  int get hashCode => id.hashCode ^ emoji.hashCode;

  @override
  String toString() {
    return 'EmojiModel(id: $id, emoji: $emoji, label: $label, category: $category, sortOrder: $sortOrder)';
  }
}
