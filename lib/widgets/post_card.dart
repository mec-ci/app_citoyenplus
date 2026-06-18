import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final String? username;
  final String? avatarUrl;
  final String? timeAgo;
  final String? excerpt;

  const PostCard({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
    this.username,
    this.avatarUrl,
    this.timeAgo,
    this.excerpt,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;
  bool _liked = false;
  int _likeCount = 0;

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _share() {
    final text = '${widget.title}\n\n${widget.content}';
    Share.share(text);
  }

  Future<void> _showComments(BuildContext context) async {
    final commentCtrl = TextEditingController();
    final comments = <String>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, sheetSetState) {
          void sendComment() {
            final text = commentCtrl.text.trim();
            if (text.isEmpty) return;
            sheetSetState(() => comments.add(text));
            commentCtrl.clear();
          }

          final keyboardHeight = MediaQuery.of(sheetCtx).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: SizedBox(
              height: MediaQuery.of(sheetCtx).size.height * 0.6,
              child: Column(
                children: [
                  // ── Drag handle ─────────────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // ── En-tête ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Commentaires${comments.isNotEmpty ? " (${comments.length})" : ""}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx),
                          child: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // ── Liste ───────────────────────────────────────────────
                  Expanded(
                    child: comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mode_comment_outlined, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('Aucun commentaire pour l\'instant.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Sois le premier à commenter !', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF1556B5),
                                    child: Text('M', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(comments[i], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  // ── Saisie ──────────────────────────────────────────────
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => sendComment(),
                            decoration: const InputDecoration(
                              hintText: 'Écrire un commentaire…',
                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                              filled: true,
                              fillColor: Color(0xFFF8F9FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(24)),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: sendComment,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1556B5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    commentCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.username ?? 'Citoyen +';
    final timeAgo = widget.timeAgo ?? "À l'instant";
    final initial = username[0].toUpperCase();
    final bool hasMore = widget.content.length > 120;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE65C00), Color(0xFF1556B5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: widget.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _initiale(initial),
                                ),
                              )
                            : _initiale(initial),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black54),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Image ────────────────────────────────────────────────────
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                widget.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),

          // ── Actions ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(_liked),
                          size: 24,
                          color: _liked ? Colors.red : Colors.black87,
                        ),
                      ),
                      if (_likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$_likeCount',
                          style: TextStyle(
                            fontSize: 13,
                            color: _liked ? Colors.red : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Commentaires
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: const Icon(Icons.mode_comment_outlined, size: 24, color: Colors.black87),
                ),
                const SizedBox(width: 16),

                // Partager
                GestureDetector(
                  onTap: _share,
                  child: const Icon(Icons.near_me_outlined, size: 24, color: Colors.black87),
                ),

                const Spacer(),
                const Icon(Icons.bookmark_border, size: 24, color: Colors.black87),
              ],
            ),
          ),

          // ── Titre + Contenu ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    widget.content,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    widget.content,
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.45),
                  ),
                ),
                if (hasMore)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? 'voir moins' : 'voir plus',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _initiale(String letter) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Color(0xFF1556B5),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
