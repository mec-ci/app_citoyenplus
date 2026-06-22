import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FeedActionCard extends StatefulWidget {
  final FeedItem item;

  const FeedActionCard({super.key, required this.item});

  @override
  State<FeedActionCard> createState() => _FeedActionCardState();
}

class _FeedActionCardState extends State<FeedActionCard> {
  bool _liked = false;
  int _likeCount = 0;

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _share() {
    Share.share('${widget.item.titre}\n${widget.item.description}');
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
                        color: const Color(0xFFEAF3DE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.favorite_outline,
                            size: 11,
                            color: Color(0xFF3B6D11),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Action citoyenne',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF3B6D11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.titre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
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
                              icon: _liked
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: _liked ? const Color(0xFF3B6D11) : null,
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
