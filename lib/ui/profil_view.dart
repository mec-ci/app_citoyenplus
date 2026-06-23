import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login.dart';
import 'settings_view.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../models/signalement.dart';
import '../providers/gamification_provider.dart';

class ProfilView extends ConsumerStatefulWidget {
  final String? userId;
  const ProfilView({super.key, this.userId});

  @override
  ConsumerState<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends ConsumerState<ProfilView> {
  late TextEditingController fullnameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  Map<String, dynamic> profileData = {};
  bool isLoading = true;
  bool _isLoggingOut = false;
  bool _isNavigating = false;

  int signalementCount = 0;
  int quizCompletedCount = 0;
  List<SignalementModel> mesSignalements = [];

  static const _orange = Color(0xFFE65C00);
  static const _blue = Color(0xFF1556B5);
  static const _fillColor = Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    fullnameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    _loadProfile();
    // Synchronise les points/niveau avec le serveur à l'ouverture du profil.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).refresh();
    });
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
      final data = await UserService.fetchProfile();
      if (!mounted) return;
      setState(() {
        profileData = data;
        final user = data['data'] ?? data;
        fullnameCtrl.text = user['fullname'] ?? user['name'] ?? '';
        emailCtrl.text = user['email'] ?? '';
        phoneCtrl.text = user['phone'] ?? '';
        isLoading = false;
      });
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    // Identifiant de l'utilisateur dont on affiche le profil : soit le profil
    // consulté (widget.userId), soit l'utilisateur connecté.
    final userId = widget.userId ?? await UserService.currentUserId();
    // Charge uniquement les signalements de cet utilisateur. Sans filtre par
    // `citoyenId`, l'API renvoie les signalements de tous les citoyens, ce qui
    // affichait un nombre erroné (ceux des autres) sur un compte vierge.
    try {
      final signalements = userId != null
          ? await UserService.fetchUserSignalements(userId)
          : <SignalementModel>[];
      if (!mounted) return;
      setState(() {
        signalementCount = signalements.length;
        mesSignalements = signalements.take(3).toList();
      });
    } catch (_) {}
    // Charge le nombre de quiz complétés depuis le serveur.
    try {
      if (userId != null) {
        final results = await ApiService.fetchQuizResults(userId);
        if (!mounted) return;
        setState(() => quizCompletedCount = results.length);
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final initiale = fullnameCtrl.text.isNotEmpty
        ? fullnameCtrl.text[0].toUpperCase()
        : '?';

    final ownProfile = widget.userId == null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          ownProfile ? 'Mon Profil' : 'Profil citoyen',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
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
                  _buildAvatarHeader(initiale),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildProgressionBar(),
                  const SizedBox(height: 20),
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  if (mesSignalements.isNotEmpty) _buildPersonalFeed(),
                  const SizedBox(height: 20),
                  _buildActions(),
                  const SizedBox(height: 20),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarHeader(String initiale) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
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
          const SizedBox(height: 8),
          Text(
            fullnameCtrl.text.isNotEmpty ? fullnameCtrl.text : '',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
          Text(
            emailCtrl.text,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          _buildNiveauBadge(),
        ],
      ),
    );
  }

  Widget _buildNiveauBadge() {
    final niveau = ref.watch(gamificationProvider).niveau;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_rounded, color: _orange, size: 16),
          const SizedBox(width: 4),
          Text(
            'Niveau $niveau',
            style: const TextStyle(
              color: _orange,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.report_problem_outlined, '$signalementCount', 'Signalements', _orange)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.military_tech_outlined, '${ref.watch(gamificationProvider).niveau}', 'Niveau', const Color(0xFF3B6D11))),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.star_rounded, '${ref.watch(gamificationProvider).totalPoints}', 'Points', _orange)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionBar() {
    final progress = signalementCount.clamp(0, 10) / 10.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progression citoyenne',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Signalez des problemes et participez a des actions pour monter de niveau',
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: _blue, size: 16),
              const SizedBox(width: 6),
              Text(
                '$quizCompletedCount quiz complétés',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
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
            decoration: _fieldDecoration('Telephone', Icons.phone_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes derniers signalements',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        ...mesSignalements.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on, color: _orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(s.adresse, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.statut == 'resolu'
                      ? const Color(0xFF3B6D11).withValues(alpha: 0.1)
                      : const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.statut == 'resolu' ? 'Resolu' : s.statut == 'en_cours' ? 'En cours' : 'Soumis',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: s.statut == 'resolu' ? const Color(0xFF3B6D11) : _orange,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Parametres du compte',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isNavigating ? null : () async {
              setState(() => _isNavigating = true);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
              if (mounted) setState(() => _isNavigating = false);
            },
          ),
        ),
        const SizedBox(height: 12),
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
            label: Text('Deconnexion', style: TextStyle(color: Colors.red.shade400, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
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
              const Text('Citoyen +', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 16),
        ],
      ),
    );
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
}
