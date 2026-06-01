// lib/screens/receptionist_dashboard.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/medline_theme.dart';
import 'login_screen.dart';
import 'patients_list_screen.dart';
import 'diagnostic_web_screen.dart';
import 'hospitalization_dashboard.dart';
import 'dmed_screen.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});
  @override State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surCtrl  = TextEditingController();
  final _queueCtrl= TextEditingController();
  final _addrCtrl = TextEditingController();
  final _issueCtrl= TextEditingController();
  final _priceCtrl= TextEditingController();
  String? _selectedDoctor;
  bool _isPaid    = false;
  bool _isLoading = false;
  List<Map<String, String>> _doctors = [];
  late AnimationController _ac;
  late Animation<double> _fade;

  StreamSubscription<QuerySnapshot>? _queueSub;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
    _loadDoctors();
    _listenQueue(); // Real-time navbat
  }
  @override
  void dispose() {
    _queueSub?.cancel();
    _ac.dispose();
    for (final c in [_nameCtrl, _surCtrl, _queueCtrl, _addrCtrl, _issueCtrl, _priceCtrl]) c.dispose();
    super.dispose();
  }

  // Real-time navbat — Firestore da yangi bemor qo'shilsa avtomatik yangilanadi
  void _listenQueue() {
    final now = DateTime.now();
    final todayStart = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    _queueSub = FirebaseFirestore.instance
        .collection('patients')
        .where('createdAt', isGreaterThanOrEqualTo: todayStart)
        .snapshots()
        .listen((snap) {
      int max = 0;
      for (var d in snap.docs) {
        final q = int.tryParse(d['queue'] as String? ?? '0') ?? 0;
        if (q > max) max = q;
      }
      if (mounted) setState(() => _queueCtrl.text = (max + 1).toString());
    }, onError: (_) {
      if (mounted) setState(() => _queueCtrl.text = '1');
    });
  }

  Future<void> _loadDoctors() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
      if (mounted) setState(() { _doctors = snap.docs.map((d) => {'id': d.id, 'name': (d['name'] as String? ?? '').trim()}).toList(); });
    } catch (_) {}
  }

  Future<void> _submit() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (!_formKey.currentState!.validate() || _selectedDoctor == null) {
      _snack('Barcha majburiy maydonlarni to\'ldiring!', ML.amber); return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('patients').add({
        'name': _nameCtrl.text.trim(), 'surname': _surCtrl.text.trim(),
        'fullName': '${_nameCtrl.text.trim()} ${_surCtrl.text.trim()}',
        'queue': _queueCtrl.text.trim(), 'address': _addrCtrl.text.trim(),
        'issue': _issueCtrl.text.trim(), 'doctorId': _selectedDoctor,
        'price': double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
        'isPaid': _isPaid, 'createdAt': FieldValue.serverTimestamp(), 'status': 'waiting',
      });
      _snack(lang.translate('patient_added') ?? 'Bemor muvaffaqiyatli qo\'shildi!', ML.mint);
      _clear();
    } catch (e) { _snack('Xato: $e', ML.coral); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _clear() {
    _formKey.currentState?.reset();
    for (final c in [_nameCtrl, _surCtrl, _addrCtrl, _issueCtrl, _priceCtrl]) c.clear();
    setState(() { _selectedDoctor = null; _isPaid = false; });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.info_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(msg))]),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (_, lang, __) => Scaffold(
        backgroundColor: ML.bgPage,
        body: Column(children: [
          _header(lang),
          Expanded(child: FadeTransition(opacity: _fade, child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const SizedBox(height: 4),
              _quickActions(lang),
              const SizedBox(height: 16),
              _formCard(lang),
              const SizedBox(height: 24),
            ]),
          ))),
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
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MEDLINE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            Text(lang.translate('receptionist') ?? 'Resepshn', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          _hBtn(Icons.people_alt_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen()))),
          _hBtn(Icons.language, () => _langDialog(lang)),
          _hBtn(Icons.logout_rounded, () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ]),
      )),
    );
  }

  Widget _hBtn(IconData icon, VoidCallback fn) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
        child: InkWell(borderRadius: BorderRadius.circular(12), onTap: fn,
            child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 21)))),
  );

  Widget _quickActions(LanguageProvider lang) {
    return Column(children: [
      Row(children: [
        _actionTile('DMED.UZ', Icons.medical_services_outlined, ML.mint,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DmedScreen(title: 'Shifokor qidirish')))),
        const SizedBox(width: 12),
        _actionTile(lang.translate('diagnostic_agent') ?? 'Diagnostika', Icons.health_and_safety_rounded, ML.coral,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticWebScreen()))),
      ]),
      const SizedBox(height: 12),
      _actionTileFull(lang.translate('hospitalization') ?? 'Yotqizish', Icons.hotel_rounded, ML.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalizationDashboard()))),
    ]);
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback fn) => Expanded(
    child: Container(
      decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(18), boxShadow: ML.cardShadow,
          border: Border.all(color: color.withOpacity(0.2))),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(18),
          child: InkWell(borderRadius: BorderRadius.circular(18), onTap: fn,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14), child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,3))]),
                    child: Icon(icon, color: Colors.white, size: 22)),
                const SizedBox(width: 10),
                Flexible(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))),
              ])))),
    ),
  );

  Widget _actionTileFull(String label, IconData icon, Color color, VoidCallback fn) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 14, offset: const Offset(0,5))],
    ),
    child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(18),
        child: InkWell(borderRadius: BorderRadius.circular(18), onTap: fn,
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ])))),
  );

  Widget _formCard(LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(color: ML.bgCard, borderRadius: BorderRadius.circular(24), boxShadow: ML.cardShadow),
      child: Padding(padding: const EdgeInsets.all(22), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ML.sectionHeader(lang.translate('patient_info') ?? 'Bemor ma\'lumotlari', icon: Icons.person_add_rounded),
        Row(children: [
          Expanded(child: _fld(_nameCtrl, lang.translate('name'), Icons.person_outline_rounded, req: true)),
          const SizedBox(width: 14),
          Expanded(child: _fld(_surCtrl, lang.translate('surname') ?? 'Familiya', Icons.person_rounded, req: true)),
        ]),
        const SizedBox(height: 14),
        _fld(_queueCtrl, lang.translate('queue') ?? 'Navbat №', Icons.format_list_numbered_rounded, readOnly: true),
        const SizedBox(height: 14),
        _fld(_addrCtrl, lang.translate('address'), Icons.location_on_rounded),
        const SizedBox(height: 14),
        _fld(_issueCtrl, lang.translate('issue'), Icons.healing_rounded, maxLines: 3, req: true),
        const SizedBox(height: 14),
        _doctorDrop(lang),
        const SizedBox(height: 14),
        _fld(_priceCtrl, lang.translate('price') ?? 'To\'lov (so\'m)', Icons.payments_rounded, keyType: TextInputType.number, req: true),
        const SizedBox(height: 14),
        _paidToggle(lang),
        const SizedBox(height: 22),
        Row(children: [
          OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(lang.translate('clear') ?? 'Tozalash'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(width: 14),
          Expanded(child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(_isLoading ? 'Saqlanmoqda...' : (lang.translate('save') ?? 'Saqlash'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: ML.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          )),
        ]),
      ]))),
    );
  }

  Widget _fld(TextEditingController c, String? lbl, IconData icon,
      {bool req = false, bool readOnly = false, int maxLines = 1, TextInputType? keyType}) =>
      TextFormField(
        controller: c, readOnly: readOnly, maxLines: maxLines, keyboardType: keyType,
        style: const TextStyle(fontSize: 15, color: Color(0xFF023E8A)),
        decoration: ML.inputDec(lbl ?? '', icon),
        validator: req ? (v) => v == null || v.trim().isEmpty ? 'Majburiy maydon' : null : null,
      );

  Widget _doctorDrop(LanguageProvider lang) => Theme(
    data: Theme.of(context).copyWith(
      canvasColor: Colors.white,
      textTheme: Theme.of(context).textTheme.apply(bodyColor: const Color(0xFF023E8A)),
    ),
    child: DropdownButtonFormField<String>(
      value: _selectedDoctor,
      style: const TextStyle(fontSize: 15, color: Color(0xFF023E8A)),
      dropdownColor: Colors.white,
      menuMaxHeight: 300,
      decoration: ML.inputDec(lang.translate('select_doctor') ?? 'Shifokor tanlang', Icons.person_search_rounded),
      items: _doctors.map((d) => DropdownMenuItem(
        value: d['id'],
        child: Text(d['name']!, style: const TextStyle(color: Color(0xFF023E8A), fontSize: 15, fontWeight: FontWeight.w500)),
      )).toList(),
      onChanged: (v) => setState(() => _selectedDoctor = v),
      validator: (v) => v == null ? 'Shifokor tanlang' : null,
    ),
  );

  Widget _paidToggle(LanguageProvider lang) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: _isPaid ? ML.paidBg : ML.bgField,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _isPaid ? ML.paid.withOpacity(0.4) : const Color(0xFFD0E8FF), width: 1.5),
    ),
    child: Row(children: [
      Icon(_isPaid ? Icons.verified_rounded : Icons.radio_button_unchecked_rounded,
          color: _isPaid ? ML.paid : Colors.grey, size: 24),
      const SizedBox(width: 12),
      Text(_isPaid ? (lang.translate('paid') ?? 'To\'langan') : (lang.translate('unpaid') ?? 'To\'lanmagan'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _isPaid ? ML.paid : Colors.grey.shade500)),
      const Spacer(),
      Switch.adaptive(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v),
          activeColor: ML.paid),
    ]),
  );

  void _langDialog(LanguageProvider lang) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(children: [Icon(Icons.language, color: ML.primary), SizedBox(width: 8), Text('Til', style: TextStyle(color: ML.primary, fontWeight: FontWeight.w800))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: ['UZB', 'ENG', 'RUS', 'KYR'].map((c) {
        final names = {'UZB': 'O\'zbekcha', 'ENG': 'English', 'RUS': 'Русский', 'KYR': 'Кыргызча'};
        final sel = lang.currentLanguage == c;
        return ListTile(
          title: Text(names[c]!, style: TextStyle(fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? ML.primary : Colors.black87)),
          trailing: sel ? const Icon(Icons.check_circle_rounded, color: ML.primary) : null,
          onTap: () { lang.changeLanguage(c); Navigator.pop(context); },
        );
      }).toList()),
    ));
  }
}