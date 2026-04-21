// lib/screens/laboratory_dashboard.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';

class LaboratoryDashboard extends StatefulWidget {
  const LaboratoryDashboard({super.key});

  @override
  State<LaboratoryDashboard> createState() => _LaboratoryDashboardState();
}

class _LaboratoryDashboardState extends State<LaboratoryDashboard> with TickerProviderStateMixin {
  String _selectedTab = 'all'; // all, pending, completed
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
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
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- ANIMATIONS ---
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

  // --- DIALOGS (Refactored to Modern UI) ---

  void _showTestTypesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.category, color: Color(0xFF4DB6AC), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Test Turlari', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('test_types').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('Test turlari yo\'q', style: TextStyle(color: Colors.white.withOpacity(0.5))));
                    }
                    final testTypes = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: testTypes.length,
                      itemBuilder: (context, index) {
                        final testType = testTypes[index];
                        final data = testType.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.biotech, color: Colors.white.withOpacity(0.7)),
                            title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${data['price'] ?? 0} so\'m', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('test_types').doc(testType.id).delete();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddTestTypeDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Yangi Test Turi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7075),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTestTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yangi Test Turi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                _glassField(controller: nameController, label: 'Test turi nomi', icon: Icons.biotech),
                const SizedBox(height: 16),
                _glassField(controller: priceController, label: 'Narx (so\'m)', icon: Icons.attach_money, isNumber: true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Bekor qilish', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await FirebaseFirestore.instance.collection('test_types').add({
                              'name': nameController.text.trim(),
                              'price': double.parse(priceController.text.trim()),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A7075), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTestDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedTestTypeId;
    String? selectedTestTypeName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F36).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Yangi Test Qo\'shish', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 24),
                      _glassField(controller: nameController, label: 'Bemor ismi', icon: Icons.person),
                      const SizedBox(height: 16),
                      // Dropdown for Test Type
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('test_types').orderBy('name').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final testTypes = snapshot.data!.docs;
                          
                          if (testTypes.isEmpty) return const Text('Test turlari yo\'q', style: TextStyle(color: Colors.white));

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1A1F36),
                                value: selectedTestTypeId,
                                hint: const Text('Test turini tanlang', style: TextStyle(color: Colors.white54)),
                                style: const TextStyle(color: Colors.white),
                                items: testTypes.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child: Text('${data['name']} - ${data['price']} so\'m'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedTestTypeId = value;
                                    final selectedDoc = testTypes.firstWhere((doc) => doc.id == value);
                                    final data = selectedDoc.data() as Map<String, dynamic>;
                                    selectedTestTypeName = data['name'];
                                    priceController.text = data['price'].toString();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _glassField(controller: priceController, label: 'Narx (so\'m)', icon: Icons.attach_money, isNumber: true, readOnly: true),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Bekor qilish', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate() && selectedTestTypeId != null) {
                                  await FirebaseFirestore.instance.collection('laboratory_tests').add({
                                    'patientName': nameController.text.trim(),
                                    'testType': selectedTestTypeName,
                                    'testTypeId': selectedTestTypeId,
                                    'price': double.parse(priceController.text.trim()),
                                    'status': 'pending',
                                    'isPaid': false,
                                    'result': null,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'createdBy': FirebaseAuth.instance.currentUser?.uid,
                                  });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A7075), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResultDialog(BuildContext context, String testId, Map<String, dynamic> testData) {
    final resultController = TextEditingController(text: testData['result']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36).withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Test Natijasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                   const SizedBox(height: 24),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                     child: Column(
                       children: [
                         _buildInfoRow(Icons.person, 'Bemor', testData['patientName'] ?? ''),
                         const SizedBox(height: 8),
                         _buildInfoRow(Icons.biotech, 'Test', testData['testType'] ?? ''),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   TextFormField(
                     controller: resultController,
                     decoration: InputDecoration(
                       labelText: 'Natija',
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.05),
                       labelStyle: const TextStyle(color: Colors.white70),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                     ),
                     style: const TextStyle(color: Colors.white),
                     maxLines: 4,
                   ),
                   const SizedBox(height: 24),
                   Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Bekor qilish', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                              await FirebaseFirestore.instance.collection('laboratory_tests').doc(testId).update({
                                'result': resultController.text.trim(),
                                'status': 'completed',
                                'completedAt': FieldValue.serverTimestamp(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Saqlash', style: TextStyle(color: Colors.white)),
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

  // --- PDF GENERATION ---
  Future<void> _generatePDF(List<QueryDocumentSnapshot> tests) async {
    final pdf = pw.Document();
    
    // Calculate stats
    int totalTests = tests.length;
    int completedTests = tests.where((t) => (t.data() as Map)['status'] == 'completed').length;
    int pendingTests = totalTests - completedTests;
    double totalRevenue = tests.fold(0.0, (sum, t) {
      final data = t.data() as Map<String, dynamic>;
      return sum + (data['isPaid'] == true ? (data['price'] ?? 0.0) : 0.0);
    });

    // Font setup omitted for brevity but standard PDF workflow
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
             pw.Header(level: 0, child: pw.Text('MEDLINE Laboratory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
             pw.SizedBox(height: 20),
             pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
             pw.SizedBox(height: 20),
             pw.Table.fromTextArray(
               context: context,
               data: <List<String>>[
                 <String>['Metric', 'Value'],
                 <String>['Total Tests', '$totalTests'],
                 <String>['Completed', '$completedTests'],
                 <String>['Pending', '$pendingTests'],
                 <String>['Revenue', '$totalRevenue'],
               ],
             ),
             pw.SizedBox(height: 20),
             pw.Table.fromTextArray(
               context: context,
               data: <List<String>>[
                 <String>['Patient', 'Test Type', 'Price', 'Status'],
                 ...tests.map((t) {
                   final d = t.data() as Map<String, dynamic>;
                   return [d['patientName'] ?? '', d['testType'] ?? '', '${d['price']}', d['status']];
                 }),
               ],
             ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }


  // --- WIDGETS ---
  Widget _glassField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
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
      validator: (v) => v == null || v.isEmpty ? 'Maydonni to\'ldiring' : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildTabButton(String title, String tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4DB6AC) : Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(title, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.science, color: Color(0xFF0A7075), size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Laboratory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.category, color: Colors.white), onPressed: () => _showTestTypesDialog(context)),
              IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () async {
                 await FirebaseAuth.instance.signOut();
                 if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }),
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
                    colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A), Color(0xFF0F1E3C)],
                  ),
                ),
              ),
              ...List.generate(6, (i) => _floatingParticle(i)),

              SafeArea(
                child: Column(
                  children: [
                    // Stats and Filter
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('laboratory_tests').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final tests = snapshot.data!.docs;
                              final total = tests.length;
                              final completed = tests.where((t) => (t.data() as Map)['status'] == 'completed').length;
                              final pending = tests.where((t) => (t.data() as Map)['status'] == 'pending').length;
                              
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Jami', '$total', Icons.science, Colors.blueAccent),
                                  _buildStatItem('Bajarilgan', '$completed', Icons.check_circle, Colors.greenAccent),
                                  _buildStatItem('Kutilmoqda', '$pending', Icons.pending, Colors.orangeAccent),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildTabButton('Hammasi', 'all')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTabButton('Kutilmoqda', 'pending')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTabButton('Bajarilgan', 'completed')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // LIST
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('laboratory_tests').orderBy('createdAt', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Ma\'lumotlar yo\'q', style: TextStyle(color: Colors.white60)));

                          var tests = snapshot.data!.docs;
                           if (_selectedTab != 'all') {
                              tests = tests.where((d) => (d.data() as Map)['status'] == _selectedTab).toList();
                           }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: tests.length,
                            itemBuilder: (context, index) {
                              final test = tests[index];
                              final data = test.data() as Map<String, dynamic>;
                              final isCompleted = data['status'] == 'completed';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: InkWell(
                                  onTap: isCompleted ? null : () => _showResultDialog(context, test.id, data),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                              child: Icon(isCompleted ? Icons.check : Icons.hourglass_empty, color: isCompleted ? Colors.greenAccent : Colors.orangeAccent, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(data['patientName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                  Text(data['testType'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${data['price'] ?? 0} so\'m',
                                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (isCompleted && data['result'] != null) ...[
                                           const SizedBox(height: 12),
                                           Container(
                                             width: double.infinity,
                                             padding: const EdgeInsets.all(12),
                                             decoration: BoxDecoration(
                                               color: Colors.green.withOpacity(0.1),
                                               borderRadius: BorderRadius.circular(12),
                                               border: Border.all(color: Colors.green.withOpacity(0.3)),
                                             ),
                                             child: Text(data['result'], style: const TextStyle(color: Colors.white)),
                                           ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              Positioned(
                bottom: 20, 
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddTestDialog(context),
                  backgroundColor: const Color(0xFF4DB6AC),
                  icon: const Icon(Icons.add),
                  label: const Text('New Test'),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton(
                   mini: true,
                   onPressed: () async {
                      // Generate report for all visible
                      final snapshot = await FirebaseFirestore.instance.collection('laboratory_tests').get();
                      _generatePDF(snapshot.docs);
                   },
                   backgroundColor: Colors.redAccent,
                   child: const Icon(Icons.picture_as_pdf),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}