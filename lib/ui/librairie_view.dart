import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'detail_page.dart';
import 'regions_page.dart';
import 'livre_pdf_view.dart';

class LibrairieView extends StatefulWidget {
  const LibrairieView({super.key});

  @override
  State<LibrairieView> createState() => _LibrairieViewState();
}

class _LibrairieViewState extends State<LibrairieView>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);

  List<Map<String, dynamic>> documents = [];
  late List<Map<String, dynamic>> filteredDocuments;
  final TextEditingController searchCtrl = TextEditingController();
  late TabController _tabController;
  bool _isLoadingDocuments = true;
  String? _documentsError;

  @override
  void initState() {
    super.initState();
    filteredDocuments = [];
    searchCtrl.addListener(() => filterDocuments(searchCtrl.text));
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
      _documentsError = null;
    });
    try {
      final token = await AuthService.getToken();
      final docs = await ApiService.fetchLibraryDocuments('1', token ?? '');
      if (!mounted) return;
      setState(() {
        documents = docs;
        filteredDocuments = List<Map<String, dynamic>>.from(docs);
        _isLoadingDocuments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _documentsError = e.toString();
        _isLoadingDocuments = false;
      });
    }
  }

  void filterDocuments(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      filteredDocuments = q.isEmpty
          ? List<Map<String, dynamic>>.from(documents)
          : documents.where((doc) {
              final title = (doc['titre'] ?? doc['title'] ?? '').toString().toLowerCase();
              final description = (doc['description'] ?? '').toString().toLowerCase();
              return title.contains(q) || description.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Librairie',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Découvrez les ressources citoyennes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),

                // ── Barre de recherche ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: Colors.grey[400]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Rechercher un document...",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ),
                      ),
                      if (searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () { searchCtrl.clear(); filterDocuments(''); },
                          child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoadingDocuments)
                  const Center(child: CircularProgressIndicator())
                else if (_documentsError != null)
                  Column(
                    children: [
                      Text('Erreur : $_documentsError', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _loadDocuments, child: const Text('Réessayer')),
                    ],
                  ),
                const SizedBox(height: 16),

                // ── Tabs ───────────────────────────────────────────────
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Bibliothèque'),
                      Tab(text: 'Informations'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Contenu ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBibliotheque(),
                _buildInformations(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bibliothèque ──────────────────────────────────────────────────────────
  Widget _buildBibliotheque() {
    if (filteredDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("Aucun document trouvé", style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 260, // ✅ hauteur fixe par cellule — pas d'overflow
      ),
      itemCount: filteredDocuments.length,
      itemBuilder: (context, i) {
        final doc = filteredDocuments[i];
        final title = doc['titre'] ?? doc['title'] ?? 'Document';
        final description = doc['description'] ?? '';
        final imageUrl = doc['couverture'] ?? doc['image'] ?? '';
        final rawUrl = doc['pdf'] ?? doc['url'] ?? doc['documentUrl'] ?? '';

        return GestureDetector(
          onTap: () async {
            if (rawUrl.isNotEmpty) {
              final uri = Uri.tryParse(rawUrl);
              if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
                await launchUrl(uri);
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => LivrePdfView(pdf: rawUrl)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document introuvable')));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[100],
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Center(child: Icon(Icons.insert_drive_file_outlined, color: Colors.grey)),
                          ),
                  ),
                ),
                // Texte
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((description ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          description.toString(),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Informations ──────────────────────────────────────────────────────────
  Widget _buildInformations() {
    final cards = [
      {
        "title": "Présentation du pays",
        "subtitle": "Capitale, langue, population, monnaie et géographie.",
        "icon": Icons.public,
        "color": _orange,
        "emoji": "🌍",
        "onTap": () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(
          title: "Présentation du pays",
          details: "La Côte d'Ivoire est située en Afrique de l'Ouest.\n\nCapitale économique : Abidjan\nCapitale politique : Yamoussoukro\nLangue officielle : français\nPopulation : environ 26 millions\nMonnaie : Franc CFA",
        ))),
      },
      {
        "title": "Régions",
        "subtitle": "Le pays est divisé en 31 régions aux cultures variées.",
        "icon": Icons.map_outlined,
        "color": _blue,
        "emoji": "🗺️",
        "onTap": () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegionsPage(
          title: "Régions de la Côte d'Ivoire",
          regions: ["Abidjan", "Bouaké", "San Pedro", "Korhogo"],
        ))),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final Color color = card["color"] as Color;
        return GestureDetector(
          onTap: card["onTap"] as VoidCallback?,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(card["emoji"] as String, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card["title"] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card["subtitle"] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Flèche
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}