import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class HttpErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showErrorAlert(String title, String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Message lisible pour une erreur quelconque (DioException ou autre).
  /// Utilisé pour afficher la vraie cause d'un échec à l'utilisateur plutôt
  /// qu'un message générique.
  static String describe(Object error) {
    if (error is DioException) return extractErrorMessage(error);
    return 'Une erreur est survenue.';
  }

  static String extractErrorMessage(DioException error) {    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? message;
    if (data is Map) {
      message = data['message']?.toString() ??
          data['error']?.toString() ??
          data['errors']?.toString();
    } else if (data is String) {
      message = data;
    }

    if (message == null || message.isEmpty) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          message = 'Le serveur ne répond pas. Vérifie ta connexion.';
          break;
        case DioExceptionType.connectionError:
          message = 'Erreur réseau. Vérifie ta connexion internet.';
          break;
        case DioExceptionType.badResponse:
          message = statusCode != null
              ? 'Erreur $statusCode du serveur.'
              : 'Réponse invalide du serveur.';
          break;
        default:
          message = 'Une erreur est survenue.';
      }
    }

    if (statusCode != null && statusCode != 200) {
      message = '[Erreur $statusCode] $message';
    }

    return message;
  }
}
