import 'package:citoyen_plus/ui/entete.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_action_card.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_signal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedItemType { signalement, action }

class FeedItem {
  final FeedItemType type;
  final String titre;
  final String description;
  final String auteurInitiales;
  final String auteurNom;
  final String duree;
  final String ville;
  final String statut;
  final List<String> hashtags;
  final int points;
  final String? imageUrl;

  const FeedItem({
    required this.type,
    required this.titre,
    required this.description,
    required this.auteurInitiales,
    required this.auteurNom,
    required this.duree,
    required this.ville,
    required this.statut,
    required this.hashtags,
    required this.points,
    this.imageUrl,
  });
}

final feedTabProvider = StateNotifierProvider<FeedTabNotifier, int>((ref) {
  return FeedTabNotifier();
});

class FeedTabNotifier extends StateNotifier<int> {
  FeedTabNotifier() : super(0);

  void select(int index) {
    state = index;
  }
}

class FeedPage extends ConsumerStatefulWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const FeedPage({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = const ['Tous', 'Signalements', 'Actions'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(feedTabProvider.notifier).select(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FeedItem> get _feedItems => const [
    FeedItem(
      type: FeedItemType.signalement,
      titre: 'Nappe d’eau sur le trottoir principal de Cocody',
      description:
          'Les piétons doivent descendre sur la chaussée tous les matins.',
      auteurInitiales: 'MA',
      auteurNom: 'Marie A.',
      duree: '45 min',
      ville: 'Abidjan',
      statut: 'En cours',
      hashtags: [],
      points: 50,
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    ),
    FeedItem(
      type: FeedItemType.signalement,
      titre: 'Éclairage public défectueux rue des Jardins',
      description: 'Des lampadaires sont hors service depuis une semaine.',
      auteurInitiales: 'KD',
      auteurNom: 'Koffi D.',
      duree: '1h',
      ville: 'Yamoussoukro',
      statut: 'Soumis',
      hashtags: [],
      points: 50,
      imageUrl: null,
    ),
    FeedItem(
      type: FeedItemType.signalement,
      titre: 'Poubelles pleines et déchets sur la route principale',
      description: 'Le ramassage n’a pas eu lieu depuis 3 jours.',
      auteurInitiales: 'SA',
      auteurNom: 'Sarra A.',
      duree: '3h',
      ville: 'Bouaké',
      statut: 'Résolu',
      hashtags: [],
      points: 50,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
    ),
    FeedItem(
      type: FeedItemType.action,
      titre: 'Nettoyage citoyen du parc de la liberté',
      description: 'Rassemblement ce samedi pour réduire les déchets verts.',
      auteurInitiales: 'PN',
      auteurNom: 'Paul N.',
      duree: '1 jour',
      ville: 'San Pedro',
      statut: '',
      hashtags: ['#nettoyage', '#environnement'],
      points: 30,
      imageUrl: null,
    ),
    FeedItem(
      type: FeedItemType.action,
      titre: 'Création d’un potager collectif dans le quartier',
      description:
          'Un atelier participatif pour sensibiliser à l’agriculture urbaine.',
      auteurInitiales: 'OK',
      auteurNom: 'Olivier K.',
      duree: '2 jours',
      ville: 'Grand-Bassam',
      statut: '',
      hashtags: ['#solidarité', '#agriculture'],
      points: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1473855966489-0fd6bf8fb364?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  List<FeedItem> _itemsForTab(int index) {
    if (index == 1) {
      return _feedItems
          .where((item) => item.type == FeedItemType.signalement)
          .toList();
    }
    if (index == 2) {
      return _feedItems
          .where((item) => item.type == FeedItemType.action)
          .toList();
    }
    return _feedItems;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(feedTabProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: EntetePersonalise(
        title: 'Accueil',
        onNotificationPressed: widget.onNotificationPressed,
        onSearchPressed: widget.onSearchPressed,
        onProfilePressed: widget.onProfilePressed,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFE65C00),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              indicator: const _CenteredIndicator(
                color: Color(0xFFE65C00),
                height: 3,
                widthFraction: 0.7,
              ),
              indicatorPadding: const EdgeInsets.only(bottom: 6),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              onTap: (value) {
                ref.read(feedTabProvider.notifier).select(value);
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                return _buildListView(_itemsForTab(index));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<FeedItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.type == FeedItemType.signalement) {
            return FeedSignalCard(item: item);
          }
          return FeedActionCard(item: item);
        },
      ),
    );
  }
}

class _CenteredIndicator extends Decoration {
  final Color color;
  final double height;
  final double widthFraction;

  const _CenteredIndicator({
    required this.color,
    this.height = 3,
    this.widthFraction = 0.7,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CenteredIndicatorPainter(color, height, widthFraction);
  }
}

class _CenteredIndicatorPainter extends BoxPainter {
  final Color color;
  final double height;
  final double widthFraction;

  _CenteredIndicatorPainter(this.color, this.height, this.widthFraction);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final width = configuration.size?.width ?? 0;
    final indicatorWidth = width * widthFraction;
    final dx = offset.dx + (width - indicatorWidth) / 2;
    final dy = (configuration.size?.height ?? 0) - height;
    final rect = Rect.fromLTWH(dx, dy, indicatorWidth, height);
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }
}
