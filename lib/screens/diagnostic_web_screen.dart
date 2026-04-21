// lib/screens/diagnostic_web_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';

class DiagnosticWebScreen extends StatefulWidget {
  const DiagnosticWebScreen({super.key});

  @override
  State<DiagnosticWebScreen> createState() => _DiagnosticWebScreenState();
}

class _DiagnosticWebScreenState extends State<DiagnosticWebScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<String> selectedSymptoms = [];
  List<String> allSymptoms = [];
  List<Map<String, dynamic>> diseases = [];
  String _sortBy = 'percentage';
  bool _showOnlyHighRisk = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    diseases = _getDiseases();
    allSymptoms = _getAllSymptoms();
    setState(() {});
  }

  List<String> _getAllSymptoms() {
    final Set<String> set = {};
    for (var d in diseases) {
      set.addAll(d['symptoms'] as List<String>);
    }
    return set.toList()..sort();
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (selectedSymptoms.contains(symptom)) {
        selectedSymptoms.remove(symptom);
      } else {
        selectedSymptoms.add(symptom);
      }
    });
  }

  void _clearAll() {
    setState(() {
      selectedSymptoms.clear();
      _searchController.clear();
      _showOnlyHighRisk = false;
    });
  }

  List<Map<String, dynamic>> _getResults() {
    if (selectedSymptoms.isEmpty) return [];

    var results = diseases.map((d) {
      final matched = (d['symptoms'] as List<String>)
          .where((s) => selectedSymptoms.contains(s))
          .toList();
      final percentage = matched.isNotEmpty
          ? (matched.length / selectedSymptoms.length * 100).round()
          : 0;
      final coverage = matched.isNotEmpty
          ? (matched.length / (d['symptoms'] as List).length * 100).round()
          : 0;
      // Weighted score: prioritizing how many of the *selected* symptoms explain the disease
      // AND how much of the disease is explained.
      return {...d, 'matched': matched, 'percentage': percentage, 'coverage': coverage};
    }).where((r) => r['percentage'] > 0).toList();

    if (_showOnlyHighRisk) {
      results = results.where((r) => r['percentage'] >= 60).toList();
    }

    switch (_sortBy) {
      case 'percentage':
        results.sort((a, b) => b['percentage'].compareTo(a['percentage']));
        break;
      case 'name':
        results.sort((a, b) => a['name'].compareTo(b['name']));
        break;
    }

    return results;
  }

  Color _getColor(int percentage) {
    if (percentage >= 80) return Colors.redAccent;
    if (percentage >= 60) return Colors.orangeAccent;
    if (percentage >= 40) return Colors.amberAccent;
    return Colors.greenAccent;
  }
  
  // --- ANIMATIONS & VISUALS ---
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

  @override
  Widget build(BuildContext context) {
    final results = _getResults();
    final filteredSymptoms = allSymptoms.where((s) {
      if (_searchController.text.isEmpty) return true;
      return s.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tibbiy Diagnostika", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("30+ kasallik bazasi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (selectedSymptoms.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text('${selectedSymptoms.length}', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _clearAll, tooltip: 'Tozalash'),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
             decoration: const BoxDecoration(
                gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Color(0xFF0A7075), Color(0xFF083D56), Color(0xFF0A2D4A)],
                ),
             ),
          ),
          ...List.generate(6, (i) => _floatingParticle(i)),
          SafeArea(
            child: Row(
               children: [
                  // LEFT PANEL: Symptoms
                  Expanded(
                     flex: 3,
                     child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                           children: [
                              // Search
                              Container(
                                 decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                 ),
                                 child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                       hintText: "Simptom qidirish...",
                                       hintStyle: const TextStyle(color: Colors.white54),
                                       prefixIcon: const Icon(Icons.search, color: Colors.white54),
                                       suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () { _searchController.clear(); setState(() {}); }) : null,
                                       border: InputBorder.none,
                                       contentPadding: const EdgeInsets.all(16),
                                    ),
                                 ),
                              ),
                              const SizedBox(height: 16),
                              // Selected
                              if (selectedSymptoms.isNotEmpty) ...[
                                 Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                                    child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                             Text("Tanlangan: ${selectedSymptoms.length} ta", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                             TextButton.icon(onPressed: _clearAll, icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), label: const Text("Tozalash", style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                                          ]),
                                          const SizedBox(height: 8),
                                          Wrap(
                                             spacing: 6, runSpacing: 6,
                                             children: selectedSymptoms.map((s) => Chip(
                                                label: Text(s, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                                onDeleted: () => _toggleSymptom(s),
                                                deleteIconColor: Colors.white70,
                                                backgroundColor: const Color(0xFF4DB6AC).withOpacity(0.3),
                                                side: BorderSide.none,
                                             )).toList(),
                                          ),
                                       ],
                                    ),
                                 ),
                                 const SizedBox(height: 16),
                              ],
                              // Grid
                              Expanded(
                                 child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                       maxCrossAxisExtent: 250, childAspectRatio: 3.5, crossAxisSpacing: 8, mainAxisSpacing: 8,
                                    ),
                                    itemCount: filteredSymptoms.length,
                                    itemBuilder: (ctx, i) {
                                       final symptom = filteredSymptoms[i];
                                       final isSelected = selectedSymptoms.contains(symptom);
                                       return GestureDetector(
                                          onTap: () => _toggleSymptom(symptom),
                                          child: AnimatedContainer(
                                             duration: const Duration(milliseconds: 200),
                                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                             decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF4DB6AC).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: isSelected ? const Color(0xFF4DB6AC) : Colors.white.withOpacity(0.1)),
                                             ),
                                             child: Row(
                                                children: [
                                                   Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: isSelected ? const Color(0xFF4DB6AC) : Colors.white24),
                                                   const SizedBox(width: 8),
                                                   Expanded(child: Text(symptom, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                                                ],
                                             ),
                                          ),
                                       );
                                    },
                                 ),
                              ),
                           ],
                        ),
                     ),
                  ),
                  // RIGHT PANEL: Results
                  Expanded(
                     flex: 2,
                     child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                           color: const Color(0xFF1E2746).withOpacity(0.6),
                           borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.white.withOpacity(0.1)),
                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                        ),
                        child: Column(
                           children: [
                              Container(
                                 padding: const EdgeInsets.all(20),
                                 decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                 ),
                                 child: Column(
                                    children: [
                                       Row(children: [
                                          const Icon(Icons.analytics, color: Colors.white, size: 24),
                                          const SizedBox(width: 12),
                                          const Text("Natijalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                          const Spacer(),
                                          if (results.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF4DB6AC).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('${results.length}', style: const TextStyle(color: Color(0xFF4DB6AC), fontSize: 12, fontWeight: FontWeight.bold))),
                                       ]),
                                       if (results.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Row(children: [
                                             Expanded(
                                                child: Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 12),
                                                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                                   child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                         value: _sortBy,
                                                         dropdownColor: const Color(0xFF1E2746),
                                                         icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                                         style: const TextStyle(color: Colors.white, fontSize: 12),
                                                         items: const [DropdownMenuItem(value: 'percentage', child: Text('Foiziga ko\'ra')), DropdownMenuItem(value: 'name', child: Text('Nomiga ko\'ra'))],
                                                         onChanged: (v) => setState(() => _sortBy = v!),
                                                      ),
                                                   ),
                                                ),
                                             ),
                                             const SizedBox(width: 8),
                                             InkWell(
                                                onTap: () => setState(() => _showOnlyHighRisk = !_showOnlyHighRisk),
                                                child: Container(
                                                   padding: const EdgeInsets.all(10),
                                                   decoration: BoxDecoration(color: _showOnlyHighRisk ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: _showOnlyHighRisk ? Colors.redAccent : Colors.white.withOpacity(0.1))),
                                                   child: Icon(Icons.warning_amber, color: _showOnlyHighRisk ? Colors.redAccent : Colors.white70, size: 20),
                                                ),
                                             ),
                                          ]),
                                       ],
                                    ],
                                 ),
                              ),
                              Expanded(
                                 child: results.isEmpty 
                                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.medical_information, size: 48, color: Colors.white24), const SizedBox(height: 16), const Text("Simptomlarni tanlang", style: TextStyle(fontSize: 16, color: Colors.white54))]))
                                    : ListView.builder(
                                       padding: const EdgeInsets.all(16),
                                       itemCount: results.length,
                                       itemBuilder: (ctx, i) {
                                          final result = results[i];
                                          final percentage = result['percentage'] as int;
                                          final color = _getColor(percentage);
                                          final isTop = i == 0;
                                          return Container(
                                             margin: const EdgeInsets.only(bottom: 12),
                                             decoration: BoxDecoration(
                                                color: isTop ? color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: isTop ? color.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                                             ),
                                             child: Theme(
                                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white70)),
                                                child: ExpansionTile(
                                                   leading: Stack(alignment: Alignment.center, children: [
                                                      SizedBox(width: 40, height: 40, child: CircularProgressIndicator(value: percentage / 100, strokeWidth: 3, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(color))),
                                                      Text('${percentage}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                                   ]),
                                                   title: Text(result['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                                   subtitle: Text(result['doctor'], style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                                   children: [
                                                      Padding(
                                                         padding: const EdgeInsets.all(16),
                                                         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                            const Text("Mos simptomlar:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                                            const SizedBox(height: 8),
                                                            Wrap(spacing: 6, runSpacing: 6, children: (result['matched'] as List).map<Widget>((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(s, style: TextStyle(fontSize: 10, color: color)))).toList()),
                                                            const SizedBox(height: 12),
                                                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.info_outline, color: Colors.blueAccent, size: 20), const SizedBox(width: 8), Expanded(child: Text('Tavsiya: ${result['doctor']}ga murojaat qiling', style: const TextStyle(fontSize: 11, color: Colors.blueAccent)))])),
                                                         ]),
                                                      ),
                                                   ],
                                                ),
                                             ),
                                          );
                                       },
                                    ),
                              ),
                              if (results.isNotEmpty)
                                 Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
                                    child: const Row(children: [Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 20), SizedBox(width: 8), Expanded(child: Text('Bu faqat dastlabki taxmin. Aniq tashxis uchun shifokorga murojaat qiling!', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)))]),
                                 ),
                           ],
                        ),
                     ),
                  ),
               ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DATA ---
  List<Map<String, dynamic>> _getDiseases() {
    return [
      {"name": "Gripp", "symptoms": ["Yuqori harorat", "Bosh og'rig'i", "Mushak og'rig'i", "Yo'tal", "Burun bitishi", "Charchoq", "Terga to'kilish", "Tomoq og'rig'i", "Holsizlik", "Zaiflik", "Aksirish", "Ko'z qizarishi", "Ishtahasizlik", "Tunda ter", "Ko'ngil aynash"], "doctor": "Umumiy amaliyot shifokori"},
      {"name": "COVID-19", "symptoms": ["Yuqori harorat", "Quruq yo'tal", "Ta'm va hidni yo'qotish", "Nafas qisilishi", "Charchoq", "Bosh og'rig'i", "Mushak og'rig'i", "Tomoq og'rig'i", "Ich ketish", "Ko'ngil aynash", "Burun bitishi", "Ko'z qizarishi", "Holsizlik", "Teri toshmalari", "Ko'krak og'rig'i"], "doctor": "Infeksionist"},
      {"name": "Bronxit", "symptoms": ["Yo'tal", "Balg'am chiqarish", "Ko'krak og'rig'i", "Nafas qisilishi", "Yuqori harorat", "Charchoq", "Tomoq og'rig'i", "Bosh og'rig'i", "Horg'in", "Nafas olishda og'riq", "Zaiflik", "Terlash", "Burun oqishi", "Ko'krak siqilishi", "Holsizlik"], "doctor": "Pulmonolog"},
      {"name": "Pnevmoniya", "symptoms": ["Yuqori harorat", "Yo'tal", "Ko'krak og'rig'i", "Nafas qisilishi", "Terga to'kilish", "Balg'am chiqarish", "Tez nafas olish", "Zaiflik", "Ko'ngil aynash", "Charchoq", "Bosh og'rig'i", "Holsizlik", "Qusish", "Ishtahasizlik", "Mushak og'rig'i"], "doctor": "Pulmonolog"},
      {"name": "Astma", "symptoms": ["Nafas qisilishi", "Horg'in", "Ko'krak siqilishi", "Yo'tal", "Tunda yomonlashish", "Nafas tor", "Tez nafas olish", "Charchoq", "Zaiflik", "Ko'krak og'rig'i", "Uyqu buzilishi", "Xirillash", "Nafas olish qiyinlashishi", "Sovuqdan yomonlashish", "Jismoniy yuklamada yomonlashish"], "doctor": "Pulmonolog"},
      {"name": "Gipertoniya", "symptoms": ["Bosh og'rig'i", "Bosh aylanishi", "Ko'z oldida qoralanish", "Quloq shovqini", "Yurak urishi tezlashishi", "Ko'krak og'rig'i", "Nafas qisilishi", "Ko'z qizarishi", "Burun qon ketishi", "Charchoq", "Zaiflik", "Uyqu buzilishi", "Terlash", "Qo'rquv hissi", "Holsizlik"], "doctor": "Kardiolog"},
      {"name": "Gipotoniya", "symptoms": ["Bosh aylanishi", "Zaiflik", "Holsizlik", "Ko'z qoralanishi", "Hushdan ketish", "Charchoq", "Ko'ngil aynash", "Teri rangparlik", "Sovuq ter", "Tez nafas olish", "Yurak sekin urishi", "Bosh og'rig'i", "Mushak zaiflanishi", "Koordinatsiya buzilishi", "Konsentratsiya buzilishi"], "doctor": "Kardiolog"},
      {"name": "Angina", "symptoms": ["Ko'krak og'rig'i", "Nafas tor", "Chap qo'lga tarqaluvchi og'riq", "Ko'krak siqilishi", "Terga to'kilish", "Ko'ngil aynash", "Charchoq", "Zaiflik", "Bosh aylanishi", "Yurak urishi buzilishi", "Qo'rquv hissi", "Nafas qisilishi", "Jag' og'rig'i", "Orqa og'rig'i", "Terlash"], "doctor": "Kardiolog"},
      {"name": "Miokard infarkti", "symptoms": ["Kuchli ko'krak og'rig'i", "Terga to'kilish", "Qo'rquv hissi", "Chap qo'lga og'riq", "Ko'ngil aynash", "Qusish", "Nafas qisilishi", "Bosh aylanishi", "Ko'z oldida qoralanish", "Teri rangparlik", "Sovuq ter", "Yurak urishi buzilishi", "Jag' og'rig'i", "Orqa og'rig'i", "Zaiflik"], "doctor": "Tez yordam"},
      {"name": "Gastrit", "symptoms": ["Oshqozon og'rig'i", "Ko'ngil aynash", "Qusish", "Shishish hissi", "Ishtahasizlik", "Burish", "Oshqozon kuyishi", "Ovqatdan keyin og'riq", "Yomon nafas", "Tukuruq ko'payishi", "Zaiflik", "Qorin og'rig'i", "Och qolgan og'riq", "Kuyish hissi", "Charchoq"], "doctor": "Gastroenterolog"},
      {"name": "Oshqozon yarasi", "symptoms": ["Oshqozon og'rig'i", "Qora axlat", "Qusish", "Ko'ngil aynash", "Vazn kamayishi", "Ishtahasizlik", "Shishish", "Ovqatdan keyin og'riq", "Och qolgan og'riq", "Qonli qusish", "Oshqozon kuyishi", "Burish", "Zaiflik", "Charchoq", "Teri rangparlik"], "doctor": "Gastroenterolog"},
      {"name": "Pankreatit", "symptoms": ["Yuqori qorin og'rig'i", "Qusish", "Orqaga tarqaluvchi og'riq", "Ko'ngil aynash", "Yuqori harorat", "Yurak tez urishi", "Qorin shishi", "Ich ketish", "Yog'li axlat", "Vazn kamayishi", "Ishtahasizlik", "Zaiflik", "Sariqlik", "Terlash", "Holsizlik"], "doctor": "Gastroenterolog"},
      {"name": "Qandli diabet 1-tur", "symptoms": ["Ko'p ichish", "Tez-tez siydik", "Vazn kamayishi", "Charchoq", "Zaiflik", "Ko'rish buzilishi", "Yaralarning sekin bitishi", "Teri qichishi", "Ko'ngil aynash", "Qusish", "Qorin og'rig'i", "Og'iz quruqligi", "Tez nafas olish", "Holsizlik", "Ongni yo'qotish"], "doctor": "Endokrinolog"},
      {"name": "Qandli diabet 2-tur", "symptoms": ["Ko'p ichish", "Tez-tez siydik", "Vazn ortishi", "Charchoq", "Ko'rish buzilishi", "Yaralarning sekin bitishi", "Teri qichishi", "Teri infeksiyalari", "Oyoqlar uyushishi", "Ko'z oldida qoralanish", "Zaiflik", "Holsizlik", "Ishtaha ortishi", "Og'iz quruqligi", "Mushak zaiflanishi"], "doctor": "Endokrinolog"},
      {"name": "Qalqonsimon bez giperfunksiyasi", "symptoms": ["Vazn kamayishi", "Terlash", "Qo'llar titrashi", "Yurak tez urishi", "Asabiylık", "Uyqu buzilishi", "Ko'z bo'rtishi", "Charchoq", "Ko'p ovqat yeyish", "Ich ketish", "Ko'z yonishi", "Ko'z qichishi", "Mushak zaiflanishi", "Soch to'kilishi", "Issiqlikka sezgirlik"], "doctor": "Endokrinolog"},
      {"name": "Qalqonsimon bez gipofunksiyasi", "symptoms": ["Vazn ortishi", "Charchoq", "Soch to'kilishi", "Quruq teri", "Sovuqqa sezgirlik", "Qabziyat", "Depressiya", "Mushak og'rig'i", "Bo'g'im og'rig'i", "Yurak sekin urishi", "Xotira buzilishi", "Yuz shishi", "Ovoz o'zgarishi", "Zaiflik", "Holsizlik"], "doctor": "Endokrinolog"},
      {"name": "Pielonefrit", "symptoms": ["Yuqori harorat", "Bel og'rig'i", "Og'riqli siydik", "Tez-tez siydik", "Ko'ngil aynash", "Qusish", "Sovitadigan harorat", "Charchoq", "Qonli siydik", "Loyqa siydik", "Yomon hidli siydik", "Bosh og'rig'i", "Mushak og'rig'i", "Zaiflik", "Holsizlik"], "doctor": "Urolog"},
      {"name": "Buyrak toshi", "symptoms": ["Bel og'rig'i", "Qonli siydik", "Og'riqli siydik", "Tez-tez siydik", "Ko'ngil aynash", "Qusish", "Yuqori harorat", "Sovitadigan harorat", "Qorin og'rig'i", "Past qorin og'rig'i", "Siydik ushlab turish", "Loyqa siydik", "Yomon hidli siydik", "Charchoq", "Zaiflik"], "doctor": "Urolog"},
      {"name": "Sistit", "symptoms": ["Og'riqli siydik", "Tez-tez siydik", "Past qorin og'rig'i", "Qonli siydik", "Loyqa siydik", "Yomon hidli siydik", "Siydik yonishi", "Siydik yo'li og'rig'i", "Yuqori harorat", "Bel og'rig'i", "Ko'ngil aynash", "Charchoq", "Zaiflik", "Siydik ushlab turish", "Holsizlik"], "doctor": "Urolog"},
      {"name": "Migren", "symptoms": ["Kuchli bosh og'rig'i", "Ko'ngil aynash", "Qusish", "Yorug'likka sezgirlik", "Tovushga sezgirlik", "Ko'rish buzilishi", "Hidga sezgirlik", "Bosh aylanishi", "Zaiflik", "Yuz rangparlik", "Charchoq", "Holsizlik", "Konsentratsiya buzilishi", "Uyqu buzilishi", "Og'riq bir tomonda"], "doctor": "Nevrolog"},
      {"name": "Insult", "symptoms": ["Yuz asimmetriyasi", "Qo'l-oyoq zaiflanishi", "Nutq buzilishi", "Ko'rish buzilishi", "Bosh aylanishi", "Muvozanat buzilishi", "Koordinatsiya buzilishi", "Bosh og'rig'i", "Ko'ngil aynash", "Qusish", "Chalkashlik", "Ongni yo'qotish", "Hushdan ketish", "Tutilmalar", "Yutish qiyinlashishi"], "doctor": "Tez yordam"},
      {"name": "Depressiya", "symptoms": ["G'amginlik", "Qiziqishlarning yo'qolishi", "Uyqu buzilishi", "Ishtahasizlik", "Charchoq", "Zaiflik", "Konsentratsiya buzilishi", "O'z-o'zini ayblanish", "O'lim fikrlari", "Vazn o'zgarishi", "Mushak og'rig'i", "Bosh og'rig'i", "Ijtimoiy izolyatsiya", "Holsizlik", "Umidsizlik"], "doctor": "Psixiatr"},
      {"name": "Tashvish buzilishi", "symptoms": ["Doimiy tashvish", "Yurak urishi", "Terlash", "Qo'llar titrashi", "Nafas qisilishi", "Bosh aylanishi", "Ko'ngil aynash", "Qorin noqulayligi", "Uyqu buzilishi", "Charchoq", "Asabiylık", "Konsentratsiya buzilishi", "Mushak tarangligi", "Qo'rquv hissi", "Ko'z oldida qoralanish"], "doctor": "Psixiatr"},
      {"name": "Qizamiq", "symptoms": ["Teri toshmalari", "Yo'tal", "Ko'z qizarishi", "Yuqori harorat", "Burun oqishi", "Ko'z yoshlanishi", "Og'izda oqlik", "Bosh og'rig'i", "Mushak og'rig'i", "Charchoq", "Ishtahasizlik", "Ko'ngil aynash", "Qusish", "Ich ketish", "Zaiflik"], "doctor": "Pediatr"},
      {"name": "Qizilcha", "symptoms": ["Pushti toshma", "Limfa tugunlari shishi", "Yuqori harorat", "Bosh og'rig'i", "Bo'g'im og'rig'i", "Ko'z qizarishi", "Tomoq og'rig'i", "Burun oqishi", "Ko'ngil aynash", "Charchoq", "Mushak og'rig'i", "Qichish", "Bo'yin shishi", "Zaiflik", "Holsizlik"], "doctor": "Infeksionist"},
      {"name": "Suv chechak", "symptoms": ["Qichqiriq toshma", "Pufakchalar", "Qichish", "Yuqori harorat", "Bosh og'rig'i", "Mushak og'rig'i", "Charchoq", "Ishtahasizlik", "Qorin og'rig'i", "Ko'ngil aynash", "Tomoq og'rig'i", "Og'izda yaralar", "Zaiflik", "Holsizlik", "Teri zararlari"], "doctor": "Pediatr"},
      {"name": "Allergik rinit", "symptoms": ["Burun oqishi", "Aksirish", "Ko'z yoshlanishi", "Burun qichishi", "Burun bitishi", "Ko'z qichishi", "Ko'z qizarishi", "Bosh og'rig'i", "Tomoq qichishi", "Yo'tal", "Charchoq", "Hid sezish buzilishi", "Ko'z shishi", "Quloq bitishi", "Burun sezgirligi"], "doctor": "Allergolog"},
      {"name": "Tonzillit", "symptoms": ["Tomoq og'rig'i", "Yuqori harorat", "Bo'g'izda oqlik", "Yutish qiyinlashishi", "Limfa tugunlari shishi", "Bosh og'rig'i", "Quloq og'rig'i", "Yomon nafas", "Charchoq", "Ovoz o'zgarishi", "Bo'yin og'rig'i", "Ishtahasizlik", "Zaiflik", "Mushak og'rig'i", "Terga to'kilish"], "doctor": "LOR"},
      {"name": "Gemorroy", "symptoms": ["Anal og'riq", "Qon ketishi", "Tugunlar", "Qichish", "Yonish", "Shish", "Axlat chiqarishda og'riq", "Yot jism hissi", "Shilimshiq ajralishi", "Tugunlar tashqariga chiqishi", "O'tirish og'riq", "Qabziyat", "Noqulaylik", "Qorin og'rig'i", "Charchoq"], "doctor": "Proktolog"},
      {"name": "Revmatoid artrit", "symptoms": ["Bo'g'im og'rig'i", "Ertalabki qotishish", "Simmetrik shikastlanish", "Bo'g'im shishi", "Qizarish", "Issiqlik", "Charchoq", "Vazn kamayishi", "Past harorat", "Bo'g'im deformatsiyasi", "Harakat cheklanishi", "Zaiflik", "Ishtahasizlik", "Depressiya", "Uyqu buzilishi"], "doctor": "Revmatolog"}
    ];
  }
}