import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/message.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  final StreamController<Message> _messageController = StreamController<Message>.broadcast();

  Stream<Message> get onMessage => _messageController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    final token = await AuthService.getToken();
    final uri = ApiConfig.host; // server host, expect socket.io running on same origin

    _socket = io.io(
      uri,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setQuery({'token': token ?? ''})
          .build(),
    );

    _socket!.on('connect', (_) => debugPrint('Socket connected'));
    _socket!.on('disconnect', (_) => debugPrint('Socket disconnected'));

    _socket!.on('message', (data) {
      try {
        if (data is Map) {
          final msg = Message.fromJson(Map<String, dynamic>.from(data));
          _messageController.add(msg);
        }
      } catch (e) {
        debugPrint('Socket message parse error: $e');
      }
    });

    _socket!.on('conversation_update', (data) {
      // server may emit conversation updates; map to Message if appropriate
      try {
        if (data is Map && data.containsKey('message')) {
          final msg = Message.fromJson(Map<String, dynamic>.from(data['message']));
          _messageController.add(msg);
        }
      } catch (e) {
        debugPrint('Socket conversation_update parse error: $e');
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave', {'conversationId': conversationId});
  }

  Future<void> sendMessage(String conversationId, String texte) async {
    if (_socket == null || !_socket!.connected) {
      await connect();
    }
    final payload = {'conversationId': conversationId, 'texte': texte};
    _socket?.emit('message', payload);
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }
}
