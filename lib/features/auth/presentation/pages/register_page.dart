import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../../home/presentation/pages/home_screen.dart'
    show kTeal, ArabesquePainter;
import 'auth_form_helpers.dart';
import 'login_page.dart';


class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _panggilanCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _panggilanCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final error = await ref.read(authProvider.notifier).register(
          nama: _namaCtrl.text.trim(),
          namaPanggilan: _panggilanCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          pin: _pinCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Scaffold(
      backgroundColor: kTeal,
      body: Stack(
        children: [
          // ── Konten yang bisa discroll bersamaan ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header teal + arabesque + teks
                SizedBox(
                  height: 160.0 + topPad,
                  child: CustomPaint(
                    painter: ArabesquePainter(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 52, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daftar Akun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gratis selamanya untuk konten regular',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // White rounded card — seperti settings page
                Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    padding:
                        EdgeInsets.fromLTRB(24, 32, 24, 40 + bottomPad),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error banner
                          if (_errorMsg != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: cs.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: TextStyle(
                                          color: cs.onErrorContainer,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Nama lengkap
                          const AuthFieldLabel('Nama Lengkap'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _namaCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: authInputDecoration(
                              context,
                              hint: 'Nama lengkap kamu',
                              icon: Icons.person_outline_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Nama panggilan
                          const AuthFieldLabel('Nama Panggilan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _panggilanCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: authInputDecoration(
                              context,
                              hint: 'Misalnya: Budi',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama panggilan wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Email
                          const AuthFieldLabel('Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: authInputDecoration(
                              context,
                              hint: 'contoh@email.com',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!v.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password
                          const AuthFieldLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: authInputDecoration(
                              context,
                              hint: 'Min. 6 karakter',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (v.length < 6) return 'Minimal 6 karakter';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Konfirmasi password
                          const AuthFieldLabel('Konfirmasi Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.next,
                            decoration: authInputDecoration(
                              context,
                              hint: 'Ulangi password',
                              icon: Icons.lock_reset_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordCtrl.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // PIN keamanan
                          const AuthFieldLabel('PIN Keamanan (4 digit)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _pinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: _obscurePin,
                            maxLength: 4,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: authInputDecoration(
                              context,
                              hint: '••••',
                              icon: Icons.pin_outlined,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                            ).copyWith(counterText: ''),
                            validator: (v) {
                              if (v == null || v.length != 4) {
                                return 'PIN harus 4 digit';
                              }
                              if (!RegExp(r'^\d{4}$').hasMatch(v)) {
                                return 'PIN hanya boleh angka';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 4),
                          Text(
                            'PIN digunakan untuk memulihkan akun jika lupa password',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Tombol daftar
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: kTeal,
                              disabledBackgroundColor:
                                  kTeal.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Daftar Gratis',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 24),

                          // Link ke login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: kTeal,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Tombol back tetap di atas ──
          Positioned(
            top: topPad + 4,
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
