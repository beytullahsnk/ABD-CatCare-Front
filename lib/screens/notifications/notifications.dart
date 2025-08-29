import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:abd_petcare/core/services/api_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiProvider.instance.get();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getUserNotifications(limit: 50, offset: 0);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cs.error,
          content: const Text('Impossible de charger les notifications'),
        ),
      );
    }
  }

  // Note: plus d'auto "lu" à l'ouverture; on marque comme lu au tap.

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    String two(int v) => v.toString().padLeft(2, '0');
    if (diff.inDays == 0) return '${two(dt.hour)}h${two(dt.minute)}';
    if (diff.inDays == 1) return 'Hier, ${two(dt.hour)}h${two(dt.minute)}';
    return 'Il y a ${diff.inDays} jours, ${two(dt.hour)}h${two(dt.minute)}';
  }

  List<Map<String, dynamic>> _filterForTab(int tabIndex) {
    if (tabIndex == 0) return _items;
    final key = tabIndex == 1
        ? 'activity'
        : tabIndex == 2
            ? 'litter'
            : 'environment';
    return _items
        .where((n) => (n['category'] ?? _mapTypeToCategory(n['type'])) == key)
        .toList();
  }

  String _mapTypeToCategory(dynamic type) {
    switch (type?.toString().toUpperCase()) {
      case 'MOVEMENT':
      case 'INACTIVITY':
        return 'activity';
      case 'LITTER':
        return 'litter';
      case 'TEMPERATURE':
      case 'HUMIDITY':
        return 'environment';
      default:
        return 'activity';
    }
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
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = items[index];
          final title = (n['title'] ?? '-') as String;
          final createdAt = DateTime.tryParse((n['createdAt'] ??
                      n['timestamp'] ??
                      DateTime.now().toIso8601String())
                  .toString()) ??
              DateTime.now();
          final category =
              (n['category'] ?? _mapTypeToCategory(n['type'])) as String;
          final icon = _iconFor(category);
          final isRead = n['readAt'] != null;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: cs.onSecondaryContainer),
                ),
                if (!isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                _formatTimestamp(createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isRead ? cs.onSurfaceVariant : cs.primary,
                    ),
              ),
            ),
            onTap: () async {
              // Marque comme lu lors du tap si nécessaire
              if (n['readAt'] == null && n['id'] is String) {
                try {
                  await _api.markNotificationRead(n['id'] as String);
                  if (mounted) {
                    setState(() {
                      final idx = _items.indexWhere((e) => e['id'] == n['id']);
                      if (idx != -1) {
                        final updated = Map<String, dynamic>.from(_items[idx]);
                        updated['readAt'] = DateTime.now().toIso8601String();
                        _items = List.from(_items)..[idx] = updated;
                      }
                    });
                  }
                } catch (_) {
                  // Non bloquant
                }
              }

              final actionUrl =
                  n['data'] is Map ? (n['data']['actionUrl'] as String?) : null;
              if (actionUrl != null && actionUrl.isNotEmpty) {
                context.push(actionUrl);
              }
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'litter':
        return Icons.inventory_2;
      case 'environment':
        return Icons.thermostat;
      case 'activity':
      default:
        return Icons.favorite_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Notifications'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: TabBar(
                isScrollable: false,
                labelStyle: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Tout'),
                  Tab(text: 'Activité'),
                  Tab(text: 'Litière'),
                  Tab(text: 'Environnement'),
                ],
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildListFor(0),
                  _buildListFor(1),
                  _buildListFor(2),
                  _buildListFor(3),
                ],
              ),
      ),
    );
  }
}
