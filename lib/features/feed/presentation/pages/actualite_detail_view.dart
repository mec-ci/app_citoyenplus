import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/models/post.dart';
import 'package:citoyen_plus/services/api_service.dart';
import 'package:citoyen_plus/services/commentaire_service.dart';
import 'package:citoyen_plus/services/reaction_service.dart';
import 'package:citoyen_plus/widgets/commentaires_sheet.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

const _blue = Color(0xFF1556B5);

/// Écran d'affichage complet d'une actualité.
///
/// Affiche immédiatement les informations déjà connues (image, titre, extrait)
/// à partir du [FeedItem], puis récupère le contenu complet via
/// `GET /actualites/:id`. Permet de liker, commenter et partager l'article.
class ActualiteDetailView extends StatefulWidget {
  const ActualiteDetailView({super.key, required this.item});

  final FeedItem item;

  @override
  State<ActualiteDetailView> createState() => _ActualiteDetailViewState();
}

class _ActualiteDetailViewState extends State<ActualiteDetailView> {
  PostModel? _post;
  bool _isLoading = true;
  String? _error;

  late bool _liked;
  late int _likeCount;
  late int _commentCount;
  bool _likeInFlight = false;

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  void initState() {
    super.initState();
    _liked = widget.item.likedByMe ?? false;
    _likeCount = widget.item.likesCount ?? 0;
    _commentCount = widget.item.commentsCount ?? 0;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await ApiService.fetchPostById(widget.item.id);
      if (!mounted) return;
      setState(() {
        _post = post;
        _isLoading = false;
        // Rafraîchit les compteurs d'engagement avec les valeurs serveur.
        _liked = post.likedByMe ?? _liked;
        _likeCount = post.likesCount ?? _likeCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger l’article.';
      });
    }
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final previousLiked = _liked;
    final previousCount = _likeCount;
    setState(() {
      _likeInFlight = true;
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
      if (_likeCount < 0) _likeCount = 0;
    });
    try {
      final result = await ReactionService.toggleActualite(widget.item.id);
      if (!mounted) return;
      setState(() {
        _liked = result.liked;
        _likeCount = result.likesCount;
        _likeInFlight = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = previousLiked;
        _likeCount = previousCount;
        _likeInFlight = false;
      });
    }
  }

  void _openComments() {
    showCommentairesSheet(
      context,
      cible: CommentaireCible.actualite,
      id: widget.item.id,
      onCountChanged: (count) {
        if (mounted) setState(() => _commentCount = count);
      },
    );
  }

  void _share() {
    final body = _post?.content.isNotEmpty == true
        ? _post!.content
        : widget.item.description;
    Share.share('${widget.item.titre}\n\n$body');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _post?.imageUrl ?? widget.item.imageUrl;
    final date = _post?.date ?? widget.item.createdAt;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Actualité'),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildActionBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 48),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.article_outlined,
                            size: 13, color: Color(0xFF185FA5)),
                        SizedBox(width: 5),
                        Text(
                          'Actualité',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF185FA5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.item.titre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                      if (widget.item.sourceInstitution != null &&
                          widget.item.sourceInstitution!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.account_balance_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.item.sourceInstitution!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 32),
                  _buildBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final content = _post?.content;
    if (content != null && content.isNotEmpty) {
      return Text(
        content,
        style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
      );
    }

    // Repli : si le contenu complet n'a pas pu être chargé, on affiche au moins
    // l'extrait déjà disponible, avec une option pour réessayer.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.description,
          style: const TextStyle(
              fontSize: 15, height: 1.6, color: Colors.black87),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: _loadDetail,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BarButton(
              icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: _likeCount > 0 ? '$_likeCount' : 'J’aime',
              color: _liked ? _blue : null,
              onTap: _toggleLike,
            ),
            _BarButton(
              icon: Icons.mode_comment_outlined,
              label: _commentCount > 0 ? '$_commentCount' : 'Commenter',
              onTap: _openComments,
            ),
            _BarButton(
              icon: Icons.share_outlined,
              label: 'Partager',
              onTap: _share,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
