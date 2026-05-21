import 'package:flutter/material.dart';
import 'login.dart';
import 'package:citoyen_plus/services/auth_service.dart';


const _blue = Color(0xFF1556B5);
const _fillColor = Color(0xFFF8F9FF);

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController fullnameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  Future<void> handleCreateAccount() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final result = await AuthService.signup(
      name: fullnameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => isLoading = false);
    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Compte créé avec succès !"),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: const Color(0xFFFF2D55),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
      errorMaxLines: 2,
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
                const SizedBox(height: 24),

                // ── Back + Titre ───────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Sous-titre ─────────────────────────────────────────
                Text(
                  'Rejoins la communauté Citoyen + 🇨🇮',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
                ),
                const SizedBox(height: 28),

                // ── Nom complet ────────────────────────────────────────
                TextFormField(
                  controller: fullnameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDeco('Nom complet', Icons.person_outline_rounded),
                  validator: (v) => v!.trim().isEmpty ? 'Nom et prénoms requis' : null,
                ),
                const SizedBox(height: 14),

                // ── Email ──────────────────────────────────────────────
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDeco('Email', Icons.email_outlined),
                  validator: (v) => v!.contains('@') ? null : 'Email invalide',
                ),
                const SizedBox(height: 14),

                // ── Téléphone ──────────────────────────────────────────
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDeco('Téléphone', Icons.phone_outlined),
                  validator: (v) => v!.length < 10 ? 'Numéro invalide (min. 10 chiffres)' : null,
                ),
                const SizedBox(height: 14),

                // ── Mot de passe ───────────────────────────────────────
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: hidePassword,
                  decoration: _fieldDeco(
                    'Mot de passe',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey, size: 20,
                      ),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 14),

                // ── Confirmer mot de passe ─────────────────────────────
                TextFormField(
                  controller: confirmPasswordCtrl,
                  obscureText: hideConfirm,
                  decoration: _fieldDeco(
                    'Confirmer le mot de passe',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey, size: 20,
                      ),
                      onPressed: () => setState(() => hideConfirm = !hideConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v!.length < 6) return 'Min. 6 caractères';
                    if (v != passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── Bouton créer ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Créer mon compte',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Lien connexion ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView())),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(color: _blue, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}