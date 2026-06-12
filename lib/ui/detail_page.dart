import 'package:flutter/material.dart';

const _orange = Color(0xFFFF7F00);
const _blue = Color(0xFF1556B5);

class DetailPage extends StatelessWidget {
  final String title;
  final String details;

  const DetailPage({super.key, required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    // Découpe le texte en sections si séparé par \n\n
    final sections = details.split('\n\n').where((s) => s.trim().isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Bannière titre ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _orange.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: _orange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _orange,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Sections de contenu ────────────────────────────────────────
          ...sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value.trim();
            final lines = section.split('\n').where((l) => l.isNotEmpty).toList();

            // Première section = intro (texte simple)
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text(
                  section,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              );
            }

            // Sections suivantes = lignes de données (Clé : Valeur)
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                children: lines.asMap().entries.map((e) {
                  final i = e.key;
                  final line = e.value.trim();
                  final hasSeparator = line.contains(' : ');
                  final parts = hasSeparator ? line.split(' : ') : [line];
                  final Color rowColor = i.isEven ? _blue : _orange;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: hasSeparator
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(top: 5, right: 10),
                                    decoration: BoxDecoration(
                                      color: rowColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      parts[0],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: rowColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      parts.sublist(1).join(' : '),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                line,
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                              ),
                      ),
                      if (i < lines.length - 1)
                        Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Bouton retour ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              label: const Text(
                'Retour',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}