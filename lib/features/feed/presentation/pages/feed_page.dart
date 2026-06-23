import 'package:citoyen_plus/ui/entete.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/feed_provider.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/signalement_provider.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_action_card.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_actualite_card.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/signalements_map_page.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_signal_card.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/feed_shimmer.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/signalement_card.dart';
import 'package:citoyen_plus/features/feed/presentation/widgets/signalement_shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final ScrollController _signalementScrollController = ScrollController();
  final List<String> _tabs = const ['Tous', 'Signalements', 'Actualites'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(feedTabProvider.notifier).select(_tabController.index);
      }
    });
    // Défilement infini de l'onglet « Signalements » : charge la page suivante
    // lorsqu'on approche du bas de la liste.
    _signalementScrollController.addListener(_onSignalementScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalementProvider.notifier).fetchSignalements(page: 1);
      ref.read(feedProvider.notifier).fetchAll();
    });
  }

  void _onSignalementScroll() {
    final position = _signalementScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(signalementProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _signalementScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(feedTabProvider);
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                ),
              ),
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
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                if (index == 1) {
                  final signalementState = ref.watch(signalementProvider);
                  return _buildSignalementTab(signalementState);
                }
                return _buildFeedTab(feedState, index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab(FeedState state, int index) {
    if (state.isLoading && state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ListView.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const FeedShimmer(),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65C00),
                ),
                onPressed: () =>
                    ref.read(feedProvider.notifier).refresh(),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final items = index == 0
        ? state.items
        : state.items.where((i) => i.type == FeedType.actualite).toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun contenu pour le moment.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.type == FeedType.signalement) {
              return FeedSignalCard(item: item);
            }
            if (item.type == FeedType.actualite) {
              return FeedActualiteCard(item: item);
            }
            return FeedActionCard(item: item);
          },
        ),
      ),
    );
  }

  Widget _buildSignalementTab(SignalementState state) {
    if (state.isLoading && state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ListView.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const SignalementShimmerCard(),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65C00),
                ),
                onPressed: () =>
                    ref.read(signalementProvider.notifier).refresh(),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Column(
        children: [
          _buildMapButton(),
          const Expanded(
            child: Center(child: Text('Aucun signalement trouve.')),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildMapButton(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(signalementProvider.notifier).refresh(),
              child: ListView.separated(
                controller: _signalementScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                // +1 pour le pied de liste (loader d'infinite scroll).
                itemCount: state.items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return _buildListFooter(state);
                  }
                  return SignalementCard(signalement: state.items[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter(SignalementState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFE65C00),
            ),
          ),
        ),
      );
    }
    if (!state.hasNextPage && state.items.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Vous avez tout vu.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMapButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE65C00),
            side: const BorderSide(color: Color(0xFFE65C00)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignalementsMapPage()),
          ),
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Voir les signalements à proximité'),
        ),
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
