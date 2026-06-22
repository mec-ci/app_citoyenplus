import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'livre_pdf_view.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);

/// Écran de détail d'un document de la librairie, affiché avant l'ouverture du
/// PDF : couverture, titre, catégorie, auteur, date, description et bouton
/// « Ouvrir le PDF ».
class DocumentDetailView extends StatelessWidget {
  const DocumentDetailView({super.key, required this.doc});

  final Map<String, dynamic> doc;

  String get _title =>
      (doc['titre'] ?? doc['title'] ?? 'Document').toString();
  String get _description => (doc['description'] ?? '').toString();
  String get _categorie => (doc['categorie'] ?? '').toString();
  String get _auteur => (doc['auteur'] ?? doc['author'] ?? '').toString();
  String get _cover =>
      (doc['couverture'] ?? doc['coverImage'] ?? doc['image'] ?? '').toString();
  String get _pdfUrl =>
      (doc['pdf'] ?? doc['fileUrl'] ?? doc['url'] ?? doc['documentUrl'] ?? '')
          .toString();

  String _formatDate() {
    final raw = (doc['uploadedAt'] ?? doc['createdAt'] ?? '').toString();
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
      'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    final d = date.toLocal();
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _openPdf(BuildContext context) {
    if (_pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document introuvable')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivrePdfView(pdf: _pdfUrl, title: _title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Document'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openPdf(context),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Ouvrir le PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _cover.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _cover,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _coverFallback(),
                    )
                  : _coverFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_categorie.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _categorie,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF185FA5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_auteur.isNotEmpty) ...[
                        const Icon(Icons.person_outline,
                            size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_auteur,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                        const SizedBox(width: 12),
                      ],
                      if (date.isNotEmpty) ...[
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(date,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ],
                  ),
                  if (_description.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      _description,
                      style: const TextStyle(
                          fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: _blue.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 64, color: _blue),
      ),
    );
  }
}
