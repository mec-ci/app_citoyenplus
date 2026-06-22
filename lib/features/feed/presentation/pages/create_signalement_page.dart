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

class CreateSignalementPage extends ConsumerStatefulWidget {
  const CreateSignalementPage({super.key});

  @override
  ConsumerState<CreateSignalementPage> createState() =>
      _CreateSignalementPageState();
}

class _CreateSignalementPageState extends ConsumerState<CreateSignalementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();

  CategorieSignalementModel? _selectedCategorie;
  File? _photo;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
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

  bool _locating = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategorie == null) {
      _showSnack('Selectionnez une categorie.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showSnack(
        'Detectez votre position ou saisissez l\'adresse manuellement.',
      );
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
      ref.read(signalementProvider.notifier).fetchSignalements();
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

  @override
  Widget build(BuildContext context) {
    ref.watch(signalementProvider);
    final categorieState = ref.watch(categorieSignalementProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65C00),
        title: const Text('Signaler un probleme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _selectPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: _photo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.photo_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('Ajouter une photo (optionnel)'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_photo!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCategorieField(categorieState),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis.';
                  }
                  if (value.trim().length < 5) {
                    return 'Au moins 5 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise.';
                  }
                  if (value.trim().length < 20) {
                    return 'Au moins 20 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise.';
                  }
                  return null;
                },
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
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
              if (_locationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65C00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Soumettre le signalement'),
              ),
            ],
          ),
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
        items: <DropdownMenuItem<String>>[],
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
            items: <DropdownMenuItem<String>>[],
            onChanged: null,
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () =>
                ref.read(categorieSignalementProvider.notifier).fetchCategories(),
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
        items: <DropdownMenuItem<String>>[],
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
        });
      },
      validator: (value) =>
          value == null ? 'La categorie est requise.' : null,
    );
  }
}
