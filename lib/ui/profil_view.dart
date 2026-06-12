import 'package:flutter/material.dart';
import 'login.dart';
import 'settings_view.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

class ProfilView extends StatefulWidget {
  final String? userId;
  const ProfilView({super.key, this.userId});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  late TextEditingController fullnameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  Map<String, dynamic> profileData = {};
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  bool isLoading = true;
  bool _isLoggingOut = false;
  bool _isNavigating = false;
  bool _isFollowAction = false;

  static const _orange = Color(0xFFFF7F00);
  static const _blue = Color(0xFF1556B5);
  static const _fillColor = Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    fullnameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    fullnameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final token = await AuthService.getToken();
      late final Map<String, dynamic> data;

      if (widget.userId != null) {
        final user = await ApiService.fetchUserProfile(widget.userId!);
        final followers = await ApiService.getFollowers(widget.userId!);
        final following = await ApiService.getFollowing(widget.userId!);
        followersCount = followers.length;
        followingCount = following.length;
        isFollowing = user.isFollowing;
        data = user.toJson();
      } else {
        data = await UserService.fetchProfile(token ?? '');
      }

      if (!mounted) return;
      setState(() {
        profileData = data;
        fullnameCtrl.text = data['fullname'] ?? data['name'] ?? '';
        emailCtrl.text = data['email'] ?? '';
        phoneCtrl.text = data['phone'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement profil: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null) return;
    setState(() => _isFollowAction = true);
    try {
      if (isFollowing) {
        await ApiService.unfollowUser(widget.userId!);
        setState(() {
          isFollowing = false;
          followersCount = (followersCount - 1).clamp(0, 999999);
        });
      } else {
        await ApiService.followUser(widget.userId!);
        setState(() {
          isFollowing = true;
          followersCount += 1;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isFollowAction = false);
    }
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

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final initiale = fullnameCtrl.text.isNotEmpty
        ? fullnameCtrl.text[0].toUpperCase()
        : '?';

    final ownProfile = widget.userId == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(ownProfile ? 'Mon Profil' : 'Profil citoyen', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar initiale (pas de photo) ─────────────────────
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initiale,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      fullnameCtrl.text.isNotEmpty ? fullnameCtrl.text : '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black87),
                    ),
                  ),
                  Center(
                    child: Text(
                      emailCtrl.text,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (profileData['bio'] != null && profileData['bio'].toString().isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                        child: Text(
                          profileData['bio'].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatistic('Abonnés', followersCount.toString()),
                      const SizedBox(width: 20),
                      _buildStatistic('Abonnements', followingCount.toString()),
                    ],
                  ),
                  if (!ownProfile) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isFollowAction ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.grey[200] : _blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isFollowing ? 'Se désabonner' : "S'abonner",
                          style: TextStyle(color: isFollowing ? Colors.black87 : Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Section infos ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informations personnelles',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: fullnameCtrl,
                          readOnly: true,
                          decoration: _fieldDecoration('Nom complet', Icons.person_outline_rounded),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: emailCtrl,
                          readOnly: true,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration('Adresse e-mail', Icons.mail_outline_rounded),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: phoneCtrl,
                          readOnly: true,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration('Téléphone', Icons.phone_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Bouton Paramètres du compte ─────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                      label: const Text('Paramètres du compte', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isNavigating
                          ? null
                          : () async {
                              setState(() => _isNavigating = true);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsView()),
                              );
                              if (mounted) setState(() => _isNavigating = false);
                            },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Bouton Déconnexion ─────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 18),
                      label: Text('Déconnexion', style: TextStyle(color: Colors.red.shade400, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Version de l'application ───────────────────────
                  Center(
                    child: Column(
                      children: [
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset('assets/logo_MEC_1.png', height: 16, width: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Citoyen +',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}