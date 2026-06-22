import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/features/feed/domain/models/signalement.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/signalement_detail_view.dart';
import 'package:flutter/material.dart';

class SignalementCard extends StatelessWidget {
  final Signalement signalement;

  const SignalementCard({super.key, required this.signalement});

  /// Convertit le signalement en FeedItem pour réutiliser l'écran de détail.
  FeedItem _toFeedItem() {
    return FeedItem(
      type: FeedType.signalement,
      id: signalement.id,
      titre: signalement.titre,
      description: signalement.description,
      imageUrl: signalement.photo,
      adresse: signalement.adresse,
      statut: signalement.statut,
      latitude: signalement.latitude,
      longitude: signalement.longitude,
      categorieNom: signalement.categorie?.nom,
      createdAt: signalement.createdAt,
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignalementDetailView(item: _toFeedItem()),
      ),
    );
  }

  String get _statusLabel {
    switch (signalement.statut.toUpperCase()) {
      case 'EN_COURS':
        return 'En cours';
      case 'RESOLU':
        return 'Résolu';
      case 'REJETE':
        return 'Rejeté';
      case 'NOUVEAU':
        return 'Nouveau';
      default:
        return 'Soumis';
    }
  }

  Color get _statusColor {
    switch (signalement.statut.toUpperCase()) {
      case 'EN_COURS':
        return const Color(0xFFE65C00);
      case 'RESOLU':
        return const Color(0xFF3B6D11);
      case 'REJETE':
        return const Color(0xFFFF2D55);
      default:
        return const Color(0xFF888888);
    }
  }

  Color get _statusTextColor {
    switch (signalement.statut.toUpperCase()) {
      case 'EN_COURS':
        return const Color(0xFFC44B00);
      case 'RESOLU':
        return const Color(0xFF3B6D11);
      case 'REJETE':
        return const Color(0xFFCC2244);
      default:
        return const Color(0xFF888888);
    }
  }

  String get _shortAdresse {
    final parts = signalement.adresse.split(',');
    return parts.isNotEmpty ? parts.first.trim() : signalement.adresse;
  }

  String _timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours}h';
    }
    if (duration.inDays == 1) {
      return 'hier';
    }
    if (duration.inDays < 30) {
      return '${duration.inDays}j';
    }
    if (duration.inDays < 365) {
      final months = (duration.inDays / 30).floor();
      return '${months}mois';
    }
    final years = (duration.inDays / 365).floor();
    return '${years}ans';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (signalement.photo != null && signalement.photo!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: signalement.photo!,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(height: 140, color: const Color(0xFFF0F0F0)),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: const Center(
                child: Icon(Icons.photo_outlined, color: Colors.grey, size: 32),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: _statusTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (signalement.categorie != null)
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
                          signalement.categorie!.nom,
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
                  signalement.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  signalement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (signalement.validation)
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: Color(0xFF3B6D11),
                          ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.location_on,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _shortAdresse,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFFECECEC),
                          child: Text(
                            signalement.citoyenId.isNotEmpty
                                ? signalement.citoyenId
                                    .substring(0, 2)
                                    .toUpperCase()
                                : 'CP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_timeAgo(signalement.createdAt)}',
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
      ),
    );
  }
}
