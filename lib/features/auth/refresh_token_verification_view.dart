import 'package:citoyen_plus/services/auth_service.dart';
import 'package:citoyen_plus/ui/accueil.dart';
import 'package:flutter/material.dart';

class RefreshTokenVerificationView extends StatefulWidget {
  const RefreshTokenVerificationView({super.key});

  @override
  State<RefreshTokenVerificationView> createState() =>
      _RefreshTokenVerificationViewState();
}

class _RefreshTokenVerificationViewState
    extends State<RefreshTokenVerificationView> {
  final TextEditingController _tokenCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      _showMessage('Veuillez saisir le token reçu par mail.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyRefreshToken(refreshToken: token);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token vérifié avec succès.'),
          backgroundColor: Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
      return;
    }

    _showMessage(result['message'] ?? 'Token invalide, vérifiez votre email.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF2D55),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Vérifier votre token'),
        backgroundColor: const Color(0xFFE65C00),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Entrez le token envoyé à votre adresse email pour activer votre compte.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _tokenCtrl,
                decoration: InputDecoration(
                  labelText: 'Token de confirmation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1556B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Vérifier le token',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Le token est envoyé par email après votre inscription. Si vous ne l’avez pas reçu, vérifiez vos spams ou réessayez plus tard.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
