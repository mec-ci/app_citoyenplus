import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../services/nominatim_service.dart';

const _orange = Color(0xFFE65C00);
// Centre par défaut (Abidjan) si la position GPS n'est pas disponible.
const LatLng _defaultCenter = LatLng(5.3484, -4.0273);

/// Résultat de la sélection d'une position sur la carte.
class LocationPickResult {
  final double latitude;
  final double longitude;
  final String? adresse;

  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    this.adresse,
  });
}

/// Écran de sélection d'une position sur une carte OpenStreetMap.
///
/// L'utilisateur peut taper la carte pour déplacer le marqueur ou utiliser le
/// bouton « Ma position » (GPS). À la validation, l'adresse est récupérée via
/// Nominatim (reverse geocoding) et renvoyée à l'appelant.
class PickLocationMapPage extends StatefulWidget {
  const PickLocationMapPage({super.key, this.initial});

  /// Position initiale optionnelle (ex. une position GPS déjà détectée).
  final LatLng? initial;

  @override
  State<PickLocationMapPage> createState() => _PickLocationMapPageState();
}

class _PickLocationMapPageState extends State<PickLocationMapPage> {
  final MapController _mapController = MapController();
  late LatLng _selected;
  bool _locating = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? _defaultCenter;
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activez la localisation puis réessayez.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Permission de localisation refusée.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selected = point);
      _mapController.move(point, 16);
    } catch (_) {
      _showSnack('Impossible de récupérer votre position.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final adresse =
        await NominatimService.reverse(_selected.latitude, _selected.longitude);
    if (!mounted) return;
    setState(() => _confirming = false);
    Navigator.of(context).pop(
      LocationPickResult(
        latitude: _selected.latitude,
        longitude: _selected.longitude,
        adresse: adresse,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _orange,
        title: const Text('Choisir la position'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.mec.citoyenplus',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: _orange,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'Tape sur la carte pour placer le repère, ou utilise « Ma position ».',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 92,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              foregroundColor: _orange,
              onPressed: _locating ? null : _useMyLocation,
              child: _locating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _confirming ? null : _confirm,
              icon: _confirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Valider cette position',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
