import 'package:flutter/material.dart';
import '../core/network/error_handler.dart';
import '../services/commentaire_service.dart';
import '../services/user_service.dart';

const _orange = Color(0xFFE65C00);

/// Affiche la feuille de commentaires (liste + champ d'ajout) pour une cible.
///
/// [onCountChanged] est appelé avec le nombre total de commentaires à chaque
/// fois qu'il évolue (chargement, ajout, suppression), pour permettre à l'écran
/// parent de rafraîchir son compteur.
Future<void> showCommentairesSheet(
  BuildContext context, {
  required CommentaireCible cible,
  required String id,
  ValueChanged<int>? onCountChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CommentairesSheet(
      cible: cible,
      id: id,
      onCountChanged: onCountChanged,
    ),
  );
}

class CommentairesSheet extends StatefulWidget {
  final CommentaireCible cible;
  final String id;
  final ValueChanged<int>? onCountChanged;

  const CommentairesSheet({
    super.key,
    required this.cible,
    required this.id,
    this.onCountChanged,
  });

  @override
  State<CommentairesSheet> createState() => _CommentairesSheetState();
}

class _CommentairesSheetState extends State<CommentairesSheet> {
  static const int _pageSize = 20;

  final TextEditingController _controller = TextEditingController();
  final List<Commentaire> _commentaires = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _sending = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final id = await UserService.currentUserId();
    if (!mounted) return;
    setState(() => _currentUserId = id);
  }

  void _notifyCount() => widget.onCountChanged?.call(_total);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await CommentaireService.fetch(
        cible: widget.cible,
        id: widget.id,
        page: 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = 1;
        _commentaires
          ..clear()
          ..addAll(result.data);
        _total = result.total;
        _hasMore =
            result.data.isNotEmpty && _commentaires.length < result.total;
        _loading = false;
      });
      _notifyCount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = HttpErrorHandler.describe(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final result = await CommentaireService.fetch(
        cible: widget.cible,
        id: widget.id,
        page: next,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = next;
        _commentaires.addAll(result.data);
        _total = result.total;
        _hasMore =
            result.data.isNotEmpty && _commentaires.length < result.total;
        _loadingMore = false;
      });
      _notifyCount();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await CommentaireService.add(
        cible: widget.cible,
        id: widget.id,
        contenu: texte,
      );
      if (!mounted) return;
      setState(() {
        _commentaires.insert(0, created);
        _total += 1;
        _controller.clear();
        _sending = false;
      });
      _notifyCount();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'envoi : ${HttpErrorHandler.describe(e)}")),
      );
    }
  }

  Future<void> _delete(Commentaire c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le commentaire'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce commentaire ? Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await CommentaireService.delete(
        cible: widget.cible,
        id: widget.id,
        commentaireId: c.id,
      );
      if (!mounted) return;
      setState(() {
        _commentaires.removeWhere((e) => e.id == c.id);
        if (_total > 0) _total -= 1;
      });
      _notifyCount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression : ${HttpErrorHandler.describe(e)}')),
      );
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _total > 0 ? 'Commentaires ($_total)' : 'Commentaires',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildList(scrollController)),
              const Divider(height: 1),
              _buildInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _orange),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_commentaires.isEmpty) {
      return const Center(
        child: Text(
          'Aucun commentaire. Soyez le premier !',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_hasMore &&
            !_loadingMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 120) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _commentaires.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index >= _commentaires.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildCommentTile(_commentaires[index]);
        },
      ),
    );
  }

  Widget _buildCommentTile(Commentaire c) {
    final nom = c.auteur?.nom ?? 'Utilisateur';
    final avatar = c.auteur?.avatar;
    final isMine = _currentUserId != null &&
        c.auteur?.id != null &&
        c.auteur!.id == _currentUserId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFECECEC),
          backgroundImage: (avatar != null && avatar.isNotEmpty)
              ? NetworkImage(avatar)
              : null,
          child: (avatar == null || avatar.isEmpty)
              ? Text(
                  nom.isNotEmpty ? nom[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      nom,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(c.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                c.contenu,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        if (isMine)
          GestureDetector(
            onTap: () => _delete(c),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 6, top: 2),
              child: Icon(Icons.delete_outline, size: 18, color: Colors.black38),
            ),
          ),
      ],
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _orange,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
