import 'package:citoyen_plus/services/mes_signalements_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signalement.dart';

class MesActionsView extends StatefulWidget {
  final List<dynamic> posts;
  final VoidCallback? onBackPressed; // ✅ retour vers notifications
  const MesActionsView({super.key, required this.posts, this.onBackPressed});

  @override
  State<MesActionsView> createState() => _MesActionsViewState();
}

class _MesActionsViewState extends State<MesActionsView> {
  late Future<List<SignalementModel>> _futureSignalements;

  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);

  @override
  void initState() {
    super.initState();
    _futureSignalements = _loadMesSignalements();
  }

  Future<List<SignalementModel>> _loadMesSignalements() async {
    final prefs = await SharedPreferences.getInstance();
    final citoyenId = prefs.getString('citoyenId') ?? '';
    return MesSignalementsService.fetchMesSignalements(citoyenId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Entête custom ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
              child: Row(
                children: [
                  // Bouton retour vers notifications
                  GestureDetector(
                    onTap: widget.onBackPressed,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Icône + Titre
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mes actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),

                  // Bouton actualiser
                  GestureDetector(
                    onTap: () => setState(() {
                      _futureSignalements = _loadMesSignalements();
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 20, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // ── Corps ──────────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<SignalementModel>>(
                future: _futureSignalements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Erreur : ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {
                              _futureSignalements = _loadMesSignalements();
                            }),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final signalements = snapshot.data ?? [];

                  if (signalements.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.report_off_outlined,
                                size: 48, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune action pour le moment',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tes signalements apparaîtront ici.',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _orange,
                    onRefresh: () async {
                      setState(() {
                        _futureSignalements = _loadMesSignalements();
                      });
                      await _futureSignalements;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: signalements.length,
                      itemBuilder: (context, index) {
                        return _ActionCard(signalement: signalements[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card signalement ───────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.signalement});
  final SignalementModel signalement;

  @override
  Widget build(BuildContext context) {
    final statut = signalement.statut ?? 'NOUVEAU';
    final couleur = _couleurStatut(statut);
    final icone = _iconeStatut(statut);
    final date = signalement.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ──────────────────────────────────────────────────
          if (signalement.photo != null && signalement.photo!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                signalement.photo!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre + statut ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        signalement.titre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: couleur.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icone, size: 12, color: couleur),
                          const SizedBox(width: 4),
                          Text(statut,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: couleur)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Catégorie ────────────────────────────────────────
                if (signalement.categorieNom != null &&
                    signalement.categorieNom!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 12, color: Color(0xFF1556B5)),
                        const SizedBox(width: 4),
                        Text(
                          signalement.categorieNom!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1556B5),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                // ── Description ──────────────────────────────────────
                Text(
                  signalement.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // ── Adresse + date ───────────────────────────────────
                Row(
                  children: [
                    if (signalement.adresse.isNotEmpty) ...[
                      const Icon(Icons.place_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          signalement.adresse,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (date != null)
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Color _couleurStatut(String s) {
    switch (s.toUpperCase()) {
      case 'NOUVEAU':   return const Color(0xFF1556B5);
      case 'EN_COURS':
      case 'EN COURS':  return const Color(0xFFFF7F00);
      case 'RÉSOLU':
      case 'RESOLU':    return const Color(0xFF34C759);
      case 'REJETÉ':
      case 'REJETE':    return const Color(0xFFFF2D55);
      default:          return Colors.grey;
    }
  }

  IconData _iconeStatut(String s) {
    switch (s.toUpperCase()) {
      case 'NOUVEAU':   return Icons.fiber_new_outlined;
      case 'EN_COURS':
      case 'EN COURS':  return Icons.hourglass_top_rounded;
      case 'RÉSOLU':
      case 'RESOLU':    return Icons.check_circle_outline;
      case 'REJETÉ':
      case 'REJETE':    return Icons.cancel_outlined;
      default:          return Icons.info_outline;
    }
  }
}