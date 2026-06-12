import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'entete.dart';
import 'quizquestions.dart';

const _orange = Color(0xFFFF7F00);
const _blue = Color(0xFF1556B5);
const _green = Color(0xFF34C759);

// ── Données des catégories ────────────────────────────────────────────────────

List<Map<String, dynamic>> _categories = [
  {"icon": Icons.flag_circle_outlined, "title": "Citoyenneté", "color": _orange},
  {"icon": Icons.directions_car_outlined, "title": "Code de la route", "color": _blue},
  {"icon": Icons.public_outlined, "title": "Côte d'Ivoire", "color": _orange},
  {"icon": Icons.gavel_outlined, "title": "Institutions", "color": _blue},
  {"icon": Icons.scale_outlined, "title": "Droits humains", "color": _orange},
  {"icon": Icons.handshake_outlined, "title": "Civisme et valeurs", "color": _blue},
  {"icon": Icons.phone_android_outlined, "title": "Citoyenneté numérique", "color": _orange},
  {"icon": Icons.eco_outlined, "title": "Environnement", "color": _green},
  {"icon": Icons.how_to_vote_outlined, "title": "Responsabilité civique", "color": _blue},
];

// ── Vue principale Quiz ───────────────────────────────────────────────────────

class QuizView extends StatefulWidget {
  const QuizView({super.key});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  Map<String, Map<int, bool>> _progress = {};
  bool _isLoadingCategories = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadCategories();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, Map<int, bool>> progress = {};
    for (final cat in _categories) {
      final title = cat['title'] as String;
      progress[title] = {
        1: prefs.getBool('quiz_${title}_1_done') ?? false,
        2: prefs.getBool('quiz_${title}_2_done') ?? false,
        3: prefs.getBool('quiz_${title}_3_done') ?? false,
      };
    }
    if (mounted) setState(() => _progress = progress);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final token = await AuthService.getToken();
      final categories = await ApiService.fetchQuizCategories(token ?? '');
      if (!mounted) return;
      setState(() {
        _categories = categories.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return {
            'title': item['titre'] ?? item['title'] ?? item['name'] ?? 'Thème ${index + 1}',
            'icon': _categoryIconForIndex(index),
            'color': index.isEven ? _orange : _blue,
          };
        }).toList();
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoriesError = 'Impossible de charger les catégories de quiz';
        _isLoadingCategories = false;
      });
    }
  }

  IconData _categoryIconForIndex(int index) {
    const icons = [
      Icons.flag_circle_outlined,
      Icons.directions_car_outlined,
      Icons.public_outlined,
      Icons.gavel_outlined,
      Icons.scale_outlined,
      Icons.handshake_outlined,
      Icons.phone_android_outlined,
      Icons.eco_outlined,
      Icons.how_to_vote_outlined,
      Icons.account_balance,
    ];
    return icons[index % icons.length];
  }

  int _unlockedLevel(String categorie) {
    final p = _progress[categorie];
    if (p == null) return 1;
    if (p[2] == true) return 3;
    if (p[1] == true) return 2;
    return 1;
  }

  int _completedLevels(String categorie) {
    final p = _progress[categorie];
    if (p == null) return 0;
    return [p[1], p[2], p[3]].where((v) => v == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EntetePersonalise(),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ───────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_alt_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Choisis ton quiz",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text("🧠", style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${_categories.length} thèmes · 3 niveaux chacun",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),

              // ── Grille catégories ─────────────────────────────────────
              if (_isLoadingCategories)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_categoriesError != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_categoriesError!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadCategories,
                          style: ElevatedButton.styleFrom(backgroundColor: _orange),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    itemCount: _categories.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 3 / 3.8,
                    ),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final Color color = cat["color"];
                    final title = cat["title"] as String;
                    final completed = _completedLevels(title);
                    final unlocked = _unlockedLevel(title);

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizLevelView(
                              categorie: title,
                              color: color,
                              icon: cat["icon"] as IconData,
                              unlockedLevel: unlocked,
                              completedLevels:
                                  _progress[title] ?? {},
                              onProgressChanged: _loadProgress,
                            ),
                          ),
                        );
                        _loadProgress();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.15),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cat["icon"] as IconData,
                                  size: 28, color: color),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Étoiles de progression
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final done =
                                    _progress[title]?[i + 1] == true;
                                return Icon(
                                  done
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: done ? _orange : Colors.grey[300],
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "$completed/3 niveaux",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
        ),
      ),
    );
  }
}

// ── Sélection de niveau ───────────────────────────────────────────────────────

class QuizLevelView extends StatelessWidget {
  final String categorie;
  final Color color;
  final IconData icon;
  final int unlockedLevel;
  final Map<int, bool> completedLevels;
  final VoidCallback onProgressChanged;

  const QuizLevelView({
    super.key,
    required this.categorie,
    required this.color,
    required this.icon,
    required this.unlockedLevel,
    required this.completedLevels,
    required this.onProgressChanged,
  });

  static const _levelLabels = ["Débutant", "Intermédiaire", "Avancé"];
  static const _levelDesc = [
    "Les fondamentaux à connaître",
    "Approfondis tes connaissances",
    "Maîtrise les aspects avancés",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              categorie,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choisis un niveau",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Réussis un niveau pour débloquer le suivant (≥ 60%)",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (i) {
              final level = i + 1;
              final isUnlocked = level <= unlockedLevel;
              final isDone = completedLevels[level] == true;

              return GestureDetector(
                onTap: isUnlocked
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Quizquestions(
                              categorie: categorie,
                              level: level,
                              questions: getQuestionsForCategoryAndLevel(
                                  categorie, level),
                              onLevelCompleted: (passed) async {
                                if (passed) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'quiz_${categorie}_${level}_done',
                                      true);
                                  onProgressChanged();
                                }
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : Colors.grey[100],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDone
                          ? _green.withValues(alpha: 0.4)
                          : isUnlocked
                              ? color.withValues(alpha: 0.2)
                              : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // Badge niveau
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDone
                              ? _green.withValues(alpha: 0.1)
                              : isUnlocked
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isUnlocked
                              ? (isDone
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: _green, size: 26)
                                  : Text(
                                      "$level",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: color,
                                      ),
                                    ))
                              : const Icon(Icons.lock_outline_rounded,
                                  color: Colors.grey, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Niveau $level · ${_levelLabels[i]}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isUnlocked
                                    ? Colors.black87
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isUnlocked
                                  ? _levelDesc[i]
                                  : "Réussis le niveau ${level - 1} pour débloquer",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked && !isDone)
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: color),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Réussi ✓",
                            style: TextStyle(
                              fontSize: 11,
                              color: _green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Questions par catégorie et niveau ────────────────────────────────────────

List<Map<String, dynamic>> getQuestionsForCategoryAndLevel(
    String categorie, int level) {
  final all = _questionBank[categorie];
  if (all == null || level < 1 || level > all.length) {
    return [
      {
        "question": "Quiz en construction pour ce niveau.",
        "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
        "correct": 0
      }
    ];
  }
  return all[level - 1];
}

// ── Banque de questions ───────────────────────────────────────────────────────

final Map<String, List<List<Map<String, dynamic>>>> _questionBank = {
  // ────────────────────────────────────── CITOYENNETÉ
  "Citoyenneté": [
    // Niveau 1
    [
      {"question": "Quel est le symbole de la République de Côte d'Ivoire ?", "options": ["L'aigle", "L'éléphant", "Le lion", "La gazelle"], "correct": 1},
      {"question": "Quel est le rôle principal d'un citoyen dans son pays ?", "options": ["Observer", "Participer à la vie publique", "Critiquer", "Ignorer les lois"], "correct": 1},
      {"question": "Quel document prouve la nationalité ivoirienne ?", "options": ["Le passeport", "La carte nationale d'identité", "Le permis de conduire", "L'acte de naissance"], "correct": 1},
      {"question": "Que signifie le mot civisme ?", "options": ["Le respect des lois et des règles", "L'amour du football", "La défense de sa tribu", "La liberté totale"], "correct": 0},
      {"question": "Quel est le devoir d'un citoyen lors des élections ?", "options": ["Voter", "Voyager", "Dormir", "Protester"], "correct": 0},
      {"question": "Quel est le régime politique de la Côte d'Ivoire ?", "options": ["Monarchie", "République", "Dictature", "Fédération"], "correct": 1},
      {"question": "Que représente le drapeau ivoirien ?", "options": ["L'unité", "Les richesses du pays", "Les régions", "Les partis politiques"], "correct": 1},
      {"question": "Que signifie être responsable ?", "options": ["Assumer ses actes", "Faire ce qu'on veut", "Suivre les autres", "Refuser les règles"], "correct": 0},
      {"question": "Quel est le rôle de la Constitution ?", "options": ["Régler les matchs", "Fixer les lois fondamentales", "Organiser les fêtes", "Choisir le président"], "correct": 1},
      {"question": "Que favorise le respect des lois ?", "options": ["Le désordre", "La paix sociale", "La division", "Le chaos"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Qu'est-ce que le suffrage universel ?", "options": ["Le droit de vote accordé à tous les citoyens majeurs", "Un vote réservé aux hommes", "Un vote organisé par l'ONU", "Le droit de se présenter aux élections"], "correct": 0},
      {"question": "Quel est l'âge minimum pour voter en Côte d'Ivoire ?", "options": ["16 ans", "17 ans", "18 ans", "21 ans"], "correct": 2},
      {"question": "Que signifie la séparation des pouvoirs ?", "options": ["La division entre exécutif, législatif et judiciaire", "La répartition des terres", "La séparation des partis politiques", "L'indépendance des régions"], "correct": 0},
      {"question": "Qui peut proposer une loi en Côte d'Ivoire ?", "options": ["Le président seul", "Les juges", "Les députés et le gouvernement", "Le peuple directement"], "correct": 2},
      {"question": "Que signifie 'l'état de droit' ?", "options": ["Un pays fort militairement", "Un pays où les dirigeants décident seuls", "Un pays où la loi s'applique à tous sans exception", "Un pays riche"], "correct": 2},
      {"question": "Qu'est-ce qu'une pétition citoyenne ?", "options": ["Une plainte judiciaire", "Une demande collective signée par des citoyens", "Une loi votée au parlement", "Un discours politique"], "correct": 1},
      {"question": "Combien de mandats présidentiels sont possibles en Côte d'Ivoire ?", "options": ["Un seul", "Deux mandats maximum", "Trois mandats", "Illimités"], "correct": 1},
      {"question": "Qu'est-ce qu'une constitution ?", "options": ["La loi fondamentale qui organise l'État", "Un traité international", "Un règlement municipal", "Un accord commercial"], "correct": 0},
    ],
    // Niveau 3
    [
      {"question": "Quel est le principe de la démocratie représentative ?", "options": ["Les citoyens élisent des représentants pour décider en leur nom", "Chaque citoyen vote directement sur chaque loi", "Le gouvernement décide sans consulter le peuple", "Les juges gouvernent le pays"], "correct": 0},
      {"question": "Que garantit la présomption d'innocence ?", "options": ["Qu'une personne est innocente jusqu'à preuve du contraire", "Que l'accusé est toujours coupable", "Que le procureur a toujours raison", "Que les crimes ne sont pas punis"], "correct": 0},
      {"question": "Qu'est-ce qu'un référendum ?", "options": ["Une élection de maire", "Un vote parlementaire", "Un vote direct du peuple sur une question importante", "Une consultation des juges"], "correct": 2},
      {"question": "Qu'est-ce que le bicamérisme ?", "options": ["Un système à deux partis", "Un parlement composé de deux chambres", "Deux présidents au pouvoir", "Un double vote aux élections"], "correct": 1},
      {"question": "Que signifie le pluralisme politique ?", "options": ["La coexistence de plusieurs partis politiques", "L'interdiction de l'opposition", "Un seul parti au pouvoir", "L'absence de partis"], "correct": 0},
      {"question": "Quel est le rôle de l'opposition dans une démocratie ?", "options": ["Approuver toutes les décisions du gouvernement", "Ignorer la politique", "Préparer un coup d'état", "Contrôler et critiquer le gouvernement de façon constructive"], "correct": 3},
      {"question": "Qu'est-ce que la démocratie participative ?", "options": ["Une démocratie sans élections", "La participation directe des citoyens aux décisions publiques", "Un gouvernement d'experts", "Le vote en ligne uniquement"], "correct": 1},
      {"question": "Que protège la liberté d'expression dans un État de droit ?", "options": ["Le droit de tout dire sans limite", "Le droit de s'exprimer dans le cadre de la loi", "L'interdiction de critiquer le gouvernement", "Le droit au silence uniquement"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── CODE DE LA ROUTE
  "Code de la route": [
    // Niveau 1
    [
      {"question": "Que signifie un feu rouge ?", "options": ["Avancer", "Ralentir", "S'arrêter", "Klaxonner"], "correct": 2},
      {"question": "Que fait-on avant de dépasser un véhicule ?", "options": ["On accélère fort", "On vérifie les rétroviseurs", "On klaxonne seulement", "On ferme les yeux"], "correct": 1},
      {"question": "Quel est le côté de circulation en Côte d'Ivoire ?", "options": ["Gauche", "Droite", "Milieu", "Aucun"], "correct": 1},
      {"question": "Que signifie un panneau triangulaire rouge ?", "options": ["Danger", "Stationnement", "Interdiction", "Fin de route"], "correct": 0},
      {"question": "Quelle est la vitesse maximale en agglomération ?", "options": ["30 km/h", "50 km/h", "80 km/h", "100 km/h"], "correct": 1},
      {"question": "Que faut-il porter à moto ?", "options": ["Une casquette", "Un casque", "Une chemise", "Une écharpe"], "correct": 1},
      {"question": "Que signifie un panneau bleu rond ?", "options": ["Obligation", "Danger", "Interdiction", "Signal d'arrêt"], "correct": 0},
      {"question": "Que faire si un piéton traverse ?", "options": ["Accélérer", "S'arrêter", "Klaxonner", "Ignorer"], "correct": 1},
      {"question": "Quelle est la priorité sur une route sans panneau ?", "options": ["Celui de droite", "Celui de gauche", "Celui qui klaxonne", "Celui qui roule vite"], "correct": 0},
      {"question": "Quel document doit-on toujours avoir en voiture ?", "options": ["Carte grise", "Facture d'achat", "Passeport", "Bulletin de notes"], "correct": 0},
    ],
    // Niveau 2
    [
      {"question": "Que signifie le panneau STOP ?", "options": ["S'arrêter complètement et céder la priorité", "Ralentir légèrement", "Klaxonner avant de passer", "Accélérer pour dégager la zone"], "correct": 0},
      {"question": "Quand doit-on utiliser ses feux de croisement ?", "options": ["Uniquement en ville", "La nuit et par mauvaise visibilité", "Seulement sur autoroute", "Jamais en journée"], "correct": 1},
      {"question": "La ligne blanche continue au milieu de la route signifie ?", "options": ["Interdiction de dépasser", "Obligation de dépasser", "Zone de travaux", "Fin de chaussée"], "correct": 0},
      {"question": "Que faire en cas d'accident avec blessés ?", "options": ["Alerter les secours et sécuriser la zone", "Partir rapidement", "Attendre que quelqu'un d'autre appelle", "Prendre des photos seulement"], "correct": 0},
      {"question": "Que signifie un feu orange fixe ?", "options": ["Passer rapidement", "Préparez-vous à vous arrêter", "Autorisation de passer", "Zone scolaire"], "correct": 1},
      {"question": "Quelle est la distance minimale de sécurité sur route ?", "options": ["5 mètres", "La distance parcourue en 2 secondes", "50 mètres fixes", "La longueur d'un véhicule"], "correct": 1},
      {"question": "Que signifie une flèche verte en bas d'un feu rouge ?", "options": ["Tourner librement dans la direction indiquée", "Attendre que le feu passe au vert", "S'arrêter immédiatement", "Klaxonner"], "correct": 0},
      {"question": "Quand un bus scolaire est arrêté avec ses feux clignotants allumés ?", "options": ["On peut dépasser normalement", "On doit s'arrêter et laisser descendre les enfants", "On klaxonne", "On slalome entre les enfants"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Que faire si votre véhicule tombe en panne sur la route ?", "options": ["Mettre les feux de détresse et placer le triangle de signalisation", "Rester dans le véhicule sans rien faire", "Tenter de réparer seul sans signalisation", "Abandonner le véhicule"], "correct": 0},
      {"question": "Qu'est-ce que l'aquaplaning ?", "options": ["Un type de pneu", "La perte de contact des pneus avec la route due à l'eau", "Un mode de freinage", "Une technique de dépassement"], "correct": 1},
      {"question": "Comment se comporter face à un conducteur agressif ?", "options": ["Répondre à la provocation", "Accélérer pour fuir", "Rester calme et ne pas répondre à la provocation", "Klaxonner longuement"], "correct": 2},
      {"question": "Que signifie une ligne mixte sur la chaussée ?", "options": ["Interdiction totale de dépasser dans les deux sens", "On peut dépasser du côté de la ligne discontinue uniquement", "Zone de travaux", "Fin de route prioritaire"], "correct": 1},
      {"question": "Que faire si vos freins deviennent moins efficaces en descente ?", "options": ["Freiner en continu", "Rétrograder et utiliser le frein moteur", "Couper le moteur", "Ouvrir la portière"], "correct": 1},
      {"question": "Quel est l'impact de la fatigue sur la conduite ?", "options": ["Aucun impact", "Améliore les réflexes", "Réduit les réflexes et l'attention, augmentant le risque d'accident", "Ralentit seulement la vitesse"], "correct": 2},
      {"question": "Quand peut-on rouler sur la bande d'arrêt d'urgence ?", "options": ["En cas de bouchon", "Jamais, sauf urgence ou autorisation", "Pour doubler", "Toujours si la voie est libre"], "correct": 1},
      {"question": "Comment réduire sa consommation de carburant en conduisant ?", "options": ["Accélérer et freiner brusquement", "Conduire à régime constant et anticiper les freinages", "Rouler avec la climatisation à fond", "Gonfler excessivement les pneus"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── CÔTE D'IVOIRE
  "Côte d'Ivoire": [
    // Niveau 1
    [
      {"question": "Quelle est la capitale politique de la Côte d'Ivoire ?", "options": ["Abidjan", "Bouaké", "Yamoussoukro", "Korhogo"], "correct": 2},
      {"question": "En quelle année la Côte d'Ivoire a-t-elle obtenu son indépendance ?", "options": ["1958", "1960", "1962", "1970"], "correct": 1},
      {"question": "Qui fut le premier président de la Côte d'Ivoire ?", "options": ["Laurent Gbagbo", "Henri Konan Bédié", "Félix Houphouët-Boigny", "Alassane Ouattara"], "correct": 2},
      {"question": "Quelle est la devise nationale de la Côte d'Ivoire ?", "options": ["Travail – Famille – Patrie", "Union – Discipline – Travail", "Paix – Unité – Progrès", "Force – Courage – Foi"], "correct": 2},
      {"question": "Quel est le plus grand stade du pays ?", "options": ["Stade Houphouët-Boigny", "Stade de la Paix", "Stade Alassane Ouattara d'Ebimpé", "Stade Gagnoa"], "correct": 2},
      {"question": "Quel est le fleuve le plus long du pays ?", "options": ["Bandama", "Comoé", "Sassandra", "Cavally"], "correct": 0},
      {"question": "Quel est le surnom d'Abidjan ?", "options": ["La belle des lagunes", "La ville lumière", "La cité du cacao", "La capitale de l'Afrique de l'Ouest"], "correct": 0},
      {"question": "Quel est l'hymne national de la Côte d'Ivoire ?", "options": ["L'Abidjanaise", "Paix et Unité", "L'Ivoirienne", "Notre Patrie"], "correct": 0},
      {"question": "Quelle est la monnaie utilisée en Côte d'Ivoire ?", "options": ["Le Dollar", "Le Franc CFA", "L'Euro", "Le Naira"], "correct": 1},
      {"question": "Quel est le premier produit agricole d'exportation de la Côte d'Ivoire ?", "options": ["Le café", "Le cacao", "L'anacarde", "Le caoutchouc"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Combien de régions compte la Côte d'Ivoire ?", "options": ["14", "19", "31", "33"], "correct": 2},
      {"question": "Quelle est la deuxième grande ville de Côte d'Ivoire ?", "options": ["Bouaké", "San Pedro", "Daloa", "Korhogo"], "correct": 0},
      {"question": "Quelle organisation régionale regroupe la Côte d'Ivoire avec ses voisins ?", "options": ["La CEDEAO", "L'Union africaine seulement", "La CEMAC", "L'OPEP"], "correct": 0},
      {"question": "Quel accord a marqué la réconciliation ivoirienne après la crise de 2002 ?", "options": ["Accords de Libreville", "Accords de Marcoussis", "Accords de Dakar", "Accords de Lagos"], "correct": 1},
      {"question": "La Côte d'Ivoire appartient à quelle zone économique monétaire ?", "options": ["La zone CEMAC", "L'UEMOA", "La zone dollar", "La zone rand"], "correct": 1},
      {"question": "Quel est le nom du principal port de Côte d'Ivoire ?", "options": ["Port d'Abidjan", "Port de San Pedro", "Port de Bassam", "Port de Tabou"], "correct": 0},
      {"question": "En quelle année la Côte d'Ivoire a-t-elle accueilli la CAN ?", "options": ["2012", "2015", "2019", "2024"], "correct": 3},
      {"question": "Quel est le barrage hydroélectrique le plus grand de Côte d'Ivoire ?", "options": ["Barrage de Kossou", "Barrage d'Ayamé", "Barrage de Taabo", "Barrage de Buyo"], "correct": 0},
    ],
    // Niveau 3
    [
      {"question": "Quel texte constitutionnel régit actuellement la Côte d'Ivoire ?", "options": ["La Constitution de 1960", "La Constitution de 2000", "La Constitution de 2016", "La Constitution de 2010"], "correct": 2},
      {"question": "Qui a fondé le PDCI-RDA en Côte d'Ivoire ?", "options": ["Félix Houphouët-Boigny", "Laurent Gbagbo", "Alassane Ouattara", "Henri Konan Bédié"], "correct": 0},
      {"question": "Quelle est la particularité économique qui a valu à la Côte d'Ivoire le surnom de 'miracle ivoirien' ?", "options": ["Sa forte industrie pétrolière", "Sa croissance économique exceptionnelle des années 1960-1970", "Son secteur minier dominant", "Son tourisme développé"], "correct": 1},
      {"question": "Quel est le rôle de la BCEAO pour la Côte d'Ivoire ?", "options": ["Banque centrale de la zone UEMOA", "Banque nationale ivoirienne", "Fonds de développement africain", "Institution de microfinance"], "correct": 0},
      {"question": "Quelle ethnie représente le plus grand groupe de Côte d'Ivoire ?", "options": ["Les Bété", "Les Dioula", "Les Akan", "Les Malinké"], "correct": 2},
      {"question": "Quel est l'organisme chargé d'organiser les élections en Côte d'Ivoire ?", "options": ["Le Conseil Constitutionnel", "La CEI", "Le Ministère de l'Intérieur", "La Commission nationale de réconciliation"], "correct": 1},
      {"question": "Quel prix international Félix Houphouët-Boigny a-t-il inspiré ?", "options": ["Le Prix Nobel de la Paix", "Le Prix Houphouët-Boigny pour la recherche de la paix", "Le Prix africain du leadership", "Le Grand Prix de l'OUA"], "correct": 1},
      {"question": "Quelle est la principale forêt classée de Côte d'Ivoire ?", "options": ["Forêt de Taï", "Forêt du Banco", "Forêt de la Comoé", "Forêt d'Assinie"], "correct": 0},
    ],
  ],

  // ────────────────────────────────────── INSTITUTIONS
  "Institutions": [
    // Niveau 1
    [
      {"question": "Quelle institution veille au respect de la Constitution ?", "options": ["La CEI", "Le Conseil Constitutionnel", "Le Sénat", "Le Gouvernement"], "correct": 1},
      {"question": "Quel est le rôle principal de l'Assemblée Nationale ?", "options": ["Faire les lois", "Contrôler les frontières", "Nommer le président", "Organiser les élections"], "correct": 0},
      {"question": "Combien de pouvoirs composent l'État ivoirien ?", "options": ["2", "3", "4", "5"], "correct": 1},
      {"question": "Qui nomme le Premier ministre en Côte d'Ivoire ?", "options": ["Le peuple", "Le Président de la République", "Le Sénat", "La CEI"], "correct": 1},
      {"question": "Quelle institution organise les élections ?", "options": ["CPI", "ONU", "CEI", "Conseil Constitutionnel"], "correct": 2},
      {"question": "Quelle est la plus haute juridiction du pays ?", "options": ["Cour d'appel", "Cour suprême", "Tribunal de première instance", "Conseil d'État"], "correct": 1},
      {"question": "Quel est le rôle de la Cour des comptes ?", "options": ["Contrôler les finances publiques", "Juger les citoyens", "Créer les lois", "Organiser les élections"], "correct": 0},
      {"question": "Quel est le mandat du Président ivoirien ?", "options": ["3 ans", "4 ans", "5 ans", "6 ans"], "correct": 2},
      {"question": "Où siège le Sénat ivoirien ?", "options": ["Abidjan", "Bouaké", "Yamoussoukro", "Korhogo"], "correct": 2},
      {"question": "Qui représente l'État dans les régions ?", "options": ["Le Maire", "Le Gouverneur", "Le Préfet de région", "Le Député"], "correct": 2},
    ],
    // Niveau 2
    [
      {"question": "Qui nomme les ministres en Côte d'Ivoire ?", "options": ["Le Président de la République sur proposition du PM", "Le Parlement", "La CEI", "Le Conseil Constitutionnel"], "correct": 0},
      {"question": "Qu'est-ce que l'immunité parlementaire ?", "options": ["L'exemption totale de la loi pour les députés", "La protection des élus contre des poursuites liées à leur mandat", "Le droit de vote multiple", "L'accès gratuit aux services publics"], "correct": 1},
      {"question": "Qui vote le budget national ?", "options": ["L'Assemblée Nationale", "Le Président", "Le Sénat seul", "Le gouvernement"], "correct": 0},
      {"question": "Qu'est-ce qu'un décret présidentiel ?", "options": ["Une loi votée au parlement", "Un acte réglementaire signé par le Président", "Un accord international", "Une décision de justice"], "correct": 1},
      {"question": "Quel est le rôle du Conseil Économique et Social ?", "options": ["Gouverner le pays", "Donner des avis consultatifs sur les questions économiques", "Organiser les élections", "Juger les criminels"], "correct": 1},
      {"question": "Qu'est-ce qu'une loi organique ?", "options": ["Une loi sur l'environnement", "Une loi qui précise et complète la Constitution", "Une loi temporaire", "Une loi internationale"], "correct": 1},
      {"question": "Quel est le rôle du procureur de la République ?", "options": ["Défendre l'accusé", "Représenter l'État dans les affaires pénales", "Nommer les juges", "Voter les lois"], "correct": 1},
      {"question": "Qu'est-ce qu'une interpellation parlementaire ?", "options": ["Une arrestation", "Questionner un ministre sur sa politique devant le parlement", "Un vote de censure", "Une pétition citoyenne"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Quelle est la hiérarchie des normes juridiques ivoiriennes ?", "options": ["Lois > Constitution > Règlements", "Constitution > Lois > Règlements", "Règlements > Lois > Constitution", "Toutes les normes sont équivalentes"], "correct": 1},
      {"question": "Qui peut saisir le Conseil Constitutionnel ?", "options": ["Tout citoyen ivoirien", "Le Président, les présidents d'assemblées ou des parlementaires", "Les juges uniquement", "Les partis politiques uniquement"], "correct": 1},
      {"question": "Qu'est-ce que la décentralisation ?", "options": ["La suppression des régions", "Le transfert de pouvoirs de l'État central aux collectivités locales", "La création d'États fédérés", "La privatisation des services publics"], "correct": 1},
      {"question": "Qu'est-ce que l'état d'urgence ?", "options": ["Un régime normal de gouvernement", "Un régime exceptionnel limitant certaines libertés pour raison sécuritaire", "Un référendum d'urgence", "Une dissolution du parlement"], "correct": 1},
      {"question": "Quel est le délai constitutionnel pour promulguer une loi après vote ?", "options": ["24 heures", "15 jours", "30 jours", "6 mois"], "correct": 1},
      {"question": "Qu'est-ce que le contrôle de constitutionnalité ?", "options": ["L'examen d'une loi pour vérifier sa conformité à la Constitution", "Le contrôle des frontières", "L'audit financier de l'État", "La vérification des élections"], "correct": 0},
      {"question": "Quel organe gère les conflits entre l'État et les collectivités ?", "options": ["La Cour suprême", "Le Conseil d'État", "La Cour d'appel", "Le Tribunal administratif"], "correct": 1},
      {"question": "Qu'est-ce que le principe de séparation de l'Église et de l'État ?", "options": ["L'interdiction de toute religion", "La neutralité de l'État en matière religieuse", "L'obligation d'appartenir à une religion", "La fusion des pouvoirs religieux et politiques"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── DROITS HUMAINS
  "Droits humains": [
    // Niveau 1
    [
      {"question": "Quel est le premier droit de tout être humain ?", "options": ["Le droit à la santé", "Le droit à la vie", "Le droit au travail", "Le droit à l'éducation"], "correct": 1},
      {"question": "Quel texte protège les droits humains en Côte d'Ivoire ?", "options": ["Le Code civil", "La Constitution", "Le Code du travail", "Le Code pénal"], "correct": 1},
      {"question": "Qui veille à la protection des droits de l'Homme ?", "options": ["ONU", "CNDH", "CEI", "Assemblée Nationale"], "correct": 1},
      {"question": "Quel document international protège les droits humains ?", "options": ["La Déclaration universelle des droits de l'Homme", "La Charte africaine du sport", "Le traité de Versailles", "Le Code électoral"], "correct": 0},
      {"question": "Le droit à l'éducation s'applique à :", "options": ["Seulement aux enfants", "Tous les citoyens", "Les fonctionnaires", "Les étrangers uniquement"], "correct": 1},
      {"question": "Quel droit est garanti à toute personne arrêtée ?", "options": ["Le droit d'être entendue par un juge", "Le droit de garder le silence total", "Le droit de fuir", "Le droit de refuser tout jugement"], "correct": 0},
      {"question": "Les droits humains sont :", "options": ["Optionnels", "Universels et inaliénables", "Nationaux", "Héréditaires"], "correct": 1},
      {"question": "Le droit d'expression permet :", "options": ["De dire ce qu'on veut en respectant la loi", "D'insulter les autres", "De mentir en public", "De menacer les institutions"], "correct": 0},
      {"question": "Quel groupe est protégé par des droits spécifiques ?", "options": ["Les enfants et les femmes", "Les hommes riches", "Les stars de foot", "Les politiciens"], "correct": 0},
      {"question": "La DUDH a été adoptée en quelle année ?", "options": ["1945", "1948", "1960", "1975"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Quelle institution internationale veille aux droits des enfants ?", "options": ["L'OMS", "La FAO", "L'UNICEF", "L'UNESCO"], "correct": 2},
      {"question": "Qu'est-ce que le droit d'asile ?", "options": ["Le droit d'avoir une maison", "Le droit d'être protégé dans un autre pays en cas de persécution", "Le droit de voyager librement", "L'accès aux soins médicaux"], "correct": 1},
      {"question": "Quel texte africain protège les droits humains et des peuples ?", "options": ["La Charte africaine des droits de l'Homme et des peuples", "Le Traité de Lagos", "La Convention de Genève", "Le Pacte de Dakar"], "correct": 0},
      {"question": "Qu'est-ce que la discrimination positive ?", "options": ["Une forme de racisme", "Favoriser des groupes défavorisés pour corriger des inégalités historiques", "Interdire l'accès à certains droits", "Favoriser les hommes dans les postes"], "correct": 1},
      {"question": "Qui peut saisir la CNDH en Côte d'Ivoire ?", "options": ["Uniquement les avocats", "Uniquement les ONG", "Tout citoyen victime d'une violation de ses droits", "Uniquement les fonctionnaires"], "correct": 2},
      {"question": "Qu'est-ce que le droit à un procès équitable ?", "options": ["Être jugé rapidement sans défense", "Être jugé par un tribunal impartial avec droit à la défense", "Éviter tout jugement", "Être jugé par ses pairs uniquement"], "correct": 1},
      {"question": "Quels sont les droits dits 'de deuxième génération' ?", "options": ["Droits civils et politiques", "Droits économiques, sociaux et culturels", "Droits des peuples", "Droits environnementaux"], "correct": 1},
      {"question": "Qu'est-ce que la protection des données personnelles ?", "options": ["Le droit d'accéder aux données des autres", "Le droit au contrôle de ses propres informations personnelles", "L'obligation de partager ses données", "L'interdiction d'internet"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Que protège la Convention de Genève ?", "options": ["Les droits des commerçants", "Les droits des personnes en temps de guerre", "Les droits des animaux", "Les droits des investisseurs"], "correct": 1},
      {"question": "Qu'est-ce que le droit à l'autodétermination des peuples ?", "options": ["Le droit individuel de voyager", "Le droit d'un peuple à choisir librement son statut politique", "Le droit de faire la guerre", "L'indépendance économique d'un pays"], "correct": 1},
      {"question": "Quel est le rôle de la Cour Pénale Internationale ?", "options": ["Juger les crimes commerciaux internationaux", "Juger les crimes contre l'humanité, les génocides et les crimes de guerre", "Arbitrer les conflits commerciaux", "Juger les violations des droits de douane"], "correct": 1},
      {"question": "Qu'est-ce que la justice transitionnelle ?", "options": ["Un type de justice pour les mineurs", "Des mécanismes pour réconcilier une société après un conflit", "Une justice temporaire d'urgence", "La justice internationale uniquement"], "correct": 1},
      {"question": "Qu'est-ce que les 'droits de troisième génération' ?", "options": ["Droits civils", "Droits économiques", "Droits de solidarité comme le droit au développement et à la paix", "Droits numériques"], "correct": 2},
      {"question": "Quel organe de l'ONU supervise l'application du Pacte des droits civils ?", "options": ["Le Comité des droits de l'Homme", "La Cour internationale de justice", "L'Assemblée générale", "Le Conseil de sécurité"], "correct": 0},
      {"question": "Qu'est-ce que le principe de non-refoulement ?", "options": ["L'interdiction de renvoyer un réfugié vers un pays où il serait en danger", "L'obligation de renvoyer les immigrants", "L'interdiction de l'immigration", "Le droit de séjour permanent"], "correct": 0},
      {"question": "Comment la Côte d'Ivoire intègre-t-elle les traités internationaux dans son droit ?", "options": ["Les traités ne s'appliquent pas en droit ivoirien", "Les traités ratifiés ont une valeur supérieure aux lois nationales", "Les traités ont la même valeur que les décrets", "Les traités doivent être votés par référendum"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── CIVISME ET VALEURS
  "Civisme et valeurs": [
    // Niveau 1
    [
      {"question": "Qu'est-ce que le civisme ?", "options": ["Le respect des lois et du bien commun", "L'amour du sport", "L'obéissance à un chef", "La liberté totale"], "correct": 0},
      {"question": "Quelle valeur favorise la paix dans une société ?", "options": ["La tolérance", "La haine", "La jalousie", "La division"], "correct": 0},
      {"question": "Jeter les ordures dans une poubelle, c'est un acte de :", "options": ["Malpropreté", "Civisme", "Paresse", "Protestation"], "correct": 1},
      {"question": "Que doit faire un bon citoyen pendant les élections ?", "options": ["Voter dans le calme", "Faire campagne dans la rue illégalement", "Refuser le scrutin", "Protester violemment"], "correct": 0},
      {"question": "Le respect du drapeau national est un signe de :", "options": ["Civisme et patriotisme", "Désintérêt", "Rébellion", "Ignorance"], "correct": 0},
      {"question": "Quelle valeur est importante pour vivre ensemble ?", "options": ["Le respect", "L'égoïsme", "La moquerie", "La violence"], "correct": 0},
      {"question": "Rendre service à son voisin est un acte de :", "options": ["Civisme", "Solidarité", "Paresse", "Colère"], "correct": 1},
      {"question": "Être ponctuel montre :", "options": ["Le respect du temps", "Le désordre", "La paresse", "Le mépris"], "correct": 0},
      {"question": "Pourquoi doit-on respecter les autorités ?", "options": ["Parce qu'elles représentent la loi", "Parce qu'on a peur", "Pour gagner de l'argent", "Par obligation uniquement"], "correct": 0},
      {"question": "Quelle est une valeur fondamentale de la société ivoirienne ?", "options": ["La fraternité", "La tricherie", "Le mensonge", "L'indifférence"], "correct": 0},
    ],
    // Niveau 2
    [
      {"question": "Que signifie le respect du bien public ?", "options": ["Prendre soin des infrastructures et équipements collectifs", "Utiliser les biens publics pour soi seul", "Ignorer l'état des routes", "Privatiser les services publics"], "correct": 0},
      {"question": "Qu'est-ce que l'engagement associatif ?", "options": ["Travailler pour un parti politique", "Participer bénévolement à des activités d'intérêt général", "Rejoindre une entreprise", "Cotiser à une banque"], "correct": 1},
      {"question": "Que représente le fait de payer ses impôts ?", "options": ["Une perte d'argent", "Une contribution au financement des services publics", "Un cadeau au gouvernement", "Une obligation inutile"], "correct": 1},
      {"question": "Pourquoi signaler une infraction à la loi est-il un acte civique ?", "options": ["Pour punir son voisin", "Parce que cela protège la communauté et renforce l'ordre social", "Pour obtenir une récompense", "Pour se faire remarquer"], "correct": 1},
      {"question": "Comment lutter contre la corruption au quotidien ?", "options": ["En refusant de donner ou de recevoir des pots-de-vin", "En ignorant les pratiques corrompues", "En payant pour obtenir des services plus vite", "En évitant toute relation avec les fonctionnaires"], "correct": 0},
      {"question": "Qu'est-ce qu'un bénévole ?", "options": ["Un salarié payé au minimum", "Une personne qui travaille sans rémunération pour le bien commun", "Un fonctionnaire", "Un entrepreneur"], "correct": 1},
      {"question": "Qu'est-ce que la solidarité nationale ?", "options": ["L'entraide entre les membres d'une même communauté", "La compétition entre les régions", "L'aide uniquement aux étrangers", "L'indifférence aux problèmes des autres"], "correct": 0},
      {"question": "Quel comportement favorise la cohésion sociale ?", "options": ["Répandre des rumeurs", "Le dialogue et le respect des différences", "L'exclusion des minorités", "La méfiance entre communautés"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Qu'est-ce que l'éthique civique ?", "options": ["L'ensemble des valeurs qui guident la conduite d'un bon citoyen", "Les règles d'une entreprise", "Les lois écrites", "Les coutumes tribales uniquement"], "correct": 0},
      {"question": "Pourquoi la diversité culturelle est-elle une richesse ?", "options": ["Elle crée des conflits inévitables", "Elle favorise l'échange et l'enrichissement mutuel des cultures", "Elle affaiblit l'identité nationale", "Elle complique la gouvernance"], "correct": 1},
      {"question": "Qu'est-ce que la désobéissance civile pacifique ?", "options": ["Un acte violent contre l'État", "Le refus non violent d'obéir à une loi jugée injuste", "La fuite du pays", "L'abstention aux élections"], "correct": 1},
      {"question": "Que signifie 'vivre en démocratie' au quotidien ?", "options": ["Faire uniquement ce que l'on veut", "Respecter les opinions des autres et participer à la vie collective", "Obéir aveuglément aux dirigeants", "Ignorer la politique"], "correct": 1},
      {"question": "Quel est l'impact du civisme sur le développement d'un pays ?", "options": ["Aucun impact", "Il favorise la bonne gouvernance et le progrès social", "Il ralentit l'économie", "Il augmente les impôts"], "correct": 1},
      {"question": "Qu'est-ce que la citoyenneté mondiale ?", "options": ["La renonciation à sa nationalité", "La conscience d'appartenir à une communauté humaine globale", "Le droit de vivre n'importe où sans restrictions", "L'appartenance à une organisation mondiale"], "correct": 1},
      {"question": "Comment promouvoir la paix dans sa communauté ?", "options": ["En ignorant les conflits", "En favorisant le dialogue et le respect mutuel", "En imposant ses opinions", "En évitant tout contact avec les autres communautés"], "correct": 1},
      {"question": "Quelle est la relation entre éducation civique et démocratie ?", "options": ["L'éducation civique affaiblit la démocratie", "L'éducation civique est inutile dans une démocratie", "L'éducation civique renforce la participation citoyenne et la démocratie", "Il n'y a aucun lien entre les deux"], "correct": 2},
    ],
  ],

  // ────────────────────────────────────── CITOYENNETÉ NUMÉRIQUE (NOUVEAU)
  "Citoyenneté numérique": [
    // Niveau 1
    [
      {"question": "Qu'est-ce que la citoyenneté numérique ?", "options": ["L'utilisation responsable et éthique des technologies numériques", "Le fait d'avoir un smartphone", "L'accès illimité à internet", "La possession d'un ordinateur"], "correct": 0},
      {"question": "Qu'est-ce qu'une donnée personnelle ?", "options": ["Un fichier stocké sur internet", "Toute information permettant d'identifier une personne", "Un mot de passe", "Un document officiel"], "correct": 1},
      {"question": "Que signifie le terme 'harcèlement en ligne' ?", "options": ["Des publicités intrusives", "Des comportements agressifs et répétés envers une personne sur internet", "Des emails non sollicités", "Des virus informatiques"], "correct": 1},
      {"question": "Qu'est-ce qu'un mot de passe sécurisé ?", "options": ["Son prénom et sa date de naissance", "Un mot de passe court facile à retenir", "Un mot de passe long combinant lettres, chiffres et symboles", "Le mot 'password'"], "correct": 2},
      {"question": "Que faire si on reçoit un email d'un expéditeur inconnu avec un lien ?", "options": ["Cliquer immédiatement pour voir le contenu", "Ne pas cliquer et signaler le message comme spam", "Répondre pour demander plus d'informations", "Transférer à tous ses contacts"], "correct": 1},
      {"question": "Qu'est-ce que les 'fake news' ?", "options": ["Des nouvelles en anglais", "Des informations fausses diffusées délibérément", "Des informations payantes", "Des nouvelles très anciennes"], "correct": 1},
      {"question": "Comment protéger sa vie privée sur les réseaux sociaux ?", "options": ["Partager toutes ses informations publiquement", "Configurer les paramètres de confidentialité et limiter les partages", "Désactiver tous ses comptes", "Ignorer les paramètres de sécurité"], "correct": 1},
      {"question": "Qu'est-ce que le droit à l'oubli numérique ?", "options": ["Le droit d'oublier ses mots de passe", "Le droit de demander la suppression de ses données personnelles en ligne", "L'interdiction de stocker des données", "Le droit de changer d'identité"], "correct": 1},
      {"question": "Qu'est-ce que le phishing ?", "options": ["Un jeu en ligne", "Une tentative de vol de données personnelles via de faux emails ou sites", "Une technique de pêche sportive", "Un logiciel de protection"], "correct": 1},
      {"question": "Pourquoi est-il important de vérifier une information avant de la partager ?", "options": ["Pour éviter de ralentir sa connexion", "Pour éviter de propager de fausses informations", "Pour économiser des données mobiles", "C'est inutile"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Qu'est-ce que l'identité numérique ?", "options": ["Une carte d'identité électronique", "L'ensemble des traces et informations qu'on laisse en ligne", "Un profil sur un seul réseau social", "Un email professionnel"], "correct": 1},
      {"question": "Comment vérifier si une information en ligne est fiable ?", "options": ["En regardant le nombre de likes", "En croisant plusieurs sources crédibles et reconnues", "En faisant confiance aux premiers résultats Google", "En lisant uniquement les commentaires"], "correct": 1},
      {"question": "Qu'est-ce qu'une empreinte numérique ?", "options": ["Une signature biométrique", "Les traces laissées par nos activités sur internet", "Un type de virus", "Un mode de paiement"], "correct": 1},
      {"question": "Que faire face au cyberharcèlement ?", "options": ["Répondre agressivement", "Signaler le harceleur, conserver les preuves et en parler à un adulte", "Supprimer son compte", "Ignorer sans agir"], "correct": 1},
      {"question": "Qu'est-ce que le droit d'auteur numérique ?", "options": ["Le droit de copier tout contenu en ligne", "La protection des œuvres créées, même diffusées sur internet", "L'obligation de payer pour lire des articles", "Le droit d'utiliser librement toute image"], "correct": 1},
      {"question": "Quel est le danger principal des réseaux Wi-Fi publics ?", "options": ["Ils consomment trop de batterie", "Les données peuvent être interceptées par des tiers", "Ils sont toujours trop lents", "Ils bloquent certains sites"], "correct": 1},
      {"question": "Qu'est-ce qu'un logiciel malveillant (malware) ?", "options": ["Un logiciel trop lent", "Un programme conçu pour nuire à un système informatique", "Un antivirus", "Un logiciel non mis à jour"], "correct": 1},
      {"question": "Comment protéger ses enfants sur internet ?", "options": ["En leur interdisant tout accès à internet", "Avec un contrôle parental adapté et un dialogue ouvert", "En leur laissant une liberté totale", "En utilisant uniquement des applications payantes"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Qu'est-ce que la neutralité du net ?", "options": ["L'absence de censure sur internet", "Le principe que toutes les données internet sont traitées de façon égale", "L'accès gratuit à internet pour tous", "L'interdiction des publicités en ligne"], "correct": 1},
      {"question": "Qu'est-ce qu'un deepfake ?", "options": ["Un réseau social secret", "Une vidéo ou image truquée par intelligence artificielle pour tromper", "Un type de piratage informatique", "Un logiciel de montage vidéo professionnel"], "correct": 1},
      {"question": "Que signifie 'open source' ?", "options": ["Un logiciel payant de qualité", "Un logiciel dont le code source est accessible et modifiable par tous", "Un réseau social ouvert", "Un fichier non crypté"], "correct": 1},
      {"question": "Qu'est-ce que le HTTPS indique sur un site web ?", "options": ["Que le site est gratuit", "Que la connexion est sécurisée et les données chiffrées", "Que le site appartient au gouvernement", "Que le site est populaire"], "correct": 1},
      {"question": "Qu'est-ce que l'intelligence artificielle ?", "options": ["Un robot humanoïde", "Des algorithmes capables d'apprendre et de simuler certaines formes d'intelligence", "Un superordinateur", "Internet en version avancée"], "correct": 1},
      {"question": "Quels droits numériques les citoyens doivent-ils revendiquer ?", "options": ["Le droit d'accéder à internet, à la vie privée et à la protection des données", "Le droit de pirater légalement", "L'accès illimité à tous les contenus sans restriction", "Le droit d'anonymat total"], "correct": 0},
      {"question": "Qu'est-ce que la fracture numérique ?", "options": ["Une panne de réseau", "L'inégalité d'accès aux technologies numériques entre les personnes et régions", "Un conflit entre opérateurs téléphoniques", "Le coût élevé des smartphones"], "correct": 1},
      {"question": "Comment un citoyen peut-il utiliser le numérique pour s'engager politiquement ?", "options": ["En envoyant des menaces aux dirigeants", "En participant à des pétitions en ligne, en suivant l'actualité et en votant informé", "En créant des faux comptes", "En diffusant de la propagande"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── ENVIRONNEMENT (NOUVEAU)
  "Environnement": [
    // Niveau 1
    [
      {"question": "Qu'est-ce que l'effet de serre ?", "options": ["Une serre de jardinage moderne", "Un phénomène naturel amplifié par les gaz polluants qui réchauffe la planète", "Un type de pollution sonore", "Un phénomène uniquement artificiel"], "correct": 1},
      {"question": "Qu'est-ce que le recyclage ?", "options": ["Jeter les déchets dans la nature", "Transformer les déchets en nouvelles matières réutilisables", "Brûler les déchets", "Exporter les déchets"], "correct": 1},
      {"question": "Quel gaz est principalement responsable du réchauffement climatique ?", "options": ["Le dioxyde de carbone (CO2)", "L'oxygène", "L'azote", "L'hydrogène"], "correct": 0},
      {"question": "Qu'est-ce que la biodiversité ?", "options": ["La diversité des cultures humaines", "La variété des espèces vivantes sur Terre", "La diversité des minéraux", "La diversité des religions"], "correct": 1},
      {"question": "Qu'est-ce qu'une énergie renouvelable ?", "options": ["Une énergie très chère", "Une énergie dont la source se régénère naturellement", "L'énergie nucléaire", "Une énergie importée"], "correct": 1},
      {"question": "Que signifie 'développement durable' ?", "options": ["Un développement très rapide", "Un développement qui satisfait les besoins actuels sans compromettre ceux des générations futures", "La construction de bâtiments solides", "L'agriculture intensive"], "correct": 1},
      {"question": "Pourquoi ne faut-il pas gaspiller l'eau ?", "options": ["Parce que l'eau coûte cher", "Parce que l'eau douce est une ressource limitée et précieuse", "Parce que les robinets s'usent", "Ce n'est pas important"], "correct": 1},
      {"question": "Quelle est l'une des principales causes de la déforestation ?", "options": ["Le tourisme", "L'agriculture intensive et l'exploitation du bois", "Les pluies abondantes", "Les tremblements de terre"], "correct": 1},
      {"question": "Comment réduire sa consommation d'énergie à la maison ?", "options": ["Laisser toutes les lumières allumées", "Éteindre les appareils inutilisés et utiliser des ampoules LED", "Augmenter le chauffage", "Utiliser plus d'appareils électriques"], "correct": 1},
      {"question": "Qu'est-ce qu'une zone naturelle protégée ?", "options": ["Un parc d'attractions", "Un espace où la nature est préservée des activités humaines nuisibles", "Une forêt exploitée", "Un terrain agricole"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Qu'est-ce que l'empreinte carbone ?", "options": ["Une trace de pas dans le sable", "La quantité de CO2 émise par nos activités", "La surface forestière d'un pays", "Le poids de nos déchets"], "correct": 1},
      {"question": "Quel accord international lutte contre le changement climatique ?", "options": ["Le Traité de Kyoto uniquement", "L'Accord de Paris", "La Convention de Berne", "Le Protocole de Montréal"], "correct": 1},
      {"question": "Pourquoi préserver les abeilles est-il crucial ?", "options": ["Pour leur miel uniquement", "Car elles pollinisent les plantes et maintiennent la biodiversité et notre alimentation", "Pour décorer les jardins", "Car elles nettoient l'air"], "correct": 1},
      {"question": "Qu'est-ce que le compostage ?", "options": ["Un type de recyclage du plastique", "La transformation des déchets organiques en engrais naturel", "Un mode de traitement des eaux usées", "La collecte des ordures ménagères"], "correct": 1},
      {"question": "Comment lutter contre la pollution des océans ?", "options": ["En augmentant la pêche industrielle", "En réduisant l'utilisation du plastique à usage unique", "En construisant plus de bateaux", "En déversant les déchets en mer profonde"], "correct": 1},
      {"question": "Qu'est-ce que l'agriculture biologique ?", "options": ["Une agriculture avec des OGM uniquement", "Une agriculture sans pesticides ni engrais chimiques de synthèse", "Une agriculture entièrement mécanisée", "Une agriculture sous serre uniquement"], "correct": 1},
      {"question": "Qu'est-ce qu'une espèce en voie de disparition ?", "options": ["Une espèce très répandue", "Une espèce dont la population est si faible qu'elle risque de disparaître", "Une espèce invasive", "Une espèce domestique"], "correct": 1},
      {"question": "Quel est l'impact de la déforestation sur le climat ?", "options": ["Elle rafraîchit le climat", "Elle augmente les émissions de CO2 et réduit la capacité d'absorption de carbone", "Elle n'a aucun impact sur le climat", "Elle augmente les précipitations"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Qu'est-ce que l'économie circulaire ?", "options": ["Une économie qui favorise la croissance infinie", "Un modèle économique qui minimise les déchets en réutilisant les ressources", "Une économie basée sur le commerce circulaire", "Un système financier mondial"], "correct": 1},
      {"question": "Quel est le rôle des forêts tropicales dans le climat mondial ?", "options": ["Elles augmentent les températures", "Elles absorbent le CO2 et régulent les précipitations mondiales", "Elles n'ont pas d'impact sur le climat mondial", "Elles produisent des gaz à effet de serre"], "correct": 1},
      {"question": "Qu'est-ce que la transition énergétique ?", "options": ["Le remplacement d'une compagnie d'énergie par une autre", "Le passage progressif des énergies fossiles aux énergies renouvelables", "L'augmentation de la production pétrolière", "La privatisation des réseaux électriques"], "correct": 1},
      {"question": "Qu'est-ce que le protocole de Montréal a accompli ?", "options": ["Il a réduit les émissions de CO2", "Il a protégé la couche d'ozone en réduisant les substances appauvrissant l'ozone", "Il a interdit la déforestation mondiale", "Il a créé des zones marines protégées"], "correct": 1},
      {"question": "Comment les villes peuvent-elles devenir plus durables ?", "options": ["En construisant plus de routes et parkings", "En développant les transports verts, les espaces verts et réduisant les déchets", "En augmentant la densité de population", "En privatisant tous les services publics"], "correct": 1},
      {"question": "Qu'est-ce que la Côte d'Ivoire peut faire pour protéger ses forêts ?", "options": ["Augmenter l'exploitation forestière", "Renforcer les zones protégées, promouvoir l'agroforesterie et sanctionner la déforestation illégale", "Interdire toute agriculture", "Privatiser toutes les forêts"], "correct": 1},
      {"question": "Qu'est-ce que l'adaptation climatique ?", "options": ["Réduire les émissions de gaz à effet de serre", "Modifier nos sociétés et infrastructures pour faire face aux impacts du changement climatique", "Annuler tous les accords climatiques", "Nier l'existence du changement climatique"], "correct": 1},
      {"question": "Quel est l'enjeu environnemental majeur pour l'Afrique de l'Ouest ?", "options": ["Le refroidissement climatique", "La désertification, la déforestation et la raréfaction des ressources en eau", "L'excès de précipitations uniquement", "La surpopulation animale"], "correct": 1},
    ],
  ],

  // ────────────────────────────────────── RESPONSABILITÉ CIVIQUE (NOUVEAU)
  "Responsabilité civique": [
    // Niveau 1
    [
      {"question": "Qu'est-ce que la responsabilité civique ?", "options": ["L'ensemble des devoirs d'un citoyen envers sa communauté et son pays", "Le droit de faire tout ce qu'on veut", "Une obligation imposée par l'armée", "Un impôt supplémentaire"], "correct": 0},
      {"question": "Pourquoi payer ses impôts est-il un devoir civique ?", "options": ["Pour enrichir les politiciens", "Parce que les impôts financent les services publics dont tout le monde bénéficie", "Parce que c'est une tradition", "Parce qu'on y est obligé sous peine de prison immédiate"], "correct": 1},
      {"question": "Qu'est-ce que le service civique ?", "options": ["Le service militaire obligatoire", "Une mission d'intérêt général réalisée par des volontaires pour la communauté", "Un emploi dans la fonction publique", "Un cours d'éducation civique"], "correct": 1},
      {"question": "Qu'est-ce que la corruption ?", "options": ["Un type de maladie", "L'abus de pouvoir ou de confiance à des fins personnelles illégales", "Un comportement normal dans les affaires", "Une forme de négociation"], "correct": 1},
      {"question": "Comment participer à la vie de sa commune ?", "options": ["En évitant les élections", "En votant, en assistant aux réunions publiques et en s'engageant associativement", "En payant plus d'impôts", "En critiquant les élus sans agir"], "correct": 1},
      {"question": "Qu'est-ce qu'un citoyen responsable ?", "options": ["Quelqu'un qui obéit aveuglément", "Quelqu'un qui connaît ses droits et devoirs et agit pour le bien commun", "Quelqu'un qui évite toute responsabilité", "Quelqu'un qui ne vote jamais"], "correct": 1},
      {"question": "Qu'est-ce que l'intérêt général ?", "options": ["Ce qui est bon pour une personne riche", "Ce qui est bon pour l'ensemble de la société", "Ce qui rapporte de l'argent", "Ce qui plait à la majorité uniquement"], "correct": 1},
      {"question": "Comment lutter contre la désinformation ?", "options": ["En partageant toutes les informations reçues", "En vérifiant les sources avant de partager une information", "En faisant confiance aux rumeurs", "En évitant internet"], "correct": 1},
      {"question": "Pourquoi respecter les lois est-il important ?", "options": ["Pour éviter la prison uniquement", "Pour assurer l'ordre, la justice et la coexistence pacifique dans la société", "Par habitude", "Parce que les policiers surveillent"], "correct": 1},
      {"question": "Quel est le droit de vote ?", "options": ["Le droit de voter plusieurs fois", "Le droit de participer aux élections pour choisir ses représentants", "Le droit d'imposer son candidat", "Le droit d'annuler les élections"], "correct": 1},
    ],
    // Niveau 2
    [
      {"question": "Qu'est-ce que la démocratie participative ?", "options": ["Une démocratie sans élections", "La participation directe des citoyens aux décisions qui les concernent", "Un gouvernement d'experts", "Le vote en ligne uniquement"], "correct": 1},
      {"question": "Quel est le devoir des médias dans une démocratie ?", "options": ["Soutenir le gouvernement en place", "Informer le public de façon objective, vérifiée et pluraliste", "Divertir uniquement", "Diffuser uniquement les informations officielles"], "correct": 1},
      {"question": "Qu'est-ce que la société civile ?", "options": ["Les militaires", "L'ensemble des associations, ONG et organisations non gouvernementales", "La population rurale", "Les fonctionnaires"], "correct": 1},
      {"question": "Comment un citoyen peut-il influencer les politiques publiques ?", "options": ["En achetant les médias", "En votant, en pétitionnant, en rejoignant des associations et en se mobilisant pacifiquement", "En menaçant les élus", "En ignorant la politique"], "correct": 1},
      {"question": "Pourquoi signaler les infractions à la loi est-il un acte civique ?", "options": ["Pour nuire à ses voisins", "Pour permettre aux autorités d'agir et protéger la communauté", "Pour obtenir de l'argent", "Ce n'est pas un acte civique"], "correct": 1},
      {"question": "Qu'est-ce que le lobbying dans le cadre légal ?", "options": ["La corruption des élus", "La pratique légale d'influencer les décisions politiques en défendant des intérêts", "L'achat de votes", "Une forme de chantage"], "correct": 1},
      {"question": "Quel est le rôle des ONG dans une société ?", "options": ["Remplacer le gouvernement", "Défendre des causes d'intérêt public et compléter l'action de l'État", "Faire du profit", "Créer de la division"], "correct": 1},
      {"question": "Qu'est-ce que la transparence dans la gouvernance ?", "options": ["Cacher les informations sensibles", "L'accès du public aux informations sur les actions et décisions du gouvernement", "La confidentialité totale des affaires publiques", "La communication uniquement positive"], "correct": 1},
    ],
    // Niveau 3
    [
      {"question": "Qu'est-ce que la désobéissance civile pacifique ?", "options": ["Un acte violent contre l'État", "Le refus non violent et assumé d'obéir à une loi jugée profondément injuste", "La fuite du pays", "L'abstention aux élections"], "correct": 1},
      {"question": "Que signifie 'rendre des comptes' (accountability) en gouvernance ?", "options": ["Faire ses comptes bancaires", "Être transparent sur ses actions et en accepter les conséquences", "Rembourser les dettes", "Présenter un rapport financier"], "correct": 1},
      {"question": "Qu'est-ce que la vigilance citoyenne ?", "options": ["La surveillance de ses voisins", "La surveillance collective et pacifique des actions des gouvernants", "L'espionnage", "Le contrôle de la police"], "correct": 1},
      {"question": "Pourquoi la liberté de la presse est-elle essentielle dans une démocratie ?", "options": ["Elle permet aux journalistes de s'enrichir", "Elle permet d'informer le public et de contrôler les abus de pouvoir", "Elle affaiblit le gouvernement", "Elle crée de la confusion"], "correct": 1},
      {"question": "Comment prévenir la corruption dans les institutions publiques ?", "options": ["En augmentant les salaires des fonctionnaires uniquement", "Par des contrôles indépendants, la transparence financière et des sanctions fermes", "En interdisant les marchés publics", "En privatisant toutes les institutions"], "correct": 1},
      {"question": "Qu'est-ce que l'audit citoyen ?", "options": ["Un bilan médical pour les élus", "L'examen par des citoyens des comptes et actions publics pour vérifier leur légalité", "Un vote sanction", "Une procédure judiciaire"], "correct": 1},
      {"question": "Pourquoi la participation électorale est-elle un indicateur de santé démocratique ?", "options": ["Elle ne l'est pas", "Un fort taux de participation montre l'implication des citoyens dans la démocratie", "Un faible taux est toujours meilleur", "Seul le résultat compte, pas la participation"], "correct": 1},
      {"question": "Comment réconcilier responsabilité individuelle et bien commun ?", "options": ["En privilégiant toujours ses intérêts personnels", "En agissant de manière à ce que ses choix profitent à la fois à soi et à la société", "En ignorant ses droits individuels", "En remettant toutes les décisions à l'État"], "correct": 1},
    ],
  ],
};
