enum RuuviTagType {
  collar('COLLAR', 'Collier'),
  environment('ENVIRONMENT', 'Environnement'),
  litter('LITTER', 'Litière');

  const RuuviTagType(this.value, this.displayName);
  final String value;
  final String displayName;
}

class RuuviTag {
  final String id;
  final RuuviTagType type;
  final List<String>? catIds;
  final Map<String, dynamic>? alertThresholds; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RuuviTag({
    required this.id,
    required this.type,
    this.catIds,
    this.alertThresholds,
    this.createdAt,
    this.updatedAt,
  });

  factory RuuviTag.fromJson(Map<String, dynamic> json) => RuuviTag(
        id: json['id'] as String? ?? '',
        type: RuuviTagType.values.firstWhere(
          (e) => e.value == json['type'],
          orElse: () => RuuviTagType.environment,
        ),
        catIds: (json['catIds'] as List?)?.cast<String>(),
        alertThresholds: json['alertThresholds'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.value,
        'catIds': catIds,
        'alertThresholds': alertThresholds,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  RuuviTag copyWith({
    String? id,
    RuuviTagType? type,
    List<String>? catIds,
    Map<String, dynamic>? alertThresholds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RuuviTag(
      id: id ?? this.id,
      type: type ?? this.type,
      catIds: catIds ?? this.catIds,
      alertThresholds: alertThresholds ?? this.alertThresholds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 