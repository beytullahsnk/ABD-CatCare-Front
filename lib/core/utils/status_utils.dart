import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Helpers pour déterminer le statut KPI selon les seuils.
/// Retour: 'ok' | 'warn' | 'alert'
String kpiStatusForTemp(double t) {
  if (t < kTempLow || t > kTempHigh) return 'alert';
  return 'ok';
}

String kpiStatusForHumidity(int h) {
  if (h < kHumidityLow || h > kHumidityHigh) return 'warn';
  return 'ok';
}

String kpiStatusForActivity(int a) {
  if (a < kActivityLow) return 'warn';
  return 'ok';
}

String kpiStatusForLitterHumidity(int h) {
  if (h > kLitterHumidityHigh) return 'alert';
  return 'ok';
}

/// Optionnel: couleur principale de l'icône selon status
Color resolveKpiIconColor(BuildContext context, String status) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case 'alert':
      return cs.error;
    case 'warn':
      return cs.tertiary;
    case 'ok':
    default:
      return cs.secondary;
  }
}
