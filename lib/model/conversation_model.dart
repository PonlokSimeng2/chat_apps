class ConversationModel {
  final int? id;
  final String? name;
  final String? description;
  final String createdBy;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationModel({
    this.id,
    this.name,
    this.description,
    required this.createdBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      createdBy: json['created_by'].toString(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'is_active': isActive ?? true,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    int? id,
    String? name,
    String? description,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}