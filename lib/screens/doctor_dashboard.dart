// lib/screens/doctor_dashboard.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';
import '../utils/date_utils.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  String _selectedTab = 'waiting'; // waiting, completed
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Note: _pulseController removed if not used, or re-add if needed for logo pulsing
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

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
              const Icon(Icons.language, color: Colors.white, size: 32),
              const SizedBox(height: 15),
              _buildLanguageOption('UZB', 'O\'zbekcha'),
              const Divider(color: Colors.white24),
              _buildLanguageOption('ENG', 'English'),
              const Divider(color: Colors.white24),
              _buildLanguageOption('RUS', 'Русский'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: lang.currentLanguage == code
          ? const Icon(Icons.check, color: Color(0xFF4DB6AC))
          : null,
      onTap: () {
        lang.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Consumer<LanguageProvider>(
      builder: (context, lang, child) {
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.local_hospital, size: 32, color: Color(0xFF0A7075)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEDLINE',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(lang.translate('doctor_panel'),
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ],
            ),
            actions: [
              const ThemeIconButton(), // Theme toggle
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: _showLanguageDialog,
                tooltip: lang.translate('language'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: lang.translate('logout'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A), Color(0xFF0F1E3C), Color(0xFF0D162F)],
                  ),
                ),
              ),
              ...List.generate(6, (i) => _floatingParticle(i)),

              SafeArea(
                child: Column(
                  children: [
                    // Tab selector
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildTabButton(lang.translate('waiting'), Icons.hourglass_empty, 'waiting')),
                          Expanded(
                              child: _buildTabButton(lang.translate('completed'), Icons.check_circle, 'completed')),
                        ],
                      ),
                    ),

                    // Patient list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('patients')
                            .where('doctorId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('${lang.translate('error')}: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState(lang);
                          }

                          final allPatients = snapshot.data!.docs;
                          var filteredPatients = allPatients.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'waiting';
                            return status == _selectedTab;
                          }).toList();

                          filteredPatients.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });

                          if (filteredPatients.isEmpty) {
                            return _buildEmptyState(lang);
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = filteredPatients[index];
                              final data = patient.data() as Map<String, dynamic>;
                              return _buildPatientCard(context, patient.id, data, lang);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String title, IconData icon, String tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFF0A7075), Color(0xFF14B8A6)]) : null,
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0A7075).withOpacity(0.4), blurRadius: 10)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedTab == 'waiting' ? Icons.inbox : Icons.check_circle_outline,
              size: 64, color: Colors.white30,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedTab == 'waiting' ? lang.translate('no_waiting_patients') : lang.translate('no_patients'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, String patientId, Map<String, dynamic> data, LanguageProvider lang) {
    final isCompleted = data['status'] == 'completed';
    final patientName = data['fullName'] ?? '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
    final isPaid = data['isPaid'] ?? false;
    final price = data['price'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isCompleted ? null : () => _showDiagnosisDialog(context, patientId, patientName, data, lang),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'B',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isCompleted ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName.isNotEmpty ? patientName : 'Bemor',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(isCompleted ? Icons.check_circle : Icons.pending, size: 14, color: isCompleted ? Colors.greenAccent : Colors.orangeAccent),
                              const SizedBox(width: 6),
                              Text(
                                isCompleted ? lang.translate('completed') : lang.translate('waiting'),
                                style: TextStyle(fontSize: 13, color: isCompleted ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (data['queue'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('${data['queue']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 16),
                if (data['address'] != null) ...[
                  _buildInfoRow(Icons.location_on, lang.translate('address'), data['address']),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow(Icons.healing, lang.translate('issue'), data['issue'] ?? lang.translate('no_patients')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isPaid ? Icons.check_circle : Icons.pending, size: 16, color: isPaid ? Colors.greenAccent : Colors.orangeAccent),
                    const SizedBox(width: 8),
                    Text(isPaid ? lang.translate('paid') : lang.translate('unpaid'), style: TextStyle(fontSize: 13, color: isPaid ? Colors.greenAccent : Colors.orangeAccent)),
                  ],
                ),
                if (isCompleted && data['diagnosis'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diagnosis:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(data['diagnosis'], style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
                if (!isCompleted) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDiagnosisDialog(context, patientId, patientName, data, lang),
                      icon: const Icon(Icons.edit_note, size: 20, color: Colors.white),
                      label: Text(lang.translate('add_diagnosis'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A7075),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.white60)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.white))),
      ],
    );
  }

  void _showDiagnosisDialog(BuildContext context, String patientId, String patientName, Map<String, dynamic> patientData, LanguageProvider lang) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.translate('add_diagnosis'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(patientName, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '${lang.translate('diagnosis')} *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: lang.translate('enter_diagnosis'),
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? lang.translate('enter_diagnosis') : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await FirebaseFirestore.instance.collection('patients').doc(patientId).update({
                                'diagnosis': controller.text.trim(),
                                'status': 'completed',
                                'diagnosedAt': FieldValue.serverTimestamp(),
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('diagnosis_saved')), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.translate('error')}: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A7075),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(lang.translate('save'), style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}