// lib/screens/admin_dashboard.dart
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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  String _selectedPeriod = 'today';
  int _selectedIndex = 0;
  String? _selectedPatientFilter;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

  @override
  void dispose() {
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

  String _formatMoney(dynamic amount) {
    final number = amount is num ? amount.toDouble() : 0.0;
    return '${NumberFormat('#,###', 'uz_UZ').format(number)} so\'m';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showLanguageDialog() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
             color: const Color(0xFF1E2746).withOpacity(0.95),
             borderRadius: BorderRadius.circular(24),
             border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.translate('language'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildLanguageOption('UZB', 'O\'zbekcha'),
              _buildLanguageOption('ENG', 'English'),
              _buildLanguageOption('RUS', 'Русский'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
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
  
  Widget _glassField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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

  // --- DIALOGS ---
  void _showAddStaffDialog(LanguageProvider lang) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'doctor';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
               color: const Color(0xFF1E2746).withOpacity(0.95),
               borderRadius: BorderRadius.circular(28),
               border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.translate('add_staff'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _glassField(controller: nameController, label: lang.translate('name'), icon: Icons.person),
                  const SizedBox(height: 16),
                  _glassField(controller: emailController, label: lang.translate('email'), icon: Icons.email, type: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _glassField(controller: passwordController, label: lang.translate('password'), icon: Icons.lock, isPassword: true),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        dropdownColor: const Color(0xFF1E2746),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: ['doctor', 'receptionist', 'laboratory', 'pharmacy'].map((r) => DropdownMenuItem(value: r, child: Text(lang.translate(r == 'pharmacy' ? 'pharmacist' : r)))).toList(),
                        onChanged: (v) => setDialogState(() => selectedRole = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                     Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.white)))),
                     const SizedBox(width: 12),
                     Expanded(child: ElevatedButton(
                       onPressed: () async {
                          if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.length < 6) return;
                          try {
                             UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text);
                             await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                               'name': nameController.text.trim(),
                               'email': emailController.text.trim(),
                               'role': selectedRole,
                               'createdAt': FieldValue.serverTimestamp(),
                               'createdBy': FirebaseAuth.instance.currentUser?.uid,
                             });
                             if (mounted) Navigator.pop(context);
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), padding: const EdgeInsets.symmetric(vertical: 16)),
                       child: Text(lang.translate('add'), style: const TextStyle(color: Colors.white)),
                     )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditStaffDialog(String id, Map<String, dynamic> data, LanguageProvider lang) {
      final nameController = TextEditingController(text: data['name']);
      String selectedRole = data['role'] ?? 'doctor';
      
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.95), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(lang.translate('edit_staff'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 24),
                   _glassField(controller: nameController, label: lang.translate('name'), icon: Icons.person),
                   const SizedBox(height: 16),
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: const Color(0xFF1E2746),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: ['doctor', 'receptionist', 'laboratory', 'pharmacy'].map((r) => DropdownMenuItem(value: r, child: Text(lang.translate(r == 'pharmacy' ? 'pharmacist' : r)))).toList(),
                          onChanged: (v) => setDialogState(() => selectedRole = v!),
                        ),
                      ),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                         await FirebaseFirestore.instance.collection('users').doc(id).update({
                            'name': nameController.text.trim(),
                            'role': selectedRole,
                            'updatedAt': FieldValue.serverTimestamp(),
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
      );
  }

  void _showDoctorDetailDialog(String doctorId, Map<String, dynamic> doctorData, LanguageProvider lang) {
     showDialog(
       context: context,
       builder: (context) => Dialog(
         backgroundColor: Colors.transparent,
         child: Container(
           height: 600,
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.95), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.1))),
           child: Column(
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(doctorData['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(doctorData['email'] ?? '', style: const TextStyle(color: Colors.white60)),
                   ]),
                   IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                 ],
               ),
               const SizedBox(height: 24),
               Expanded(
                 child: FutureBuilder<Map<String, dynamic>>(
                   future: _getDetailedDoctorStats(doctorId),
                   builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final stats = snapshot.data!;
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                             Row(children: [
                                Expanded(child: _miniStat(lang.translate('total_patients'), stats['totalPatients'].toString(), Icons.people, Colors.blueAccent)),
                                const SizedBox(width: 12),
                                Expanded(child: _miniStat(lang.translate('total_revenue'), _formatMoney(stats['totalRevenue']), Icons.attach_money, Colors.greenAccent)),
                             ]),
                             const SizedBox(height: 12),
                             Row(children: [
                                Expanded(child: _miniStat(lang.translate('completed'), stats['completedPatients'].toString(), Icons.check_circle, Colors.tealAccent)),
                                const SizedBox(width: 12),
                                Expanded(child: _miniStat(lang.translate('waiting'), stats['waitingPatients'].toString(), Icons.hourglass_empty, Colors.orangeAccent)),
                             ]),
                             const SizedBox(height: 20),
                             const Divider(color: Colors.white24),
                             const SizedBox(height: 12),
                             Text(lang.translate('period_statistics'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                             const SizedBox(height: 12),
                             _periodRow(lang.translate('today'), stats['todayPatients'], stats['todayRevenue'], Colors.blueAccent),
                             _periodRow(lang.translate('this_week'), stats['weekPatients'], stats['weekRevenue'], Colors.purpleAccent),
                             _periodRow(lang.translate('this_month'), stats['monthPatients'], stats['monthRevenue'], Colors.orangeAccent),
                          ],
                        ),
                      );
                   },
                 ),
               ),
             ],
           ),
         ),
       ),
     );
  }

  // --- STATS LOGIC ---
  Future<Map<String, dynamic>> _getStatistics(String period) async {
    Query query = FirebaseFirestore.instance.collection('patients');
    final now = DateTime.now();
    DateTime? startDate;

    if (period == 'today') startDate = DateTime(now.year, now.month, now.day);
    else if (period == 'week') startDate = now.subtract(Duration(days: now.weekday - 1));
    else if (period == 'month') startDate = DateTime(now.year, now.month, 1);

    if (startDate != null) query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

    final snapshot = await query.get();
    int totalPatients = snapshot.size;
    double totalRevenue = 0.0;
    int paid = 0, unpaid = 0;

    for (var doc in snapshot.docs) {
       final data = doc.data() as Map<String, dynamic>;
       final isPaid = data['isPaid'] ?? false;
       if (isPaid) {
          totalRevenue += (data['price'] ?? 0.0) as num;
          paid++;
       } else {
          unpaid++;
       }
    }
    return {'totalPatients': totalPatients, 'totalRevenue': totalRevenue, 'paidPatients': paid, 'unpaidPatients': unpaid};
  }

  Future<Map<String, dynamic>> _getDetailedDoctorStats(String doctorId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    final snapshot = await FirebaseFirestore.instance.collection('patients').where('doctorId', isEqualTo: doctorId).get();
    
    int total = snapshot.size, completed = 0, waiting = 0, paid = 0, unpaid = 0;
    double revenue = 0.0, todayRev = 0.0, weekRev = 0.0, monthRev = 0.0;
    int todayP = 0, weekP = 0, monthP = 0;
    
    for (var doc in snapshot.docs) {
       final data = doc.data();
       final status = data['status'];
       final isPaid = data['isPaid'] ?? false;
       final price = (data['price'] ?? 0.0) as num;
       final date = (data['createdAt'] as Timestamp?)?.toDate();
       
       if (status == 'completed') completed++; else waiting++;
       if (isPaid) { paid++; revenue += price.toDouble(); } else unpaid++;
       
       if (date != null) {
          if (date.isAfter(todayStart)) { todayP++; if(isPaid) todayRev += price; }
          if (date.isAfter(weekStart)) { weekP++; if(isPaid) weekRev += price; }
          if (date.isAfter(monthStart)) { monthP++; if(isPaid) monthRev += price; }
       }
    }
    return {
       'totalPatients': total, 'totalRevenue': revenue, 'completedPatients': completed, 'waitingPatients': waiting,
       'paidPatients': paid, 'unpaidPatients': unpaid, 'todayPatients': todayP, 'todayRevenue': todayRev,
       'weekPatients': weekP, 'weekRevenue': weekRev, 'monthPatients': monthP, 'monthRevenue': monthRev
    };
  }

  // --- WIDGETS ---
  Widget _buildMainStats(LanguageProvider lang) {
     return FutureBuilder<Map<String, dynamic>>(
        future: _getStatistics(_selectedPeriod),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           final stats = snapshot.data!;
           return Column(
              children: [
                 Row(children: [
                    Expanded(child: _statCard(lang.translate('total_patients'), stats['totalPatients'].toString(), Icons.people, Colors.blueAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(lang.translate('total_revenue'), _formatMoney(stats['totalRevenue']), Icons.attach_money, Colors.greenAccent)),
                 ]),
                 const SizedBox(height: 12),
                 Row(children: [
                    Expanded(child: _statCard(lang.translate('paid'), stats['paidPatients'].toString(), Icons.check_circle, Colors.tealAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(lang.translate('unpaid'), stats['unpaidPatients'].toString(), Icons.cancel, Colors.redAccent)),
                 ]),
              ],
           );
        },
     );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
       ),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Icon(icon, color: color, size: 28),
             const SizedBox(height: 12),
             Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
             Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
       ),
     );
  }
  
  Widget _miniStat(String title, String value, IconData icon, Color color) {
     return Container(
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
       child: Column(
          children: [
             Icon(icon, color: color),
             Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
          ],
       ),
     );
  }

  Widget _periodRow(String period, int count, double rev, Color color) {
     return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
           children: [
              Container(width: 4, height: 30, color: color),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(period, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 Text('$count patients', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
              const Spacer(),
              Text(_formatMoney(rev), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
           ],
        ),
     );
  }

  Widget _buildDoctorStats(LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').snapshots(),
      builder: (context, snapshot) {
         if (!snapshot.hasData) return const SizedBox();
         final doctors = snapshot.data!.docs;
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text(lang.translate('doctor_statistics'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...doctors.map((doc) => _buildDoctorItem(doc, lang)),
           ],
         );
      },
    );
  }

  Widget _buildDoctorItem(DocumentSnapshot doc, LanguageProvider lang) {
     final data = doc.data() as Map<String, dynamic>;
     return FutureBuilder<Map<String, dynamic>>(
        future: _getDetailedDoctorStats(doc.id),
        builder: (context, snapshot) {
           final stats = snapshot.data ?? {};
           final revenue = stats['totalRevenue'] ?? 0.0;
           return GestureDetector(
             onTap: () => _showDoctorDetailDialog(doc.id, data, lang),
             child: Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
               child: Row(
                  children: [
                     CircleAvatar(backgroundColor: Colors.white.withOpacity(0.1), child: const Icon(Icons.medical_services, color: Colors.white)),
                     const SizedBox(width: 12),
                     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${stats['totalPatients'] ?? 0} patients', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                     ])),
                     Text(_formatMoney(revenue), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
               ),
             ),
           );
        },
     );
  }

  // --- PAGES ---
  Widget _buildStatisticsPage(LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: ['today', 'week', 'month'].map((p) => Expanded(
               child: GestureDetector(
                 onTap: () => setState(() => _selectedPeriod = p),
                 child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _selectedPeriod == p ? const Color(0xFF4DB6AC) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(lang.translate(p), style: TextStyle(color: _selectedPeriod == p ? Colors.white : Colors.white60, fontWeight: FontWeight.bold))),
                 ),
               ),
             )).toList(),
          ),
          const SizedBox(height: 24),
          _buildMainStats(lang),
          const SizedBox(height: 24),
          _buildDoctorStats(lang),
        ],
      ),
    );
  }

  Widget _buildPatientsPage(LanguageProvider lang) {
     return StreamBuilder<QuerySnapshot>(
       stream: _selectedPatientFilter == null 
           ? FirebaseFirestore.instance.collection('patients').snapshots() 
           : FirebaseFirestore.instance.collection('patients').where('status', isEqualTo: _selectedPatientFilter).snapshots(),
       builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final patients = snapshot.data!.docs;
          return Column(
             children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                     children: [
                        _filterTab(lang.translate('all'), null),
                        const SizedBox(width: 8),
                        _filterTab(lang.translate('waiting'), 'waiting'),
                        const SizedBox(width: 8),
                        _filterTab(lang.translate('completed'), 'completed'),
                     ],
                  ),
                ),
                Expanded(
                   child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                         final data = patients[index].data() as Map<String, dynamic>;
                         return Container(
                           margin: const EdgeInsets.only(bottom: 12),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                           child: ListTile(
                              leading: CircleAvatar(backgroundColor: (data['status'] == 'completed' ? Colors.green : Colors.orange).withOpacity(0.2), child: Icon(data['status'] == 'completed' ? Icons.check : Icons.hourglass_empty, color: data['status'] == 'completed' ? Colors.green : Colors.orange)),
                              title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white)),
                              subtitle: Text(DateFormat('dd/MM HH:mm').format((data['createdAt'] as Timestamp).toDate()), style: const TextStyle(color: Colors.white54)),
                              trailing: Text(_formatMoney(data['price']), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                           ),
                         );
                      },
                   ),
                ),
             ],
          );
       },
     );
  }

  Widget _filterTab(String label, String? filter) {
     final isSelected = _selectedPatientFilter == filter;
     return Expanded(
        child: GestureDetector(
           onTap: () => setState(() => _selectedPatientFilter = filter),
           child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF4DB6AC) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60))),
           ),
        ),
     );
  }
  
  Widget _buildStaffPage(LanguageProvider lang) {
     return Column(
       children: [
         Container(
           width: double.infinity,
           margin: const EdgeInsets.all(16),
           child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => _showAddStaffDialog(lang),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(lang.translate('add_staff'), style: const TextStyle(color: Colors.white)),
           ),
         ),
         Expanded(
            child: StreamBuilder<QuerySnapshot>(
               stream: FirebaseFirestore.instance.collection('users').where('role', whereIn: ['doctor', 'receptionist', 'laboratory', 'pharmacy']).snapshots(),
               builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final staff = snapshot.data!.docs;
                  return ListView.builder(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     itemCount: staff.length,
                     itemBuilder: (context, index) {
                        final doc = staff[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                           margin: const EdgeInsets.only(bottom: 12),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                           child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.1), child: Icon(Icons.person, color: Colors.white)),
                              title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white)),
                              subtitle: Text(lang.translate(data['role']), style: const TextStyle(color: Colors.white54)),
                              trailing: IconButton(onPressed: () => _showEditStaffDialog(doc.id, data, lang), icon: const Icon(Icons.edit, color: Colors.white70)),
                           ),
                        );
                     },
                  );
               },
            ),
         ),
       ],
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
            title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                 child: _selectedIndex == 0 ? _buildStatisticsPage(lang) :
                        _selectedIndex == 1 ? _buildPatientsPage(lang) :
                        _buildStaffPage(lang),
              ),
              Positioned(
                 bottom: 20, left: 20, right: 20,
                 child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF1E2746).withOpacity(0.9), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)]),
                    child: ClipRRect(
                       borderRadius: BorderRadius.circular(24),
                       child: BottomNavigationBar(
                          currentIndex: _selectedIndex,
                          onTap: (i) => setState(() => _selectedIndex = i),
                          backgroundColor: Colors.transparent,
                          selectedItemColor: const Color(0xFF4DB6AC),
                          unselectedItemColor: Colors.grey,
                          elevation: 0,
                          items: [
                             BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: lang.translate('statistics')),
                             BottomNavigationBarItem(icon: const Icon(Icons.people), label: lang.translate('patients')),
                             BottomNavigationBarItem(icon: const Icon(Icons.badge), label: lang.translate('staff')),
                          ],
                       ),
                    ),
                 ),
              )
            ],
          ),
        );
      },
    );
  }
}