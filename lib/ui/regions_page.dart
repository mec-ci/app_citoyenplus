import 'package:flutter/material.dart';
import 'detail_page.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);

// ── Données enrichies par région ─────────────────────────────────────────────
const Map<String, Map<String, String>> _regionDetails = {
  "Abidjan": {
    "details": "Abidjan est la capitale économique de la Côte d'Ivoire et la plus grande ville du pays.\n\nChef-lieu : Abidjan\nPopulation : environ 6 millions d'habitants\nSuperficie : 2 119 km²\nSituation : Sud du pays, sur la lagune Ébrié\nMonnaie : Franc CFA",
    "infos": "Abidjan est le poumon économique de la Côte d'Ivoire. Elle abrite le port autonome, le plus grand port d'Afrique de l'Ouest, ainsi que le Plateau, quartier des affaires.\n\nPrincipal centre commercial, industriel et financier du pays.",
    "emoji": "🏙️",
  },
  "Bouaké": {
    "details": "Bouaké est la deuxième ville de Côte d'Ivoire, située au centre du pays.\n\nChef-lieu : Bouaké\nPopulation : environ 1,5 million d'habitants\nSuperficie : 12 800 km²\nSituation : Centre du pays\nEthnies principales : Baoulé, Dioula",
    "infos": "Bouaké est un carrefour commercial majeur entre le Nord et le Sud du pays. La ville est reconnue pour son marché textile, l'un des plus importants d'Afrique de l'Ouest.\n\nElle accueille aussi une université et plusieurs établissements d'enseignement supérieur.",
    "emoji": "🏘️",
  },
  "San Pedro": {
    "details": "San Pedro est une ville portuaire du Sud-Ouest, premier port mondial d'exportation de cacao.\n\nChef-lieu : San Pedro\nPopulation : environ 700 000 habitants\nSuperficie : 18 298 km²\nSituation : Sud-Ouest, façade atlantique\nPrincipale activité : Exportation cacao, bois",
    "infos": "San Pedro abrite le second port de Côte d'Ivoire, spécialisé dans l'exportation agricole. La région produit une grande partie du cacao ivoirien.\n\nLa ville est aussi un point d'entrée touristique pour les plages du littoral sud-ouest.",
    "emoji": "⚓",
  },
  "Korhogo": {
    "details": "Korhogo est la principale ville du Nord ivoirien et capitale de la région du Poro.\n\nChef-lieu : Korhogo\nPopulation : environ 500 000 habitants\nSuperficie : 12 500 km²\nSituation : Nord du pays\nEthnies principales : Sénoufo, Dioula",
    "infos": "Korhogo est réputée pour son artisanat traditionnel, notamment les toiles peintes Sénoufo et les statuettes en bronze.\n\nLa ville est un centre commercial du Nord avec un important marché de coton, anacarde et bétail.",
    "emoji": "🏺",
  },
  "Yamoussoukro": {
    "details": "Yamoussoukro est la capitale politique officielle de la Côte d'Ivoire depuis 1983.\n\nChef-lieu : Yamoussoukro\nPopulation : environ 400 000 habitants\nSuperficie : 3 500 km²\nSituation : Centre du pays\nPatrimoine : Basilique Notre-Dame-de-la-Paix",
    "infos": "Yamoussoukro abrite la Basilique Notre-Dame-de-la-Paix, la plus grande église du monde par sa superficie.\n\nLa ville est aussi le siège de plusieurs grandes institutions, dont l'Institut National Polytechnique Félix Houphouët-Boigny (INP-HB).",
    "emoji": "⛪",
  },
  "Daloa": {
    "details": "Daloa est la troisième ville de Côte d'Ivoire, chef-lieu de la région du Haut-Sassandra.\n\nChef-lieu : Daloa\nPopulation : environ 400 000 habitants\nSuperficie : 15 200 km²\nSituation : Centre-Ouest\nPrincipal produit : Cacao, café",
    "infos": "Daloa est au cœur de la zone de production cacaoyère ivoirienne. La région est l'une des plus productives du pays en cacao et café.\n\nLa ville est un centre commercial dynamique avec un marché régional très actif.",
    "emoji": "🌱",
  },
  "Man": {
    "details": "Man est la capitale de la région des Dix-Huit Montagnes, réputée pour ses reliefs et cascades.\n\nChef-lieu : Man\nPopulation : environ 200 000 habitants\nSuperficie : 16 500 km²\nSituation : Ouest, frontière Guinée/Liberia\nPoint culminant : Mont Nimba (1 752 m)",
    "infos": "Man est connue pour le 'Pays des Dan', une région de montagnes, forêts et cascades spectaculaires.\n\nLe masque Gunyé (sur visage) et les danses traditionnelles Dan sont classés parmi les richesses culturelles nationales.",
    "emoji": "⛰️",
  },
  "Abengourou": {
    "details": "Abengourou est le chef-lieu de la région de l'Indénié-Djuablin, à l'Est du pays.\n\nChef-lieu : Abengourou\nPopulation : environ 150 000 habitants\nSuperficie : 6 900 km²\nSituation : Est, frontière Ghana\nEthnie principale : Agni",
    "infos": "Abengourou est la capitale du Royaume Agni de l'Indénié, avec une royauté traditionnelle toujours en activité.\n\nLa région est riche en cacao et café, et partage une frontière culturelle et commerciale avec le Ghana.",
    "emoji": "👑",
  },
};

String _getDetails(String region) {
  final data = _regionDetails[region];
  if (data == null) return "Informations détaillées sur $region à venir.\n\nCette région fait partie des 31 régions administratives de la Côte d'Ivoire.";
  return "${data['details']}\n\n${data['infos']}";
}

String _getEmoji(String region) => _regionDetails[region]?['emoji'] ?? '📍';

// ── Page régions ─────────────────────────────────────────────────────────────
class RegionsPage extends StatelessWidget {
  final String title;
  final List<String> regions;

  const RegionsPage({super.key, required this.title, required this.regions});

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Compteur ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${regions.length} ${regions.length > 1 ? 'régions' : 'région'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),

          // ── Liste ───────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final Color color = index.isEven ? _orange : _blue;
                final String region = regions[index];
                final bool hasData = _regionDetails.containsKey(region);

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(
                        title: region,
                        details: _getDetails(region),
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        // Emoji ou numéro
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: hasData
                                ? Text(_getEmoji(region), style: const TextStyle(fontSize: 20))
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Nom + badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                region,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (hasData) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Infos disponibles',
                                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Flèche
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                          child: Icon(Icons.arrow_forward_ios, size: 12, color: color),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}