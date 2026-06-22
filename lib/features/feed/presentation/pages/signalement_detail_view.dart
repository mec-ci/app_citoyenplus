import 'package:cached_network_image/cached_network_image.dart';
import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/services/commentaire_service.dart';
import 'package:citoyen_plus/services/reaction_service.dart';
import 'package:citoyen_plus/widgets/commentaires_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);

/// Écran de détail d'un signalement : photo, statut, catégorie, description,
/// position sur une carte OpenStreetMap, et actions (j'aime / commenter /
/// partager).
class SignalementDetailView extends StatefulWidget {
  const SignalementDetailView({super.key, required this.item});

  final FeedItem item;

  @override
  State<SignalementDetailView> createState() => _SignalementDetailViewState();
}

class _SignalementDetailViewState extends State<SignalementDetailView> {
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

  bool get _hasLocation =>
      widget.item.latitude != null &&
      widget.item.longitude != null &&
      !(widget.item.latitude == 0 && widget.item.longitude == 0);

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

  String get _statusLabel {
    switch (widget.item.statut?.toLowerCase()) {
      case 'en_cours':
        return 'En cours';
      case 'nouveau':
        return 'Nouveau';
      case 'resolu':
        return 'Résolu';
      case 'rejete':
        return 'Rejeté';
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
    Share.share('${widget.item.titre}\n\n${widget.item.description}');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.item.imageUrl;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Signalement'),
        backgroundColor: _orange,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.item.categorieNom != null &&
                          widget.item.categorieNom!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.item.categorieNom!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF185FA5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                  if (widget.item.adresse != null &&
                      widget.item.adresse!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.item.adresse!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  Text(
                    widget.item.description,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                  if (_hasLocation) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Localisation',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildMap(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final point = LatLng(widget.item.latitude!, widget.item.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            // Carte d'aperçu : on désactive les interactions de rotation.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.mec.citoyenplus',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on,
                      color: _orange, size: 44),
                ),
              ],
            ),
          ],
        ),
      ),
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
