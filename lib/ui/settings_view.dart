import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();
  final _picker = ImagePicker();

  late TextEditingController fullnameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController oldPasswordCtrl;
  late TextEditingController newPasswordCtrl;
  late TextEditingController confirmPasswordCtrl;

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _isLoggingOut = false;
  bool _isUpdatingAvatar = false;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  String? _avatarUrl;

  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);
  static const _fillColor = Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    fullnameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    oldPasswordCtrl = TextEditingController();
    newPasswordCtrl = TextEditingController();
    confirmPasswordCtrl = TextEditingController();
    _initialize();
  }

  @override
  void dispose() {
    fullnameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    oldPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadBiometricSupport();
    await _loadProfile();
  }

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

  Future<void> _loadBiometricSupport() async {
    final canCheckBiometrics = await _auth.canCheckBiometrics;
    final enabled = await _storage.read(key: 'biometric_enabled') == 'true';
    if (mounted) {
      setState(() {
        _biometricSupported = canCheckBiometrics;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final token = await AuthService.getToken();
      final data = await UserService.fetchProfile(token ?? '');
      if (!mounted) return;
      setState(() {
        fullnameCtrl.text = data['fullname'] ?? data['name'] ?? '';
        emailCtrl.text = data['email'] ?? '';
        phoneCtrl.text = data['phone'] ?? '';
        _avatarUrl = data['avatarUrl'] ?? data['avatar'] ?? ''; 
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement profil: $e')),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_biometricSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biométrie non disponible sur cet appareil.')),
      );
      return;
    }

    if (value) {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Active la connexion biométrique pour Citoyen +',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return;
    }

    await _storage.write(key: 'biometric_enabled', value: value ? 'true' : 'false');
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isUpdatingAvatar = true);
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      final token = await AuthService.getToken();
      if (token == null) return;
      final uploadedUrl = await UserService.uploadAvatar(token, image);
      if (!mounted) return;
      if (uploadedUrl != null) {
        setState(() => _avatarUrl = uploadedUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar mis à jour avec succès')),        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de télécharger l’avatar')),        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur avatar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
        return;
      }
      final success = await UserService.updateProfile(
        token: token,
        name: fullnameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        avatarUrl: _avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil mis à jour avec succès' : 'Impossible de mettre à jour le profil'),
          backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nouveau mot de passe ne correspond pas')),      );
      return;
    }
    if (oldPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complète tous les champs du mot de passe')),      );
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
        return;
      }
      final success = await UserService.changePassword(
        token: token,
        oldPassword: oldPasswordCtrl.text.trim(),
        newPassword: newPasswordCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Mot de passe changé avec succès' : 'Erreur lors du changement de mot de passe'),
          backgroundColor: success ? const Color(0xFF34C759) : Colors.red,
        ),
      );
      if (success) {
        oldPasswordCtrl.clear();
        newPasswordCtrl.clear();
        confirmPasswordCtrl.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du compte'),
        backgroundColor: _blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: _blue.withValues(alpha: 0.15),
                          foregroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null,
                          child: _avatarUrl == null || _avatarUrl!.isEmpty
                              ? Text(
                                  fullnameCtrl.text.isNotEmpty ? fullnameCtrl.text[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: _orange,
                              child: _isUpdatingAvatar
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Informations générales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(controller: fullnameCtrl, decoration: _fieldDecoration('Nom complet', Icons.person_outline_rounded)),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _fieldDecoration('Email', Icons.mail_outline_rounded)),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: _fieldDecoration('Téléphone', Icons.phone_outlined)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: _isSavingProfile
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('Sécurité', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text('Connexion biométrique'),
                    subtitle: Text(_biometricSupported ? 'Utilise empreinte ou reconnaissance faciale' : 'Biométrie non supportée'),
                    value: _biometricEnabled,
                    activeThumbColor: _orange,
                    onChanged: _biometricSupported ? _toggleBiometric : null,
                  ),
                  const Divider(height: 32),

                  const Text('Changer le mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(controller: oldPasswordCtrl, obscureText: true, decoration: _fieldDecoration('Mot de passe actuel', Icons.lock_outline_rounded)),
                  const SizedBox(height: 12),
                  TextField(controller: newPasswordCtrl, obscureText: true, decoration: _fieldDecoration('Nouveau mot de passe', Icons.lock_outline_rounded)),
                  const SizedBox(height: 12),
                  TextField(controller: confirmPasswordCtrl, obscureText: true, decoration: _fieldDecoration('Confirmer le nouveau mot de passe', Icons.lock_outline_rounded)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isChangingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: _isChangingPassword
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Modifier le mot de passe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _handleLogout,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 18),
                      label: Text('Se déconnecter', style: TextStyle(color: Colors.red.shade400, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
