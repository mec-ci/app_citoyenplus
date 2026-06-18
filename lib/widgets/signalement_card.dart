import 'package:flutter/material.dart';

class SignalementCard extends StatefulWidget {
  final String nom;
  final String description;
  final String? photoUrl;
  final String? statut;
  final String? categorie;

  final bool expandable;

  const SignalementCard({
    super.key,
    required this.nom,
    required this.description,
    this.photoUrl,
    this.statut,
    this.categorie,
    this.expandable = false, // désactivé par défaut (scroll horizontal)
  });

  @override
  State<SignalementCard> createState() => _SignalementCardState();
}

class _SignalementCardState extends State<SignalementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool hasMore = widget.description.length > 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Photo ──────────────────────────────────────────────────
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                widget.photoUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: Colors.grey[100],
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _ShimmerBox(height: 120);
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Catégorie (haut) ────────────────────────────────
                if (widget.categorie != null && widget.categorie!.isNotEmpty)
                  _Badge(
                    label: widget.categorie!,
                    icone: Icons.category_outlined,
                    couleur: const Color(0xFF1556B5),
                  ),

                // ── Séparateur ──────────────────────────────────────
                if ((widget.categorie != null && widget.categorie!.isNotEmpty) &&
                    (widget.statut != null && widget.statut!.isNotEmpty))
                  const Divider(height: 10, thickness: 0.5),

                // ── Statut (bas) ────────────────────────────────────
                if (widget.statut != null && widget.statut!.isNotEmpty)
                  _Badge(
                    label: widget.statut!,
                    icone: _iconeStatut(widget.statut!),
                    couleur: _couleurStatut(widget.statut!),
                    withBorder: true,
                  ),

                const SizedBox(height: 8),

                // ── Titre ───────────────────────────────────────────
                Text(
                  widget.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // ── Description avec voir plus ───────────────────────
                if (widget.expandable)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      widget.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      widget.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3),
                    ),
                  )
                else
                  Text(
                    widget.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                // ── Bouton voir plus / voir moins (seulement si expandable) ──
                if (hasMore && widget.expandable)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? 'voir moins' : 'voir plus',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut.toUpperCase()) {
      case 'NOUVEAU':     return const Color(0xFF1556B5);
      case 'EN_COURS':
      case 'EN COURS':   return const Color(0xFFE65C00);
      case 'RÉSOLU':
      case 'RESOLU':     return const Color(0xFF34C759);
      case 'REJETÉ':
      case 'REJETE':     return const Color(0xFFFF2D55);
      default:           return Colors.grey;
    }
  }

  IconData _iconeStatut(String statut) {
    switch (statut.toUpperCase()) {
      case 'NOUVEAU':     return Icons.fiber_new_outlined;
      case 'EN_COURS':
      case 'EN COURS':   return Icons.hourglass_top_rounded;
      case 'RÉSOLU':
      case 'RESOLU':     return Icons.check_circle_outline;
      case 'REJETÉ':
      case 'REJETE':     return Icons.cancel_outlined;
      default:           return Icons.info_outline;
    }
  }
}

// ── Badge générique ──────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color couleur;
  final bool withBorder;

  const _Badge({
    required this.label,
    required this.icone,
    required this.couleur,
    this.withBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: withBorder ? Border.all(color: couleur.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 10, color: couleur),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: couleur),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Shimmer placeholder ──────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double height;
  const _ShimmerBox({required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300]!.withValues(alpha: _anim.value),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}