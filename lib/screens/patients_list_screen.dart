// lib/screens/patients_list_screen.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../providers/language_provider.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, waiting, completed, paid, daily
  String _sortBy = 'date'; // date, name, status
  DateTime _selectedDate = DateTime.now();

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

  // --- UTILS ---
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _formatMoney(num amount) {
    return '${NumberFormat('#,###', 'uz_UZ').format(amount)}';
  }

  // --- PDF ---
  Future<void> _selectDate(LanguageProvider lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4DB6AC),
                onPrimary: Colors.white,
                surface: Color(0xFF1E2746),
                onSurface: Colors.white,
             ),
             dialogBackgroundColor: const Color(0xFF1E2746),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterStatus = 'daily';
      });
    }
  }

  Future<void> _savePdfToDevice(LanguageProvider lang, List<QueryDocumentSnapshot> patients) async {
     await _generatePdf(lang, patients, share: true);
  }
  
  Future<void> _printDailyReport(LanguageProvider lang, List<QueryDocumentSnapshot> patients) async {
     await _generatePdf(lang, patients, share: false);
  }

  Future<void> _generatePdf(LanguageProvider lang, List<QueryDocumentSnapshot> patients, {required bool share}) async {
    final doctorsSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'doctor').get();
    final doctorNames = { for (var doc in doctorsSnapshot.docs) doc.id: (doc['name'] as String?)?.trim() ?? 'Unknown' };

    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    num totalAmount = 0;
    num paidAmount = 0;
    for (var doc in patients) {
      final price = doc['price'] as num? ?? 0;
      totalAmount += price;
      if (doc['isPaid'] == true) paidAmount += price;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(child: pw.Column(children: [
               pw.Text('MEDLINE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 8),
               pw.Text('Daily Report', style: const pw.TextStyle(fontSize: 18)),
               pw.SizedBox(height: 4),
               pw.Text(dateStr, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ])),
            pw.SizedBox(height: 24),
            pw.Container(
               padding: const pw.EdgeInsets.all(12),
               decoration: pw.BoxDecoration(border: pw.Border.all(), borderRadius: pw.BorderRadius.circular(8)),
               child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
                  pw.Column(children: [pw.Text('${patients.length}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)), pw.Text('Total Patients')]),
                  pw.Column(children: [pw.Text(_formatMoney(totalAmount), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)), pw.Text('Total Amount')]),
                  pw.Column(children: [pw.Text(_formatMoney(paidAmount), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)), pw.Text('Paid')]),
               ]),
            ),
            pw.SizedBox(height: 24),
            pw.Table(border: pw.TableBorder.all(), columnWidths: {0: const pw.FixedColumnWidth(30), 4: const pw.FixedColumnWidth(70), 5: const pw.FixedColumnWidth(50)}, children: [
               pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey300), children: ['#', 'Patient', 'Complaint', 'Doctor', 'Amount', 'Paid'].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))).toList()),
               ...patients.asMap().entries.map((entry) {
                  final data = entry.value.data() as Map<String, dynamic>;
                  return pw.TableRow(children: [
                     pw.Text('${entry.key + 1}'),
                     pw.Text('${data['name'] ?? ''} ${data['surname'] ?? ''}'),
                     pw.Text((data['issue'] as String? ?? '').length > 30 ? '${(data['issue'] ?? '').substring(0, 30)}...' : (data['issue'] ?? '')),
                     pw.Text(doctorNames[data['doctorId']] ?? ''),
                     pw.Text(_formatMoney(data['price'] ?? 0)),
                     pw.Text((data['isPaid'] ?? false) ? '+' : '-'),
                  ].map((w) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: w)).toList());
               }).toList(),
            ]),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
               pw.Text('Printed: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
               pw.Text('MEDLINE System', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ];
        },
      ),
    );
    
    final name = 'MEDLINE_${dateStr.replaceAll('.', '_')}.pdf';
    if (share) {
       await Printing.sharePdf(bytes: await pdf.save(), filename: name);
    } else {
       await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: name);
    }
  }

  // --- WIDGETS ---
  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isSelected = false, VoidCallback? onTap, String? subtitle}) {
     return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
           duration: const Duration(milliseconds: 200),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.1)),
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : [],
           ),
           child: Column(
              children: [
                 Icon(icon, color: color, size: 24),
                 const SizedBox(height: 8),
                 Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                 Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                 if (subtitle != null) Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
           ),
        ),
     );
  }

  Widget _buildPatientCard(QueryDocumentSnapshot doc, LanguageProvider lang) {
     final data = doc.data() as Map<String, dynamic>;
     final isPaid = data['isPaid'] ?? false;
     final status = data['status'] ?? 'waiting';
     final color = status == 'completed' ? Colors.green : Colors.orange;
     
     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.05),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ListTile(
           contentPadding: const EdgeInsets.all(16),
           onTap: () => _showPatientDetails(doc, lang),
           leading: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.1), child: Text((data['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
           title: Text('${data['name'] ?? ''} ${data['surname'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (data['queue'] != null) Text("${lang.translate('queue')}: ${data['queue']}", style: const TextStyle(color: Colors.white60)),
              Text(_formatDate(data['createdAt']), style: const TextStyle(color: Colors.white54, fontSize: 12)),
           ]),
           trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                 child: Text(lang.translate(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('${_formatMoney(data['price'] ?? 0)} UZS', style: TextStyle(color: isPaid ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
           ]),
        ),
     );
  }

  void _showPatientDetails(QueryDocumentSnapshot doc, LanguageProvider lang) {
     final data = doc.data() as Map<String, dynamic>;
     showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
           height: MediaQuery.of(context).size.height * 0.8,
           decoration: BoxDecoration(
              color: const Color(0xFF1E2746).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
           ),
           child: Column(
              children: [
                 Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                 Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(children: [
                       CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.1), child: Text((data['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                       const SizedBox(width: 16),
                       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${data['name'] ?? ''} ${data['surname'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(_formatDate(data['createdAt']), style: const TextStyle(color: Colors.white60)),
                       ])),
                       IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                    ]),
                 ),
                 const Divider(color: Colors.white10),
                 Expanded(
                    child: ListView(padding: const EdgeInsets.all(24), children: [
                       _detailItem(Icons.numbers, lang.translate('queue'), data['queue']),
                       _detailItem(Icons.location_on, lang.translate('address'), data['address']),
                       _detailItem(Icons.healing, lang.translate('issue'), data['issue']),
                       FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(data['doctorId']).get(),
                          builder: (context, snap) => _detailItem(Icons.medical_services, lang.translate('doctor'), snap.data?['name'] ?? 'Loading...'),
                       ),
                       _detailItem(Icons.price_check, lang.translate('price'), '${_formatMoney(data['price'] ?? 0)} UZS'),
                       _detailItem(Icons.payment, lang.translate('status'), data['isPaid'] == true ? lang.translate('paid') : lang.translate('unpaid'), color: data['isPaid'] == true ? Colors.greenAccent : Colors.orangeAccent),
                    ]),
                 ),
              ],
           ),
        ),
     );
  }

  Widget _detailItem(IconData icon, String label, String? value, {Color? color}) {
     if (value == null || value.isEmpty) return const SizedBox();
     return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
           Icon(icon, color: Colors.white60, size: 20),
           const SizedBox(width: 12),
           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 16)),
           ])),
        ]),
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
            title: const Text('Patients List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
               Theme(data: Theme.of(context).copyWith(cardColor: const Color(0xFF1E2746), iconTheme: const IconThemeData(color: Colors.white)), child: PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onSelected: (v) => setState(() => _filterStatus = v),
                  itemBuilder: (ctx) => ['all', 'waiting', 'completed', 'paid'].map((v) => PopupMenuItem(value: v, child: Text(lang.translate(v + (v == 'all' ? '_patients' : '')), style: const TextStyle(color: Colors.white)))).toList(),
               )),
               Theme(data: Theme.of(context).copyWith(cardColor: const Color(0xFF1E2746), iconTheme: const IconThemeData(color: Colors.white)), child: PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onSelected: (v) => setState(() => _sortBy = v),
                  itemBuilder: (ctx) => ['date', 'name', 'status'].map((v) => PopupMenuItem(value: v, child: Text(lang.translate('sort_by_$v'), style: const TextStyle(color: Colors.white)))).toList(),
               )),
            ],
          ),
          body: Stack(
            children: [
               Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A)]))),
               ...List.generate(6, (i) => _floatingParticle(i)),
               SafeArea(
                  child: Column(
                     children: [
                        Padding(
                           padding: const EdgeInsets.all(16),
                           child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                 hintText: lang.translate('search_patients'),
                                 hintStyle: const TextStyle(color: Colors.white54),
                                 prefixIcon: const Icon(Icons.search, color: Colors.white54),
                                 suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () => setState(() => _searchQuery = '')) : null,
                                 filled: true, fillColor: Colors.white.withOpacity(0.05),
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                           ),
                        ),
                        // Stats
                        StreamBuilder<QuerySnapshot>(
                           stream: FirebaseFirestore.instance.collection('patients').snapshots(),
                           builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final docs = snapshot.data!.docs;
                              final total = docs.length;
                              final waiting = docs.where((d) => d['status'] == 'waiting').length;
                              final completed = docs.where((d) => d['status'] == 'completed').length;
                              final paid = docs.where((d) => d['isPaid'] == true).length;
                              final paidAmount = docs.where((d) => d['isPaid'] == true).fold(0.0, (sum, d) => sum + (d['price'] ?? 0));
                              
                              final dailyDocs = docs.where((d) {
                                 final dt = (d['createdAt'] as Timestamp?)?.toDate();
                                 if (dt == null) return false;
                                 return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                              }).toList();
                              
                              return Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 child: Column(children: [
                                    Row(children: [
                                       Expanded(child: _buildStatCard(lang.translate('total'), '$total', Icons.people, Colors.blueAccent, isSelected: _filterStatus == 'all', onTap: () => setState(() => _filterStatus = 'all'))),
                                       const SizedBox(width: 8),
                                       Expanded(child: _buildStatCard(lang.translate('waiting'), '$waiting', Icons.pending, Colors.orangeAccent, isSelected: _filterStatus == 'waiting', onTap: () => setState(() => _filterStatus = 'waiting'))),
                                       const SizedBox(width: 8),
                                       Expanded(child: _buildStatCard(lang.translate('completed'), '$completed', Icons.check_circle, Colors.greenAccent, isSelected: _filterStatus == 'completed', onTap: () => setState(() => _filterStatus = 'completed'))),
                                       const SizedBox(width: 8),
                                       Expanded(child: _buildStatCard(lang.translate('paid'), '$paid', Icons.attach_money, Colors.tealAccent, subtitle: _formatMoney(paidAmount), isSelected: _filterStatus == 'paid', onTap: () => setState(() => _filterStatus = 'paid'))),
                                    ]),
                                    const SizedBox(height: 12),
                                    // Daily Card
                                    GestureDetector(
                                       onTap: () => setState(() => _filterStatus = 'daily'),
                                       child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: _filterStatus == 'daily' ? Colors.purpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: _filterStatus == 'daily' ? Colors.purpleAccent : Colors.white.withOpacity(0.1))),
                                          child: Row(children: [
                                             const Icon(Icons.calendar_today, color: Colors.purpleAccent),
                                             const SizedBox(width: 12),
                                             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(DateFormat('dd.MM.yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                Text('${dailyDocs.length} patients | ${_formatMoney(dailyDocs.where((d) => d['isPaid'] == true).fold(0.0, (s, d) => s + (d['price'] ?? 0)))} UZS', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                             ])),
                                             IconButton(icon: const Icon(Icons.edit_calendar, color: Colors.white70), onPressed: () => _selectDate(lang)),
                                             if (dailyDocs.isNotEmpty) IconButton(icon: const Icon(Icons.print, color: Colors.white70), onPressed: () => _printDailyReport(lang, dailyDocs)),
                                             if (dailyDocs.isNotEmpty) IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white70), onPressed: () => _savePdfToDevice(lang, dailyDocs)),
                                          ]),
                                       ),
                                    ),
                                 ]),
                              );
                           },
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: StreamBuilder<QuerySnapshot>(
                           stream: FirebaseFirestore.instance.collection('patients').snapshots(),
                           builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              var list = snapshot.data!.docs;
                              
                              if (_filterStatus == 'waiting') list = list.where((d) => d['status'] == 'waiting').toList();
                              else if (_filterStatus == 'completed') list = list.where((d) => d['status'] == 'completed').toList();
                              else if (_filterStatus == 'paid') list = list.where((d) => d['isPaid'] == true).toList();
                              else if (_filterStatus == 'daily') list = list.where((d) {
                                 final dt = (d['createdAt'] as Timestamp?)?.toDate();
                                 if (dt == null) return false;
                                 return dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day;
                              }).toList();
                              
                              if (_searchQuery.isNotEmpty) {
                                 list = list.where((d) => (d['name'] ?? '').toString().toLowerCase().contains(_searchQuery) || (d['surname'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
                              }
                              
                              list.sort((a, b) {
                                 if (_sortBy == 'name') return (a['name'] ?? '').compareTo(b['name'] ?? '');
                                 if (_sortBy == 'status') return (a['status'] ?? '').compareTo(b['status'] ?? '');
                                 final da = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                                 final db = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
                                 return db.compareTo(da);
                              });
                              
                              if (list.isEmpty) return Center(child: Text(lang.translate('no_patients'), style: const TextStyle(color: Colors.white60)));
                              
                              return ListView.builder(
                                 padding: const EdgeInsets.symmetric(horizontal: 16),
                                 itemCount: list.length,
                                 itemBuilder: (context, index) => _buildPatientCard(list[index], lang),
                              );
                           },
                        )),
                     ],
                  ),
               ),
            ],
          ),
        );
      },
    );
  }
}