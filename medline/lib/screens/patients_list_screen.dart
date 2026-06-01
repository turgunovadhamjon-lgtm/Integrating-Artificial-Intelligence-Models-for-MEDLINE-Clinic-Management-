// lib/screens/patients_list_screen.dart — YANGI DIZAYN
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});
  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> with SingleTickerProviderStateMixin {
  String _search = '';
  String _filter = 'all';
  String _sort = 'date';
  DateTime _date = DateTime.now();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color primary = Color(0xFF0077B6);
  static const Color bgPage  = Color(0xFFF0F7FF);
  static const Color doneClr = Color(0xFF06D6A0);
  static const Color doneBg  = Color(0xFFE8FBF5);
  static const Color pendClr = Color(0xFFFF6B35);
  static const Color pendBg  = Color(0xFFFFF0EA);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }
  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  String _fmtDate(Timestamp? ts) => ts == null ? '' : DateFormat('dd.MM.yyyy HH:mm').format(ts.toDate());
  String _fmt(num n) => NumberFormat('#,###', 'uz_UZ').format(n);

  pw.Widget _pdfCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
  );

  Future<void> _selectDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) setState(() { _date = d; _filter = 'daily'; });
  }

  Future<void> _printReport(LanguageProvider lang, List<QueryDocumentSnapshot> patients) async {
    final dsSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
    final dNames = { for (var d in dsSnap.docs) d.id: (d['name'] as String?)?.trim() ?? 'N/A' };
    final dateStr = DateFormat('dd.MM.yyyy').format(_date);
    num total = 0, paid = 0;
    for (var d in patients) { final p = d['price'] as num? ?? 0; total += p; if (d['isPaid'] == true) paid += p; }
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (_) => [
      pw.Center(child: pw.Column(children: [
        pw.Text('MEDLINE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Kunlik Hisobot', style: const pw.TextStyle(fontSize: 18)),
        pw.Text(dateStr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ])),
      pw.SizedBox(height: 20),
      pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all()), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
        pw.Column(children: [pw.Text('${patients.length}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)), pw.Text('Jami bemorlar')]),
        pw.Column(children: [pw.Text('${_fmt(total)} so\'m', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)), pw.Text('Jami summa')]),
        pw.Column(children: [pw.Text('${_fmt(paid)} so\'m', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)), pw.Text('To\'langan')]),
      ])),
      pw.SizedBox(height: 20),
      pw.Table(border: pw.TableBorder.all(), children: [
        pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue100),
            children: ['#','Bemor','Shikoyat','Shifokor','Summa','Holat']
                .map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8),
                child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))).toList()),
        ...patients.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          final isPaid = d['isPaid'] == true;
          final issue = (d['issue'] ?? '').toString();
          return pw.TableRow(children: [
            _pdfCell('${e.key + 1}'),
            _pdfCell('${d['name'] ?? ''} ${d['surname'] ?? ''}'.trim()),
            _pdfCell(issue.length > 25 ? '${issue.substring(0, 25)}...' : issue),
            _pdfCell(dNames[d['doctorId']] ?? '-'),
            _pdfCell('${_fmt(d['price'] ?? 0)} so\'m'),
            pw.Container(
              color: isPaid ? PdfColors.green100 : PdfColors.red50,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                isPaid ? "To'langan" : "To'lanmagan",
                style: pw.TextStyle(
                  color: isPaid ? PdfColors.green800 : PdfColors.red700,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ]);
        }),
      ]),
      pw.SizedBox(height: 20),
      pw.Text('Chop etildi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
    ]));
    await Printing.layoutPdf(onLayout: (_) => pdf.save(), name: 'MEDLINE_$dateStr.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (ctx, lang, _) => Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF00B4D8)]),
        )),
        elevation: 0, toolbarHeight: 66,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 10),
          Text(lang.translate('patients_list') ?? 'Bemorlar ro\'yxati', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'all', child: Text(lang.translate('all'))),
              PopupMenuItem(value: 'waiting', child: Text(lang.translate('waiting'))),
              PopupMenuItem(value: 'completed', child: Text(lang.translate('completed'))),
              PopupMenuItem(value: 'paid', child: Text(lang.translate('paid'))),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'date', child: Text(lang.translate('sort_by_date') ?? 'Sana')),
              PopupMenuItem(value: 'name', child: Text(lang.translate('sort_by_name') ?? 'Ism')),
              PopupMenuItem(value: 'status', child: Text(lang.translate('sort_by_status') ?? 'Holat')),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF00BCD4)])))),
      ),
      body: FadeTransition(opacity: _fadeAnim, child: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: TextField(
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: lang.translate('search_patients'),
            prefixIcon: const Icon(Icons.search_rounded, color: primary, size: 20),
            suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () => setState(() => _search = '')) : null,
            filled: true, fillColor: const Color(0xFFF5F9FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6E4FF))),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
        )),
        // Stats bar
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('patients').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const SizedBox();
            final docs = snap.data!.docs;
            final total = docs.length;
            final wait = docs.where((d) => d['status'] == 'waiting').length;
            final done = docs.where((d) => d['status'] == 'completed').length;
            final paid = docs.where((d) => d['isPaid'] == true).length;
            final paidAmt = docs.where((d) => d['isPaid'] == true).fold(0.0, (s, d) => s + (d['price'] as num? ?? 0).toDouble());
            final dailyDocs = docs.where((d) { final dt = (d['createdAt'] as Timestamp?)?.toDate(); if (dt == null) return false; return dt.year == _date.year && dt.month == _date.month && dt.day == _date.day; }).toList();
            return Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: Column(children: [
              Row(children: [
                _sCard('$total', lang.translate('all'), Icons.people_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD), 'all'),
                const SizedBox(width: 6),
                _sCard('$wait', lang.translate('waiting'), Icons.access_time_rounded, pendClr, pendBg, 'waiting'),
                const SizedBox(width: 6),
                _sCard('$done', lang.translate('completed'), Icons.check_circle_rounded, doneClr, doneBg, 'completed'),
                const SizedBox(width: 6),
                _sCard('$paid', lang.translate('paid'), Icons.payments_rounded, const Color(0xFF00838F), const Color(0xFFE0F7FA), 'paid'),
              ]),
              const SizedBox(height: 8),
              GestureDetector(onTap: () => setState(() => _filter = 'daily'), child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _filter == 'daily' ? const Color(0xFFEDE7F6) : const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _filter == 'daily' ? const Color(0xFF6A1B9A) : const Color(0xFFD6E4FF))),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, color: _filter == 'daily' ? const Color(0xFF6A1B9A) : Colors.grey, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('dd.MM.yyyy').format(_date), style: TextStyle(fontWeight: FontWeight.bold, color: _filter == 'daily' ? const Color(0xFF4A148C) : Colors.black87, fontSize: 13)),
                    Text('${dailyDocs.length} bemor  •  ${_fmt(dailyDocs.where((d) => d['isPaid'] == true).fold(0.0, (s, d) => s + (d['price'] as num? ?? 0).toDouble()))} so\'m', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ])),
                  IconButton(icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey), onPressed: _selectDate, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 8),
                  if (dailyDocs.isNotEmpty) IconButton(icon: const Icon(Icons.print_rounded, size: 18, color: Colors.grey), onPressed: () => _printReport(lang, dailyDocs), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ]),
              )),
            ]));
          },
        ),
        // List
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('patients').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
            var list = snap.data!.docs;
            if (_filter == 'waiting') list = list.where((d) => d['status'] == 'waiting').toList();
            else if (_filter == 'completed') list = list.where((d) => d['status'] == 'completed').toList();
            else if (_filter == 'paid') list = list.where((d) => d['isPaid'] == true).toList();
            else if (_filter == 'daily') list = list.where((d) { final dt = (d['createdAt'] as Timestamp?)?.toDate(); if (dt == null) return false; return dt.year == _date.year && dt.month == _date.month && dt.day == _date.day; }).toList();
            if (_search.isNotEmpty) list = list.where((d) => (d['name']??'').toString().toLowerCase().contains(_search) || (d['surname']??'').toString().toLowerCase().contains(_search)).toList();
            list.sort((a, b) {
              if (_sort == 'name') return (a['name']??'').compareTo(b['name']??'');
              if (_sort == 'status') return (a['status']??'').compareTo(b['status']??'');
              final da = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              final db = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
              return db.compareTo(da);
            });
            if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle), child: const Icon(Icons.people_alt_rounded, size: 48, color: primary)),
              const SizedBox(height: 16), Text(lang.translate('no_patients'), style: const TextStyle(color: Colors.black45, fontSize: 16)),
            ]));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final d = list[i].data() as Map<String, dynamic>;
                final done = d['status'] == 'completed';
                final paid = d['isPaid'] ?? false;
                final name = '${d['name']??''} ${d['surname']??''}'.trim();
                final init = name.isNotEmpty ? name[0].toUpperCase() : 'B';
                return GestureDetector(
                  onTap: () => _patientDetail(d, lang),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        border: Border.all(color: done ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80))),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: done ? [doneClr, const Color(0xFF4CAF50)] : [primary, const Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name.isNotEmpty ? name : 'Bemor', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: done ? doneBg : pendBg, borderRadius: BorderRadius.circular(20)),
                              child: Text(done ? lang.translate('completed') : lang.translate('waiting'), style: TextStyle(fontSize: 11, color: done ? doneClr : pendClr, fontWeight: FontWeight.w600))),
                          if (d['queue'] != null) ...[const SizedBox(width: 6), Text('№${d['queue']}', style: const TextStyle(fontSize: 11, color: Colors.black45))],
                        ]),
                        Text(_fmtDate(d['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.black38)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${_fmt(d['price'] as num? ?? 0)} so\'m', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 13, color: paid ? doneClr : Colors.orange),
                          const SizedBox(width: 3),
                          Text(paid ? lang.translate('paid') : lang.translate('unpaid'), style: TextStyle(fontSize: 11, color: paid ? doneClr : Colors.orange, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                    ])),
                  ),
                );
              },
            );
          },
        )),
      ])),
    ));
  }

  Widget _sCard(String val, String label, IconData icon, Color color, Color bg, String filterKey) {
    final sel = _filter == filterKey;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _filter = filterKey),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(color: sel ? color : bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? color : color.withOpacity(0.3))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: sel ? Colors.white : color),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sel ? Colors.white : color)),
          Text(label, style: TextStyle(fontSize: 9, color: sel ? Colors.white70 : Colors.black45), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ]),
      ),
    ));
  }

  void _patientDetail(Map<String, dynamic> d, LanguageProvider lang) {
    final name = '${d['name']??''} ${d['surname']??''}'.trim();
    final done = d['status'] == 'completed';
    final paid = d['isPaid'] ?? false;
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: done ? [doneClr, const Color(0xFF4CAF50)] : [primary, const Color(0xFF42A5F5)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Row(children: [
                CircleAvatar(backgroundColor: Colors.white.withOpacity(0.2), radius: 26, child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isNotEmpty ? name : 'Bemor', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_fmtDate(d['createdAt']), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
              ])),
          Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
            _dRow(Icons.format_list_numbered_rounded, lang.translate('queue'), d['queue']?.toString(), primary),
            _dRow(Icons.location_on_rounded, lang.translate('address'), d['address'], const Color(0xFF6A1B9A)),
            _dRow(Icons.healing_rounded, lang.translate('issue'), d['issue'], Colors.red.shade700),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(d['doctorId']).get(),
              builder: (_, s) => _dRow(Icons.medical_services_rounded, lang.translate('doctor'), s.data?['name'] ?? '...', const Color(0xFF1565C0)),
            ),
            _dRow(Icons.payments_rounded, lang.translate('price'), '${_fmt(d['price']??0)} so\'m', const Color(0xFF1B5E20)),
            _dRow(paid ? Icons.check_circle_rounded : Icons.cancel_rounded, lang.translate('payment'), paid ? lang.translate('paid') : lang.translate('unpaid'), paid ? doneClr : pendClr),
            if (d['diagnosis'] != null && (d['diagnosis'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: doneBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFA5D6A7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.assignment_turned_in_rounded, size: 14, color: doneClr), SizedBox(width: 6), Text('Diagnoz', style: TextStyle(color: doneClr, fontWeight: FontWeight.bold, fontSize: 13))]),
                const SizedBox(height: 6),
                Text(d['diagnosis'], style: const TextStyle(color: Color(0xFF1B5E20))),
              ])),
            ],
          ])),
        ]),
      ),
    ));
  }

  Widget _dRow(IconData icon, String label, String? val, Color color) {
    if (val == null || val.isEmpty) return const SizedBox();
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
        Text(val, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      ])),
    ]));
  }
}