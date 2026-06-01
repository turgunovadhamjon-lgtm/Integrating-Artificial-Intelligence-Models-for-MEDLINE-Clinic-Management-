// lib/screens/register_screen.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _animationController.forward();
  }

  // Floating orbs (from login screen for consistency)
  Widget _floatingOrb(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 120 + 60;
    final duration = 15 + random.nextInt(20);

    return AnimatedPositioned(
      duration: Duration(seconds: duration),
      curve: Curves.easeInOutSine,
      top: -size,
      left: (random.nextDouble() * 100).clamp(0.0, 85.0), // Using % based positioning roughly
      child: AnimatedContainer(
        duration: Duration(seconds: duration),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 50,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Faqat admin sifatida ro'yxatdan o'tadi
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'admin', // Faqat admin
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(lang.translate('registration_success')),
            ],
          ),
          backgroundColor: const Color(0xFF0A7075),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      Navigator.pushReplacementNamed(context, '/auth');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? '${lang.translate('error')}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLanguageDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A7075).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF0A7075), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    lang.translate('language'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLanguageOption('UZB', 'O\'zbekcha', 'UZB'),
              const Divider(height: 1),
              _buildLanguageOption('ENG', 'English', 'ENG'),
              const Divider(height: 1),
              _buildLanguageOption('RUS', 'Русский', 'RUS'),
              const Divider(height: 1),
              _buildLanguageOption('KYR', 'Кыргызча', 'KYR'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String flag) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isSelected = lang.currentLanguage == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          lang.changeLanguage(code);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF0A7075) : const Color(0xFF1A1F36),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF0A7075), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<LanguageProvider>(
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // === BACKGROUND ===
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A7075),
                      Color(0xFF083D56),
                      Color(0xFF0A2D4A),
                      Color(0xFF0F1E3C),
                      Color(0xFF0D162F),
                    ],
                    stops: [0.0, 0.3, 0.6, 0.85, 1.0],
                  ),
                ),
              ),

              // Floating Orbs
              ...List.generate(6, (i) => _floatingOrb(i)),

              // Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Language Switcher (Top Right)
                          Align(
                            alignment: Alignment.topRight,
                            child: Material(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: _showLanguageDialog,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language, color: Colors.white, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        lang.currentLanguage,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Header with Icon
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0A7075).withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            lang.translate('admin_registration'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            lang.translate('admin_registration_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Glassmorphism Card
                          Container(
                            constraints: BoxConstraints(maxWidth: size.width > 600 ? 500 : double.infinity),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Info Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              lang.translate('admin_register_info'),
                                              style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    _buildGlassTextField(
                                      controller: _nameController,
                                      label: lang.translate('name'),
                                      icon: Icons.person_outline,
                                      lang: lang,
                                    ),

                                    const SizedBox(height: 20),

                                    _buildGlassTextField(
                                      controller: _emailController,
                                      label: lang.translate('email'),
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      lang: lang,
                                      validator: (v) => v!.contains('@') ? null : lang.translate('invalid_email'),
                                    ),

                                    const SizedBox(height: 20),

                                    _buildGlassTextField(
                                      controller: _passwordController,
                                      label: lang.translate('password'),
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      lang: lang,
                                      validator: (v) => v!.length >= 6 ? null : lang.translate('password_min_length'),
                                    ),

                                    const SizedBox(height: 40),

                                    // Register Button
                                    Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0A7075), Color(0xFF14B8A6)],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0A7075).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    lang.translate('register_as_admin'),
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Switch to Login
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                                          children: [
                                            const TextSpan(text: "Already have an account?  "),
                                            TextSpan(
                                              text: lang.translate('go_to_login'),
                                              style: const TextStyle(
                                                color: Color(0xFF4DB6AC),
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required LanguageProvider lang,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (v) => v!.isEmpty ? lang.translate('fill_required_fields') : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF4DB6AC)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}