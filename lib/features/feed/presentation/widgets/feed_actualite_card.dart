import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/actualite_detail_view.dart';
import 'package:citoyen_plus/services/commentaire_service.dart';
import 'package:citoyen_plus/services/reaction_service.dart';
import 'package:citoyen_plus/core/network/error_handler.dart';
import 'package:citoyen_plus/widgets/commentaires_sheet.dart';
import 'package:citoyen_plus/widgets/simple_html_view.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FeedActualiteCard extends StatefulWidget {
  final FeedItem item;

  const FeedActualiteCard({super.key, required this.item});

  @override
  State<FeedActualiteCard> createState() => _FeedActualiteCardState();
}

class _FeedActualiteCardState extends State<FeedActualiteCard> {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = previousLiked;
        _likeCount = previousCount;
        _likeInFlight = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like impossible : ${HttpErrorHandler.describe(e)}')),
      );
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
    Share.share(
        '${widget.item.titre}\n${htmlToPlainText(widget.item.description)}');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActualiteDetailView(item: widget.item),
            ),
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
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: const Color(0xFFF0F0F0),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
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
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.article_outlined,
                            size: 11,
                            color: Color(0xFF185FA5),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Actualite',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF185FA5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                    const SizedBox(height: 6),
                    Text(
                      htmlToPlainText(widget.item.description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    if (widget.item.sourceInstitution != null &&
                        widget.item.sourceInstitution!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F1FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.item.sourceInstitution!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF185FA5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFECECEC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.item.auteurInitiales,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
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
