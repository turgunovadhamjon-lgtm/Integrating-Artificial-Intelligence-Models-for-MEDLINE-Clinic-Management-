// lib/screens/admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  String _period = 'today';
  int _tabIdx = 0;
  String? _patFilter;
  late AnimationController _ac;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }

  String _fmt(dynamic n) => '${NumberFormat('#,###', 'uz_UZ').format((n is num ? n.toDouble() : 0.0))} so\'m';

  Future<Map<String,dynamic>> _getStats(String period) async {
    Query q = FirebaseFirestore.instance.collection('patients');
    final now = DateTime.now();
    DateTime? start;
    if (period == 'today') start = DateTime(now.year, now.month, now.day);
    else if (period == 'week') start = now.subtract(Duration(days: now.weekday - 1));
    else if (period == 'month') start = DateTime(now.year, now.month, 1);
    if (start != null) q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    final snap = await q.get();
    double rev = 0; int paid = 0, unpaid = 0;
    for (var d in snap.docs) { final data = d.data() as Map; if (data['isPaid'] == true) { rev += (data['price'] ?? 0) as num; paid++; } else unpaid++; }
    return {'total': snap.size, 'rev': rev, 'paid': paid, 'unpaid': unpaid};
  }

  Future<Map<String,dynamic>> _getDoctorStats(String docId) async {
    final now = DateTime.now();
    final todayS = DateTime(now.year, now.month, now.day);
    final weekS  = now.subtract(Duration(days: now.weekday - 1));
    final monthS = DateTime(now.year, now.month, 1);
    final snap = await FirebaseFirestore.instance.collection('patients').where('doctorId', isEqualTo: docId).get();
    int total = snap.size, done = 0, wait = 0, paid = 0, unpaid = 0;
    double rev = 0, todayR = 0, weekR = 0, monthR = 0;
    int todayP = 0, weekP = 0, monthP = 0;
    for (var d in snap.docs) {
      final data = d.data(); final isPaid = data['isPaid'] ?? false;
      final price = (data['price'] ?? 0) as num; final date = (data['createdAt'] as Timestamp?)?.toDate();
      if (data['status'] == 'completed') done++; else wait++;
      if (isPaid) { paid++; rev += price.toDouble(); } else unpaid++;
      if (date != null) {
        if (date.isAfter(todayS)) { todayP++; if(isPaid) todayR += price; }
        if (date.isAfter(weekS))  { weekP++;  if(isPaid) weekR  += price; }
        if (date.isAfter(monthS)) { monthP++; if(isPaid) monthR += price; }
      }
    }
    return {'total': total, 'rev': rev, 'done': done, 'wait': wait, 'paid': paid, 'unpaid': unpaid, 'todayP': todayP, 'todayR': todayR, 'weekP': weekP, 'weekR': weekR, 'monthP': monthP, 'monthR': monthR};
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (_, lang, __) => Scaffold(
      backgroundColor: ML.bgPage,
      body: Column(children: [
        _header(lang),
        _navBar(lang),
        Expanded(child: FadeTransition(opacity: _fade, child:
          _tabIdx == 0 ? _statsPage(lang) : _tabIdx == 1 ? _patientsPage(lang) : _staffPage(lang))),
      ]),
    ));
  }

  // ── HEADER ──
  Widget _header(LanguageProvider lang) => Container(
    decoration: const BoxDecoration(
      gradient: ML.headerGrad,
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
    ),
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MEDLINE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
          const Text('Admin Panel', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        const Spacer(),
        _hBtn(Icons.logout_rounded, () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        }),
      ]),
    )),
  );

  Widget _hBtn(IconData icon, VoidCallback fn) => Material(
    color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
    child: InkWell(borderRadius: BorderRadius.circular(12), onTap: fn,
      child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22))),
  );

  // ── NAV BAR ──
  Widget _navBar(LanguageProvider lang) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow),
    child: Row(children: [
      _navItem(0, Icons.bar_chart_rounded, lang.translate('statistics')),
      _navItem(1, Icons.people_rounded, lang.translate('patients')),
      _navItem(2, Icons.badge_rounded, lang.translate('staff')),
    ]),
  );

  Widget _navItem(int idx, IconData icon, String label) {
    final sel = _tabIdx == idx;
    final grads = [ML.headerGrad, ML.mintGrad, ML.purpleGrad];
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tabIdx = idx),
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

  // ── STATS PAGE ──
  Widget _statsPage(LanguageProvider lang) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      // Period tabs
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: ML.cardShadow),
        child: Row(children: ['today','week','month'].map((p) {
          final sel = _period == p;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _period = p),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(gradient: sel ? ML.headerGrad : null, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(lang.translate(p),
                style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13))),
            ),
          ));
        }).toList()),
      ),
      const SizedBox(height: 16),
      FutureBuilder<Map<String,dynamic>>(
        future: _getStats(_period),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: ML.primary)));
          final s = snap.data!;
          return Column(children: [
            Row(children: [
              Expanded(child: ML.statCard(lang.translate('total_patients'), '${s['total']}', Icons.people_alt_rounded, ML.headerGrad)),
              const SizedBox(width: 12),
              Expanded(child: ML.statCard(lang.translate('total_revenue'), _fmt(s['rev']), Icons.account_balance_wallet_rounded, ML.mintGrad)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ML.statCard(lang.translate('paid'), '${s['paid']}', Icons.check_circle_rounded,
                const LinearGradient(colors: [Color(0xFF2EC4B6), Color(0xFF06D6A0)]))),
              const SizedBox(width: 12),
              Expanded(child: ML.statCard(lang.translate('unpaid'), '${s['unpaid']}', Icons.cancel_rounded, ML.coralGrad)),
            ]),
          ]);
        },
      ),
      const SizedBox(height: 24),
      ML.sectionHeader(lang.translate('doctor_statistics'), icon: Icons.medical_services_rounded),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const SizedBox();
          return Column(children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String,dynamic>;
            return _doctorCard(doc.id, d, lang);
          }).toList());
        },
      ),
    ]),
  );

  Widget _doctorCard(String id, Map<String,dynamic> d, LanguageProvider lang) {
    final init = (d['name'] as String? ?? 'D')[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(20), boxShadow: ML.cardShadow,
        border: Border.all(color: ML.primary.withOpacity(0.15))),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(20),
        child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => _doctorDetailDialog(id, d, lang),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 50, height: 50,
              decoration: BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: ML.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))]),
              child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF023E8A))),
              const SizedBox(height: 4),
              ML.badge(lang.translate('doctor'), Icons.medical_services_rounded, ML.primary, const Color(0xFFE3F2FD)),
            ])),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18)),
          ])),
        ),
      ),
    );
  }

  void _doctorDetailDialog(String id, Map<String,dynamic> d, LanguageProvider lang) {
    showDialog(context: context, builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Text(d['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
        FutureBuilder<Map<String,dynamic>>(
          future: _getDoctorStats(id),
          builder: (_, snap) {
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: ML.primary));
            final s = snap.data!;
            return Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              Row(children: [
                _miniStat('${s['total']}', lang.translate('total_patients'), Icons.people_rounded, ML.primary),
                _miniStat('${s['done']}', lang.translate('completed'), Icons.check_circle_rounded, ML.mint),
                _miniStat('${s['wait']}', lang.translate('waiting'), Icons.hourglass_top_rounded, ML.waiting),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _miniStat('${s['paid']}', lang.translate('paid'), Icons.verified_rounded, ML.paid),
                _miniStat('${s['unpaid']}', lang.translate('unpaid'), Icons.pending_rounded, ML.coral),
                _miniStat(_fmt(s['rev']), lang.translate('total_revenue'), Icons.account_balance_wallet_rounded, ML.accent),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: ML.primary, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Yopish'),
              ),
            ]));
          },
        ),
      ]),
    ));
  }

  Widget _miniStat(String val, String lbl, IconData icon, Color c) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: c, size: 20),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(lbl, style: const TextStyle(color: Colors.black45, fontSize: 9), textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── PATIENTS PAGE ──
  Widget _patientsPage(LanguageProvider lang) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: ML.cardShadow),
        child: Row(children: [
          _fChip(null, lang.translate('all')),
          _fChip('waiting', lang.translate('waiting')),
          _fChip('completed', lang.translate('completed')),
        ]),
      ),
    ),
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: _patFilter == null
          ? FirebaseFirestore.instance.collection('patients').snapshots()
          : FirebaseFirestore.instance.collection('patients').where('status', isEqualTo: _patFilter).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: ML.primary));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(gradient: ML.mintGrad, shape: BoxShape.circle),
            child: const Icon(Icons.people_outline, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          const Text('Bemor topilmadi', style: TextStyle(color: Color(0xFF5E8DB8), fontSize: 15, fontWeight: FontWeight.w600)),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final done = d['status'] == 'completed';
            final paid = d['isPaid'] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow,
                border: Border.all(color: done ? ML.done.withOpacity(0.2) : ML.waiting.withOpacity(0.2))),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(width: 46, height: 46,
                  decoration: BoxDecoration(gradient: done ? ML.mintGrad : ML.coralGrad, borderRadius: BorderRadius.circular(13)),
                  child: Icon(done ? Icons.check_rounded : Icons.hourglass_top_rounded, color: Colors.white, size: 22)),
                title: Text(d['name'] ?? d['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF023E8A))),
                subtitle: d['createdAt'] != null ? Text(
                  DateFormat('dd.MM.yyyy HH:mm').format((d['createdAt'] as Timestamp).toDate()),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5E8DB8))) : null,
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: paid ? ML.paidBg : ML.unpaidBg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: paid ? ML.paid.withOpacity(0.3) : ML.coral.withOpacity(0.3))),
                  child: Text('${NumberFormat('#,###').format((d['price'] ?? 0) as num)} so\'m',
                    style: TextStyle(color: paid ? ML.paid : ML.coral, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
            );
          },
        );
      },
    )),
  ]);

  Widget _fChip(String? val, String lbl) {
    final sel = _patFilter == val;
    final grads = {null: ML.headerGrad, 'waiting': ML.coralGrad, 'completed': ML.mintGrad};
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _patFilter = val),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(gradient: sel ? grads[val] : null, borderRadius: BorderRadius.circular(11)),
        child: Center(child: Text(lbl, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey, fontWeight: sel ? FontWeight.w700 : FontWeight.normal))),
      ),
    ));
  }

  // ── STAFF PAGE ──
  Widget _staffPage(LanguageProvider lang) => Column(children: [
    Padding(padding: const EdgeInsets.all(14), child: Container(
      decoration: BoxDecoration(gradient: ML.purpleGrad, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: ML.purple.withOpacity(0.35), blurRadius: 14, offset: const Offset(0,5))]),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _addStaffDialog(lang),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Text(lang.translate('add_staff'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ])))),
    )),
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', whereIn: ['doctor','receptionist','laboratory','pharmacy']).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: ML.primary));
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String,dynamic>;
            final role = d['role'] as String? ?? '';
            final roleData = _roleData(role);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow,
                border: Border.all(color: (roleData['color'] as Color).withOpacity(0.2))),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: Container(width: 46, height: 46,
                  decoration: BoxDecoration(gradient: roleData['grad'] as LinearGradient, borderRadius: BorderRadius.circular(13)),
                  child: Icon(roleData['icon'] as IconData, color: Colors.white, size: 22)),
                title: Text(d['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF023E8A))),
                subtitle: Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: (roleData['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(lang.translate(role == 'pharmacy' ? 'pharmacist' : role),
                    style: TextStyle(fontSize: 11, color: roleData['color'] as Color, fontWeight: FontWeight.w700))),
                trailing: Material(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10),
                  child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => _editStaffDialog(docs[i].id, d, lang),
                    child: Padding(padding: const EdgeInsets.all(8), child: const Icon(Icons.edit_rounded, color: ML.primary, size: 18)))),
              ),
            );
          },
        );
      },
    )),
  ]);

  Map<String,dynamic> _roleData(String role) {
    if (role == 'doctor')       return {'color': ML.primary, 'grad': ML.headerGrad, 'icon': Icons.medical_services_rounded};
    if (role == 'receptionist') return {'color': ML.purple,  'grad': ML.purpleGrad, 'icon': Icons.assignment_ind_rounded};
    if (role == 'laboratory')   return {'color': ML.accent,  'grad': const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF00838F)]), 'icon': Icons.science_rounded};
    if (role == 'pharmacy')     return {'color': ML.mint,    'grad': ML.mintGrad,   'icon': Icons.local_pharmacy_rounded};
    return {'color': Colors.grey, 'grad': const LinearGradient(colors: [Colors.grey, Colors.blueGrey]), 'icon': Icons.person};
  }

  // ── DIALOGS ──
  void _addStaffDialog(LanguageProvider lang) {
    final nCtrl = TextEditingController(), eCtrl = TextEditingController(), pCtrl = TextEditingController();
    String role = 'doctor';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(gradient: ML.purpleGrad, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Text(lang.translate('add_staff'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _dlgFld(nCtrl, lang.translate('name'), Icons.person_rounded),
          const SizedBox(height: 12),
          _dlgFld(eCtrl, lang.translate('email'), Icons.email_rounded, type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _dlgFld(pCtrl, lang.translate('password'), Icons.lock_rounded, obscure: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: ML.inputDec(lang.translate('role') ?? 'Rol', Icons.badge_rounded),
            items: ['doctor','receptionist','laboratory','pharmacy'].map((r) => DropdownMenuItem(value: r, child: Text(lang.translate(r == 'pharmacy' ? 'pharmacist' : r)))).toList(),
            onChanged: (v) => setSt(() => role = v!),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Color(0xFFDDD)), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(lang.translate('cancel')))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ML.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: () async {
                if (nCtrl.text.isEmpty || eCtrl.text.isEmpty || pCtrl.text.length < 6) return;
                try {
                  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: eCtrl.text.trim(), password: pCtrl.text);
                  await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({'name': nCtrl.text.trim(), 'email': eCtrl.text.trim(), 'role': role, 'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid});
                  if (mounted) Navigator.pop(ctx);
                } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: ML.coral)); }
              },
              child: Text(lang.translate('add'), style: const TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ])),
      ]),
    )));
  }

  void _editStaffDialog(String id, Map<String,dynamic> data, LanguageProvider lang) {
    final nCtrl = TextEditingController(text: data['name']); String role = data['role'] ?? 'doctor';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Text(lang.translate('edit_staff'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _dlgFld(nCtrl, lang.translate('name'), Icons.person_rounded),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role, decoration: ML.inputDec(lang.translate('role') ?? 'Rol', Icons.badge_rounded),
            items: ['doctor','receptionist','laboratory','pharmacy'].map((r) => DropdownMenuItem(value: r, child: Text(lang.translate(r == 'pharmacy' ? 'pharmacist' : r)))).toList(),
            onChanged: (v) => setSt(() => role = v!),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Color(0xFFDDD)), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(lang.translate('cancel')))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ML.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(id).update({'name': nCtrl.text.trim(), 'role': role, 'updatedAt': FieldValue.serverTimestamp()});
                if (mounted) Navigator.pop(ctx);
              },
              child: Text(lang.translate('save'), style: const TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ])),
      ]),
    )));
  }

  Widget _dlgFld(TextEditingController c, String lbl, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) =>
    TextField(controller: c, obscureText: obscure, keyboardType: type, style: const TextStyle(fontSize: 15, color: Color(0xFF023E8A)), decoration: ML.inputDec(lbl, icon));
}
