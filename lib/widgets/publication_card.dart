import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/publication.dart';

class PublicationCard extends StatefulWidget {
  final Publication publication;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PublicationCard({
    super.key,
    required this.publication,
    this.onProfileTap,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  late bool _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.publication.liked;
    _likesCount = widget.publication.likesCount;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  void _share() {
    final text = '${widget.publication.authorName} · ${widget.publication.categorie}\n\n${widget.publication.texte}';
    Share.share(text);
    widget.onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
      final timeLabel = _timeAgo(publication.createdAt);
    final avatarInitial = publication.authorName.isNotEmpty ? publication.authorName[0].toUpperCase() : 'C';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1556B5),
                    child: publication.authorAvatar != null && publication.authorAvatar!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              publication.authorAvatar!,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                              errorBuilder: (_, __, ___) => Text(
                                avatarInitial,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                          )
                        : Text(
                            avatarInitial,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            publication.categorie.isNotEmpty ? publication.categorie : publication.type,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          if (publication.localisation != null && publication.localisation!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.place, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                publication.localisation!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  timeLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (publication.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              child: Image.network(
                publication.images.first,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 190,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(
              publication.texte,
              style: const TextStyle(fontSize: 14, height: 1.55, color: Colors.black87),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _liked ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: _liked ? Colors.redAccent : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likesCount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _liked ? Colors.redAccent : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: widget.onComment,
                  child: Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, size: 22, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        '${publication.commentsCount}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _share,
                  child: const Icon(Icons.share_outlined, size: 22, color: Colors.black87),
                ),
                const Spacer(),
                if (publication.statut != null && publication.statut!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: publication.statut!.toLowerCase().contains('résolu') || publication.statut!.toLowerCase().contains('resolu')
                          ? const Color(0xFFEDF7EF)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      publication.statut!,
                      style: TextStyle(
                        color: publication.statut!.toLowerCase().contains('résolu') || publication.statut!.toLowerCase().contains('resolu')
                            ? const Color(0xFF1E7A3F)
                            : const Color(0xFFB45A00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }
}
