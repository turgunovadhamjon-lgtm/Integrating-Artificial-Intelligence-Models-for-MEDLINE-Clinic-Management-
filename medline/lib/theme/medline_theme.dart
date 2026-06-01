// lib/theme/medline_theme.dart
// Barcha ekranlar uchun umumiy dizayn tizimi
import 'package:flutter/material.dart';

class ML {
  ML._();

  // === ASOSIY RANGLAR ===
  static const Color primary    = Color(0xFF0077B6); // Azure Blue
  static const Color primary2   = Color(0xFF023E8A); // Dark Navy
  static const Color accent     = Color(0xFF00B4D8); // Sky Blue
  static const Color mint       = Color(0xFF06D6A0); // Mint Green
  static const Color coral      = Color(0xFFFF6B6B); // Coral Red
  static const Color amber      = Color(0xFFFFB703); // Warm Amber
  static const Color purple     = Color(0xFF7B2FBE); // Purple

  // === FON ===
  static const Color bgPage     = Color(0xFFF0F7FF); // Light Azure BG
  static const Color bgCard     = Color(0xFFFFFFFF);
  static const Color bgField    = Color(0xFFF5F9FF);

  // === STATUS RANGLAR ===
  static const Color waiting    = Color(0xFFFF6B35); // Orange
  static const Color waitingBg  = Color(0xFFFFF0EA);
  static const Color done       = Color(0xFF06D6A0); // Mint
  static const Color doneBg     = Color(0xFFE8FBF5);
  static const Color paid       = Color(0xFF2EC4B6); // Teal
  static const Color paidBg     = Color(0xFFE8FAF9);
  static const Color unpaid     = Color(0xFFFF6B6B); // Coral
  static const Color unpaidBg   = Color(0xFFFFEEEE);

  // === GRADIENT ===
  static const LinearGradient headerGrad = LinearGradient(
    colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient mintGrad = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF00B4D8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient coralGrad = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient amberGrad = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGrad = LinearGradient(
    colors: [Color(0xFF7B2FBE), Color(0xFF9B59B6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // === SHADOW ===
  static List<BoxShadow> shadow({Color? color, double blur = 20, double dy = 6}) => [
    BoxShadow(color: (color ?? primary).withOpacity(0.13), blurRadius: blur, offset: Offset(0, dy)),
  ];
  static List<BoxShadow> cardShadow = [
    const BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 8)),
    const BoxShadow(color: Color(0x080077B6), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // === INPUT DECORATION ===
  static InputDecoration inputDec(String label, IconData icon, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    prefixIcon: Icon(icon, color: primary, size: 21),
    labelStyle: const TextStyle(color: Color(0xFF5E8DB8)),
    filled: true, fillColor: bgField,
    contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD0E8FF), width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: coral, width: 1.5)),
  );

  // === APPBAR ===
  static AppBar appBar({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) => AppBar(
    backgroundColor: Colors.transparent,
    flexibleSpace: Container(
      decoration: const BoxDecoration(gradient: headerGrad),
    ),
    elevation: 0,
    toolbarHeight: 70,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    ]),
    actions: actions,
  );

  // === STATUS BADGE ===
  static Widget badge(String label, IconData icon, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    ]),
  );

  // === STAT CARD ===
  static Widget statCard(String label, String value, IconData icon, LinearGradient grad, {String? sub}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: grad,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: grad.colors.first.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 22)),
      const SizedBox(height: 14),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
      if (sub != null) ...[const SizedBox(height: 2), Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))],
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );

  // === SECTION HEADER ===
  static Widget sectionHeader(String title, {IconData? icon, Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      if (icon != null) ...[
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: headerGrad, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
      ],
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF023E8A))),
      if (trailing != null) ...[const Spacer(), trailing],
    ]),
  );
}
