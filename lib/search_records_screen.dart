import 'package:flutter/material.dart';
import 'app_colorspart2.dart';

class SearchRecordsScreen extends StatefulWidget {
  const SearchRecordsScreen({super.key});

  @override
  State<SearchRecordsScreen> createState() => _SearchRecordsScreenState();
}

class _SearchRecordsScreenState extends State<SearchRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedCategory = "All";

  // بيانات وهمية بسيطة لإظهار منطق الشاشة
  List<String> _recentSearches = [
    "Blood Test Results",
    "Dr. Sarah Johnson",
    "MRI Knee",
    "Vitamin D Prescription",
  ];

  final List<Map<String, dynamic>> _allRecords = [
    {
      "title": "Antibiotic Prescription",
      "type": "Prescription",
      "date": "Nov 15, 2025",
      "doctor": "Dr. Sarah Johnson",
    },
    {
      "title": "Complete Blood Count (CBC)",
      "type": "Lab Test",
      "date": "Nov 20, 2025",
      "doctor": "City Lab",
    },
    {
      "title": "Chest X-Ray",
      "type": "Imaging",
      "date": "Nov 10, 2025",
      "doctor": "Radiology Dept",
    },
    {
      "title": "Hypertension Diagnosis",
      "type": "History",
      "date": "Jan 2023",
      "doctor": "Dr. Michael Chen",
    },
    {
      "title": "Blood Pressure Meds",
      "type": "Prescription",
      "date": "Oct 28, 2025",
      "doctor": "Dr. Michael Chen",
    },
    {
      "title": "Lipid Panel",
      "type": "Lab Test",
      "date": "Nov 18, 2025",
      "doctor": "City Lab",
    },
  ];

  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      _performSearch();
    });
  }

  void _performSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allRecords.where((record) {
          bool matchesQuery =
              record['title'].toString().toLowerCase().contains(query) ||
              record['type'].toString().toLowerCase().contains(query) ||
              record['doctor'].toString().toLowerCase().contains(
                query,
              ); // 💡 البحث في الطبيب أيضاً
          bool matchesCategory =
              _selectedCategory == "All" || record['type'] == _selectedCategory;
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _addToRecent(String query) {
    if (query.trim().isEmpty) return; // منع إضافة بحث فارغ
    if (!_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search records...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(color: AppColors.textDarkTeal),
          onSubmitted: (value) => _addToRecent(value),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: _buildFilterChips(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isSearching ? _buildSearchResults() : _buildRecentSearches(),
      ),
    );
  }

  // === 1. الفلاتر ===
  Widget _buildFilterChips() {
    // ... (الكود لم يتغير)
    final categories = [
      "All",
      "Prescription",
      "Lab Test",
      "Imaging",
      "History",
    ];
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                _selectedCategory = selected ? cat : "All";
                _performSearch();
              });
            },
            backgroundColor: AppColors.background,
            selectedColor: AppColors.primaryCyan.withOpacity(0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.textDarkTeal : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryCyan
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  // === 2. عمليات البحث السابقة ===
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Text(
          "No recent searches",
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Searches",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _recentSearches.clear()),
              child: const Text(
                "Clear All",
                style: TextStyle(color: AppColors.emergencyRed, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 💡 استخدام Flexible بدلاً من Expanded لمرونة أكبر
        Flexible(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  _recentSearches[index],
                  style: const TextStyle(color: Colors.black87),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () =>
                      setState(() => _recentSearches.removeAt(index)),
                ),
                onTap: () {
                  _searchController.text = _recentSearches[index];
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // === 3. نتائج البحث (مع التنقل) ===
  Widget _buildSearchResults() {
    if (_searchController.text.trim().length < 2) {
      // 🛑 رسالة تنبيه/Validation: اطلب من المستخدم إدخال المزيد
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text(
              "Start typing to search your records.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Text(
              "Please enter at least 2 letters.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      // 🛑 رسالة تنبيه: لا توجد نتائج
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            Text(
              "No results found for \"${_searchController.text}\"",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              "Try checking your spelling or changing the filter.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // 💡 عرض النتائج
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final record = _searchResults[index];
        return GestureDetector(
          onTap: () {
            _addToRecent(record['title']);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDarkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${record['type']} • ${record['date']}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
