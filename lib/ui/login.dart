import 'package:citoyen_plus/features/onboarding/onboarding_service.dart';
import 'package:citoyen_plus/features/onboarding/onboarding_view.dart';
import 'package:citoyen_plus/ui/accueil.dart';
import 'package:flutter/material.dart';
import 'signup.dart';
import 'forgot_password_view.dart';
import '../services/auth_service.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);
const _fillColor = Color(0xFFF8F9FF);

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
  static const String defaultEmail = 'demo@citoyenplus.test';
  static const String defaultPassword = 'Demotest123!';

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    emailCtrl.text = defaultEmail;
    passwordCtrl.text = defaultPassword;
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final result = await AuthService.login(
      email: emailCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => isLoading = false);
    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Connexion réussie"),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _navigateAfterLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: const Color(0xFFFF2D55),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> handleGoogleLogin() async {
    setState(() => isGoogleLoading = true);
    final result = await AuthService.loginWithGoogle();
    if (!mounted) return;
    setState(() => isGoogleLoading = false);
    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Connexion Google réussie"),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _navigateAfterLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? 'Erreur connexion Google'),
          backgroundColor: const Color(0xFFFF2D55),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _navigateAfterLogin() async {
    final shouldShowOnboarding = await OnboardingService.shouldShowOnboarding();
    if (!mounted) return;

    if (shouldShowOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  InputDecoration _fieldDeco(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: _blue, size: 20),
      suffixIcon: suffix,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF2D55)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF2D55), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo ───────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo_MEC_1.png',
                        height: 76,
                        width: 76,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Titre ──────────────────────────────────────────────
                const Text(
                  'Heureux de te revoir 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connecte-toi pour continuer ton aventure citoyenne.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email ──────────────────────────────────────────────
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDeco('Email', Icons.email_outlined),
                  validator: (v) => v!.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 16),

                // ── Mot de passe ───────────────────────────────────────
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: hidePassword,
                  decoration: _fieldDeco(
                    'Mot de passe',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Compte de test prérempli :\n$defaultEmail / $defaultPassword',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Mot de passe oublié ────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordView(),
                      ),
                    ),
                    style: TextButton.styleFrom(foregroundColor: _blue),
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Bouton connexion ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: isGoogleLoading ? null : handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isGoogleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login, size: 20, color: Colors.red),
                    label: Text(
                      isGoogleLoading
                          ? 'Connexion Google...'
                          : 'Continuer avec Google',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Lien inscription ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pas encore de compte ? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountView(),
                        ),
                      ),
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
