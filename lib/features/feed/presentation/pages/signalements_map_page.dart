import 'package:citoyen_plus/features/feed/domain/models/feed_item.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/signalement_detail_view.dart';
import 'package:citoyen_plus/models/signalement.dart';
import 'package:citoyen_plus/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const _orange = Color(0xFFE65C00);
const LatLng _defaultCenter = LatLng(5.3484, -4.0273);

/// Carte OpenStreetMap affichant les signalements autour de la position de
/// l'utilisateur (recherche par rayon côté backend).
class SignalementsMapPage extends StatefulWidget {
  const SignalementsMapPage({super.key, this.radiusKm = 5});

  final double radiusKm;

  @override
  State<SignalementsMapPage> createState() => _SignalementsMapPageState();
}

class _SignalementsMapPageState extends State<SignalementsMapPage> {
  final MapController _mapController = MapController();
  List<SignalementModel> _signalements = [];
  LatLng _center = _defaultCenter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    LatLng center = _defaultCenter;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
          center = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {
      // On reste sur le centre par défaut si la position échoue.
    }

    try {
      final results = await ApiService.fetchSignalements(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusKm: widget.radiusKm,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _center = center;
        _signalements =
            results.where((s) => s.latitude != 0 || s.longitude != 0).toList();
        _loading = false;
      });
      _mapController.move(center, 14);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _center = center;
        _loading = false;
        _error = 'Impossible de charger les signalements à proximité.';
      });
    }
  }

  FeedItem _toFeedItem(SignalementModel s) {
    return FeedItem(
      type: FeedType.signalement,
      id: s.id,
      titre: s.titre,
      description: s.description,
      imageUrl: s.photo,
      adresse: s.adresse,
      statut: s.statut,
      latitude: s.latitude,
      longitude: s.longitude,
      categorieNom: s.categorie?.nom,
      createdAt: s.createdAt ?? DateTime.now(),
      likesCount: s.likesCount,
      commentsCount: s.commentsCount,
      likedByMe: s.likedByMe,
    );
  }

  void _openDetail(SignalementModel s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignalementDetailView(item: _toFeedItem(s)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _orange,
        title: const Text('Signalements à proximité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.mec.citoyenplus',
              ),
              MarkerLayer(
                markers: [
                  // Position de l'utilisateur.
                  Marker(
                    point: _center,
                    width: 24,
                    height: 24,
                    child: const Icon(Icons.my_location,
                        color: Color(0xFF1556B5), size: 24),
                  ),
                  ..._signalements.map(
                    (s) => Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        // Sans HitTestBehavior.opaque, le tap est capté par le
                        // gestionnaire de gestes de la carte (flutter_map v7)
                        // et n'atteint jamais le marqueur : le détail ne
                        // s'ouvrait donc pas au clic.
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openDetail(s),
                        child: const Icon(Icons.location_on,
                            color: _orange, size: 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: _orange)),
          if (!_loading && _error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Color(0xFFB00020))),
                      ),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null && _signalements.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Aucun signalement dans ce rayon.'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
