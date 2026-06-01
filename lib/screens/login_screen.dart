import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Logo puls animatsiyasi
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Shimmer animatsiyasi
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();

    _animationController.forward();
  }

  // Floating orbs yaratish
  Widget _floatingOrb(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 150 + 80;
    final duration = 20 + random.nextInt(20);
    final delay = random.nextDouble() * 5;

    return AnimatedPositioned(
      duration: Duration(seconds: duration),
      curve: Curves.easeInOutSine,
      top: -size,
      left: (random.nextDouble() * 100).clamp(0.0, 75.0),
      child: AnimatedContainer(
        duration: Duration(seconds: duration),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.08),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: Duration(seconds: (duration * 1.5).toInt()),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      _showError('${lang.translate('error')}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    switch (code) {
      case 'user-not-found':
        return lang.translate('user_not_found');
      case 'wrong-password':
        return lang.translate('wrong_password');
      case 'invalid-email':
        return lang.translate('invalid_email');
      default:
        return '${lang.translate('error')}: $code';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
              // === ZO‘R ORQA FON ===
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

              // Suzuvchi chiroyli doiralar (8 ta)
              ...List.generate(8, (i) => _floatingOrb(i)),

              // Nozik grid pattern (professional ko'rinish uchun)
              Opacity(
                opacity: 0.03,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/grid.png"), // ixtiyoriy, qo‘shsangiz yanada zo‘r bo‘ladi
                      repeat: ImageRepeat.repeat,
                      opacity: 0.05,
                    ),
                  ),
                ),
              ),

              // Asosiy kontent
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Language button
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

                          const SizedBox(height: 50),

                          // Logo with pulse animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Hero(
                                  tag: 'clinic_logo',
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A7075).withOpacity(0.3),
                                          blurRadius: 50,
                                          spreadRadius: 10,
                                        ),
                                        const BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 40,
                                          offset: Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFF0A7075), Color(0xFF14B8A6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: const Icon(
                                        Icons.local_hospital,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          Text(
                            lang.translate('app_name'),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            lang.translate('clinic_management_system'),
                            style: TextStyle(fontSize: 17, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                          ),

                          const SizedBox(height: 60),

                          // Login card
                          Container(
                            constraints: BoxConstraints(maxWidth: size.width > 600 ? 480 : double.infinity),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 50, offset: const Offset(0, 25)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(36),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      lang.translate('login'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                                    ),
                                    const SizedBox(height: 36),

                                    // Email
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Color(0xFF1A1F36), fontSize: 16),
                                      decoration: InputDecoration(
                                        labelText: lang.translate('email'),
                                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0A7075)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF0A7075), width: 2),
                                        ),
                                      ),
                                      validator: (v) => v!.contains('@') ? null : lang.translate('invalid_email'),
                                    ),

                                    const SizedBox(height: 20),

                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Color(0xFF1A1F36), fontSize: 16),
                                      decoration: InputDecoration(
                                        labelText: lang.translate('password'),
                                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0A7075)),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF64748B)),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF0A7075), width: 2),
                                        ),
                                      ),
                                      validator: (v) => v!.length >= 6 ? null : lang.translate('password_min_length'),
                                    ),

                                    const SizedBox(height: 12),

                                    // Forgot password link
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _showForgotPasswordDialog(),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 30),
                                        ),
                                        child: Text(
                                          lang.translate('forgot_password'),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Login button
                                    Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF0A7075), Color(0xFF14B8A6)]),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(color: const Color(0xFF0A7075).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : Text(
                                          lang.translate('login'),
                                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(lang.translate('dont_have_account'), style: TextStyle(color: Colors.grey.shade600)),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(context, '/register'),
                                          child: Text(
                                            lang.translate('register'),
                                            style: const TextStyle(color: Color(0xFF0A7075), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          Text(
                            lang.translate('copyright_text'),
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          ),
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

  void _showForgotPasswordDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A7075).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: Color(0xFF0A7075), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    lang.translate('forgot_password'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                lang.translate('reset_password_hint'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: lang.translate('email'),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0A7075)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0A7075), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.contains('@')) {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: emailController.text.trim(),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(lang.translate('reset_email_sent'))),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0A7075),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          _showError('${lang.translate('error')}: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A7075),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(lang.translate('send'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}