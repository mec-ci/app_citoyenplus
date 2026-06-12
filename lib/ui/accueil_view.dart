import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/publication.dart';
import '../models/commentaire.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/publication_card.dart';
import 'entete.dart';
import 'profil_view.dart';
import 'search_view.dart';
import 'messages_view.dart';

class AccueilView extends StatefulWidget {
  final VoidCallback? onNotificationPressed;

  const AccueilView({super.key, this.onNotificationPressed});

  @override
  State<AccueilView> createState() => _AccueilViewState();
}

class _AccueilViewState extends State<AccueilView> {
  int _selectedTab = 0;
  Future<Map<String, dynamic>> _futureFeed = Future.value({'publications': <Publication>[], 'nextCursor': null});
  Future<Map<String, dynamic>> _futureSubscriptions = Future.value({'publications': <Publication>[], 'nextCursor': null});
  Future<List<String>> _futureCategories = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _futureFeed = ApiService.fetchPublications();
      _futureSubscriptions = ApiService.fetchSubscriptionFeed();
      _futureCategories = ApiService.fetchCategories();
    });
  }

  Future<void> _showCreatePublicationModal() async {
    final _descriptionController = TextEditingController();
    final categories = await _futureCategories;
    final typeOptions = ['actualite', 'signalement'];
    int selectedType = 0;
    String selectedCategory = categories.isNotEmpty ? categories.first : 'Général';
    XFile? selectedImage;
    Uint8List? previewBytes;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text('Nouveau post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: List.generate(typeOptions.length, (index) {
                        final type = typeOptions[index];
                        final selected = index == selectedType;
                        return ChoiceChip(
                          label: Text(type == 'actualite' ? 'Actualité' : 'Signalement'),
                          selected: selected,
                          onSelected: (_) => setModalState(() => selectedType = index),
                          selectedColor: const Color(0xFFFF7F00),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(value: category, child: Text(category));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Raconte ton initiative, partage une envie ou signale un problème...',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setModalState(() {
                            selectedImage = file;
                            previewBytes = bytes;
                          });
                        }
                      },
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          color: const Color(0xFFF8F9FF),
                        ),
                        child: selectedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_outlined, size: 28, color: Colors.black45),
                                    SizedBox(height: 8),
                                    Text('Ajouter une photo (facultatif)', style: TextStyle(color: Colors.black45)),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: previewBytes != null
                                    ? Image.memory(previewBytes!, fit: BoxFit.cover)
                                    : const SizedBox.shrink(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_descriptionController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le message ne peut pas être vide')));
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                try {
                                  await ApiService.createPublication(
                                    texte: _descriptionController.text.trim(),
                                    categorie: selectedCategory,
                                    type: typeOptions[selectedType],
                                    images: selectedImage != null ? [selectedImage!] : null,
                                  );
                                  if (mounted) {
                                    Navigator.of(sheetContext).pop();
                                    _loadData();
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Publication créée avec succès')));
                                  }
                                } catch (error) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('Erreur: $error')));
                                  }
                                } finally {
                                  if (mounted) setModalState(() => isSubmitting = false);
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Publier'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showComments(Publication publication) async {
    final commentController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
            builder: (context, setModalState) {
            Future<List<Commentaire>> _getComments() async {
              return ApiService.fetchPublicationComments(publication.id);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text('Commentaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: MediaQuery.of(sheetContext).size.height * 0.52,
                    child: FutureBuilder<List<Commentaire>>(
                      future: _getComments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Erreur: ${snapshot.error}'));
                        }
                        final comments = snapshot.data ?? [];
                        if (comments.isEmpty) {
                          return const Center(child: Text('Aucun commentaire pour l\'instant.'));
                        }
                        return ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1556B5),
                                child: Text(comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'C'),
                              ),
                              title: Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(comment.texte),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Répondre...',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFFF7F00),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;
                            await ApiService.createComment(publicationId: publication.id, texte: text);
                            setModalState(() => commentController.clear());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Fil d\'actualité',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Découvre les initiatives, actualités citoyennes et tendances près de chez toi.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchView())),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search_rounded, color: Colors.black38),
                  SizedBox(width: 12),
                  Text('Rechercher une publication ou un profil', style: TextStyle(color: Colors.black45)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesView())),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7F00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.message_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exprime-toi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Partage une actualité, un signalement ou un message citoyen.', style: TextStyle(color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _showCreatePublicationModal,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF7F00)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Créer une publication', style: TextStyle(color: Color(0xFFFF7F00), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        _buildTabButton('Pour vous', 0),
        const SizedBox(width: 10),
        _buildTabButton('Abonnements', 1),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF7F00) : const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildTrendChips() {
    return FutureBuilder<List<String>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        final chips = snapshot.hasData && (snapshot.data ?? []).isNotEmpty
            ? snapshot.data!.take(5).toList()
            : ['Participation', 'Logement', 'Éducation', 'Transport', 'Environnement'];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: chips.map((label) {
            return Chip(
              backgroundColor: const Color(0xFFF8F9FF),
              label: Text(label, style: const TextStyle(color: Colors.black87)),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: EntetePersonalise(onNotificationPressed: widget.onNotificationPressed),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFF7F00),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 18),
            _buildActionCard(),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 20),
            _buildTrendChips(),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: _selectedTab == 0 ? _futureFeed : _futureSubscriptions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 14),
                      ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
                    ],
                  );
                }
                final data = snapshot.data ?? {'publications': <Publication>[]};
                final posts = (data['publications'] as List<Publication>?) ?? [];
                if (posts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Center(
                      child: Text('Aucune publication pour le moment.', style: TextStyle(color: Colors.black54)),
                    ),
                  );
                }
                return Column(
                  children: posts.map((publication) {
                    return PublicationCard(
                      publication: publication,
                      onProfileTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfilView(userId: publication.userId)),
                        );
                      },
                      onLike: () async {
                        try {
                            await ApiService.toggleLike(publication.id);
                          } catch (error) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de liker: $error')));
                          }
                      },
                      onComment: () => _showComments(publication),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
