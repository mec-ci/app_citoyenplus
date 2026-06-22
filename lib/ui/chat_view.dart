import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatView extends StatefulWidget {
  final Conversation conversation;
  const ChatView({super.key, required this.conversation});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  Future<List<Message>>? _futureMessages;
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    SocketService.instance.connect();
    SocketService.instance.joinConversation(widget.conversation.id);
    SocketService.instance.onMessage.listen((msg) {
      if (!mounted) return;
      if (msg.conversationId == widget.conversation.id) {
        // reload messages to keep ordering consistent
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.leaveConversation(widget.conversation.id);
    _messageController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    setState(() {
      _futureMessages = ApiService.getMessages(widget.conversation.id)
          .then((items) => items.map((json) => Message.fromJson(json)).toList());
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      // send via socket for realtime delivery; fallback to API if socket not available
      try {
        await SocketService.instance.sendMessage(widget.conversation.id, text);
      } catch (_) {
        await ApiService.sendMessage(conversationId: widget.conversation.id, texte: text);
      }
      _messageController.clear();
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.otherUserName),
            Text(
              '${widget.conversation.unreadCount} message(s) non lus',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65C00),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Message>>(
                future: _futureMessages,
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
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadMessages, child: const Text('Réessayer')),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return const Center(child: Text('Aucun message pour le moment.')); 
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.userId == widget.conversation.userId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFFE65C00) : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.texte,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black45,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE65C00),
                    child: IconButton(
                      onPressed: _sending ? null : _sendMessage,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
