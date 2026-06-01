// lib/screens/dmed_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// WebView faqat Android/iOS da import qilinadi
import 'package:webview_flutter/webview_flutter.dart'
if (dart.library.html) 'package:webview_flutter/webview_flutter.dart';

class DmedScreen extends StatefulWidget {
  final String? specificUrl;
  final String? title;

  const DmedScreen({
    super.key,
    this.specificUrl,
    this.title,
  });

  @override
  State<DmedScreen> createState() => _DmedScreenState();
}

class _DmedScreenState extends State<DmedScreen>
    with SingleTickerProviderStateMixin {

  static const String _baseUrl = 'https://my.dmed.uz/uz';
  static const Color _dmedGreen = Color(0xFF00B259);
  static const Color _bgDark = Color(0xFF0A2D4A);

  // Faqat mobile uchun
  WebViewController? _webController;
  bool _isLoading = true;
  bool _hasError = false;
  double _loadingProgress = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Windows/Linux/macOS da true
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;

  String get _targetUrl => widget.specificUrl ?? _baseUrl;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    if (!_isDesktop) {
      _initWebView();
    }
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _isLoading = true; _hasError = false; _loadingProgress = 0; });
        },
        onProgress: (p) {
          if (mounted) setState(() => _loadingProgress = p / 100);
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _isLoading = false);
            _animController.forward(from: 0);
          }
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _isLoading = false; _hasError = true; });
        },
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri != null &&
              (uri.host.contains('dmed.uz') || uri.host.contains('uzinfocom.uz'))) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(_targetUrl));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _floatingParticle(int index) {
    final r = Random(index);
    final size = r.nextDouble() * 80 + 40;
    final dur = 15 + r.nextInt(15);
    final screenW = MediaQuery.of(context).size.width;
    return Positioned(
      top: r.nextDouble() * 200 - size,
      left: r.nextDouble() * screenW,
      child: AnimatedContainer(
        duration: Duration(seconds: dur),
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            _dmedGreen.withOpacity(0.08),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ===== DESKTOP: WebView yo'q, brauzerda ochish =====
    if (_isDesktop) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A2D4A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _dmedGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('DMED',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
            const SizedBox(width: 10),
            Text(widget.title ?? 'dmed.uz',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A7075), _bgDark],
                ),
              ),
            ),
            ...List.generate(5, (i) => _floatingParticle(i)),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: _dmedGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _dmedGreen.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(color: _dmedGreen.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                        ],
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: _dmedGreen, size: 56),
                    ),
                    const SizedBox(height: 28),
                    const Text('DMED.UZ',
                        style: TextStyle(color: _dmedGreen, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Text(
                      "O'zbekiston yagona tibbiy axborot tizimi",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Windows ilovasi ichida WebView ishlamaydi.\nBrauzerda ochish uchun tugmani bosing.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Asosiy tugma — brauzerda ochish
                    SizedBox(
                      width: 280,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.open_in_browser, size: 24),
                        label: const Text('Brauzerda ochish', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dmedGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // URL ko'rsatish
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, color: Colors.white.withOpacity(0.5), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _targetUrl,
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Xususiyatlar
                    _buildFeatureRow(Icons.calendar_month, 'Shifokorga onlayn navbat olish'),
                    _buildFeatureRow(Icons.science_outlined, 'Laboratoriya tahlil natijalari'),
                    _buildFeatureRow(Icons.receipt_long, 'Elektron retseptlar'),
                    _buildFeatureRow(Icons.local_hospital_outlined, 'Klinikalar ro\'yxati'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===== MOBILE: WebView =====
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canBack = await _webController?.canGoBack() ?? false;
        if (canBack) {
          await _webController?.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A2D4A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              final canBack = await _webController?.canGoBack() ?? false;
              if (canBack) {
                await _webController?.goBack();
              } else {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _dmedGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text('DMED',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.title ?? 'dmed.uz',
                style: const TextStyle(color: Colors.white70, fontSize: 14, overflow: TextOverflow.ellipsis))),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () => _webController?.loadRequest(Uri.parse(_baseUrl)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _webController?.reload();
                setState(() { _hasError = false; _isLoading = true; });
              },
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_dmedGreen),
              minHeight: 3,
            ),
          )
              : null,
        ),
        body: Stack(
          children: [
            if (_hasError)
              _buildErrorWidget()
            else
              AnimatedOpacity(
                opacity: _isLoading ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: WebViewWidget(controller: _webController!),
              ),
            if (_isLoading && !_hasError)
              _buildLoadingWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _dmedGreen, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _dmedGreen.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _dmedGreen.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.local_hospital_outlined, color: _dmedGreen, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('DMED',
              style: TextStyle(color: _dmedGreen, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('dmed.uz yuklanmoqda...',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_dmedGreen),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 24),
            const Text("DMED.uz ga ulanib bo'lmadi",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Internet aloqangizni tekshiring yoki keyinroq urinib ko\'ring.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _webController?.reload();
                setState(() { _hasError = false; _isLoading = true; });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dmedGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Orqaga qaytish', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
          ],
        ),
      ),
    );
  }
}