import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/feed_page.dart';
import 'package:flutter/material.dart';

class FeedSignalCard extends StatelessWidget {
  final FeedItem item;

  const FeedSignalCard({super.key, required this.item});

  Color get _statusColor {
    switch (item.statut) {
      case 'En cours':
        return const Color(0xFFE65C00);
      case 'Résolu':
        return const Color(0xFF3B6D11);
      default:
        return const Color(0xFF888888);
    }
  }

  Color get _statusTextColor {
    switch (item.statut) {
      case 'En cours':
        return const Color(0xFFE65C00);
      case 'Résolu':
        return const Color(0xFF3B6D11);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
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
            padding: const EdgeInsets.all(10),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+${item.points} pts',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFC44B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
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
                          item.statut,
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
                          item.ville,
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
                            item.auteurInitiales,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.auteurNom} • ${item.duree}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                        SizedBox(width: 10),
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: Colors.grey,
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
    );
  }
}
