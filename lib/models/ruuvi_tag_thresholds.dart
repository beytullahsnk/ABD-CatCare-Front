class RuuviTagThresholds {
  final CollarThresholds collar;
  final EnvironmentThresholds environment;
  final LitterThresholds litter;

  const RuuviTagThresholds({
    required this.collar,
    required this.environment,
    required this.litter,
  });

  factory RuuviTagThresholds.defaultValues() {
    return const RuuviTagThresholds(
      collar: CollarThresholds(inactivityHours: 4),
      environment: EnvironmentThresholds(
        temperatureMin: 18,
        temperatureMax: 28,
        humidityMin: 30,
        humidityMax: 70,
      ),
      litter: LitterThresholds(dailyUsageMax: 8),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collar': collar.toJson(),
      'environment': environment.toJson(),
      'litter': litter.toJson(),
    };
  }

  factory RuuviTagThresholds.fromJson(Map<String, dynamic> json) {
    return RuuviTagThresholds(
      collar: CollarThresholds.fromJson(json['collar'] ?? {}),
      environment: EnvironmentThresholds.fromJson(json['environment'] ?? {}),
      litter: LitterThresholds.fromJson(json['litter'] ?? {}),
    );
  }

  RuuviTagThresholds copyWith({
    CollarThresholds? collar,
    EnvironmentThresholds? environment,
    LitterThresholds? litter,
  }) {
    return RuuviTagThresholds(
      collar: collar ?? this.collar,
      environment: environment ?? this.environment,
      litter: litter ?? this.litter,
    );
  }
}

class CollarThresholds {
  final int inactivityHours;

  const CollarThresholds({
    required this.inactivityHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'inactivityHours': inactivityHours,
    };
  }

  factory CollarThresholds.fromJson(Map<String, dynamic> json) {
    return CollarThresholds(
      inactivityHours: json['inactivityHours'] as int? ?? 4,
    );
  }

  CollarThresholds copyWith({
    int? inactivityHours,
  }) {
    return CollarThresholds(
      inactivityHours: inactivityHours ?? this.inactivityHours,
    );
  }
}

class EnvironmentThresholds {
  final int temperatureMin;
  final int temperatureMax;
  final int humidityMin;
  final int humidityMax;

  const EnvironmentThresholds({
    required this.temperatureMin,
    required this.temperatureMax,
    required this.humidityMin,
    required this.humidityMax,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'humidityMin': humidityMin,
      'humidityMax': humidityMax,
    };
  }

  factory EnvironmentThresholds.fromJson(Map<String, dynamic> json) {
    return EnvironmentThresholds(
      temperatureMin: json['temperatureMin'] as int? ?? 18,
      temperatureMax: json['temperatureMax'] as int? ?? 28,
      humidityMin: json['humidityMin'] as int? ?? 30,
      humidityMax: json['humidityMax'] as int? ?? 70,
    );
  }

  EnvironmentThresholds copyWith({
    int? temperatureMin,
    int? temperatureMax,
    int? humidityMin,
    int? humidityMax,
  }) {
    return EnvironmentThresholds(
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      humidityMin: humidityMin ?? this.humidityMin,
      humidityMax: humidityMax ?? this.humidityMax,
    );
  }
}

class LitterThresholds {
  final int dailyUsageMax;

  const LitterThresholds({
    required this.dailyUsageMax,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyUsageMax': dailyUsageMax,
    };
  }

  factory LitterThresholds.fromJson(Map<String, dynamic> json) {
    return LitterThresholds(
      dailyUsageMax: json['dailyUsageMax'] as int? ?? 8,
    );
  }

  LitterThresholds copyWith({
    int? dailyUsageMax,
  }) {
    return LitterThresholds(
      dailyUsageMax: dailyUsageMax ?? this.dailyUsageMax,
    );
  }
} 