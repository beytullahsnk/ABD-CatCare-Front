import 'package:flutter/material.dart';
import '../../models/ruuvi_tag.dart';
import '../../models/ruuvi_tag_thresholds.dart';

class ThresholdConfigurationScreen extends StatefulWidget {
  final String ruuviTagId;
  final RuuviTagType type;
  final Function(String ruuviTagId, RuuviTagType type, Map<String, dynamic> thresholds) onThresholdsConfigured;

  const ThresholdConfigurationScreen({
    super.key,
    required this.ruuviTagId,
    required this.type,
    required this.onThresholdsConfigured,
  });

  @override
  State<ThresholdConfigurationScreen> createState() => _ThresholdConfigurationScreenState();
}

class _ThresholdConfigurationScreenState extends State<ThresholdConfigurationScreen> {
  late CollarThresholds _collarThresholds;
  late EnvironmentThresholds _environmentThresholds;
  late LitterThresholds _litterThresholds;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs par défaut
    final defaultThresholds = RuuviTagThresholds.defaultValues();
    _collarThresholds = defaultThresholds.collar;
    _environmentThresholds = defaultThresholds.environment;
    _litterThresholds = defaultThresholds.litter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration - ${widget.type.displayName}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec informations du capteur
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getRuuviTagIcon(widget.type),
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.type.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.ruuviTagId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Configuration des seuils selon le type
            Text(
              'Configuration des seuils d\'alerte',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (widget.type == RuuviTagType.collar) ...[
              _buildCollarConfiguration(),
            ] else if (widget.type == RuuviTagType.environment) ...[
              _buildEnvironmentConfiguration(),
            ] else if (widget.type == RuuviTagType.litter) ...[
              _buildLitterConfiguration(),
            ],

            const SizedBox(height: 32),

            // Bouton de validation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirmer la configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollarConfiguration() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Seuils du collier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Heures d\'inactivité avant alerte',
              value: _collarThresholds.inactivityHours.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              onChanged: (value) {
                setState(() {
                  _collarThresholds = _collarThresholds.copyWith(
                    inactivityHours: value.round(),
                  );
                });
              },
              unit: 'h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentConfiguration() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Seuils d\'environnement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Température minimale',
              value: _environmentThresholds.temperatureMin.toDouble(),
              min: 10,
              max: 30,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _environmentThresholds = _environmentThresholds.copyWith(
                    temperatureMin: value.round(),
                  );
                });
              },
              unit: '°C',
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Température maximale',
              value: _environmentThresholds.temperatureMax.toDouble(),
              min: 20,
              max: 40,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _environmentThresholds = _environmentThresholds.copyWith(
                    temperatureMax: value.round(),
                  );
                });
              },
              unit: '°C',
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Humidité minimale',
              value: _environmentThresholds.humidityMin.toDouble(),
              min: 10,
              max: 50,
              divisions: 40,
              onChanged: (value) {
                setState(() {
                  _environmentThresholds = _environmentThresholds.copyWith(
                    humidityMin: value.round(),
                  );
                });
              },
              unit: '%',
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Humidité maximale',
              value: _environmentThresholds.humidityMax.toDouble(),
              min: 50,
              max: 90,
              divisions: 40,
              onChanged: (value) {
                setState(() {
                  _environmentThresholds = _environmentThresholds.copyWith(
                    humidityMax: value.round(),
                  );
                });
              },
              unit: '%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLitterConfiguration() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Seuils de la litière',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: 'Utilisation quotidienne maximale',
              value: _litterThresholds.dailyUsageMax.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _litterThresholds = _litterThresholds.copyWith(
                    dailyUsageMax: value.round(),
                  );
                });
              },
              unit: 'fois',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}$unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  IconData _getRuuviTagIcon(RuuviTagType type) {
    switch (type) {
      case RuuviTagType.collar:
        return Icons.pets;
      case RuuviTagType.environment:
        return Icons.home;
      case RuuviTagType.litter:
        return Icons.cleaning_services;
    }
  }

  void _saveConfiguration() {
    try {
      print('Sauvegarde de la configuration pour ${widget.type.displayName}');
      
      Map<String, dynamic> thresholds;
      
      switch (widget.type) {
        case RuuviTagType.collar:
          thresholds = _collarThresholds.toJson();
          print('Seuils collier: $thresholds');
          break;
        case RuuviTagType.environment:
          thresholds = _environmentThresholds.toJson();
          print('Seuils environnement: $thresholds');
          break;
        case RuuviTagType.litter:
          thresholds = _litterThresholds.toJson();
          print('Seuils litiere: $thresholds');
          break;
      }

      print('Appel du callback avec les seuils');
      widget.onThresholdsConfigured(widget.ruuviTagId, widget.type, thresholds);

      print('Configuration sauvegardee');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
} 