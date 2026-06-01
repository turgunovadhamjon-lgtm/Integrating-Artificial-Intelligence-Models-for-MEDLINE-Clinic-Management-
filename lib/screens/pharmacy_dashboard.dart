// lib/screens/pharmacy_dashboard.dart — YANGI DIZAYN
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});
  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> with SingleTickerProviderStateMixin {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _catFilter;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color primary  = Color(0xFF06D6A0);  // Mint — dorixona
  static const Color accent   = Color(0xFF00B4D8);
  static const Color bgPage   = Color(0xFFF0FFF8);
  static const Color lowStock = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }
  @override
  void dispose() { _animCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  String _fmt(dynamic n) => '${NumberFormat('#,###', 'uz_UZ').format((n is num ? n.toDouble() : 0.0))} so\'m';

  Color _catColor(String c) => switch(c) { 'tablets' => const Color(0xFF1565C0), 'syrup' => const Color(0xFF6A1B9A), 'injection' => const Color(0xFFC62828), 'ointment' => const Color(0xFFE65100), 'drops' => const Color(0xFF00838F), _ => Colors.grey.shade600 };
  IconData _catIcon(String c) => switch(c) { 'tablets' => Icons.medication_rounded, 'syrup' => Icons.local_drink_rounded, 'injection' => Icons.vaccines_rounded, 'ointment' => Icons.healing_rounded, 'drops' => Icons.water_drop_rounded, _ => Icons.medical_services_rounded };

  // ── PDF ──
  Future<void> _pdfReport(DateTime date, LanguageProvider lang) async {
    final s = DateTime(date.year, date.month, date.day);
    final e = s.add(const Duration(days: 1));
    final snap = await FirebaseFirestore.instance.collection('sales').where('soldAt', isGreaterThanOrEqualTo: Timestamp.fromDate(s)).where('soldAt', isLessThan: Timestamp.fromDate(e)).orderBy('soldAt', descending: true).get();
    final sales = snap.docs.map((d) => d.data()).toList();
    final total = sales.fold<double>(0, (s, d) => s + (d['totalPrice'] as num).toDouble());
    final pdf = pw.Document();
    pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(50), build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Center(child: pw.Text('MEDLINE - Kunlik Savdo Hisoboti', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Center(child: pw.Text(DateFormat('dd MMMM yyyy', 'en_US').format(date), style: const pw.TextStyle(fontSize: 18))),
      pw.Divider(thickness: 2), pw.SizedBox(height: 20),
      pw.Text('Jami tranzaksiyalar: ${sales.length}', style: const pw.TextStyle(fontSize: 15)),
      pw.SizedBox(height: 6),
      pw.Text('Jami daromad: ${_fmt(total)}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
      pw.SizedBox(height: 30),
      if (sales.isNotEmpty) pw.Table(border: pw.TableBorder.all(width: 1, color: PdfColors.grey400), columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)}, children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.green100), children: ['Dori', 'Miqdor', 'Narx', 'Jami'].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))).toList()),
        ...sales.map((s) => pw.TableRow(children: [s['medicineName'] ?? '', '${s['quantity']}', _fmt(s['price']), _fmt(s['totalPrice'])].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t))).toList())),
      ]),
    ])));
    try {
      final dir = await getTemporaryDirectory();
      final name = 'Hisobot_${DateFormat('dd-MMM-yyyy').format(date)}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(await pdf.save());
      if (!mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.check_circle, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('Hisobot tayyor')]),
        content: Text('$name saqlandi'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
          ElevatedButton.icon(icon: const Icon(Icons.print, size: 18), label: const Text('Chop etish'), style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { Navigator.pop(ctx); Printing.layoutPdf(onLayout: (_) => pdf.save(), name: name); }),
          ElevatedButton.icon(icon: const Icon(Icons.folder_open, size: 18), label: const Text('Ochish'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { Navigator.pop(ctx); OpenFilex.open(file.path); }),
        ],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Dialogs ──
  void _addMedDialog(LanguageProvider lang) {
    final nCtrl = TextEditingController(), prCtrl = TextEditingController(), qCtrl = TextEditingController();
    String cat = 'tablets'; DateTime? expiry;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add_box_rounded, color: Color(0xFF2E7D32), size: 26)),
          const SizedBox(width: 12),
          Text(lang.translate('add_medicine'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        ]),
        const SizedBox(height: 20),
        _fld(nCtrl, lang.translate('medicine_name'), Icons.medication_rounded),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: cat,
          decoration: _deco(lang.translate('category'), Icons.category_rounded),
          items: ['tablets','syrup','injection','ointment','drops'].map((c) => DropdownMenuItem(value: c, child: Text(lang.translate(c)))).toList(),
          onChanged: (v) => setSt(() => cat = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _fld(prCtrl, lang.translate('price'), Icons.payments_rounded, type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _fld(qCtrl, lang.translate('quantity'), Icons.inventory_2_rounded, type: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
            if (d != null) setSt(() => expiry = d);
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), decoration: BoxDecoration(color: const Color(0xFFF1FBF3), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFC8E6C9))),
            child: Row(children: [
              const Icon(Icons.calendar_month_rounded, color: Color(0xFF2E7D32), size: 20), const SizedBox(width: 12),
              Text(expiry != null ? DateFormat('dd/MM/yyyy').format(expiry!) : lang.translate('select_date'), style: const TextStyle(fontSize: 15, color: Colors.black87)),
            ])),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(lang.translate('cancel')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              if (nCtrl.text.isEmpty || prCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('medicines').add({'name': nCtrl.text.trim(), 'category': cat, 'price': double.tryParse(prCtrl.text) ?? 0, 'quantity': int.tryParse(qCtrl.text) ?? 0, 'expiryDate': expiry != null ? Timestamp.fromDate(expiry!) : null, 'createdAt': Timestamp.now()});
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(lang.translate('add')),
          )),
        ]),
      ]))),
    )));
  }

  void _sellDialog(String id, Map<String, dynamic> data, LanguageProvider lang) {
    final qCtrl = TextEditingController(text: '1');
    final price = data['price'] ?? 0.0;
    final current = data['quantity'] ?? 0;
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF2E7D32), size: 32)),
        const SizedBox(height: 12),
        Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        Text('Mavjud: $current dona', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        TextField(controller: qCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: _deco(lang.translate('quantity'), Icons.numbers_rounded)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(lang.translate('cancel')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.sell_rounded, size: 18),
            label: Text(lang.translate('sell')),
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              final qty = int.tryParse(qCtrl.text) ?? 0;
              if (qty > 0 && qty <= current) {
                await FirebaseFirestore.instance.collection('sales').add({'medicineId': id, 'medicineName': data['name'], 'quantity': qty, 'price': price, 'totalPrice': qty * (price as num).toDouble(), 'soldAt': Timestamp.now(), 'soldBy': FirebaseAuth.instance.currentUser?.uid});
                await FirebaseFirestore.instance.collection('medicines').doc(id).update({'quantity': current - qty});
                if (mounted) Navigator.pop(ctx);
              }
            },
          )),
        ]),
      ])),
    ));
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: primary, size: 20),
    filled: true, fillColor: const Color(0xFFF1FBF3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFC8E6C9))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8)),
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
  );

  Widget _fld(TextEditingController c, String label, IconData icon, {TextInputType type = TextInputType.text}) =>
    TextField(controller: c, keyboardType: type, style: const TextStyle(fontSize: 15, color: Colors.black87), decoration: _deco(label, icon));

  // ── Pages ──
  Widget _medPage(LanguageProvider lang) => Column(children: [
    Container(color: Colors.white, padding: const EdgeInsets.all(14), child: Column(children: [
      TextField(controller: _searchCtrl, style: const TextStyle(fontSize: 15),
        decoration: _deco(lang.translate('search_medicine'), Icons.search_rounded).copyWith(suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchCtrl.clear(); }) : null)),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _chip(null, lang.translate('all'), lang), _chip('tablets', lang.translate('tablets'), lang), _chip('syrup', lang.translate('syrup'), lang),
        _chip('injection', lang.translate('injection'), lang), _chip('ointment', lang.translate('ointment'), lang), _chip('drops', lang.translate('drops'), lang),
      ])),
    ])),
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: _catFilter == null ? FirebaseFirestore.instance.collection('medicines').snapshots() : FirebaseFirestore.instance.collection('medicines').where('category', isEqualTo: _catFilter).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        final meds = snap.data!.docs.where((d) => (d['name'] as String).toLowerCase().contains(_search.toLowerCase())).toList();
        if (meds.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle), child: const Icon(Icons.medication_rounded, size: 48, color: Color(0xFF2E7D32))),
          const SizedBox(height: 16), const Text('Dori topilmadi', style: TextStyle(color: Colors.black45, fontSize: 16)),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: meds.length,
          itemBuilder: (_, i) {
            final d = meds[i].data() as Map<String, dynamic>;
            final isLow = (d['quantity'] as num? ?? 0) < 10;
            final cat = d['category'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                border: Border.all(color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9))),
              child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: _catColor(cat).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(_catIcon(cat), color: _catColor(cat), size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(lang.translate(cat), style: TextStyle(fontSize: 12, color: _catColor(cat), fontWeight: FontWeight.w600)),
                    const Text('  •  ', style: TextStyle(color: Colors.black26)),
                    Icon(isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded, size: 13, color: isLow ? lowStock : Colors.black45),
                    const SizedBox(width: 4),
                    Text('${d['quantity']} dona', style: TextStyle(fontSize: 12, color: isLow ? lowStock : Colors.black45, fontWeight: isLow ? FontWeight.bold : FontWeight.normal)),
                  ]),
                  Text(_fmt(d['price']), style: const TextStyle(fontSize: 14, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                ])),
                Column(children: [
                  IconButton(icon: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2E7D32)), onPressed: () => _sellDialog(meds[i].id, d, lang), tooltip: lang.translate('sell')),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('O\'chirish?'), content: Text(d['name']),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { FirebaseFirestore.instance.collection('medicines').doc(meds[i].id).delete(); Navigator.pop(ctx); }, child: const Text('O\'chirish'))],
                  ))),
                ]),
              ])),
            );
          },
        );
      },
    )),
  ]);

  Widget _chip(String? cat, String label, LanguageProvider lang) {
    final sel = _catFilter == cat;
    return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
      label: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      selected: sel, onSelected: (_) => setState(() => _catFilter = sel ? null : cat),
      backgroundColor: Colors.grey.shade100, selectedColor: primary,
      checkmarkColor: Colors.white, showCheckmark: false,
      side: BorderSide(color: sel ? primary : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ));
  }

  Widget _salesPage(LanguageProvider lang) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('sales').orderBy('soldAt', descending: true).limit(50).snapshots(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
      final sales = snap.data!.docs;
      if (sales.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF2E7D32))),
        const SizedBox(height: 16), const Text('Savdolar yo\'q', style: TextStyle(color: Colors.black45, fontSize: 16)),
      ]));
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: sales.length,
        itemBuilder: (_, i) {
          final d = sales[i].data() as Map<String, dynamic>;
          final dt = (d['soldAt'] as Timestamp).toDate();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF2E7D32), size: 22)),
              title: Text(d['medicineName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(dt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${d['quantity']} x ${_fmt(d['price'])}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                Text(_fmt(d['totalPrice']), style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
          );
        },
      );
    },
  );

  Widget _statsPage(LanguageProvider lang) => FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('sales').get(),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
      final sales = snap.data!.docs;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      double today = 0, total = 0;
      for (var s in sales) { final d = s.data() as Map<String, dynamic>; final p = (d['totalPrice'] ?? 0).toDouble(); total += p; if ((d['soldAt'] as Timestamp).toDate().isAfter(todayStart)) today += p; }
      return Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        _statCard(lang.translate('today_revenue') ?? 'Bugungi daromad', _fmt(today), Icons.today_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        const SizedBox(height: 14),
        _statCard(lang.translate('total_revenue') ?? 'Jami daromad', _fmt(total), Icons.account_balance_wallet_rounded, primary, const Color(0xFFE8F5E9)),
        const SizedBox(height: 14),
        _statCard('Jami tranzaksiyalar', '${sales.length} ta', Icons.receipt_rounded, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
      ]));
    },
  );

  Widget _statCard(String title, String value, IconData icon, Color color, Color bg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      border: Border.all(color: bg)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 30)),
      const SizedBox(width: 18),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (ctx, lang, _) => Scaffold(
      backgroundColor: ML.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF06D6A0), Color(0xFF00B4D8)]),
        )),
        elevation: 0, toolbarHeight: 68,
        leading: const SizedBox.shrink(),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MEDLINE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            Text('Dorixona', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white), onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null && mounted) _pdfReport(d, lang);
          }, tooltip: 'Hisobot'),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(height: 3, color: Colors.white24)),
      ),
      body: FadeTransition(opacity: _fadeAnim, child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: ML.cardShadow),
          child: Row(children: [
            _navItem(0, Icons.medication_rounded, lang.translate('medicines')),
            _navItem(1, Icons.shopping_cart_rounded, lang.translate('sales')),
            _navItem(2, Icons.bar_chart_rounded, lang.translate('statistics')),
          ]),
        ),
        Expanded(child: _tab == 0 ? _medPage(lang) : _tab == 1 ? _salesPage(lang) : _statsPage(lang)),
      ])),
      floatingActionButton: _tab == 0 ? FloatingActionButton.extended(
        backgroundColor: primary, foregroundColor: Colors.white,
        onPressed: () => _addMedDialog(lang),
        icon: const Icon(Icons.add_rounded),
        label: Text(lang.translate('add_medicine') ?? 'Dori qo\'shish'),
        elevation: 4,
      ) : null,
    ));
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final sel = _tab == idx;
    final grads = [ML.mintGrad, ML.amberGrad, ML.headerGrad];
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(gradient: sel ? grads[idx] : null, borderRadius: BorderRadius.circular(13)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: sel ? Colors.white : Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey.shade400, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    ));
  }
}
