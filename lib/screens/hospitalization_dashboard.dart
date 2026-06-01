// lib/screens/hospitalization_dashboard.dart — YANGI DIZAYN
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';

class HospitalizationDashboard extends StatefulWidget {
  const HospitalizationDashboard({super.key});
  @override
  State<HospitalizationDashboard> createState() => _HospitalizationDashboardState();
}

class _HospitalizationDashboardState extends State<HospitalizationDashboard> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color primary = Color(0xFF0077B6);
  static const Color green   = Color(0xFF06D6A0);
  static const Color red     = Color(0xFFFF6B6B);
  static const Color bgPage  = Color(0xFFF0F7FF);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }
  @override
  void dispose() { _tabCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  String _fmtDate(dynamic d) {
    if (d == null) return '';
    final dt = (d as Timestamp).toDate();
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  Widget _field({required TextEditingController ctrl, required String label, required IconData icon, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: primary, size: 20),
        filled: true, fillColor: const Color(0xFFF5F9FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6E4FF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      ),
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  // ── Add Room Dialog ──
  void _addRoomDialog(LanguageProvider lang) {
    final roomCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final bedsCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String type = 'standard';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.hotel_rounded, color: primary, size: 24)),
          const SizedBox(width: 12),
          Text(lang.translate('add_room'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        ]),
        const SizedBox(height: 20),
        _field(ctrl: roomCtrl, label: lang.translate('room_number'), icon: Icons.door_front_door_rounded),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(ctrl: floorCtrl, label: lang.translate('floor'), icon: Icons.layers_rounded, type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field(ctrl: bedsCtrl, label: lang.translate('beds'), icon: Icons.bed_rounded, type: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        _field(ctrl: priceCtrl, label: lang.translate('daily_rate'), icon: Icons.payments_rounded, type: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: type,
          decoration: InputDecoration(labelText: lang.translate('type'), prefixIcon: const Icon(Icons.category_rounded, color: primary, size: 20), filled: true, fillColor: const Color(0xFFF5F9FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6E4FF))), contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16)),
          items: ['standard', 'vip', 'intensive'].map((t) => DropdownMenuItem(value: t, child: Text(lang.translate(t)))).toList(),
          onChanged: (v) => setSt(() => type = v!),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(lang.translate('cancel')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              if (roomCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('rooms').add({'number': roomCtrl.text.trim(), 'floor': floorCtrl.text.trim(), 'beds': int.tryParse(bedsCtrl.text) ?? 1, 'type': type, 'price': double.tryParse(priceCtrl.text) ?? 0.0, 'isAvailable': true, 'createdAt': FieldValue.serverTimestamp()});
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(lang.translate('save')),
          )),
        ]),
      ]))),
    )));
  }

  // ── Admit Patient Dialog ──
  void _admitDialog(LanguageProvider lang, String roomId, String roomNumber) async {
    final pSnap = await FirebaseFirestore.instance.collection('patients').where('status', isEqualTo: 'waiting').get();
    final dSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
    if (pSnap.docs.isEmpty) { _snack(lang.translate('no_patients'), Colors.orange); return; }
    String? pid, did;
    final diagCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_add_rounded, color: green, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text('${lang.translate('admit_patient')} - $roomNumber', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))),
        ]),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: pid,
          decoration: InputDecoration(labelText: lang.translate('patient_name'), prefixIcon: const Icon(Icons.person_rounded, color: primary, size: 20), filled: true, fillColor: const Color(0xFFF5F9FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6E4FF))), contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16)),
          items: pSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text('${d['name'] ?? ''} ${d['surname'] ?? ''}'))).toList(),
          onChanged: (v) => setSt(() => pid = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: did,
          decoration: InputDecoration(labelText: lang.translate('doctor'), prefixIcon: Icon(Icons.medical_services_rounded, color: primary, size: 20), filled: true, fillColor: const Color(0xFFF5F9FF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD6E4FF))), contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16)),
          items: dSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'] ?? ''))).toList(),
          onChanged: (v) => setSt(() => did = v),
        ),
        const SizedBox(height: 12),
        _field(ctrl: diagCtrl, label: lang.translate('diagnosis'), icon: Icons.assignment_rounded),
        const SizedBox(height: 12),
        _field(ctrl: noteCtrl, label: lang.translate('notes'), icon: Icons.notes_rounded),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(lang.translate('cancel')))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              if (pid == null || did == null) return;
              final p = pSnap.docs.firstWhere((x) => x.id == pid);
              final d = dSnap.docs.firstWhere((x) => x.id == did);
              await FirebaseFirestore.instance.collection('hospitalizations').add({'patientId': pid, 'patientName': '${p['name'] ?? ''} ${p['surname'] ?? ''}', 'roomId': roomId, 'roomNumber': roomNumber, 'doctorId': did, 'doctorName': d['name'], 'diagnosis': diagCtrl.text.trim(), 'notes': noteCtrl.text.trim(), 'admissionDate': FieldValue.serverTimestamp(), 'status': 'active', 'createdAt': FieldValue.serverTimestamp()});
              await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isAvailable': false});
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(lang.translate('save')),
          )),
        ]),
      ]))),
    )));
  }

  void _discharge(String hospId, String roomId, LanguageProvider lang) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.exit_to_app, color: Colors.red), const SizedBox(width: 8), Text(lang.translate('discharge_patient'), style: const TextStyle(fontWeight: FontWeight.bold))]),
      content: Text(lang.translate('confirm_discharge')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('cancel'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('hospitalizations').doc(hospId).update({'status': 'discharged', 'dischargeDate': FieldValue.serverTimestamp()});
            await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isAvailable': true});
            if (mounted) Navigator.pop(ctx);
          },
          child: Text(lang.translate('confirm')),
        ),
      ],
    ));
  }

  // ── Tabs ──
  Widget _roomsTab(LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').orderBy('number').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
        final rooms = snap.data!.docs;
        if (rooms.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle), child: const Icon(Icons.hotel_rounded, size: 48, color: primary)),
          const SizedBox(height: 16),
          Text(lang.translate('no_rooms'), style: const TextStyle(color: Colors.black45, fontSize: 16)),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (_, i) {
            final room = rooms[i].data() as Map<String, dynamic>;
            final avail = room['isAvailable'] ?? true;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                border: Border.all(color: avail ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A), width: 1.5)),
              child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: avail ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
                  child: Icon(avail ? Icons.meeting_room_rounded : Icons.no_meeting_room_rounded, color: avail ? green : red, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${lang.translate('room_number')} ${room['number']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: avail ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
                      child: Text(avail ? lang.translate('available') ?? 'Bo\'sh' : lang.translate('occupied') ?? 'Band', style: TextStyle(fontSize: 11, color: avail ? green : red, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 6),
                  Text('${lang.translate('floor')}: ${room['floor']}  •  ${lang.translate('beds')}: ${room['beds']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  Text('${lang.translate('type')}: ${lang.translate(room['type'] ?? 'standard')}  •  ${NumberFormat('#,###', 'uz_UZ').format((room['price'] as num? ?? 0).toDouble())} so\'m/kun',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ])),
                if (avail) ElevatedButton.icon(
                  onPressed: () => _admitDialog(lang, rooms[i].id, room['number']),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text(lang.translate('admit_patient') ?? 'Qabul', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                ),
              ])),
            );
          },
        );
      },
    );
  }

  Widget _activeTab(LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('hospitalizations').where('status', isEqualTo: 'active').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
        final list = snap.data!.docs;
        if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle), child: const Icon(Icons.people_alt_rounded, size: 48, color: green)),
          const SizedBox(height: 16),
          Text(lang.translate('no_hospitalizations') ?? 'Hozirda yotuvchi bemor yo\'q', style: const TextStyle(color: Colors.black45, fontSize: 16)),
        ]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final h = list[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5)),
              child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(gradient: const LinearGradient(colors: [primary, Color(0xFF42A5F5)]), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text((h['patientName'] as String? ?? 'B')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h['patientName'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  const SizedBox(height: 4),
                  Text('${lang.translate('room')}: ${h['roomNumber']}  •  ${lang.translate('doctor')}: ${h['doctorName']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  Text('${lang.translate('admission')}: ${_fmtDate(h['admissionDate'])}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ])),
                IconButton(
                  icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.exit_to_app_rounded, color: Colors.red, size: 22)),
                  onPressed: () => _discharge(list[i].id, h['roomId'], lang),
                ),
              ])),
            );
          },
        );
      },
    );
  }

  Widget _historyTab(LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('hospitalizations').where('status', isEqualTo: 'discharged').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
        final list = snap.data!.docs;
        if (list.isEmpty) return Center(child: Text(lang.translate('no_history') ?? 'Tarix bo\'sh', style: const TextStyle(color: Colors.black45)));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final h = list[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                border: Border.all(color: Colors.grey.shade200)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.history_rounded, color: Colors.grey, size: 24)),
                title: Text(h['patientName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                subtitle: Text('${lang.translate('room')}: ${h['roomNumber']}  •  ${lang.translate('discharged')}: ${_fmtDate(h['dischargeDate'])}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (ctx, lang, _) => Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF00B4D8)]),
          )),
          elevation: 0, toolbarHeight: 65,
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 10),
            const Text('Yotqizish bo\'limi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () {
              FirebaseAuth.instance.signOut().then((_) { if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); });
            }),
            const SizedBox(width: 4),
          ],
          bottom: TabBar(
            controller: _tabCtrl, indicatorColor: Colors.white, indicatorWeight: 3,
            labelColor: Colors.white, unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [Tab(text: lang.translate('rooms')), Tab(text: lang.translate('active')), Tab(text: lang.translate('history'))],
          ),
        ),
        body: FadeTransition(opacity: _fadeAnim, child: TabBarView(
          controller: _tabCtrl,
          children: [_roomsTab(lang), _activeTab(lang), _historyTab(lang)],
        )),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary, foregroundColor: Colors.white,
          onPressed: () => _addRoomDialog(lang),
          icon: const Icon(Icons.add_rounded),
          label: Text(lang.translate('add_room') ?? 'Xona qo\'shish'),
          elevation: 4,
        ),
      ),
    );
  }
}
