import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/utilisateur_profile.dart';
import '../services/api_service.dart';
import '../widgets/publication_card.dart';
import 'profil_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Future<Map<String, dynamic>>? _futureResults;
  

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _futureResults = ApiService.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        backgroundColor: const Color(0xFFFF7F00),
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
                        hintText: 'Rechercher des utilisateurs ou des publications',
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
                    child: const Text('OK'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _futureResults == null
                    ? const Center(
                        child: Text(
                          'Tapez un terme et lancez la recherche.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : FutureBuilder<Map<String, dynamic>>(
                        future: _futureResults,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Erreur: ${snapshot.error}'));
                          }
                          final data = snapshot.data ?? {};
                          final users = data['users'] as List<UtilisateurProfile>? ?? [];
                          final publications = data['publications'] as List<Publication>? ?? [];
                          if (users.isEmpty && publications.isEmpty) {
                            return const Center(
                              child: Text('Aucun résultat trouvé.', style: TextStyle(color: Colors.black54)),
                            );
                          }
                          return ListView(
                            children: [
                              if (users.isNotEmpty) ...[
                                const Text('Utilisateurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                ...users.map((user) {
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                    leading: CircleAvatar(
                                          backgroundColor: const Color(0xFF1556B5),
                                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                                          child: user.avatar == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U') : null,
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
                                }),
                                const Divider(height: 32),
                              ],
                              if (publications.isNotEmpty) ...[
                                const Text('Publications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                ...publications.map((publication) {
                                  return PublicationCard(
                                    publication: publication,
                                    onComment: () {},
                                    onLike: () {},
                                  );
                                }),
                              ],
                            ],
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
