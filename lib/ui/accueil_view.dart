import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signalement.dart';
import '../services/recuperer_signalement_service.dart';
import '../widgets/post_card.dart';
import '../widgets/signalement_card.dart';
import '../ui/entete.dart';
import '../ui/livre_pdf_view.dart';
import '../models/post.dart';
import '../services/recuperer_actualite_service.dart';

class AccueilView extends StatefulWidget {
  final VoidCallback? onNotificationPressed;

  const AccueilView({super.key, this.onNotificationPressed});

  @override
  State<AccueilView> createState() => _AccueilViewState();
}

class _AccueilViewState extends State<AccueilView> {
  Future<List<PostModel>> _futurePosts = Future.value([]);
  Future<List<SignalementModel>> _futureSignalements = Future.value([]);

  String userToken = "";

  final List<Map<String, String>> documents = [
    {
      "titre": "BUDGET CITOYEN",
      "couverture": "assets/budget2021.png",
      "description": "",
      "pdf": "assets/BUDGET-CITOYEN.pdf",
    },
    {
      "titre": "BUDGET CITOYEN 2024",
      "couverture": "assets/budget2024.png",
      "description": "",
      "pdf": "assets/BUDGET-CITOYEN_2024.pdf",
    },
    {
      "titre": "BUDGET CITOYEN 2025",
      "couverture": "assets/budget2025.png",
      "description": "",
      "pdf": "assets/BUDGET-CITOYEN_2025.pdf",
    },
    {
      "titre": "CNDH",
      "couverture": "assets/cndh.png",
      "description":
          "Les droits catégoriels et leur mise en œuvre en Côte d'Ivoire",
      "pdf": "assets/CNDH.pdf",
    },
    {
      "titre": "CODE D'ETHIQUE ET DE DEONTOLOGIE DGBF",
      "couverture": "assets/code_ethique.png",
      "description": "",
      "pdf": "assets/dgbf.pdf",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userToken = prefs.getString("token") ?? "";
    if (!mounted) return;
    setState(() {
      _futurePosts = RecupererActualiteService.fetchAllPosts(userToken);
      _futureSignalements =
          RecupererSignalementService.fetchAllSignalement(userToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EntetePersonalise(
        onNotificationPressed: widget.onNotificationPressed,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFF7F00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Bienvenue sur Citoyen +",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Comprendre les institutions et connaître ses droits, c'est le premier pas vers une société plus juste.",
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 24),

                // ── ACTUALITÉS CITOYENNES ─────────────────────────────────
                _SectionHeader(
                  icon: Icons.newspaper_rounded,
                  title: "Informations citoyennes",
                  color: const Color(0xFF1556B5),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<PostModel>>(
                  future: _futurePosts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('Erreur: ${snapshot.error}'),
                      ));
                    }
                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Aucune actualité disponible'),
                        ),
                      );
                    }
                    return Column(
                      children: posts.map((post) {
                        return PostCard(
                          title: post.title,
                          content: post.content,
                          imageUrl: post.imageUrl,
                          timeAgo: _timeAgo(post.date),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── BIBLIOTHÈQUE ──────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.menu_book_rounded,
                  title: "Bibliothèque citoyenne",
                  color: const Color(0xFFFF7F00),
                ),
                const SizedBox(height: 4),
                Text(
                  "Explore les bases de la citoyenneté ivoirienne.",
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: documents.length,
                    itemBuilder: (context, i) {
                      final doc = documents[i];
                      return GestureDetector(
                        onTap: () {
                          final pdfPath = doc['pdf'] ?? '';
                          if (pdfPath.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    LivrePdfView(pdf: pdfPath),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('PDF introuvable')),
                            );
                          }
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 210,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    doc["couverture"] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 210,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                doc["titre"] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((doc["description"] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    doc["description"] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // ── SIGNALEMENTS ──────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.campaign_rounded,
                  title: "Derniers signalements",
                  color: const Color(0xFF1556B5),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<SignalementModel>>(
                  future: _futureSignalements,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Erreur: ${snapshot.error}'));
                    }
                    final signalements = snapshot.data ?? [];
                    if (signalements.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Aucun signalement disponible'),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 340,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: signalements.length,
                        itemBuilder: (context, index) {
                          final s = signalements[index];
                          return SizedBox(
                            width: 240,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 14),
                              child: SignalementCard(
                                nom: s.titre,
                                description: s.description,
                                photoUrl: s.photo,
                                statut: s.statut,
                                categorie: s.categorieNom,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
