class Cat {
  final String id;
  final String name;
  final int ageMonths;
  final String? breed;

  const Cat({
    required this.id,
    required this.name,
    required this.ageMonths,
    this.breed,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        ageMonths: (json['ageMonths'] as num?)?.toInt() ?? 0,
        breed: json['breed'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'ageMonths': ageMonths,
        'breed': breed,
      };
}
