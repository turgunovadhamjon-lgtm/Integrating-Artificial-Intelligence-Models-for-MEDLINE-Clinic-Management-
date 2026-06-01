// lib/screens/doctor_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';
import 'patient_history_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with SingleTickerProviderStateMixin {
  String _tab = 'waiting';
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Consumer<LanguageProvider>(
      builder: (_, lang, __) => Scaffold(
        backgroundColor: ML.bgPage,
        body: Column(children: [
          _header(lang),
          _tabs(lang),
          Expanded(child: FadeTransition(opacity: _fade, child: _list(uid, lang))),
        ]),
      ),
    );
  }

  Widget _header(LanguageProvider lang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ML.headerGrad,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MEDLINE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
              Text(lang.translate('doctor_panel'), style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
            const Spacer(),
            _iconBtn(Icons.language, () => _langDialog(lang)),
            _iconBtn(Icons.logout_rounded, () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22))),
  );

  Widget _tabs(LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: ML.cardShadow),
      child: Row(children: [
        _tabItem(lang.translate('waiting'), Icons.hourglass_top_rounded, 'waiting', ML.waiting, ML.waitingBg),
        _tabItem(lang.translate('completed'), Icons.check_circle_rounded, 'completed', ML.done, ML.doneBg),
      ]),
    );
  }

  Widget _tabItem(String lbl, IconData icon, String key, Color c, Color bg) {
    final sel = _tab == key;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: sel ? (key == 'waiting' ? ML.coralGrad : ML.mintGrad) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 17, color: sel ? Colors.white : Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(lbl, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : Colors.grey.shade400)),
        ]),
      ),
    ));
  }

  Widget _list(String uid, LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('patients').where('doctorId', isEqualTo: uid).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ML.primary));
        }
        final docs = snap.data?.docs ?? [];
        final filtered = docs.where((d) => (d.data() as Map)['status'] == _tab).toList()
          ..sort((a, b) {
            final at = ((a.data() as Map)['createdAt'] as Timestamp?);
            final bt = ((b.data() as Map)['createdAt'] as Timestamp?);
            if (at == null && bt == null) return 0;
            if (at == null) return 1; if (bt == null) return -1;
            return bt.compareTo(at);
          });
        if (filtered.isEmpty) return _empty(lang);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _card(filtered[i].id, filtered[i].data() as Map<String, dynamic>, lang),
        );
      },
    );
  }

  Widget _empty(LanguageProvider lang) {
    final isW = _tab == 'waiting';
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: isW ? ML.coralGrad : ML.mintGrad,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (isW ? ML.waiting : ML.done).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Icon(isW ? Icons.inbox_rounded : Icons.task_alt_rounded, size: 52, color: Colors.white),
      ),
      const SizedBox(height: 20),
      Text(isW ? (lang.translate('no_waiting_patients')) : (lang.translate('no_patients')),
        style: const TextStyle(fontSize: 16, color: Color(0xFF5E8DB8), fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _card(String id, Map<String, dynamic> d, LanguageProvider lang) {
    final done = d['status'] == 'completed';
    final name  = d['fullName'] ?? '${d['name'] ?? ''} ${d['surname'] ?? ''}'.trim();
    final paid  = d['isPaid'] ?? false;
    final price = (d['price'] ?? 0.0) as num;
    final queue = d['queue'];
    final init  = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ML.bgCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ML.cardShadow,
        border: Border.all(color: done ? ML.done.withOpacity(0.2) : ML.waiting.withOpacity(0.2), width: 1.5),
      ),
      child: Material(color: Colors.transparent, child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: done ? null : () => _diagDialog(id, name, d, lang),
        child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: done ? ML.mintGrad : ML.headerGrad,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: (done ? ML.done : ML.primary).withOpacity(0.3), blurRadius: 10, offset: const Offset(0,4))],
              ),
              child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isNotEmpty ? name : 'Bemor', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF023E8A))),
              const SizedBox(height: 6),
              ML.badge(
                done ? lang.translate('completed') : lang.translate('waiting'),
                done ? Icons.check_circle_rounded : Icons.access_time_rounded,
                done ? ML.done : ML.waiting,
                done ? ML.doneBg : ML.waitingBg,
              ),
            ])),
            if (queue != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.circular(20),
                boxShadow: ML.shadow(color: ML.primary, blur: 10, dy: 3)),
              child: Text('№$queue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
            const SizedBox(width: 8),
            // Tarix tugmasi
            Material(
              color: ML.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PatientHistoryScreen(
                    patientId: id,
                    patientName: name,
                    patientData: d,
                  ),
                )),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.history_rounded, color: ML.accent, size: 22),
                ),
              ),
            ),
          ]),

          if (d['issue'] != null || d['address'] != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD0E8FF), Colors.transparent]))),
            const SizedBox(height: 10),
            if (d['issue'] != null) _infoRow(Icons.healing_rounded, lang.translate('issue'), d['issue'], ML.coral),
            if (d['address'] != null) ...[const SizedBox(height: 5), _infoRow(Icons.location_on_rounded, lang.translate('address'), d['address'], ML.accent)],
          ],

          const SizedBox(height: 12),
          // Payment row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: paid ? ML.paidBg : ML.unpaidBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: paid ? ML.paid.withOpacity(0.3) : ML.unpaid.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(paid ? Icons.verified_rounded : Icons.pending_rounded, size: 17, color: paid ? ML.paid : ML.unpaid),
              const SizedBox(width: 7),
              Text(paid ? lang.translate('paid') : lang.translate('unpaid'),
                style: TextStyle(fontWeight: FontWeight.w700, color: paid ? ML.paid : ML.unpaid, fontSize: 13)),
              const Spacer(),
              Text('${NumberFormat('#,###', 'uz_UZ').format(price.toDouble())} so\'m',
                style: const TextStyle(fontWeight: FontWeight.w800, color: ML.primary, fontSize: 14)),
            ]),
          ),

          if (done && d['diagnosis'] != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE8FBF5), Color(0xFFF0FFF8)]),
                borderRadius: BorderRadius.circular(14), border: Border.all(color: ML.done.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: ML.done.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.notes_rounded, size: 14, color: ML.done)),
                  const SizedBox(width: 8),
                  const Text('Diagnoz', style: TextStyle(color: ML.done, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Text(d['diagnosis'], style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 14, height: 1.4)),
              ]),
            ),
          ],

          if (!done) ...[
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () => _diagDialog(id, name, d, lang),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(lang.translate('add_diagnosis'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ML.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
              ),
            )),
          ],
        ])),
      )),
    );
  }

  Widget _infoRow(IconData icon, String label, String val, Color c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: c), const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF5E8DB8), fontWeight: FontWeight.w600)),
      Expanded(child: Text(val, style: const TextStyle(fontSize: 13, color: Color(0xFF023E8A)))),
    ],
  );

  void _langDialog(LanguageProvider lang) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(children: [Icon(Icons.language, color: ML.primary), SizedBox(width: 8), Text('Til', style: TextStyle(color: ML.primary, fontWeight: FontWeight.w800))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _langTile('UZB', 'O\'zbekcha', lang),
        _langTile('ENG', 'English', lang),
        _langTile('RUS', 'Русский', lang),
      ]),
    ));
  }

  Widget _langTile(String code, String name, LanguageProvider lang) {
    final sel = lang.currentLanguage == code;
    return ListTile(
      title: Text(name, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? ML.primary : Colors.black87)),
      trailing: sel ? const Icon(Icons.check_circle_rounded, color: ML.primary) : null,
      onTap: () { lang.changeLanguage(code); Navigator.pop(context); },
    );
  }

  void _diagDialog(String id, String name, Map<String, dynamic> d, LanguageProvider lang) {
    final ctrl = TextEditingController();
    final fk = GlobalKey<FormState>();
    showDialog(context: context, builder: (dCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Dialog header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lang.translate('add_diagnosis'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Form(key: fk, child: Column(children: [
            TextFormField(
              controller: ctrl, maxLines: 4,
              decoration: ML.inputDec(lang.translate('diagnosis'), Icons.notes_rounded, hint: lang.translate('enter_diagnosis')),
              validator: (v) => (v == null || v.trim().isEmpty) ? lang.translate('enter_diagnosis') : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(dCtx),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Color(0xFFD0D0D0)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(lang.translate('cancel')),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (!fk.currentState!.validate()) return;
                  try {
                    await FirebaseFirestore.instance.collection('patients').doc(id).update({
                      'diagnosis': ctrl.text.trim(), 'status': 'completed', 'diagnosedAt': FieldValue.serverTimestamp(),
                    });
                    // Tashrifni tarixga saqlash
                    await FirebaseFirestore.instance
                        .collection('patients').doc(id)
                        .collection('visits').add({
                      'type': 'visit',
                      'date': FieldValue.serverTimestamp(),
                      'diagnosis': ctrl.text.trim(),
                      'issue': d['issue'],
                      'doctorId': d['doctorId'],
                      'price': d['price'],
                      'isPaid': d['isPaid'],
                    });
                    if (dCtx.mounted) Navigator.pop(dCtx);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(lang.translate('diagnosis_saved')), backgroundColor: ML.done,
                      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e'), backgroundColor: ML.coral));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: ML.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: Text(lang.translate('save'), style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]))),
        ]),
      ),
    ));
  }
}
