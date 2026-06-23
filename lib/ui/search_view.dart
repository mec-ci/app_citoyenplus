import 'package:flutter/material.dart';
import 'package:citoyen_plus/models/publication.dart';
import 'package:citoyen_plus/models/utilisateur_profile.dart';
import 'package:citoyen_plus/models/post.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/services/api_service.dart';
import 'package:citoyen_plus/widgets/publication_card.dart';
import 'package:citoyen_plus/widgets/commentaires_sheet.dart';
import 'package:citoyen_plus/services/commentaire_service.dart';
import 'package:citoyen_plus/services/reaction_service.dart';
import 'package:citoyen_plus/widgets/simple_html_view.dart';
import 'detail_page.dart';
import 'livre_pdf_view.dart';
import 'quiz_view.dart';
import 'profil_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Future<Map<String, dynamic>>? _searchFuture;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searchFuture = _multiSearch(query);
    });
  }

  Future<Map<String, dynamic>> _multiSearch(String query) async {
    final results = await Future.wait([
      ApiService.search(query).catchError((_) => <String, dynamic>{}),
      ApiService.fetchPosts(page: 1, limit: 5).catchError((_) => <PostModel>[]),
      // La recherche textuelle des signalements est faite côté backend via le
      // paramètre `search` : l'API renvoie déjà les signalements filtrés.
      ApiService.fetchSignalements(page: 1, limit: 20, search: query)
          .catchError((_) => <SignalementModel>[]),
      ApiService.fetchLibraryDocuments(query).catchError((_) => <Map<String, dynamic>>[]),
      ApiService.fetchQuizCategories().catchError((_) => <Map<String, dynamic>>[]),
    ]);

    return {
      'search': results[0] as Map<String, dynamic>,
      'posts': results[1] as List<PostModel>,
      'signalements': results[2] as List<SignalementModel>,
      'documents': results[3] as List<Map<String, dynamic>>,
      'quizCategories': results[4] as List<Map<String, dynamic>>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        backgroundColor: const Color(0xFFE65C00),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65C00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchFuture == null
                    ? _buildEmptyState()
                    : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Tapez un terme et lancez la recherche.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _buildResults() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final searchResults = data['search'] as Map<String, dynamic>;
        final users = (searchResults['users'] as List?)
                ?.map((e) => UtilisateurProfile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <UtilisateurProfile>[];
        final publications = (searchResults['publications'] as List?)
                ?.map((e) => Publication.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <Publication>[];
        final posts = data['posts'] as List<PostModel>;
        final signalements = data['signalements'] as List<SignalementModel>;
        final documents = data['documents'] as List<Map<String, dynamic>>;
        final quizCategories = data['quizCategories'] as List<Map<String, dynamic>>;

        final hasResults = users.isNotEmpty ||
            publications.isNotEmpty ||
            posts.isNotEmpty ||
            signalements.isNotEmpty ||
            documents.isNotEmpty ||
            quizCategories.isNotEmpty;

        if (!hasResults) {
          return const Center(
            child: Text(
              'Aucun resultat trouve.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView(
          children: [
            if (users.isNotEmpty) ...[
              _sectionHeader('Utilisateurs', Icons.people_outline),
              const SizedBox(height: 8),
              ...users.map((user) => _userTile(user)),
              const SizedBox(height: 16),
            ],
            if (publications.isNotEmpty) ...[
              _sectionHeader('Publications', Icons.article_outlined),
              const SizedBox(height: 8),
              ...publications.map((pub) => PublicationCard(
                    publication: pub,
                    onComment: () => showCommentairesSheet(
                      context,
                      cible: pub.type == 'signalement'
                          ? CommentaireCible.signalement
                          : CommentaireCible.actualite,
                      id: pub.id,
                    ),
                    onLike: () async {
                      // Persiste le like au backend (l'UI a déjà été mise à
                      // jour de façon optimiste par la carte). Best-effort.
                      try {
                        if (pub.type == 'signalement') {
                          await ReactionService.toggleSignalement(pub.id);
                        } else {
                          await ReactionService.toggleActualite(pub.id);
                        }
                      } catch (_) {}
                    },
                  )),
              const SizedBox(height: 16),
            ],
            if (posts.isNotEmpty) ...[
              _sectionHeader('Actualites', Icons.newspaper_outlined),
              const SizedBox(height: 8),
              ...posts.map((post) => _postTile(post)),
              const SizedBox(height: 16),
            ],
            if (signalements.isNotEmpty) ...[
              _sectionHeader('Signalements', Icons.report_problem_outlined),
              const SizedBox(height: 8),
              ...signalements.map((s) => _signalementTile(s)),
              const SizedBox(height: 16),
            ],
            if (documents.isNotEmpty) ...[
              _sectionHeader('Documents', Icons.library_books_outlined),
              const SizedBox(height: 8),
              ...documents.map((doc) => _documentTile(doc)),
              const SizedBox(height: 16),
            ],
            if (quizCategories.isNotEmpty) ...[
              _sectionHeader('Quiz', Icons.emoji_events_outlined),
              const SizedBox(height: 8),
              ...quizCategories.map((cat) => _quizTile(cat)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE65C00)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _userTile(UtilisateurProfile user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1556B5),
        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
        child: user.avatar == null
            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U')
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.bio ?? ''),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilView(userId: user.id),
          ),
        );
      },
    );
  }

  Widget _postTile(PostModel post) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: post.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.article, color: Colors.grey),
                ),
              ),
            )
          : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article, color: Colors.grey),
            ),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(htmlToPlainText(post.excerpt),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        // Le contenu des actualités est du HTML : on le convertit en texte
        // lisible pour la page de détail générique.
        final details = post.content.isNotEmpty
            ? htmlToPlainText(post.content)
            : (post.excerpt.isNotEmpty
                ? htmlToPlainText(post.excerpt)
                : post.title);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(title: post.title, details: details),
          ),
        );
      },
    );
  }

  Widget _signalementTile(SignalementModel s) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.location_on, color: Color(0xFFE65C00)),
      ),
      title: Text(s.titre, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(s.adresse, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        final buffer = StringBuffer();
        if (s.description.isNotEmpty) {
          buffer.write(s.description);
          buffer.write('\n\n');
        }
        buffer.write('Statut : ${s.statut}');
        if (s.adresse.isNotEmpty) buffer.write('\nAdresse : ${s.adresse}');
        if (s.categorie?.nom.isNotEmpty == true) {
          buffer.write('\nCatégorie : ${s.categorie!.nom}');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(
              title: s.titre,
              details: buffer.toString(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDocument(Map<String, dynamic> doc) async {
    final rawUrl = (doc['pdf'] ?? doc['url'] ?? doc['documentUrl'] ?? '')
        .toString();
    final title = doc['title']?.toString() ?? doc['titre']?.toString() ?? '';
    if (rawUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document introuvable')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivrePdfView(pdf: rawUrl, title: title),
      ),
    );
  }

  Widget _documentTile(Map<String, dynamic> doc) {
    final title = doc['title']?.toString() ?? doc['titre']?.toString() ?? '';
    final desc = doc['description']?.toString() ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F1FB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.description, color: Color(0xFF185FA5)),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _openDocument(doc),
    );
  }

  Widget _quizTile(Map<String, dynamic> cat) {
    final title = cat['title']?.toString() ??
        cat['titre']?.toString() ??
        cat['nom']?.toString() ??
        cat['name']?.toString() ??
        '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3DE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.quiz_outlined, color: Color(0xFF3B6D11)),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        if (title.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizLevelView(
              categorie: title,
              color: const Color(0xFFE65C00),
              icon: Icons.quiz_outlined,
              unlockedLevel: 1,
              completedLevels: const <int, bool>{},
              onProgressChanged: () {},
            ),
          ),
        );
      },
    );
  }
}
