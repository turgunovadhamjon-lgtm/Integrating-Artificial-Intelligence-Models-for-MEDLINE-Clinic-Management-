// lib/screens/laboratory_dashboard.dart — YANGI DIZAYN
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';

// Keep for auth_wrapper compatibility
class HospitalizationDashboard {}

class LaboratoryDashboard extends StatefulWidget {
  const LaboratoryDashboard({super.key});
  @override
  State<LaboratoryDashboard> createState() => _LaboratoryDashboardState();
}

class _LaboratoryDashboardState extends State<LaboratoryDashboard> with SingleTickerProviderStateMixin {
  String _tab = 'all';
  final _searchCtrl = TextEditingController();
  String _search = '';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color primary  = Color(0xFF7B2FBE); // Purple — lab
  static const Color accent   = Color(0xFF00B4D8);
  static const Color bgPage   = Color(0xFFF5F0FF);
  static const Color doneClr  = Color(0xFF06D6A0);
  static const Color doneBg   = Color(0xFFE8FBF5);
  static const Color pendClr  = Color(0xFFFF6B35);
  static const Color pendBg   = Color(0xFFFFF0EA);

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

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: primary, size: 20),
    filled: true, fillColor: const Color(0xFFF3E5F5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCE93D8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.8)),
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
  );

  // ── Test Types Dialog ──
  void _testTypesDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.category_rounded, color: primary, size: 24)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Test turlari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 16),
          Expanded(child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('test_types').orderBy('name').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
              if (snap.data!.docs.isEmpty) return const Center(child: Text('Test turlari yo\'q', style: TextStyle(color: Colors.black45)));
              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (_, i) {
                  final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF8F0FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCE93D8))),
                    child: ListTile(
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE1BEE7), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.biotech_rounded, color: primary, size: 20)),
                      title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A148C))),
                      subtitle: Text('${NumberFormat('#,###', 'uz_UZ').format((d['price'] as num? ?? 0).toDouble())} so\'m', style: const TextStyle(color: primary, fontWeight: FontWeight.bold)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () async { await FirebaseFirestore.instance.collection('test_types').doc(snap.data!.docs[i].id).delete(); }),
                    ),
                  );
                },
              );
            },
          )),
          const Divider(),
          _addTestTypeRow(ctx),
        ]),
      ),
    ));
  }

  Widget _addTestTypeRow(BuildContext dialogCtx) {
    final nCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    return Row(children: [
      Expanded(child: TextField(controller: nCtrl, style: const TextStyle(fontSize: 14), decoration: _deco('Test nomi', Icons.science_rounded).copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14)))),
      const SizedBox(width: 8),
      SizedBox(width: 90, child: TextField(controller: pCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 14), decoration: _deco('Narx', Icons.payments_rounded).copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14)))),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), elevation: 0),
        onPressed: () async {
          if (nCtrl.text.isEmpty) return;
          await FirebaseFirestore.instance.collection('test_types').add({'name': nCtrl.text.trim(), 'price': double.tryParse(pCtrl.text) ?? 0, 'createdAt': FieldValue.serverTimestamp()});
          nCtrl.clear(); pCtrl.clear();
        },
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    ]);
  }

  // ── Add Test Dialog ──
  void _addTestDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? testTypeId, testTypeName;
    final fk = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_circle_outline_rounded, color: primary, size: 26)),
          const SizedBox(width: 12),
          const Text('Yangi test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        ]),
        const SizedBox(height: 20),
        TextFormField(
          controller: nameCtrl, style: const TextStyle(fontSize: 15),
          decoration: _deco('Bemor ismi', Icons.person_rounded),
          validator: (v) => v == null || v.trim().isEmpty ? 'Majburiy' : null,
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('test_types').orderBy('name').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const CircularProgressIndicator(color: primary);
            return DropdownButtonFormField<String>(
              value: testTypeId,
              decoration: _deco('Test turini tanlang', Icons.biotech_rounded),
              items: snap.data!.docs.map((d) {
                final dd = d.data() as Map<String, dynamic>;
                return DropdownMenuItem(value: d.id, child: Text('${dd['name']} - ${NumberFormat('#,###', 'uz_UZ').format((dd['price'] as num? ?? 0).toDouble())} so\'m'));
              }).toList(),
              onChanged: (v) {
                setSt(() { testTypeId = v; final doc = snap.data!.docs.firstWhere((d) => d.id == v); final dd = doc.data() as Map<String, dynamic>; testTypeName = dd['name']; priceCtrl.text = dd['price'].toString(); });
              },
              validator: (v) => v == null ? 'Tanlang' : null,
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(controller: priceCtrl, readOnly: true, style: const TextStyle(fontSize: 15), decoration: _deco('Narx (so\'m)', Icons.payments_rounded)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Bekor'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              if (fk.currentState!.validate() && testTypeId != null) {
                await FirebaseFirestore.instance.collection('laboratory_tests').add({'patientName': nameCtrl.text.trim(), 'testType': testTypeName, 'testTypeId': testTypeId, 'price': double.tryParse(priceCtrl.text) ?? 0, 'status': 'pending', 'isPaid': false, 'result': null, 'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid});
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Saqlash'),
          )),
        ]),
      ]))),
    )));
  }

  // ── Result Dialog ──
  void _resultDialog(String id, Map<String, dynamic> data) {
    final ctrl = TextEditingController(text: data['result']);
    final fk = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2E7D32), size: 26)),
          const SizedBox(width: 12),
          const Text('Test natijasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        ]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F0FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFCE93D8))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.person_rounded, size: 15, color: primary), const SizedBox(width: 6), Text(data['patientName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A148C)))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.biotech_rounded, size: 15, color: Colors.grey), const SizedBox(width: 6), Text(data['testType'] ?? '', style: const TextStyle(color: Colors.black54))]),
        ])),
        const SizedBox(height: 16),
        TextFormField(controller: ctrl, maxLines: 4, style: const TextStyle(fontSize: 15), decoration: _deco('Natija', Icons.notes_rounded), validator: (v) => v == null || v.trim().isEmpty ? 'Natija kiriting' : null),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Bekor'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              if (fk.currentState!.validate()) {
                await FirebaseFirestore.instance.collection('laboratory_tests').doc(id).update({'result': ctrl.text.trim(), 'status': 'completed', 'completedAt': FieldValue.serverTimestamp()});
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Saqlash'),
          )),
        ]),
      ]))),
    ));
  }

  // ── PDF ──
  Future<void> _generatePDF(List<QueryDocumentSnapshot> tests) async {
    final pdf = pw.Document();
    final total = tests.length;
    final done = tests.where((t) => (t.data() as Map)['status'] == 'completed').length;
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
      pw.Header(level: 0, child: pw.Text('MEDLINE Laboratoriya Hisoboti', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 10),
      pw.Text('Sana: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(data: [['Ko\'rsatkich', 'Qiymat'], ['Jami testlar', '$total'], ['Bajarilgan', '$done'], ['Kutilmoqda', '${total - done}']]),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(data: [['Bemor', 'Test', 'Narx', 'Holat'], ...tests.map((t) { final d = t.data() as Map<String, dynamic>; return [d['patientName'] ?? '', d['testType'] ?? '', '${d['price']}', d['status']]; })]),
    ]));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (ctx, lang, _) => Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF9B59B6)]),
        )),
        elevation: 0, toolbarHeight: 68,
        leading: const SizedBox.shrink(),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.science_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MEDLINE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            Text('Laboratoriya', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.category_rounded, color: Colors.white), onPressed: _testTypesDialog, tooltip: 'Test turlari'),
          IconButton(icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white), onPressed: () async {
            final snap = await FirebaseFirestore.instance.collection('laboratory_tests').get();
            _generatePDF(snap.docs);
          }, tooltip: 'Hisobot'),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFCE93D8), Color(0xFF80DEEA)])))),
      ),
      body: FadeTransition(opacity: _fadeAnim, child: Column(children: [
        // Stats
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('laboratory_tests').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const SizedBox();
            final docs = snap.data!.docs;
            final total = docs.length;
            final done = docs.where((d) => (d.data() as Map)['status'] == 'completed').length;
            final pend = total - done;
            return Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow),
              child: Row(children: [
                _stat('Jami', '$total', Icons.science_rounded, ML.purple, const Color(0xFFF3E5F5)),
                _stat('Bajarilgan', '$done', Icons.check_circle_rounded, doneClr, doneBg),
                _stat('Kutilmoqda', '$pend', Icons.pending_rounded, pendClr, pendBg),
              ]),
            );
          },
        ),
        // Search & tabs
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(14, 8, 14, 0), child: Column(children: [
          TextField(controller: _searchCtrl, style: const TextStyle(fontSize: 14), decoration: _deco('Bemor ismi bo\'yicha qidirish', Icons.search_rounded).copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14), suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchCtrl.clear(); }) : null)),
          const SizedBox(height: 8),
          Row(children: [
            _tabBtn('Hammasi', 'all'), const SizedBox(width: 8),
            _tabBtn('Kutilmoqda', 'pending'), const SizedBox(width: 8),
            _tabBtn('Bajarilgan', 'completed'),
          ]),
          const SizedBox(height: 4),
        ])),
        // List
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('laboratory_tests').orderBy('createdAt', descending: true).snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primary));
            if (!snap.hasData || snap.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF3E5F5), shape: BoxShape.circle), child: const Icon(Icons.science_rounded, size: 48, color: primary)),
              const SizedBox(height: 16), const Text('Testlar yo\'q', style: TextStyle(color: Colors.black45, fontSize: 16)),
            ]));
            var docs = snap.data!.docs;
            if (_tab != 'all') docs = docs.where((d) => (d.data() as Map)['status'] == _tab).toList();
            if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map)['patientName'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
            if (docs.isEmpty) return Center(child: Text('Natija topilmadi', style: const TextStyle(color: Colors.black45)));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final done = d['status'] == 'completed';
                final name = (d['patientName'] as String? ?? '');
                final init = name.isNotEmpty ? name[0].toUpperCase() : 'B';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    border: Border.all(color: done ? ML.done.withOpacity(0.3) : ML.waiting.withOpacity(0.3), width: 1.5)),
                  child: Material(color: Colors.transparent, child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: done ? null : () => _resultDialog(docs[i].id, d),
                    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 46, height: 46,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: done ? [doneClr, const Color(0xFF4CAF50)] : [primary, const Color(0xFFAB47BC)]), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name.isNotEmpty ? name : 'Bemor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.biotech_rounded, size: 13, color: Colors.grey.shade500), const SizedBox(width: 4),
                            Text(d['testType'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: done ? doneBg : pendBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(done ? 'Bajarildi' : 'Kutilmoqda', style: TextStyle(fontSize: 11, color: done ? doneClr : pendClr, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 4),
                          Text('${NumberFormat('#,###', 'uz_UZ').format((d['price'] as num? ?? 0).toDouble())} so\'m', style: const TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                      if (done && d['result'] != null) ...[
                        const SizedBox(height: 12),
                        Container(width: double.infinity, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: doneBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFA5D6A7))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Row(children: [Icon(Icons.assignment_turned_in_rounded, size: 13, color: doneClr), SizedBox(width: 5), Text('Natija', style: TextStyle(color: doneClr, fontWeight: FontWeight.bold, fontSize: 12))]),
                            const SizedBox(height: 5),
                            Text(d['result'], style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 13)),
                          ])),
                      ],
                      if (!done) ...[
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(
                          onPressed: () => _resultDialog(docs[i].id, d),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Natija kiritish', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        )),
                      ],
                    ])),
                  )),
                );
              },
            );
          },
        )),
      ])),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary, foregroundColor: Colors.white,
        onPressed: _addTestDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yangi test'),
        elevation: 4,
      ),
    ));
  }

  Widget _stat(String label, String val, IconData icon, Color color, Color bg) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45), textAlign: TextAlign.center),
    ]),
  ));

  Widget _tabBtn(String label, String key) {
    final sel = _tab == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: sel ? primary : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey, fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
      ),
    ));
  }
}
