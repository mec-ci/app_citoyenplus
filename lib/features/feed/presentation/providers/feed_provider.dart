import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citoyen_plus/services/api_service.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/models/post.dart';
import 'package:citoyen_plus/models/signalement.dart';

class FeedState {
  final List<FeedItem> items;
  final bool isLoading;
  final String? error;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  FeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _fetchSignalements(),
        _fetchActualites(),
      ]);

      final allItems = <FeedItem>[];
      for (final list in results) {
        allItems.addAll(list);
      }
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = FeedState(items: allItems, isLoading: false);
    } catch (e) {
      state = FeedState(
        items: state.items,
        isLoading: false,
        error: 'Erreur lors du chargement du fil.',
      );
    }
  }

  Future<List<FeedItem>> _fetchSignalements() async {
    try {
      final signalements = await ApiService.fetchSignalements();
      return signalements.map(_mapSignalementToFeedItem).toList();
    } catch (_) {
      return [];
    }
  }

  FeedItem _mapSignalementToFeedItem(SignalementModel s) {
    return FeedItem(
      type: FeedType.signalement,
      id: s.id,
      titre: s.titre,
      description: s.description,
      imageUrl: s.photo,
      createdAt: s.createdAt ?? DateTime.now(),
      statut: s.statut,
      adresse: s.adresse,
      latitude: s.latitude,
      longitude: s.longitude,
      categorieNom: s.categorie?.nom,
      likesCount: s.likesCount,
      commentsCount: s.commentsCount,
      likedByMe: s.likedByMe,
    );
  }

  Future<List<FeedItem>> _fetchActualites() async {
    try {
      final posts = await ApiService.fetchPosts();
      return posts.where((p) => p.createdAt != null).map(_mapPostToFeedItem).toList();
    } catch (_) {
      return [];
    }
  }

  FeedItem _mapPostToFeedItem(PostModel post) {
    final title = post.title;
    return FeedItem(
      type: FeedType.actualite,
      id: post.id,
      titre: title,
      description: post.excerpt.isNotEmpty ? post.excerpt : post.content,
      imageUrl: post.imageUrl,
      slug: post.slug,
      createdAt: post.createdAt ?? post.date,
      auteurInitiales: 'OF',
      auteurNom: 'Officiel',
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      likedByMe: post.likedByMe,
    );
  }

  Future<void> refresh() async {
    await fetchAll();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
