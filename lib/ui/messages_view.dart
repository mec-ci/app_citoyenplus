import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'chat_view.dart';
import '../services/socket_service.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  Future<List<Conversation>>? _futureConversations;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    SocketService.instance.connect();
    SocketService.instance.onMessage.listen((msg) {
      // any incoming message may affect conversations list; refresh
      _loadConversations();
    });
  }

  void _loadConversations() {
    setState(() {
      _futureConversations = ApiService.getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFFF7F00),
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _futureConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 14),
                  ElevatedButton(onPressed: _loadConversations, child: const Text('Réessayer')),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(
              child: Text('Tu n\'as pas encore de conversation.', style: TextStyle(color: Colors.black54)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadConversations(),
            color: const Color(0xFFFF7F00),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF1556B5),
                    backgroundImage: conversation.otherUserAvatar != null ? NetworkImage(conversation.otherUserAvatar!) : null,
                    child: conversation.otherUserAvatar == null
                        ? Text(conversation.otherUserName.isNotEmpty ? conversation.otherUserName[0].toUpperCase() : 'U')
                        : null,
                  ),
                  title: Text(conversation.otherUserName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7F00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatView(conversation: conversation),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}
