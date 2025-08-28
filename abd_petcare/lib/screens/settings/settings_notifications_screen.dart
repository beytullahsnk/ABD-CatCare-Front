import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// modèle simple pour l'exemple
class NotificationItem {
  final String id;
  final String title;
  final String type; // 'activity' | 'litter' | 'environment'
  final DateTime date;
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.icon,
  });
}

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> with TickerProviderStateMixin {
  // exemple de données (remplace par ton API)
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Activité accrue détectée',
      type: 'activity',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.favorite_border,
    ),
    NotificationItem(
      id: '2',
      title: 'Action requise : Utilisation de la litière',
      type: 'litter',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      icon: Icons.inventory_2,
    ),
    NotificationItem(
      id: '3',
      title: 'Utilisation de la litière',
      type: 'litter',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      icon: Icons.inventory_2,
    ),
    NotificationItem(
      id: '4',
      title: 'Changement de température',
      type: 'environment',
      date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      icon: Icons.thermostat,
    ),
    NotificationItem(
      id: '5',
      title: 'Activité accrue détectée',
      type: 'activity',
      date: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
      icon: Icons.favorite_border,
    ),
  ];

  int _bottomIndex = 1; // notifications selected
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    // aujourd'hui -> "10h30"
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h' 'h$m';
    }

    // hier -> "Hier, 20h30"
    if (diff.inDays == 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hier, $h' 'h$m';
    }

    // >1 jour -> "Il y a X jours, HHhMM"
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return 'Il y a ${diff.inDays} jours, $h' 'h$m';
  }

  List<NotificationItem> _filterForTab(int tabIndex) {
    if (tabIndex == 0) return _notifications;
    if (tabIndex == 1) {
      return _notifications.where((n) => n.type == 'activity').toList();
    }
    // tabIndex == 2 -> litter
    return _notifications.where((n) => n.type == 'litter').toList();
  }

  Widget _buildListFor(int tabIndex) {
    final items = _filterForTab(tabIndex);
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune notification pour cette catégorie.'),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final n = items[index];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(n.icon, color: cs.onSecondaryContainer),
          ),
          title: Text(
            n.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              _formatTimestamp(n.date),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.primary),
            ),
          ),
          onTap: () {
            // exemple : ouvrir detail (à adapter)
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // TabBar row (comme sur la maquette)
          Material(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: cs.onSurface,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              indicatorWeight: 2.5,
              labelStyle: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Tout'),
                Tab(text: 'Activité'),
                Tab(text: 'Litière'),
              ],
            ),
          ),

          // contenu
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListFor(0),
                _buildListFor(1),
                _buildListFor(2),
              ],
            ),
          ),
        ],
      ),

      // bottom navigation similaire à la maquette
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);
          // si tu utilises go_router, tu peux naviguer ici :
          // if (i == 0) context.go('/home');
          // if (i == 1) context.go('/notifications');
          // ...
        },
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined,
                color: _bottomIndex == 0 ? cs.primary : cs.onSurfaceVariant),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none,
                color: _bottomIndex == 1 ? cs.primary : cs.onSurfaceVariant),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined,
                color: _bottomIndex == 2 ? cs.primary : cs.onSurfaceVariant),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline,
                color: _bottomIndex == 3 ? cs.primary : cs.onSurfaceVariant),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
