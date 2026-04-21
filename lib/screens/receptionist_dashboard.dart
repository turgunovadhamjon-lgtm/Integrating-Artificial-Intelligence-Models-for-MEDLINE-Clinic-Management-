// lib/screens/receptionist_dashboard.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';
import 'patients_list_screen.dart';
import 'diagnostic_web_screen.dart';
import 'hospitalization_dashboard.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _queueController = TextEditingController();
  final _addressController = TextEditingController();
  final _issueController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedDoctor;
  bool _isPaid = false;
  List<Map<String, String>> _doctors = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _loadDoctors();
    _loadNextQueueNumber();
  }

  // Floating particles
  Widget _floatingParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 100 + 50;
    final duration = 20 + random.nextInt(15);
    return AnimatedPositioned(
      duration: Duration(seconds: duration),
      curve: Curves.easeInOutSine,
      top: -size,
      left: (random.nextDouble() * 100).clamp(0.0, 95.0) * (MediaQuery.of(context).size.width / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withOpacity(0.08), Colors.transparent],
          ),
          boxShadow: [
            BoxShadow(color: Colors.white.withOpacity(0.06), blurRadius: 40, spreadRadius: 10),
          ],
        ),
      ),
    );
  }

  void _loadNextQueueNumber() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      int nextQueue = 1;
      if (snapshot.docs.isNotEmpty) {
        int maxQueue = 0;
        for (var doc in snapshot.docs) {
          final queueNum = int.tryParse(doc['queue'] as String? ?? '0') ?? 0;
          if (queueNum > maxQueue) maxQueue = queueNum;
        }
        nextQueue = maxQueue + 1;
      }
      if (mounted) setState(() => _queueController.text = nextQueue.toString());
    } catch (e) {
      if (mounted) setState(() => _queueController.text = '1');
    }
  }

  void _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      setState(() {
        _doctors = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': (doc['name'] as String?)?.trim() ?? 'Noma\'lum'})
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _submitPatient() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (!_formKey.currentState!.validate() || _selectedDoctor == null) {
      _showSnackBar('Barcha maydonlarni to‘ldiring!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('patients').add({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'fullName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        'queue': _queueController.text.trim(),
        'address': _addressController.text.trim(),
        'issue': _issueController.text.trim(),
        'doctorId': _selectedDoctor,
        'price': double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0,
        'isPaid': _isPaid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
      });

      _showSnackBar('Bemor muvaffaqiyatli qo‘shildi!', const Color(0xFF0A7075));
      _clearForm();
      _loadNextQueueNumber();
    } catch (e) {
      _showSnackBar('Xato: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.info, color: Colors.white), const SizedBox(width: 12), Text(message, style: const TextStyle(color: Colors.white))]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _surnameController.clear();
    _addressController.clear();
    _issueController.clear();
    _priceController.clear();
    setState(() {
      _selectedDoctor = null;
      _isPaid = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // TIL O‘ZGARTIRISH DIALOGI
  void _showLanguageDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A7075).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.language, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    lang.translate('language') ?? 'Tilni tanlang',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _languageOption('UZB', 'O‘zbekcha', 'UZB'),
              const Divider(color: Colors.white, height: 1),
              _languageOption('ENG', 'English', 'ENG'),
              const Divider(color: Colors.white, height: 1),
              _languageOption('RUS', 'Русский', 'RUS'),
              const Divider(color: Colors.white, height: 1),
              _languageOption('KYR', 'Кыргызча', 'KYR'),
            ],
          ),
        ),
      ),
    );
  }

  // UZB, ENG, RUS YOZUVLARI ENDI TOZA OQ, KATTA VA CHIROYLII!
  Widget _languageOption(String code, String name, String flag) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isSelected = lang.currentLanguage == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          lang.changeLanguage(code);
          Navigator.pop(context);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0A7075).withOpacity(0.35) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // FLAG – TOZA OQ, KATTA VA QALIN!
              Text(
                flag,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Row(
          children: [
            Hero(
              tag: 'clinic_logo',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.local_hospital, size: 36, color: Color(0xFF0A7075)),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MEDLINE', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  lang.translate('receptionist_panel') ?? 'Qabulxona',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const ThemeIconButton(), // Theme toggle
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsListScreen())),
            tooltip: lang.translate('patients_list') ?? 'Bemorlar',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.language, color: Colors.white, size: 26),
            ),
            onPressed: _showLanguageDialog,
            tooltip: lang.translate('language') ?? 'Til',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: () {
              _loadDoctors();
              _loadNextQueueNumber();
            },
            tooltip: lang.translate('refresh') ?? 'Yangilash',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
            onPressed: _logout,
            tooltip: lang.translate('logout') ?? 'Chiqish',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A), Color(0xFF0F1E3C), Color(0xFF0D162F)],
              ),
            ),
          ),
          ...List.generate(10, (i) => _floatingParticle(i)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF4081)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 30)],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticWebScreen())),
                          icon: const Icon(Icons.health_and_safety, size: 36, color: Colors.white),
                          label: Text(
                            lang.translate('diagnostic_agent') ?? 'Tibbiy Diagnostika Agenti',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                        ),
                      ),

                      // HOSPITALIZATION BUTTON
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 30)],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HospitalizationDashboard())),
                          icon: const Icon(Icons.hotel, size: 36, color: Colors.white),
                          label: Text(
                            lang.translate('hospitalization') ?? 'Yotqizish bo\'limi',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40)],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    lang.translate('patient_info') ?? 'Bemor maʼlumotlari',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              Row(
                                children: [
                                  Expanded(child: _glassField(_nameController, lang.translate('name'), Icons.person, true)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _glassField(_surnameController, lang.translate('surname') ?? 'Familiya', Icons.person_outline, true)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _glassField(_queueController, lang.translate('queue') ?? 'Navbat raqami', Icons.format_list_numbered, false, readOnly: true),
                              const SizedBox(height: 20),
                              _glassField(_addressController, lang.translate('address') ?? 'Manzil', Icons.home, false),
                              const SizedBox(height: 20),
                              _glassField(_issueController, lang.translate('issue') ?? 'Shikoyat', Icons.medical_information, true, maxLines: 4),
                              const SizedBox(height: 24),
                              _doctorDropdown(lang),
                              const SizedBox(height: 20),
                              _glassField(_priceController, lang.translate('price') ?? 'To‘lov summasi (so‘m)', Icons.payments, true, keyboardType: TextInputType.number),
                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isPaid
                                        ? [Colors.teal.withOpacity(0.3), Colors.cyan.withOpacity(0.2)]
                                        : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _isPaid ? Colors.teal : Colors.white24, width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.payment, size: 32, color: _isPaid ? Colors.tealAccent : Colors.white70),
                                        const SizedBox(width: 16),
                                        Text(
                                          _isPaid ? (lang.translate('paid') ?? 'To‘langan') : (lang.translate('unpaid') ?? 'To‘lanmagan'),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _isPaid,
                                      onChanged: (v) => setState(() => _isPaid = v),
                                      activeColor: Colors.tealAccent,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _clearForm,
                                      icon: const Icon(Icons.refresh, color: Colors.white),
                                      label: Text(
                                        lang.translate('clear') ?? 'Tozalash',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        side: const BorderSide(color: Colors.white, width: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF0A7075), Color(0xFF14B8A6)]),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [BoxShadow(color: const Color(0xFF0A7075).withOpacity(0.5), blurRadius: 20)],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ? null : _submitPatient,
                                        icon: _isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                            : const Icon(Icons.save_alt, color: Colors.white),
                                        label: Text(
                                          _isLoading ? (lang.translate('saving') ?? 'Saqlanmoqda...') : (lang.translate('save') ?? 'Saqlash'),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassField(TextEditingController controller, String label, IconData icon, bool required,
      {int maxLines = 1, bool readOnly = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF4DB6AC)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: required ? (v) => v!.trim().isEmpty ? 'Majburiy maydon' : null : null,
    );
  }

  Widget _doctorDropdown(LanguageProvider lang) {
    return DropdownButtonFormField<String>(
      value: _selectedDoctor,
      dropdownColor: const Color(0xFF1F2940), // Darker consistent background
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: lang.translate('select_doctor') ?? 'Shifokorni tanlang',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(Icons.person_search, color: Color(0xFF4DB6AC)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5)),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
      items: _doctors.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name']!, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: (v) => setState(() => _selectedDoctor = v),
      validator: (v) => v == null ? (lang.translate('select_doctor') ?? 'Shifokor tanlang') : null,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _queueController.dispose();
    _addressController.dispose();
    _issueController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}