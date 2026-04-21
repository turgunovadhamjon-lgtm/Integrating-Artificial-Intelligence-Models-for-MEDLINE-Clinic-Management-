// lib/screens/hospitalization_dashboard.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';

class HospitalizationDashboard extends StatefulWidget {
  const HospitalizationDashboard({super.key});

  @override
  State<HospitalizationDashboard> createState() => _HospitalizationDashboardState();
}

class _HospitalizationDashboardState extends State<HospitalizationDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- ANIMATIONS & UTILS ---
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final d = (date as Timestamp).toDate();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
  
  String _translateRoomType(String? type, LanguageProvider lang) {
     return lang.translate(type ?? 'standard');
  }

  void _showLanguageDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.translate('language'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _languageOption('UZB', 'O\'zbekcha'),
              _languageOption('ENG', 'English'),
              _languageOption('RUS', 'Русский'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageOption(String code, String name) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isSelected = lang.currentLanguage == code;
    return ListTile(
      title: Text(name, style: TextStyle(color: isSelected ? const Color(0xFF4DB6AC) : Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF4DB6AC)) : null,
      onTap: () {
        lang.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _glassField({required TextEditingController controller, required String label, required IconData icon, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5)),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // --- DIALOGS ---
  void _showAddRoomDialog(LanguageProvider lang) {
     final roomNumberController = TextEditingController();
     final floorController = TextEditingController();
     final bedsController = TextEditingController();
     final priceController = TextEditingController();
     String selectedType = 'standard';
     
     showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
           builder: (context, setDialogState) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.95), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.1))),
                 child: SingleChildScrollView(
                    child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          Text(lang.translate('add_room'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _glassField(controller: roomNumberController, label: lang.translate('room_number'), icon: Icons.door_front_door),
                          const SizedBox(height: 12),
                          _glassField(controller: floorController, label: lang.translate('floor'), icon: Icons.layers, type: TextInputType.number),
                          const SizedBox(height: 12),
                          _glassField(controller: bedsController, label: lang.translate('beds'), icon: Icons.bed, type: TextInputType.number),
                          const SizedBox(height: 12),
                          _glassField(controller: priceController, label: lang.translate('daily_rate'), icon: Icons.attach_money, type: TextInputType.number),
                          const SizedBox(height: 12),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12),
                             decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                             child: DropdownButtonHideUnderline(
                               child: DropdownButton<String>(
                                 value: selectedType,
                                 dropdownColor: const Color(0xFF1E2746),
                                 isExpanded: true,
                                 style: const TextStyle(color: Colors.white),
                                 items: ['standard', 'vip', 'intensive'].map((t) => DropdownMenuItem(value: t, child: Text(lang.translate(t)))).toList(),
                                 onChanged: (v) => setDialogState(() => selectedType = v!),
                               ),
                             ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), minimumSize: const Size(double.infinity, 50)),
                             onPressed: () async {
                                if (roomNumberController.text.isEmpty || priceController.text.isEmpty) return;
                                await FirebaseFirestore.instance.collection('rooms').add({
                                   'number': roomNumberController.text.trim(),
                                   'floor': floorController.text.trim(),
                                   'beds': int.tryParse(bedsController.text) ?? 1,
                                   'type': selectedType,
                                   'price': double.tryParse(priceController.text) ?? 0.0,
                                   'isAvailable': true,
                                   'createdAt': FieldValue.serverTimestamp(),
                                });
                                if (mounted) Navigator.pop(context);
                             },
                             child: Text(lang.translate('save'), style: const TextStyle(color: Colors.white)),
                          ),
                       ],
                    ),
                 ),
              ),
           ),
        ),
     );
  }

  void _showAdmitPatientDialog(LanguageProvider lang, String roomId, String roomNumber) async {
     final patientsSnap = await FirebaseFirestore.instance.collection('patients').where('status', isEqualTo: 'waiting').get();
     final doctorsSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
     
     if (patientsSnap.docs.isEmpty) { _showSnackBar(lang.translate('no_patients'), Colors.orange); return; }
     
     String? selectedPatientId;
     String? selectedDoctorId;
     final diagnosisController = TextEditingController();
     final notesController = TextEditingController();
     
     if (!mounted) return;
     showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
           builder: (context, setDialogState) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.95), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.1))),
                 child: SingleChildScrollView(
                    child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          Text("${lang.translate('admit_patient')} - $roomNumber", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                             value: selectedPatientId,
                             dropdownColor: const Color(0xFF1E2746),
                             style: const TextStyle(color: Colors.white),
                             decoration: InputDecoration(
                                labelText: lang.translate('patient_name'), labelStyle: const TextStyle(color: Colors.white70),
                                filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             items: patientsSnap.docs.map((d) {
                                final name = d['name'] ?? 'Unknown';
                                final surname = d['surname'] ?? '';
                                return DropdownMenuItem(value: d.id, child: Text('$name $surname'));
                             }).toList(),
                             onChanged: (v) => setDialogState(() => selectedPatientId = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                             value: selectedDoctorId,
                             dropdownColor: const Color(0xFF1E2746),
                             style: const TextStyle(color: Colors.white),
                             decoration: InputDecoration(
                                labelText: lang.translate('doctor'), labelStyle: const TextStyle(color: Colors.white70),
                                filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             items: doctorsSnap.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'] ?? 'Doctor'))).toList(),
                             onChanged: (v) => setDialogState(() => selectedDoctorId = v),
                          ),
                          const SizedBox(height: 12),
                          _glassField(controller: diagnosisController, label: lang.translate('diagnosis'), icon: Icons.assignment),
                          const SizedBox(height: 12),
                          _glassField(controller: notesController, label: lang.translate('notes'), icon: Icons.note),
                          const SizedBox(height: 24),
                          ElevatedButton(
                             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), minimumSize: const Size(double.infinity, 50)),
                             onPressed: () async {
                                if (selectedPatientId == null || selectedDoctorId == null) return;
                                final patient = patientsSnap.docs.firstWhere((p) => p.id == selectedPatientId);
                                final doctor = doctorsSnap.docs.firstWhere((d) => d.id == selectedDoctorId);
                                final pName = patient['name'] ?? '';
                                final pSurname = patient['surname'] ?? '';
                                await FirebaseFirestore.instance.collection('hospitalizations').add({
                                   'patientId': selectedPatientId,
                                   'patientName': '$pName $pSurname',
                                   'roomId': roomId,
                                   'roomNumber': roomNumber,
                                   'doctorId': selectedDoctorId,
                                   'doctorName': doctor['name'],
                                   'diagnosis': diagnosisController.text.trim(),
                                   'notes': notesController.text.trim(),
                                   'admissionDate': FieldValue.serverTimestamp(),
                                   'status': 'active',
                                   'createdAt': FieldValue.serverTimestamp(),
                                });
                                await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isAvailable': false});
                                if (mounted) Navigator.pop(context);
                             },
                             child: Text(lang.translate('save'), style: const TextStyle(color: Colors.white)),
                          ),
                       ],
                    ),
                 ),
              ),
           ),
        ),
     );
  }

  void _dischargePatient(String hospId, String roomId, LanguageProvider lang) {
     showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
           backgroundColor: const Color(0xFF1E2746),
           title: Text(lang.translate('discharge_patient'), style: const TextStyle(color: Colors.white)),
           content: Text(lang.translate('confirm_discharge'), style: const TextStyle(color: Colors.white70)),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.white60))),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                 onPressed: () async {
                    await FirebaseFirestore.instance.collection('hospitalizations').doc(hospId).update({
                       'status': 'discharged',
                       'dischargeDate': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({'isAvailable': true});
                    if (mounted) Navigator.pop(ctx);
                 },
                 child: Text(lang.translate('confirm')),
              ),
           ],
        ),
     );
  }

  // --- PAGES ---
  Widget _buildRoomsTab(LanguageProvider lang) {
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('rooms').orderBy('number').snapshots(),
       builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rooms = snapshot.data!.docs;
          if (rooms.isEmpty) return Center(child: Text(lang.translate('no_rooms'), style: const TextStyle(color: Colors.white60)));
          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: rooms.length,
             itemBuilder: (context, index) {
                final room = rooms[index].data() as Map<String, dynamic>;
                final isAvailable = room['isAvailable'] ?? true;
                return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                   child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                         child: Icon(isAvailable ? Icons.meeting_room : Icons.no_meeting_room, color: isAvailable ? Colors.greenAccent : Colors.redAccent),
                      ),
                      title: Text("${lang.translate('room_number')} ${room['number']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                         const SizedBox(height: 4),
                         Text('${lang.translate('floor')}: ${room['floor']} | ${lang.translate('beds')}: ${room['beds']}', style: const TextStyle(color: Colors.white60)),
                         Text('${lang.translate('type')}: ${lang.translate(room['type'] ?? 'standard')}', style: const TextStyle(color: Colors.white60)),
                         Text('${room['price']} KGS', style: const TextStyle(color: Colors.greenAccent)),
                      ]),
                      trailing: isAvailable ? IconButton(
                         icon: const Icon(Icons.person_add, color: Colors.blueAccent),
                         onPressed: () => _showAdmitPatientDialog(lang, rooms[index].id, room['number']),
                      ) : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(lang.translate('occupied'), style: const TextStyle(color: Colors.redAccent, fontSize: 10))),
                   ),
                );
             },
          );
       },
     );
  }
  
  Widget _buildActiveHospitalizationsTab(LanguageProvider lang) {
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('hospitalizations').where('status', isEqualTo: 'active').snapshots(),
       builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!.docs;
          if (list.isEmpty) return Center(child: Text(lang.translate('no_hospitalizations'), style: const TextStyle(color: Colors.white60)));
          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: list.length,
             itemBuilder: (context, index) {
                final hosp = list[index].data() as Map<String, dynamic>;
                return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                   child: ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.1), child: const Icon(Icons.local_hospital, color: Colors.white)),
                      title: Text(hosp['patientName'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                         Text("${lang.translate('room')}: ${hosp['roomNumber']}", style: const TextStyle(color: Colors.white70)),
                         Text("${lang.translate('doctor')}: ${hosp['doctorName']}", style: const TextStyle(color: Colors.white54)),
                         Text("${lang.translate('admission')}: ${_formatDate(hosp['admissionDate'])}", style: const TextStyle(color: Colors.white54)),
                      ]),
                      trailing: IconButton(
                         icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                         onPressed: () => _dischargePatient(list[index].id, hosp['roomId'], lang),
                      ),
                   ),
                );
             },
          );
       },
     );
  }
  
  Widget _buildHistoryTab(LanguageProvider lang) {
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('hospitalizations').where('status', isEqualTo: 'discharged').snapshots(),
       builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!.docs;
          if (list.isEmpty) return Center(child: Text(lang.translate('no_history'), style: const TextStyle(color: Colors.white60)));
          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: list.length,
             itemBuilder: (context, index) {
                final hosp = list[index].data() as Map<String, dynamic>;
                return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                   child: ListTile(
                      leading: const Icon(Icons.history, color: Colors.white54),
                      title: Text(hosp['patientName'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text("${lang.translate('discharged')}: ${_formatDate(hosp['dischargeDate'])}", style: const TextStyle(color: Colors.white54)),
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
      builder: (context, lang, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Hospitalization', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            bottom: TabBar(
               controller: _tabController,
               indicatorColor: const Color(0xFF4DB6AC),
               labelColor: const Color(0xFF4DB6AC),
               unselectedLabelColor: Colors.white60,
               tabs: [
                  Tab(text: lang.translate('rooms')),
                  Tab(text: lang.translate('active')),
                  Tab(text: lang.translate('history')),
               ],
            ),
            actions: [
               IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: _showLanguageDialog),
               IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())))),
            ],
          ),
          body: Stack(
            children: [
              Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A)]))),
              ...List.generate(6, (i) => _floatingParticle(i)),
              SafeArea(
                 child: TabBarView(
                    controller: _tabController,
                    children: [
                       _buildRoomsTab(lang),
                       _buildActiveHospitalizationsTab(lang),
                       _buildHistoryTab(lang),
                    ],
                 ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
             backgroundColor: const Color(0xFF4DB6AC),
             onPressed: () => _showAddRoomDialog(lang),
             child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}