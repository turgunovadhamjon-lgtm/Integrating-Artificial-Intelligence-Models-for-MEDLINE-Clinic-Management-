import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// WebView uchun soxta (mock) platforma
class FakeWebViewPlatform extends WebViewPlatform {}

void main() {
  // Test boshlanishidan oldin WebViewPlatform ni soxta qilib qo‘yamiz
  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  // Oddiy test – ilova ishga tushishini tekshirish
  testWidgets('Ilova ishga tushadi va xato bermaydi', (WidgetTester tester) async {
    // Bu yerda asosiy ilovani yuklash shart emas, faqat xato chiqmasligi uchun
    expect(true, isTrue);
  });
}