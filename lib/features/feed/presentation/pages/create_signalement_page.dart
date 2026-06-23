import 'dart:io';

import 'package:citoyen_plus/features/feed/data/repositories/signalement_repository.dart';
import 'package:citoyen_plus/features/feed/presentation/pages/pick_location_map_page.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/categorie_signalement_provider.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/signalement_provider.dart';
import 'package:citoyen_plus/models/categorie_signalement_model.dart';
import 'package:citoyen_plus/services/nominatim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

const _orange = Color(0xFFE65C00);
const _stepLabels = ['Type', 'Description', 'Lieu'];

class CreateSignalementPage extends ConsumerStatefulWidget {
  const CreateSignalementPage({super.key});

  @override
  ConsumerState<CreateSignalementPage> createState() =>
      _CreateSignalementPageState();
}

class _CreateSignalementPageState extends ConsumerState<CreateSignalementPage> {
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();

  int _step = 0;

  CategorieSignalementModel? _selectedCategorie;
  File? _photo;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _locating = false;

  String? _titreError;
  String? _categorieError;
  String? _descriptionError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categorieSignalementProvider.notifier).fetchCategories();
    });
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // ── Navigation entre étapes ────────────────────────────────────────────────

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        final titre = _titreController.text.trim();
        setState(() {
          _categorieError =
              _selectedCategorie == null ? 'La catégorie est requise.' : null;
          if (titre.isEmpty) {
            _titreError = 'Le titre est requis.';
          } else if (titre.length < 5) {
            _titreError = 'Au moins 5 caractères.';
          } else {
            _titreError = null;
          }
        });
        return _categorieError == null && _titreError == null;
      case 1:
        final desc = _descriptionController.text.trim();
        setState(() {
          if (desc.isEmpty) {
            _descriptionError = 'La description est requise.';
          } else if (desc.length < 20) {
            _descriptionError = 'Au moins 20 caractères.';
          } else {
            _descriptionError = null;
          }
        });
        return _descriptionError == null;
      case 2:
        final adresse = _adresseController.text.trim();
        setState(() {
          if (_latitude == null || _longitude == null) {
            _locationError =
                'Indiquez la position (« Ma position » ou « Carte »).';
          } else if (adresse.isEmpty) {
            _locationError = 'L\'adresse est requise.';
          } else {
            _locationError = null;
          }
        });
        return _latitude != null &&
            _longitude != null &&
            adresse.isNotEmpty;
    }
    return true;
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) setState(() => _step--);
  }

  // ── Photo ──────────────────────────────────────────────────────────────────

  Future<void> _selectPhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _photo = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _photo = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Localisation ────────────────────────────────────────────────────────────

  /// Détecte rapidement la position GPS et remplit l'adresse via Nominatim.
  Future<void> _detectLocation() async {
    setState(() {
      _locationError = null;
      _locating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationError = 'Activez la localisation puis reessayez.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Permission localisation refusee.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final address = await NominatimService.reverse(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (address != null && address.isNotEmpty) {
          _adresseController.text = address;
        }
      });
    } catch (e) {
      setState(() => _locationError = 'Impossible de detecter la position.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Ouvre la carte OpenStreetMap pour choisir la position manuellement.
  Future<void> _pickOnMap() async {
    final initial = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : null;
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => PickLocationMapPage(initial: initial),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _locationError = null;
      _latitude = result.latitude;
      _longitude = result.longitude;
      if (result.adresse != null && result.adresse!.isNotEmpty) {
        _adresseController.text = result.adresse!;
      }
    });
  }

  // ── Soumission ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedCategorie == null ||
        _latitude == null ||
        _longitude == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(signalementProvider.notifier)
        .createSignalement(
          CreateSignalementDto(
            titre: _titreController.text.trim(),
            description: _descriptionController.text.trim(),
            categorieId: _selectedCategorie!.id,
            adresse: _adresseController.text.trim(),
            latitude: _latitude!,
            longitude: _longitude!,
            photo: _photo,
          ),
        );
    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      _showSnack('Signalement soumis avec succes.');
      Navigator.of(context).pop(true);
      ref.read(signalementProvider.notifier).refresh();
    } else {
      _showSnack(
        ref.read(signalementProvider).error ??
            'Erreur lors de la creation du signalement.',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(signalementProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _orange,
        title: const Text('Signaler un probleme'),
      ),
      body: Column(
        children: [
          _buildProgress(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i <= _step;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? _orange : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_step + 1} sur 3 · ${_stepLabels[_step]}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildDescriptionStep();
      default:
        return _buildLocationStep();
    }
  }

  // Étape 1 — Type : catégorie + titre.
  Widget _buildTypeStep() {
    final categorieState = ref.watch(categorieSignalementProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildCategorieField(categorieState),
          if (_categorieError != null) ...[
            const SizedBox(height: 6),
            Text(_categorieError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _titreController,
            onChanged: (_) {
              if (_titreError != null) setState(() => _titreError = null);
            },
            decoration: InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex. Nid de poule dangereux',
              border: const OutlineInputBorder(),
              errorText: _titreError,
            ),
          ),
        ],
      ),
    );
  }

  // Étape 2 — Description « façon Facebook » : grand composeur plein écran.
  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE6F1FB),
              child: Icon(Icons.person, color: Color(0xFF185FA5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategorie?.nom ?? 'Signalement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Décris ce que tu signales',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: _descriptionController,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            onChanged: (_) {
              if (_descriptionError != null) {
                setState(() => _descriptionError = null);
              }
            },
            style: const TextStyle(fontSize: 18, height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Que veux-tu signaler ? Donne un maximum de détails…',
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
        if (_descriptionError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _descriptionError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const Divider(height: 1),
        _buildPhotoComposer(),
      ],
    );
  }

  Widget _buildPhotoComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _photo!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _photo = null),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Retirer la photo'),
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _selectPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: const Text('Ajouter une photo (optionnel)'),
            ),
        ],
      ),
    );
  }

  // Étape 3 — Lieu : adresse + position (GPS / carte).
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _detectLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: const Text('Ma position'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Carte'),
                ),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF34C759), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Position définie : '
                    '${_latitude!.toStringAsFixed(5)}, '
                    '${_longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ],
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _step == 2;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _back,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _next,
                child: (_isSubmitting && isLast)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isLast ? 'Publier le signalement' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorieField(CategorieSignalementState state) {
    if (state.isLoading) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Categorie',
          border: OutlineInputBorder(),
        ),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      );
    }

    if (state.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Categorie',
              border: OutlineInputBorder(),
              errorText: 'Erreur de chargement',
            ),
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => ref
                .read(categorieSignalementProvider.notifier)
                .fetchCategories(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reessayer'),
          ),
        ],
      );
    }

    if (state.categories.isEmpty) {
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Categorie',
          border: OutlineInputBorder(),
          hintText: 'Aucune categorie disponible',
        ),
        items: const <DropdownMenuItem<String>>[],
        onChanged: null,
      );
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Categorie',
        border: OutlineInputBorder(),
      ),
      initialValue: _selectedCategorie?.id,
      items: state.categories
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.nom),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategorie =
              state.categories.firstWhere((c) => c.id == value);
          _categorieError = null;
        });
      },
    );
  }
}
