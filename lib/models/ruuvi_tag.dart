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
  final String ruuviTagId;
  final RuuviTagType type;
  final String? name;
  final String? description;
  final bool isActive;

  const RuuviTag({
    required this.id,
    required this.ruuviTagId,
    required this.type,
    this.name,
    this.description,
    this.isActive = true,
  });

  factory RuuviTag.fromJson(Map<String, dynamic> json) => RuuviTag(
        id: json['id'] as String? ?? '',
        ruuviTagId: json['ruuviTagId'] as String? ?? '',
        type: RuuviTagType.values.firstWhere(
          (e) => e.value == json['type'],
          orElse: () => RuuviTagType.environment,
        ),
        name: json['name'] as String?,
        description: json['description'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'ruuviTagId': ruuviTagId,
        'type': type.value,
        'name': name,
        'description': description,
        'isActive': isActive,
      };

  RuuviTag copyWith({
    String? id,
    String? ruuviTagId,
    RuuviTagType? type,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return RuuviTag(
      id: id ?? this.id,
      ruuviTagId: ruuviTagId ?? this.ruuviTagId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
} 