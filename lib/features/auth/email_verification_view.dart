import 'dart:async';

import 'package:citoyen_plus/features/onboarding/onboarding_service.dart';
import 'package:citoyen_plus/features/onboarding/onboarding_view.dart';
import 'package:citoyen_plus/services/auth_service.dart';
import 'package:citoyen_plus/ui/accueil.dart';
import 'package:citoyen_plus/widgets/otp_input.dart';
import 'package:flutter/material.dart';

const _orange = Color(0xFFE65C00);
const _blue = Color(0xFF1556B5);

/// Écran de saisie du code OTP reçu par email après l'inscription.
///
/// L'utilisateur entre le code à 6 chiffres ; en cas de succès le backend
/// renvoie les tokens et l'utilisateur est connecté automatiquement.
class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  String _otp = '';
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown <= 1) {
          _resendCountdown = 0;
          timer.cancel();
        } else {
          _resendCountdown--;
        }
      });
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      _showMessage('Veuillez saisir le code à 6 chiffres.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyEmailOtp(
      email: widget.email,
      otp: _otp,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showMessage('✅ Email vérifié avec succès.');
      await _navigateAfterVerification();
      return;
    }

    _showMessage(
      result['message']?.toString() ?? 'Code invalide ou expiré.',
      isError: true,
    );
  }

  Future<void> _navigateAfterVerification() async {
    final shouldShowOnboarding = await OnboardingService.shouldShowOnboarding();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            shouldShowOnboarding ? const OnboardingView() : const Home(),
      ),
      (route) => false,
    );
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final result = await AuthService.resendEmailOtp(email: widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    final success = result['success'] == true;
    _showMessage(
      result['message']?.toString() ??
          (success ? 'Un nouveau code a été envoyé.' : 'Échec de l’envoi.'),
      isError: !success,
    );
    if (success) _startResendCountdown();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFFF2D55) : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Vérification de l’email'),
        backgroundColor: _orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.mark_email_read_outlined,
                  size: 64, color: _blue),
              const SizedBox(height: 20),
              const Text(
                'Confirme ton adresse email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: 'Nous avons envoyé un code à 6 chiffres à\n',
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OtpInput(
                enabled: !_isLoading,
                onChanged: (value) => _otp = value,
                onCompleted: (value) {
                  _otp = value;
                  _verify();
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas reçu le code ? ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  TextButton(
                    onPressed: (_resendCountdown > 0 || _isResending)
                        ? null
                        : _resend,
                    style: TextButton.styleFrom(foregroundColor: _blue),
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? 'Renvoyer (${_resendCountdown}s)'
                                : 'Renvoyer le code',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
