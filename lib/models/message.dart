class Message {
  final String id;
  final String conversationId;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String texte;
  final DateTime createdAt;
  final bool read;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.texte,
    required this.createdAt,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      authorName: json['authorName'] ?? json['author_name'] ?? json['userName'] ?? 'Utilisateur',
      authorAvatar: json['authorAvatar'] ?? json['author_avatar'] ?? json['userAvatar'],
      texte: json['texte'] ?? json['text'] ?? json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      read: json['read'] ?? json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'userId': userId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'texte': texte,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };
}

class Conversation {
  final String id;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      otherUserId: json['otherUserId'] ?? json['other_user_id'] ?? '',
      otherUserName: json['otherUserName'] ?? json['other_user_name'] ?? 'Utilisateur',
      otherUserAvatar: json['otherUserAvatar'] ?? json['other_user_avatar'],
      lastMessage: json['lastMessage'] ?? json['last_message'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'].toString())
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserAvatar': otherUserAvatar,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'unreadCount': unreadCount,
      };
}
