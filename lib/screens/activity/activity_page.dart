import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_provider.dart';
import '../../core/services/api_service.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _activityData;
  List<Map<String, dynamic>> _activityHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchActivityData();
  }

  Future<void> _fetchActivityData() async {
    setState(() {
      _loading = true;
    });

    try {
      final api = ApiProvider.instance.get();
      if (api is RealApiService) {
        final catId = await api.getUserCatId();
        
        if (catId != null) {
          // Récupérer les dernières données
          final data = await api.fetchLatestSensorData(catId);
          setState(() {
            _activityData = data?['collar'];
          });

          // Récupérer l'historique des 10 dernières activités
          final history = await api.getActivityHistory(catId, limit: 10);
          setState(() {
            _activityHistory = history ?? [];
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des données d\'activité: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatActivityTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes}min';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours}h';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Timestamp invalide';
    }
  }

  String _formatExactTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Activité"),
        centerTitle: true,
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/activity'),
            tooltip: 'Paramètres des seuils',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchActivityData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        // Statistiques d'activité (si disponibles)
                        if (_activityData != null) ...[
              const Text(
                            "Dernière activité",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                            children: [
                  Expanded(
                                child: _StatCard(
                                  title: "Dernière activité",
                                  value: _activityData!['timestamp'] != null
                                      ? _formatActivityTime(_activityData!['timestamp'])
                                      : "N/A",
                                ),
                  ),
                ],
              ),
                          const SizedBox(height: 24),
              const Text(
                            "Historique des activités",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _activityHistory.isNotEmpty
                                ? ListView.builder(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: _activityHistory.length,
                                    itemBuilder: (context, index) {
                                      final activity = _activityHistory[index];
                                      final timestamp = activity['timestamp'] as String?;
                                      final movement = double.tryParse(activity['movement']?.toString() ?? '0') ?? 0.0;
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              movement > 0.5
                                                  ? Icons.pets
                                                  : Icons.bedtime,
                                              color: movement > 0.5
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    timestamp != null
                                                        ? _formatActivityTime(timestamp)
                                                        : "N/A",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    movement > 0.5
                                                        ? "Mouvement détecté"
                                                        : "Au repos",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              timestamp != null
                                                  ? _formatExactTime(timestamp)
                                                  : "N/A",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      "Aucun historique disponible",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ] else ...[
                          // Message d'information seulement quand il n'y a pas de données
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Les données d\'activité seront disponibles une fois que les capteurs commenceront à envoyer des données.',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
              ),
              const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.pets, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'En attente des données des capteurs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
