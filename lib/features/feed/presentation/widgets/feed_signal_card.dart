import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/services/commentaire_service.dart';
import 'package:citoyen_plus/services/reaction_service.dart';
import 'package:citoyen_plus/widgets/commentaires_sheet.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FeedSignalCard extends StatefulWidget {
  final FeedItem item;

  const FeedSignalCard({super.key, required this.item});

  @override
  State<FeedSignalCard> createState() => _FeedSignalCardState();
}

class _FeedSignalCardState extends State<FeedSignalCard> {
  late bool _liked;
  late int _likeCount;
  late int _commentCount;
  bool _likeInFlight = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.item.likedByMe ?? false;
    _likeCount = widget.item.likesCount ?? 0;
    _commentCount = widget.item.commentsCount ?? 0;
  }

  Color get _statusColor {
    switch (widget.item.statut?.toLowerCase()) {
      case 'en_cours':
      case 'nouveau':
        return const Color(0xFFE65C00);
      case 'resolu':
        return const Color(0xFF3B6D11);
      case 'rejete':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF888888);
    }
  }

  Color get _statusTextColor {
    switch (widget.item.statut?.toLowerCase()) {
      case 'en_cours':
      case 'nouveau':
        return const Color(0xFFC44B00);
      case 'resolu':
        return const Color(0xFF3B6D11);
      case 'rejete':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF888888);
    }
  }

  String get _statusLabel {
    switch (widget.item.statut?.toLowerCase()) {
      case 'en_cours':
        return 'En cours';
      case 'nouveau':
        return 'Nouveau';
      case 'resolu':
        return 'Resolu';
      case 'rejete':
        return 'Rejete';
      default:
        return 'Soumis';
    }
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
      final result = await ReactionService.toggleSignalement(widget.item.id);
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
      cible: CommentaireCible.signalement,
      id: widget.item.id,
      onCountChanged: (count) {
        if (mounted) setState(() => _commentCount = count);
      },
    );
  }

  void _share() {
    Share.share('${widget.item.titre}\n${widget.item.description}');
  }

  void _flag() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signalement signale. Merci.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.item.titre} (details a venir)')),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.imageUrl!,
                    height: 140,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 140,
                      color: const Color(0xFFF0F0F0),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 140,
                      color: const Color(0xFFF0F0F0),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.photo_outlined, color: Colors.grey, size: 36),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.location_on,
                                size: 11,
                                color: Color(0xFFC44B00),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Signalement',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFC44B00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: _statusTextColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.ville ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: const Color(0xFFECECEC),
                              child: Text(
                                widget.item.auteurInitiales,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.item.auteurNom} \u2022 ${widget.item.duree}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.flag_outlined,
                              onTap: _flag,
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.mode_comment_outlined,
                              onTap: _openComments,
                            ),
                            if (_commentCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '$_commentCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: _liked
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              color: _liked ? const Color(0xFF1556B5) : null,
                              onTap: _toggleLike,
                            ),
                            if (_likeCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '$_likeCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              onTap: _share,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 16, color: color ?? Colors.grey),
    );
  }
}
