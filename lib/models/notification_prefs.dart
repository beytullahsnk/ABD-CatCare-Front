class NotificationPrefs {
  final bool activity;
  final bool environment;
  final bool litter;
  final String channel; // 'push' | 'email' | 'both'

  const NotificationPrefs({
    required this.activity,
    required this.environment,
    required this.litter,
    required this.channel,
  });

  factory NotificationPrefs.defaults() => const NotificationPrefs(
        activity: true,
        environment: true,
        litter: true,
        channel: 'both',
      );

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        activity: json['activity'] as bool? ?? true,
        environment: json['environment'] as bool? ?? true,
        litter: json['litter'] as bool? ?? true,
        channel: json['channel'] as String? ?? 'both',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'activity': activity,
        'environment': environment,
        'litter': litter,
        'channel': channel,
      };
}
