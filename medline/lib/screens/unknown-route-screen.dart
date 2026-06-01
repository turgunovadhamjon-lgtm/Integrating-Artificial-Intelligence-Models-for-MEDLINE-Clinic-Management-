// lib/screens/unknown-route-screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UnknownRouteScreen extends StatefulWidget {
  const UnknownRouteScreen({super.key});

  @override
  State<UnknownRouteScreen> createState() => _UnknownRouteScreenState();
}

class _UnknownRouteScreenState extends State<UnknownRouteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _floatingParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 100 + 50;
    final duration = 20 + random.nextInt(15);
    return AnimatedPositioned(
      duration: Duration(seconds: duration),
      curve: Curves.easeInOutSine,
      top: -size,
      left: (random.nextDouble() * 100).clamp(0.0, 95.0) *
          (MediaQuery.of(context).size.width / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withOpacity(0.08), Colors.transparent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.06),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          
          // Floating Particles
          ...List.generate(8, (i) => _floatingParticle(i)),
          
          // Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 404 Icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // 404 Text
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.primaryTeal, Colors.white],
                        ).createShader(bounds),
                        child: const Text(
                          '404',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Message
                      const Text(
                        'Sahifa topilmadi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Siz qidirayotgan sahifa mavjud emas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Back Button
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Orqaga qaytish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Home Button
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/auth', (route) => false),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Bosh sahifaga'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
  }
}