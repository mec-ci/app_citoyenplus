import 'package:flutter/material.dart';
import 'entete.dart';
import '../services/ai_chat_service.dart';

class AiChatView extends StatefulWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const AiChatView({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  State<AiChatView> createState() => AiChatViewState();
}

class AiChatViewState extends State<AiChatView> {
  // Historique affiché à l'écran
  final List<Map<String, dynamic>> _messages = [
    {
      "text":
          "Salut ! Je suis ton assistant IA Citoyen +. Pose-moi tes questions sur tes droits, les institutions ivoiriennes ou tes démarches citoyennes.",
      "isUser": false,
    },
  ];

  // Historique envoyé à l'API (format role/content)
  final List<Map<String, String>> _apiHistory = [];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  final Color mecOrange = const Color(0xFFFF7F00);
  final Color mecBlue = const Color(0xFF1556B5);

  // Contexte système : définit le rôle de l'IA
  static const String _systemPrompt =
      "Tu es un assistant citoyen expert des institutions ivoiriennes. "
      "Tu aides les citoyens à comprendre leurs droits, les procédures administratives, "
      "les lois en Côte d'Ivoire, et tu les guides dans leurs démarches civiques. "
      "Réponds toujours en français, de manière claire, précise et bienveillante. "
      "Si une question dépasse tes compétences, oriente l'utilisateur vers les autorités compétentes.";

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 1. Ajouter le message de l'utilisateur
    setState(() {
      _messages.add({"text": text, "isUser": true});
      _apiHistory.add({"role": "user", "content": text});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // 2. Appeler le backend avec l'historique complet
      final reponse = await AiChatService.sendMessage([
        // On envoie le system prompt comme premier message utilisateur si besoin
        // (selon comment ton backend gère le system prompt)
        {"role": "system", "content": _systemPrompt},
        ..._apiHistory,
      ]);

      // 3. Ajouter la réponse de l'IA
      if (mounted) {
        setState(() {
          _messages.add({"text": reponse, "isUser": false});
          _apiHistory.add({"role": "assistant", "content": reponse});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "text":
                "Désolé, une erreur est survenue. Vérifie ta connexion et réessaie.",
            "isUser": false,
            "isError": true,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EntetePersonalise(
        title: 'Agent IA',
        onNotificationPressed: widget.onNotificationPressed,
        onSearchPressed: widget.onSearchPressed,
        onProfilePressed: widget.onProfilePressed,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ── Zone des messages ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Bulle de chargement "..."
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingIndicator(),
                  );
                }

                final msg = _messages[index];
                final isUser = msg["isUser"] as bool;
                final isError = msg["isError"] == true;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              colors: [mecOrange, mecBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isError
                          ? const LinearGradient(
                              colors: [Color(0xFFFFEDED), Color(0xFFFFEDED)],
                            )
                          : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 18),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : isError
                            ? Colors.red[700]
                            : Colors.black87,
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Champ de saisie ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontFamily: 'Metropolis'),
                      enabled: !_isLoading,
                      maxLines: null, // ✅ Multi-lignes
                      decoration: InputDecoration(
                        hintText: _isLoading
                            ? "L'IA répond..."
                            : "Pose ta question...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isLoading
                            ? const LinearGradient(
                                colors: [Colors.grey, Colors.grey],
                              )
                            : LinearGradient(
                                colors: [mecOrange, mecBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: Icon(
                        _isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Indicateur de frappe "..." ─────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: FadeTransition(
        opacity: _anim,
        child: const Text(
          '● ● ●',
          style: TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 3),
        ),
      ),
    );
  }
}
