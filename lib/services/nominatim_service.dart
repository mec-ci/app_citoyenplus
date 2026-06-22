import 'dart:convert';

import 'package:http/http.dart' as http;

/// Résultat d'une recherche d'adresse Nominatim.
class NominatimPlace {
  final String displayName;
  final double latitude;
  final double longitude;

  const NominatimPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

/// Service de géocodage basé sur Nominatim (OpenStreetMap).
///
/// Aucune clé API n'est requise. La politique d'usage de Nominatim impose un
/// `User-Agent` identifiant l'application et un débit raisonnable (~1 req/s) :
/// on ne l'appelle qu'à la demande de l'utilisateur (bouton / confirmation).
class NominatimService {
  static const String _base = 'https://nominatim.openstreetmap.org';
  // En-tête obligatoire pour respecter la politique d'usage de Nominatim.
  static const Map<String, String> _headers = {
    'User-Agent': 'CitoyenPlus/1.0 (https://mec-ci.org)',
    'Accept': 'application/json',
  };

  /// Convertit des coordonnées en adresse lisible (reverse geocoding).
  /// Renvoie `null` si aucune adresse n'est trouvée ou en cas d'erreur réseau.
  static Future<String?> reverse(double latitude, double longitude) async {
    final uri = Uri.parse(
      '$_base/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=fr',
    );
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final name = data['display_name'];
        if (name is String && name.isNotEmpty) return name;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Recherche une adresse à partir d'un texte libre (forward geocoding).
  /// Renvoie une liste de lieux candidats (vide en cas d'erreur).
  static Future<List<NominatimPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final uri = Uri.parse(
      '$_base/search?format=jsonv2&q=${Uri.encodeQueryComponent(trimmed)}&limit=5&accept-language=fr',
    );
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body);
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => NominatimPlace(
                displayName: e['display_name']?.toString() ?? '',
                latitude: double.tryParse(e['lat']?.toString() ?? '') ?? 0,
                longitude: double.tryParse(e['lon']?.toString() ?? '') ?? 0,
              ))
          .where((p) => p.latitude != 0 || p.longitude != 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
