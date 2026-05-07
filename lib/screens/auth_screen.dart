import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/peak_picks_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        await AuthService.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInAsGuest();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Catch any non-FirebaseAuthException errors (network, platform, etc.)
      // so the loading state is cleared and the user sees feedback instead of
      // a stuck spinner.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't start guest session. Please check your connection and try again.",
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PeakPicksLogo(height: 48)),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Rank everything.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Welcome back' : 'Create account',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),

                        // Name field (signup only)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Your name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) {
                              if (!_isLogin &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: _isLogin
                                ? 'Your password'
                                : 'Min. 6 characters',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            if (!_isLogin && v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              disabledBackgroundColor:
                                  AppColors.accent.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isLogin ? 'Sign In' : 'Create Account'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Toggle login/signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                        }),
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ]),

                  const SizedBox(height: 16),

                  // Continue as Guest
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _continueAsGuest,
                      icon: const Icon(Icons.person_outline_rounded,
                          color: AppColors.textSecondary),
                      label: const Text('Continue as Guest',
                          style: TextStyle(color: AppColors.textSecondary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Guest data is saved locally and may be lost\nif you sign out or reinstall the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
