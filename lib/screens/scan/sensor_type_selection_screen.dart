import 'package:flutter/material.dart';
import '../../models/ruuvi_tag.dart';

class SensorTypeSelectionScreen extends StatefulWidget {
  final String ruuviTagId;
  final List<RuuviTagType> usedTypes; // Nouveau paramètre
  final Function(String ruuviTagId, RuuviTagType type) onTypeSelected;

  const SensorTypeSelectionScreen({
    super.key,
    required this.ruuviTagId,
    required this.usedTypes, // Nouveau paramètre
    required this.onTypeSelected,
  });

  @override
  State<SensorTypeSelectionScreen> createState() => _SensorTypeSelectionScreenState();
}

class _SensorTypeSelectionScreenState extends State<SensorTypeSelectionScreen> {
  RuuviTagType? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Type de capteur'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RuuviTag scanné',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.ruuviTagId,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sélectionnez le type de capteur :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...RuuviTagType.values.map((type) => _buildTypeCard(type)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedType != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirmer',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(RuuviTagType type) {
    final isSelected = selectedType == type;
    final isUsed = widget.usedTypes.contains(type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? Theme.of(context).primaryColor.withOpacity(0.1) 
          : isUsed 
              ? Colors.grey.withOpacity(0.3)
              : null,
      child: InkWell(
        onTap: isUsed ? null : () => setState(() => selectedType = type),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getTypeIcon(type),
                size: 32,
                color: isUsed 
                    ? Colors.grey
                    : isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[600],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUsed 
                            ? Colors.grey
                            : isSelected 
                                ? Theme.of(context).primaryColor 
                                : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUsed 
                          ? 'Déjà utilisé'
                          : _getTypeDescription(type),
                      style: TextStyle(
                        fontSize: 14,
                        color: isUsed ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                )
              else if (isUsed)
                Icon(
                  Icons.block,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(RuuviTagType type) {
    switch (type) {
      case RuuviTagType.collar:
        return Icons.pets;
      case RuuviTagType.environment:
        return Icons.home;
      case RuuviTagType.litter:
        return Icons.cleaning_services;
    }
  }

  String _getTypeDescription(RuuviTagType type) {
    switch (type) {
      case RuuviTagType.collar:
        return 'Collier porté par le chat pour suivre son activité';
      case RuuviTagType.environment:
        return 'Capteur d\'environnement (température, humidité)';
      case RuuviTagType.litter:
        return 'Capteur de litière pour surveiller l\'utilisation';
    }
  }

  void _confirmSelection() {
    if (selectedType != null) {
      widget.onTypeSelected(widget.ruuviTagId, selectedType!);
      Navigator.of(context).pop();
    }
  }
} 