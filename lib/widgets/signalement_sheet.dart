import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:citoyen_plus/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:citoyen_plus/services/ajouter_signalement.dart';
import '../models/categorie_signalement_model.dart';
import '../services/recuperer_categorie_signalement_service.dart';

void showSignalementSheet(BuildContext context, Function(dynamic) onCreated) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _SignalementSheet(onCreated: onCreated),
  );
}

class _SignalementSheet extends StatefulWidget {
  const _SignalementSheet({required this.onCreated});
  final Function(dynamic) onCreated;

  @override
  State<_SignalementSheet> createState() => _SignalementSheetState();
}

class _SignalementSheetState extends State<_SignalementSheet> {
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();

  CategorieSignalementModel? _selectedCategorie;
  List<CategorieSignalementModel> _categories = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  double? _latitude;
  double? _longitude;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _locating = true;
  bool _submitting = false;

  // Couleurs MEC
  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);
  static const _fillColor = Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadCategories();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: _blue, size: 20),
      filled: true,
      fillColor: _fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Géolocalisation ───────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDisabledDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog(
          permanent: permission == LocationPermission.deniedForever,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur localisation : $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Localisation désactivée'),
        content: const Text(
          'Veuillez activer la localisation pour créer un signalement.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
              _fetchLocation();
            },
            child: const Text('Activer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog({required bool permanent}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission refusée'),
        content: Text(
          permanent
              ? 'Activez la localisation depuis les paramètres.'
              : 'La localisation est nécessaire pour créer un signalement.',
        ),
        actions: [
          if (permanent)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
                _fetchLocation();
              },
              child: const Text('Paramètres'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ── Catégories ────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final result = await fetchAllCategories();
      if (mounted) {
        setState(() {
          _categories = result;
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = 'Impossible de charger les catégories.';
          _categoriesLoading = false;
        });
      }
    }
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: _blue),
                ),
                title: const Text(
                  'Prendre une photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: _orange),
                ),
                title: const Text(
                  'Choisir depuis la galerie',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Soumission ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_titreController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedCategorie == null ||
        _latitude == null ||
        _longitude == null) {
      _showSnack('Veuillez remplir tous les champs obligatoires.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final newSignalement = await createSignalement(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        categorieId: _selectedCategorie!.id,
        adresse: _adresseController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        photo: _photo,
      );
      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.show(
          titre: 'Signalement créé',
          corps: 'Votre signalement a été envoyé avec succès.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Signalement créé avec succès !'),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        widget.onCreated(newSignalement);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur : $e');
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Barre de drag ────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // ── Titre du sheet ───────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.report_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nouveau signalement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Localisation ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _latitude != null
                    ? const Color(0xFFE8F8EE)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _latitude != null
                      ? const Color(0xFF34C759).withValues(alpha: 0.4)
                      : _orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _orange,
                          ),
                        )
                      : Icon(
                          _latitude != null
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _latitude != null
                              ? const Color(0xFF34C759)
                              : _orange,
                          size: 20,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locating
                          ? 'Récupération de la position…'
                          : _latitude != null
                          ? 'Position détectée ✓'
                          : 'Localisation non disponible',
                      style: TextStyle(
                        color: _latitude != null
                            ? const Color(0xFF1E7A3A)
                            : const Color(0xFF8B4500),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!_locating && _latitude == null)
                    TextButton(
                      onPressed: _fetchLocation,
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(color: _orange),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Catégorie ────────────────────────────────────────────────
            if (_categoriesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Chargement des catégories…',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (_categoriesError != null)
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _categoriesError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadCategories,
                    child: const Text('Réessayer'),
                  ),
                ],
              )
            else if (_categories.isEmpty)
              Row(
                children: [
                  const Icon(Icons.info_outline, color: _orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Aucune catégorie disponible.',
                      style: TextStyle(fontSize: 13, color: _orange),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadCategories,
                    child: const Text('Réessayer'),
                  ),
                ],
              )
            else
              DropdownButtonFormField<CategorieSignalementModel>(
                decoration: _fieldDecoration(
                  'Catégorie *',
                  Icons.category_outlined,
                ),
                hint: const Text('Sélectionner une catégorie'),
                initialValue: _selectedCategorie,
                borderRadius: BorderRadius.circular(14),
                menuMaxHeight: 200,
                isExpanded: true,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat.nom,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (cat) => setState(() => _selectedCategorie = cat),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),

            // ── Titre ────────────────────────────────────────────────────
            TextField(
              controller: _titreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration('Titre *', Icons.title_rounded),
            ),
            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────────────
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(
                'Description *',
                Icons.description_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),

            // ── Adresse ──────────────────────────────────────────────────
            TextField(
              controller: _adresseController,
              decoration: _fieldDecoration(
                'Adresse (optionnel)',
                Icons.place_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // ── Photo ────────────────────────────────────────────────────
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_photoBytes != null)
                              Image.memory(_photoBytes!, fit: BoxFit.cover)
                            else
                              const SizedBox.shrink(),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _photo = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ajouter une photo',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'optionnel',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Bouton soumettre ─────────────────────────────────────────
            SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Envoyer le signalement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
