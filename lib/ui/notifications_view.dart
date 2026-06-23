import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mes_signalements_service.dart';

class NotificationView extends StatefulWidget {
  final VoidCallback? onMesActionsPressed;
  const NotificationView({super.key, this.onMesActionsPressed});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Toutes', 'Récents', 'Résolus'];
  Future<List<Map<String, dynamic>>>? _futureNotifications;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await AuthService.getToken();
    if (!mounted) return;
    setState(() {
      _futureNotifications =
          token == null ? Future.value([]) : _loadActivites();
    });
  }

  /// L'« Activité » du citoyen correspond à ses signalements (mêmes données que
  /// la page « Mes actions »). Endpoint : GET /signalement-citoyen/me
  /// (citoyen déduit du JWT). Il n'existe pas d'endpoint GET /notifications
  /// côté backend.
  Future<List<Map<String, dynamic>>> _loadActivites() async {
    final signalements = await MesSignalementsService.fetchMesSignalements();
    return signalements
        .map((s) => <String, dynamic>{
              'title': s.titre,
              'message': s.description,
              'status': s.statut,
              'createdAt': s.createdAt?.toIso8601String(),
            })
        .toList();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    switch (_selectedTab) {
      case 1:
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        return all.where((item) {
          final raw = item['createdAt'] ?? item['date'] ?? item['dateTime'];
          final date = _parseDate(raw);
          return date != null && date.isAfter(cutoff);
        }).toList();
      case 2:
        return all.where((item) {
          final status = (item['status'] ?? item['statut'] ?? '').toString().toLowerCase();
          return status.contains('résolu') || status.contains('resolu') || status.contains('closed');
        }).toList();
      default:
        return all;
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Activité',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onMesActionsPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.list_alt_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text('Mes actions', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = _selectedTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white54,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureNotifications,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE65C00)),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                          const SizedBox(height: 12),
                          const Text('Erreur de chargement', style: TextStyle(color: Colors.white38, fontSize: 14)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _load, child: const Text('Réessayer', style: TextStyle(color: Color(0xFFE65C00)))),
                        ],
                      ),
                    );
                  }

                  final all = snapshot.data ?? [];
                  final notifications = _filtered(all);

                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 52),
                          SizedBox(height: 12),
                          Text('Aucune activité pour le moment', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFFE65C00),
                    backgroundColor: const Color(0xFF1C1C1C),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _NotificationTile(notification: notifications[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationTile({required this.notification});

  Color get _statusColor {
    final status = (notification['status'] ?? notification['statut'] ?? '').toString().toLowerCase();
    if (status.contains('résolu') || status.contains('resolu') || status.contains('fermé') || status.contains('closed')) {
      return const Color(0xFF34C759);
    }
    if (status.contains('en cours') || status.contains('encours') || status.contains('pending')) {
      return const Color(0xFFE65C00);
    }
    if (status.contains('rejeté') || status.contains('rejet') || status.contains('rejected')) {
      return const Color(0xFFFF2D55);
    }
    return const Color(0xFF1556B5);
  }

  String get _title {
    return notification['title']?.toString() ?? notification['subject']?.toString() ?? 'Notification citoyenne';
  }

  String get _subtitle {
    return notification['message']?.toString() ?? notification['description']?.toString() ?? notification['body']?.toString() ?? '';
  }

  String get _timeAgo {
    final raw = notification['createdAt'] ?? notification['date'] ?? notification['dateTime'];
    if (raw == null) return '';
    try {
      final date = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours} h';
      if (diff.inDays < 7) return '${diff.inDays} j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = notification['status']?.toString().toUpperCase() ?? 'N/A';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_rounded, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                if (_subtitle.isNotEmpty)
                  Text(_subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(_timeAgo, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
