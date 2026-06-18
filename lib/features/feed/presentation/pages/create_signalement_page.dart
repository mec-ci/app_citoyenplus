import 'dart:io';

import 'package:citoyen_plus/features/feed/data/repositories/signalement_repository.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/categorie_signalement_provider.dart';
import 'package:citoyen_plus/features/feed/presentation/providers/signalement_provider.dart';
import 'package:citoyen_plus/models/categorie_signalement_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _detectLocation() async {
    setState(() {
      _locationError = null;
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
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final address = placemarks.isNotEmpty
          ? '${placemarks.first.street ?? ''} ${placemarks.first.locality ?? ''}'
                .trim()
          : '';

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _adresseController.text = address.isNotEmpty
            ? address
            : _adresseController.text;
      });
    } catch (e) {
      setState(() => _locationError = 'Impossible de detecter la position.');
    }
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
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _detectLocation,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est requise.';
                  }
                  return null;
                },
              ),
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
