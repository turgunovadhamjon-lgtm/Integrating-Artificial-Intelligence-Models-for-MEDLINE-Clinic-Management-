// lib/screens/patient_history_screen.dart
// Bemor to'liq tibbiy tarixi
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/medline_theme.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final Map<String, dynamic> patientData;

  const PatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientData,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _ac;
  late Animation<double> _fade;

  // Qo'shimcha ma'lumotlar uchun controllerlar
  final _allergyCtrl    = TextEditingController();
  final _chronicCtrl    = TextEditingController();
  final _bloodTypeCtrl  = TextEditingController();
  final _noteCtrl       = TextEditingController();

  String _fmtDate(Timestamp? ts) =>
      ts == null ? '—' : DateFormat('dd.MM.yyyy HH:mm').format(ts.toDate());
  String _fmtDay(Timestamp? ts) =>
      ts == null ? '—' : DateFormat('dd MMMM yyyy', 'en_US').format(ts.toDate());

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();

    // Mavjud ma'lumotlarni yuklash
    final d = widget.patientData;
    _bloodTypeCtrl.text = d['bloodType'] ?? '';
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ac.dispose();
    _allergyCtrl.dispose();
    _chronicCtrl.dispose();
    _bloodTypeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Firestore refs ──
  DocumentReference get _patRef =>
      FirebaseFirestore.instance.collection('patients').doc(widget.patientId);
  CollectionReference get _visitsRef =>
      _patRef.collection('visits');

  // ── Allergiya qo'shish ──
  Future<void> _addAllergy() async {
    final val = _allergyCtrl.text.trim();
    if (val.isEmpty) return;
    await _patRef.update({'allergies': FieldValue.arrayUnion([val])});
    _allergyCtrl.clear();
    if (mounted) _snack('Allergiya qo\'shildi', ML.mint);
  }

  // ── Surunkali kasallik qo'shish ──
  Future<void> _addChronic() async {
    final val = _chronicCtrl.text.trim();
    if (val.isEmpty) return;
    await _patRef.update({'chronicDiseases': FieldValue.arrayUnion([val])});
    _chronicCtrl.clear();
    if (mounted) _snack('Kasallik qo\'shildi', ML.accent);
  }

  // ── Qon guruhi saqlash ──
  Future<void> _saveBloodType() async {
    await _patRef.update({'bloodType': _bloodTypeCtrl.text.trim()});
    if (mounted) _snack('Qon guruhi saqlandi', ML.mint);
  }

  // ── Izoh qo'shish ──
  Future<void> _addNote() async {
    final val = _noteCtrl.text.trim();
    if (val.isEmpty) return;
    await _visitsRef.add({
      'type': 'note',
      'note': val,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _noteCtrl.clear();
    if (mounted) _snack('Izoh qo\'shildi', ML.primary);
  }

  // ── Elementni o'chirish (allergiya, surunkali) ──
  Future<void> _removeItem(String field, String value) async {
    await _patRef.update({field: FieldValue.arrayRemove([value])});
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ML.bgPage,
      body: FadeTransition(
        opacity: _fade,
        child: Column(children: [
          _header(),
          _profileCard(),
          _tabBar(),
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            children: [_visitsTab(), _healthTab(), _infoTab()],
          )),
        ]),
      ),
    );
  }

  // ── HEADER ──
  Widget _header() {
    final init = widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'B';
    return Container(
      decoration: const BoxDecoration(
        gradient: ML.headerGrad,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.patientName.isNotEmpty ? widget.patientName : 'Bemor',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const Text('Bemor kartochkasi', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('ID: ${widget.patientId.substring(0, 6).toUpperCase()}',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
      )),
    );
  }

  // ── PROFIL KARTASI ──
  Widget _profileCard() {
    final d = widget.patientData;
    final bloodType = d['bloodType'] as String?;

    return StreamBuilder<DocumentSnapshot>(
      stream: _patRef.snapshots(),
      builder: (_, snap) {
        final live = snap.data?.data() as Map<String, dynamic>? ?? d;
        final allergies = (live['allergies'] as List?)?.cast<String>() ?? [];
        final chronic   = (live['chronicDiseases'] as List?)?.cast<String>() ?? [];
        final bt = live['bloodType'] as String? ?? bloodType ?? '';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(20), boxShadow: ML.cardShadow),
          child: Row(children: [
            // Qon guruhi
            _quickBadge(bt.isNotEmpty ? bt : '—', Icons.water_drop_rounded, ML.coral, 'Qon guruhi'),
            const SizedBox(width: 12),
            // Allergiyalar soni
            _quickBadge('${allergies.length}', Icons.warning_amber_rounded, ML.amber, 'Allergiya'),
            const SizedBox(width: 12),
            // Surunkali kasalliklar
            _quickBadge('${chronic.length}', Icons.monitor_heart_rounded, ML.purple, 'Surunkali'),
            const SizedBox(width: 12),
            // Jami tashriflar
            StreamBuilder<QuerySnapshot>(
              stream: _visitsRef.snapshots(),
              builder: (_, vs) => _quickBadge(
                '${vs.data?.docs.where((d) => (d.data() as Map)['type'] == 'visit').length ?? 0}',
                Icons.event_note_rounded, ML.primary, 'Tashrif'),
            ),
          ]),
        );
      },
    );
  }

  Widget _quickBadge(String val, IconData icon, Color color, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        Text(lbl, style: const TextStyle(color: Colors.black45, fontSize: 9), textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── TAB BAR ──
  Widget _tabBar() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: ML.cardShadow),
    child: TabBar(
      controller: _tabCtrl,
      indicator: BoxDecoration(gradient: ML.headerGrad, borderRadius: BorderRadius.circular(12)),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey.shade400,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Tashriflar'),
        Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Sog\'liq'),
        Tab(icon: Icon(Icons.info_rounded, size: 18), text: 'Ma\'lumot'),
      ],
    ),
  );

  // ══════════════════════════════════════════
  // TAB 1 — TASHRIFLAR TARIXI
  // ══════════════════════════════════════════
  Widget _visitsTab() => Column(children: [
    // Izoh qo'shish
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _noteCtrl,
          style: const TextStyle(fontSize: 14, color: Color(0xFF023E8A)),
          decoration: ML.inputDec('Shifokor izohi qo\'shish...', Icons.note_add_rounded),
        )),
        const SizedBox(width: 10),
        Material(
          color: ML.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _addNote,
            child: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
          ),
        ),
      ]),
    ),
    const SizedBox(height: 12),

    // Tashriflar ro'yxati
    Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: _visitsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ML.primary));
        }

        // patients dan ham oldingi tashrifni ko'rsatamiz
        final visits = snap.data?.docs ?? [];

        // Hozirgi tashrif (patients doc)
        final d = widget.patientData;
        final hasDiagnosis = d['diagnosis'] != null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // Joriy tashrif
            _visitCard(
              type: 'current',
              title: 'Joriy tashrif',
              date: d['createdAt'] as Timestamp?,
              issue: d['issue'],
              diagnosis: d['diagnosis'],
              doctorId: d['doctorId'],
              isCurrent: true,
              hasDiagnosis: hasDiagnosis,
            ),
            const SizedBox(height: 10),

            // Oldingi tashriflar va izohlar
            ...visits.map((doc) {
              final v = doc.data() as Map<String, dynamic>;
              if (v['type'] == 'note') return _noteCard(v);
              return _visitCard(
                type: 'past',
                title: 'Oldingi tashrif',
                date: v['date'] as Timestamp?,
                issue: v['issue'],
                diagnosis: v['diagnosis'],
                doctorId: v['doctorId'],
                isCurrent: false,
                hasDiagnosis: v['diagnosis'] != null,
              );
            }),
            if (visits.isEmpty && !hasDiagnosis)
              _emptyState('Hozircha tarix yo\'q', Icons.history_rounded, ML.primary),
          ],
        );
      },
    )),
  ]);

  Widget _visitCard({
    required String type,
    required String title,
    required Timestamp? date,
    required String? issue,
    required String? diagnosis,
    required String? doctorId,
    required bool isCurrent,
    required bool hasDiagnosis,
  }) {
    return FutureBuilder<DocumentSnapshot?>(
      future: doctorId != null
          ? FirebaseFirestore.instance.collection('users').doc(doctorId).get()
          : Future.value(null),
      builder: (_, dSnap) {
        final doctorName = dSnap.data?.data() != null
            ? ((dSnap.data!.data() as Map)['name'] as String? ?? 'Shifokor')
            : 'Shifokor';
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: ML.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: ML.cardShadow,
            border: Border.all(
              color: isCurrent ? ML.primary.withOpacity(0.3) : ML.accent.withOpacity(0.2),
            ),
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isCurrent ? ML.headerGrad : const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF0077B6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isCurrent ? Icons.today_rounded : Icons.history_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: isCurrent ? ML.primary : ML.accent)),
                Text(_fmtDay(date), style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ])),
              ML.badge(
                hasDiagnosis ? 'Bajarildi' : 'Kutilmoqda',
                hasDiagnosis ? Icons.check_circle_rounded : Icons.access_time_rounded,
                hasDiagnosis ? ML.done : ML.waiting,
                hasDiagnosis ? ML.doneBg : ML.waitingBg,
              ),
            ]),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFEEF4FF)),
            const SizedBox(height: 10),
            _vRow(Icons.medical_services_rounded, 'Shifokor', doctorName, ML.primary),
            if (issue != null) ...[const SizedBox(height: 6), _vRow(Icons.healing_rounded, 'Shikoyat', issue, ML.coral)],
            if (diagnosis != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE8FBF5), Color(0xFFF0FFF8)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ML.done.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.notes_rounded, size: 14, color: ML.done),
                    SizedBox(width: 6),
                    Text('Diagnoz', style: TextStyle(color: ML.done, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Text(diagnosis, style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 13, height: 1.4)),
                ]),
              ),
            ],
          ])),
        );
      },
    );
  }

  Widget _noteCard(Map<String, dynamic> v) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ML.amber.withOpacity(0.3)),
    ),
    child: ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: ML.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.sticky_note_2_rounded, color: ML.amber, size: 20)),
      title: Text(v['note'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037))),
      subtitle: Text(_fmtDate(v['createdAt'] as Timestamp?), style: const TextStyle(fontSize: 11, color: Colors.black38)),
    ),
  );

  Widget _vRow(IconData icon, String label, String val, Color c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 6),
      Text('$label: ', style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
      Expanded(child: Text(val, style: const TextStyle(fontSize: 12, color: Color(0xFF023E8A)))),
    ],
  );

  // ══════════════════════════════════════════
  // TAB 2 — SOG'LIQ MA'LUMOTLARI
  // ══════════════════════════════════════════
  Widget _healthTab() => StreamBuilder<DocumentSnapshot>(
    stream: _patRef.snapshots(),
    builder: (_, snap) {
      final d = snap.data?.data() as Map<String, dynamic>? ?? widget.patientData;
      final allergies = (d['allergies'] as List?)?.cast<String>() ?? [];
      final chronic   = (d['chronicDiseases'] as List?)?.cast<String>() ?? [];
      final bt        = d['bloodType'] as String? ?? '';
      if (bt.isNotEmpty && _bloodTypeCtrl.text != bt) _bloodTypeCtrl.text = bt;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Qon guruhi
          ML.sectionHeader('Qon guruhi', icon: Icons.water_drop_rounded),
          Container(
            decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: ML.cardShadow),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: _bloodTypeCtrl,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF023E8A)),
                  decoration: ML.inputDec('Masalan: A(II) Rh+', Icons.water_drop_rounded),
                )),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saveBloodType,
                  style: ElevatedButton.styleFrom(backgroundColor: ML.coral, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
              if (bt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(gradient: ML.coralGrad, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(bt, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // Allergiyalar
          ML.sectionHeader('Allergiyalar', icon: Icons.warning_amber_rounded,
            trailing: Text('${allergies.length} ta', style: const TextStyle(color: ML.amber, fontWeight: FontWeight.w700))),
          Container(
            decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: ML.cardShadow),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: _allergyCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF023E8A)),
                  decoration: ML.inputDec('Allergiya qo\'shing...', Icons.add_circle_rounded),
                  onSubmitted: (_) => _addAllergy(),
                )),
                const SizedBox(width: 10),
                Material(color: ML.amber, borderRadius: BorderRadius.circular(14),
                  child: InkWell(borderRadius: BorderRadius.circular(14), onTap: _addAllergy,
                    child: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.add_rounded, color: Colors.white)))),
              ]),
              if (allergies.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: allergies.map((a) => Chip(
                  label: Text(a, style: const TextStyle(color: Color(0xFF5D4000), fontWeight: FontWeight.w600, fontSize: 13)),
                  backgroundColor: const Color(0xFFFFF3E0),
                  side: const BorderSide(color: ML.amber, width: 0.5),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16, color: ML.amber),
                  onDeleted: () => _removeItem('allergies', a),
                )).toList()),
              ] else
                _emptyChip('Allergiya yo\'q', Icons.check_circle_rounded, ML.done),
            ]),
          ),
          const SizedBox(height: 20),

          // Surunkali kasalliklar
          ML.sectionHeader('Surunkali kasalliklar', icon: Icons.monitor_heart_rounded,
            trailing: Text('${chronic.length} ta', style: const TextStyle(color: ML.purple, fontWeight: FontWeight.w700))),
          Container(
            decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: ML.cardShadow),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: _chronicCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF023E8A)),
                  decoration: ML.inputDec('Kasallik qo\'shing...', Icons.add_circle_rounded),
                  onSubmitted: (_) => _addChronic(),
                )),
                const SizedBox(width: 10),
                Material(color: ML.purple, borderRadius: BorderRadius.circular(14),
                  child: InkWell(borderRadius: BorderRadius.circular(14), onTap: _addChronic,
                    child: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.add_rounded, color: Colors.white)))),
              ]),
              if (chronic.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chronic.map((c) => Chip(
                  label: Text(c, style: const TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.w600, fontSize: 13)),
                  backgroundColor: const Color(0xFFF3E5F5),
                  side: const BorderSide(color: ML.purple, width: 0.5),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16, color: ML.purple),
                  onDeleted: () => _removeItem('chronicDiseases', c),
                )).toList()),
              ] else
                _emptyChip('Surunkali kasallik yo\'q', Icons.check_circle_rounded, ML.done),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      );
    },
  );

  Widget _emptyChip(String text, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );

  // ══════════════════════════════════════════
  // TAB 3 — BEMOR MA'LUMOTLARI
  // ══════════════════════════════════════════
  Widget _infoTab() {
    final d = widget.patientData;
    final name    = d['fullName'] ?? '${d['name'] ?? ''} ${d['surname'] ?? ''}'.trim();
    final address = d['address'] as String?;
    final price   = (d['price'] ?? 0) as num;
    final paid    = d['isPaid'] ?? false;
    final queue   = d['queue'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ML.sectionHeader('Asosiy ma\'lumotlar', icon: Icons.person_rounded),
        Container(
          decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow),
          child: Column(children: [
            _infoTile(Icons.person_rounded, 'Bemor ismi', name.isNotEmpty ? name : '—', ML.primary),
            _divider(),
            if (address != null && address.isNotEmpty)
              _infoTile(Icons.location_on_rounded, 'Manzil', address, ML.accent),
            if (address != null && address.isNotEmpty) _divider(),
            _infoTile(Icons.format_list_numbered_rounded, 'Navbat №', queue?.toString() ?? '—', ML.purple),
            _divider(),
            _infoTile(Icons.calendar_today_rounded, 'Kelgan sana', _fmtDate(d['createdAt'] as Timestamp?), ML.accent),
            _divider(),
            _infoTile(
              paid ? Icons.verified_rounded : Icons.pending_rounded,
              'To\'lov holati',
              paid ? 'To\'langan' : 'To\'lanmagan',
              paid ? ML.paid : ML.unpaid,
            ),
            _divider(),
            _infoTile(Icons.payments_rounded, 'Summa',
              '${NumberFormat('#,###', 'uz_UZ').format(price)} so\'m', ML.mint),
          ]),
        ),
        const SizedBox(height: 20),

        // Firestore real-time ma'lumotlar
        StreamBuilder<DocumentSnapshot>(
          stream: _patRef.snapshots(),
          builder: (_, snap) {
            final live = snap.data?.data() as Map<String, dynamic>? ?? d;
            final bt = live['bloodType'] as String? ?? '—';
            final allergies = (live['allergies'] as List?)?.cast<String>() ?? [];
            final chronic   = (live['chronicDiseases'] as List?)?.cast<String>() ?? [];

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ML.sectionHeader('Tibbiy ma\'lumotlar', icon: Icons.medical_information_rounded),
              Container(
                decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow),
                child: Column(children: [
                  _infoTile(Icons.water_drop_rounded, 'Qon guruhi', bt, ML.coral),
                  _divider(),
                  _infoTile(Icons.warning_amber_rounded, 'Allergiyalar',
                    allergies.isEmpty ? 'Yo\'q' : allergies.join(', '), ML.amber),
                  _divider(),
                  _infoTile(Icons.monitor_heart_rounded, 'Surunkali kasalliklar',
                    chronic.isEmpty ? 'Yo\'q' : chronic.join(', '), ML.purple),
                ]),
              ),
            ]);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
    subtitle: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF023E8A), fontWeight: FontWeight.w600)),
  );

  Widget _divider() => const Divider(height: 1, indent: 56, color: Color(0xFFEEF4FF));

  Widget _emptyState(String text, IconData icon, Color color) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: ML.headerGrad, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 40)),
        const SizedBox(height: 16),
        Text(text, style: const TextStyle(color: Color(0xFF5E8DB8), fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
