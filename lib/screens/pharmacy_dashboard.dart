// lib/screens/pharmacy_dashboard.dart
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController(); // FIXED: Controller moved here
  String _searchQuery = '';
  String? _selectedCategory;
  
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
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
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

  // --- PDF REPORT GENERATION ---
  void _showDatePickerForReport(LanguageProvider lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4CAF50), surface: Color(0xFF1E2746)),
            dialogBackgroundColor: const Color(0xFF1E2746),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _generateDailyReport(picked, lang);
    }
  }

  Future<void> _generateDailyReport(DateTime date, LanguageProvider lang) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('sales')
        .where('soldAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('soldAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('soldAt', descending: true)
        .get();

    final sales = snapshot.docs.map((e) => e.data()).toList();
    final totalAmount = sales.fold<double>(0, (sum, sale) => sum + (sale['totalPrice'] as num).toDouble());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('MEDLINE - Daily Sales Report', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 12),
              pw.Center(child: pw.Text(DateFormat('dd MMMM yyyy', 'en_US').format(date), style: const pw.TextStyle(fontSize: 20))),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 25),
              pw.Text('Total Transactions: ${sales.length}', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text('Total Revenue: ${_formatMoney(totalAmount)}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              pw.SizedBox(height: 35),
              if (sales.isEmpty)
                pw.Center(child: pw.Text('No sales recorded on this date', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey600)))
              else
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.grey500),
                  columnWidths: {0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(2)},
                  children: [
                    pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey300), children: ['Medicine', 'Qty', 'Unit Price', 'Total'].map((t) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))).toList()),
                    ...sales.map((sale) {
                      return pw.TableRow(children: [
                         pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(sale['medicineName']?.toString() ?? '')),
                         pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${sale['quantity']}')),
                         pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatMoney(sale['price']))),
                         pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_formatMoney(sale['totalPrice']))),
                      ]);
                    }),
                  ],
                ),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'Daily_Report_${DateFormat('dd-MMM-yyyy').format(date)}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2746),
          title: const Text('Report Generated', style: TextStyle(color: Colors.white)),
          content: Text('$fileName saved', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                 child: const Text('Close', style: TextStyle(color: Colors.white60))),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              onPressed: () { Navigator.pop(ctx); Printing.layoutPdf(onLayout: (_) => pdf.save(), name: fileName); },
            ),
             ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Open'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () { Navigator.pop(ctx); OpenFilex.open(file.path); },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // --- WIDGETS ---
  Widget _glassField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2), // Darker background for better contrast
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 1.5)),
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label, LanguageProvider lang) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedCategory = selected ? category : null),
        backgroundColor: Colors.black.withOpacity(0.2), // Dark background for unselected
        selectedColor: const Color(0xFF4DB6AC), // Solid teal for selected
        checkmarkColor: Colors.white, // White checkmark
        labelStyle: TextStyle(
          color: Colors.white, // Always white text for contrast
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? const Color(0xFF4DB6AC) : Colors.white.withOpacity(0.1))
        ),
      ),
    );
  }

  // --- DIALOGS (Modern) ---
  void _showAddMedicineDialog(LanguageProvider lang) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'tablets';
    DateTime? expiryDate;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2746).withOpacity(0.95), // Dark solid background
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.translate('add_medicine'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  _glassField(controller: nameController, label: lang.translate('medicine_name'), icon: Icons.medication),
                  const SizedBox(height: 16),
                  
                  // Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        dropdownColor: const Color(0xFF1A1F36),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: ['tablets', 'syrup', 'injection', 'ointment', 'drops'].map((c) => DropdownMenuItem(value: c, child: Text(lang.translate(c)))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v!),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _glassField(controller: priceController, label: lang.translate('price'), icon: Icons.attach_money, isNumber: true),
                  const SizedBox(height: 16),
                  _glassField(controller: quantityController, label: lang.translate('quantity'), icon: Icons.inventory, isNumber: true),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  InkWell(
                    onTap: () async {
                       final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now().add(const Duration(days: 365)),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                                            builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF4DB6AC), surface: Color(0xFF1E2746)), dialogBackgroundColor: const Color(0xFF1E2746)), child: child!),
                                          );
                       if (date != null) setDialogState(() => expiryDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(expiryDate != null ? DateFormat('dd/MM/yyyy').format(expiryDate!) : lang.translate('select_date'), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(children: [
                     Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.white)))),
                     const SizedBox(width: 12),
                     Expanded(child: ElevatedButton(
                       onPressed: () async {
                          if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                          await FirebaseFirestore.instance.collection('medicines').add({
                             'name': nameController.text.trim(),
                             'category': selectedCategory,
                             'price': double.parse(priceController.text),
                             'quantity': int.parse(quantityController.text),
                             'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
                             'description': descriptionController.text.trim(),
                             'createdAt': Timestamp.now(),
                          });
                          if (mounted) Navigator.pop(ctx);
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DB6AC), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showSellMedicineDialog(String id, Map<String, dynamic> data, LanguageProvider lang) {
     final qtyController = TextEditingController(text: '1');
     final price = data['price'] ?? 0.0;
     final currentQty = data['quantity'] ?? 0;
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: const Color(0xFF1E2746),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         title: Text(lang.translate('sell_medicine'), style: const TextStyle(color: Colors.white)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(data['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
             Text('Available: $currentQty', style: const TextStyle(color: Colors.white60)),
             const SizedBox(height: 16),
             TextField(
               controller: qtyController,
               keyboardType: TextInputType.number,
               style: const TextStyle(color: Colors.white),
               decoration: InputDecoration(
                 labelText: lang.translate('quantity'),
                 filled: true,
                 fillColor: Colors.black.withOpacity(0.2),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
               ),
             ),
           ],
         ),
         actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('cancel'), style: const TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                 final qty = int.tryParse(qtyController.text) ?? 0;
                 if (qty > 0 && qty <= currentQty) {
                    await FirebaseFirestore.instance.collection('sales').add({
                      'medicineId': id,
                      'medicineName': data['name'],
                      'quantity': qty,
                      'price': price,
                      'totalPrice': qty * (price as num).toDouble(),
                      'soldAt': Timestamp.now(),
                      'soldBy': FirebaseAuth.instance.currentUser?.uid,
                    });
                     await FirebaseFirestore.instance.collection('medicines').doc(id).update({
                       'quantity': currentQty - qty
                     });
                    if (mounted) Navigator.pop(ctx);
                 }
              },
              child: Text(lang.translate('sell')),
            ),
         ],
       ),
     );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tablets': return Colors.blueAccent;
      case 'syrup': return Colors.purpleAccent;
      case 'injection': return Colors.redAccent;
      case 'ointment': return Colors.orangeAccent;
      case 'drops': return Colors.tealAccent;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'tablets': return Icons.medication;
      case 'syrup': return Icons.local_drink;
      case 'injection': return Icons.vaccines;
      case 'ointment': return Icons.healing;
      case 'drops': return Icons.water_drop;
      default: return Icons.medical_services;
    }
  }

  String _formatMoney(dynamic amount) {
    final number = amount is num ? amount.toDouble() : 0.0;
    return '${NumberFormat('#,###', 'uz_UZ').format(number)} so\'m';
  }

  // --- PAGES ---
  Widget _buildMedicinesPage(LanguageProvider lang) {
    return Column(
      children: [
        Container(
           margin: const EdgeInsets.all(16),
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
           child: Column(
             children: [
               _glassField(controller: _searchController, label: lang.translate('search_medicine'), icon: Icons.search),
               const SizedBox(height: 12),
               SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: Row(
                   children: [
                     _buildCategoryChip(null, lang.translate('all'), lang),
                     _buildCategoryChip('tablets', lang.translate('tablets'), lang),
                     _buildCategoryChip('syrup', lang.translate('syrup'), lang),
                     _buildCategoryChip('injection', lang.translate('injection'), lang),
                     _buildCategoryChip('ointment', lang.translate('ointment'), lang),
                     _buildCategoryChip('drops', lang.translate('drops'), lang),
                   ],
                 ),
               ),
             ],
           ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedCategory == null 
                ? FirebaseFirestore.instance.collection('medicines').snapshots()
                : FirebaseFirestore.instance.collection('medicines').where('category', isEqualTo: _selectedCategory).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) return const SizedBox();
              
              final medicines = snapshot.data!.docs.where((doc) {
                 final data = doc.data() as Map<String, dynamic>;
                 return (data['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (medicines.isEmpty) {
                 return const Center(child: Text('No medicines found', style: TextStyle(color: Colors.white60)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final data = medicines[index].data() as Map<String, dynamic>;
                  final isLowStock = int.parse(data['quantity'].toString()) < 10;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2), // Darker card background
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _getCategoryColor(data['category'] ?? '').withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_getCategoryIcon(data['category'] ?? ''), color: _getCategoryColor(data['category'] ?? '')),
                      ),
                      title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${lang.translate(data['category'] ?? '')}  •  ${data['quantity']} ${lang.translate('pcs')}', style: TextStyle(color: isLowStock ? Colors.orangeAccent : Colors.white70)),
                          const SizedBox(height: 4),
                          Text('${_formatMoney(data['price'])}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart, color: Colors.white70),
                            onPressed: () => _showSellMedicineDialog(medicines[index].id, data, lang),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              // Confirm delete
                              showDialog(context: context, builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E2746),
                                title: const Text('Delete?', style: TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  TextButton(onPressed: () {
                                     FirebaseFirestore.instance.collection('medicines').doc(medicines[index].id).delete();
                                     Navigator.pop(ctx);
                                  }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ));
                            },
                          ),
                        ],
                      ),
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

  Widget _buildSalesPage(LanguageProvider lang) {
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance.collection('sales').orderBy('soldAt', descending: true).limit(50).snapshots(),
       builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sales = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
               final data = sales[index].data() as Map<String, dynamic>;
               final soldAt = (data['soldAt'] as Timestamp).toDate();
               
               return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                 child: ListTile(
                   leading: const Icon(Icons.shopping_bag, color: Colors.greenAccent),
                   title: Text(data['medicineName'] ?? '', style: const TextStyle(color: Colors.white)),
                   subtitle: Text('${DateFormat('dd/MM HH:mm').format(soldAt)}', style: const TextStyle(color: Colors.white54)),
                   trailing: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text('${data['quantity']} x ${_formatMoney(data['price'])}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                       Text(_formatMoney(data['totalPrice']), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
               );
            },
          );
       },
     );
  }
  
  Widget _buildStatisticsPage(LanguageProvider lang) {
     return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('sales').get(),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           
           final sales = snapshot.data!.docs;
           final now = DateTime.now();
           final todayStart = DateTime(now.year, now.month, now.day);
           
           double todaySales = 0;
           double totalSales = 0;
           
           for(var s in sales) {
             final data = s.data() as Map<String, dynamic>;
             final price = (data['totalPrice'] ?? 0).toDouble();
             totalSales += price;
             if ((data['soldAt'] as Timestamp).toDate().isAfter(todayStart)) {
                todaySales += price;
             }
           }
           
           return Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                  _statCard('Today\'s Revenue', _formatMoney(todaySales), Icons.today, Colors.blueAccent),
                  const SizedBox(height: 16),
                  _statCard('Total Revenue', _formatMoney(totalSales), Icons.attach_money, Colors.greenAccent),
               ],
             ),
           );
        },
     );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
       ),
       child: Row(
         children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white60, fontSize: 16)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            )
         ],
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
            title: const Text('Pharmacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            actions: [
               const ThemeIconButton(), // Theme toggle
               IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: () => _showDatePickerForReport(lang), tooltip: 'Hisobot'),
               IconButton(
                 icon: const Icon(Icons.logout_rounded, color: Colors.white),
                 onPressed: () async {
                   await FirebaseAuth.instance.signOut();
                   if (context.mounted) {
                     Navigator.of(context).pushAndRemoveUntil(
                       MaterialPageRoute(builder: (_) => const LoginScreen()),
                       (route) => false,
                     );
                   }
                 },
                 tooltip: 'Chiqish',
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
                    colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A), Color(0xFF0F1E3C)],
                  ),
                ),
              ),
              ...List.generate(6, (i) => _floatingParticle(i)),
              
              SafeArea(
                child: Column(
                  children: [
                     Expanded(
                        child: _selectedIndex == 0 ? _buildMedicinesPage(lang) :
                               _selectedIndex == 1 ? _buildSalesPage(lang) :
                               _buildStatisticsPage(lang)
                     ),
                  ],
                ),
              ),

              Positioned(
                 bottom: 0,
                 left: 0,
                 right: 0,
                 child: Container(
                   margin: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                      color: const Color(0xFF1E2746).withOpacity(0.95), // Solid dark
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(24),
                     child: BottomNavigationBar(
                       currentIndex: _selectedIndex,
                       onTap: (i) => setState(() => _selectedIndex = i),
                       backgroundColor: Colors.transparent,
                       selectedItemColor: const Color(0xFF4DB6AC),
                       unselectedItemColor: Colors.white54, // Better contrast than grey
                       showUnselectedLabels: false,
                       elevation: 0,
                       items: [
                         BottomNavigationBarItem(icon: const Icon(Icons.medication), label: lang.translate('medicines')),
                         BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart), label: lang.translate('sales')),
                         BottomNavigationBarItem(icon: const Icon(Icons.bar_chart), label: lang.translate('statistics')),
                       ],
                     ),
                   ),
                 ),
              )
            ],
          ),
          floatingActionButton: _selectedIndex == 0 ? Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              onPressed: () => _showAddMedicineDialog(lang),
              backgroundColor: const Color(0xFF4DB6AC),
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ) : null,
        );
      },
    );
  }
}