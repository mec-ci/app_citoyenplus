sealed class AppException {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Erreur réseau. Vérifiez votre connexion.',
  ]);
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Erreur serveur. Réessayez plus tard.',
  ]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Non autorisé. Veuillez vous reconnecter.',
  ]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Données invalides.']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Erreur inconnue.']);
}
