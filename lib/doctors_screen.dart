import 'package:flutter/material.dart';
import 'app_colorspart2.dart';
import 'doctor_details_screen.dart'; // <--- تأكدي إن السطر ده موجود ومش معمول له كومنت

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  // 1. متغير لتحديد الفلتر المختار حالياً (الافتراضي هو Rating)
  String selectedFilter = 'Rating';

  // بيانات الأطباء
  final List<Map<String, dynamic>> doctors = [
    {
      'id': 1,
      'name': 'Dr. Michael Chen',
      'specialty': 'Cardiologist',
      'rating': 4.9,
      'reviews': 127,
      'price': 85,
      'location': 'City Hospital',
      'image': 'assets/Item2.jpg',
      'isTopRated': true,
    },
    {
      'id': 2,
      'name': 'Dr. Sarah Ahmed',
      'specialty': 'General Practitioner',
      'rating': 4.8,
      'reviews': 94,
      'price': 60,
      'location': 'Health Center',
      'image': 'assets/Item3.jpg',
      'isTopRated': false,
    },
    {
      'id': 3,
      'name': 'Dr. James Wilson',
      'specialty': 'Pediatrician',
      'rating': 4.7,
      'reviews': 156,
      'price': 70,
      'location': 'Kids Clinic',
      'image': 'assets/Item2.jpg',
      'isTopRated': false,
    },
    {
      'id': 4,
      'name': 'Dr. Emily Rodriguez',
      'specialty': 'Dermatologist',
      'rating': 4.9,
      'reviews': 203,
      'price': 95,
      'location': 'Skin Care Clinic',
      'image': 'assets/Item3.jpg',
      'isTopRated': true,
    },
    {
      'id': 5,
      'name': 'Dr. David Park',
      'specialty': 'Orthopedic Surgeon',
      'rating': 4.6,
      'reviews': 88,
      'price': 110,
      'location': 'Orthopedic Center',
      'image': 'assets/Item2.jpg',
      'isTopRated': false,
    },
    {
      'id': 6,
      'name': 'Dr. Lisa Thompson',
      'specialty': 'Neurologist',
      'rating': 4.8,
      'reviews': 142,
      'price': 100,
      'location': 'Neuro Clinic',
      'image': 'assets/Item3.jpg',
      'isTopRated': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Find Doctors",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- 1. Search Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.primaryTeal),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search doctor or specialty",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- 2. Filters (Active Logic) ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Rating", Icons.star_border),
                  const SizedBox(width: 10),
                  _buildFilterChip("Price", Icons.attach_money),
                  const SizedBox(width: 10),
                  _buildFilterChip("Distance", Icons.location_on_outlined),
                  const SizedBox(width: 10),
                  _buildFilterChip(
                    "Specialty",
                    Icons.medical_services_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. Doctors List ---
            Expanded(
              child: ListView.builder(
                itemCount: doctors.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  return _buildDoctorCard(doctors[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget زر الفلتر التفاعلي ---
  Widget _buildFilterChip(String label, IconData icon) {
    // التحقق هل هذا الزر هو المختار حالياً؟
    bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        // عند الضغط، نحدث الحالة ليصبح هذا الزر هو المختار
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ), // حركة ناعمة عند تغيير اللون
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // إذا كان مختار: لون تيل (أخضر مزرق). إذا لا: أبيض مع حدود رمادية
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryTeal)
              : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              // تغيير لون الأيقونة حسب الحالة
              color: isSelected ? Colors.white : AppColors.primaryTeal,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                // تغيير لون النص حسب الحالة
                color: isSelected ? Colors.white : AppColors.primaryTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget كارت الدكتور ---
  Widget _buildDoctorCard(Map<String, dynamic> doc) {
    bool isTopRated = doc['isTopRated'] == true;

    Color bgColor = isTopRated
        ? AppColors.primaryTeal
        : const Color(0xFFD6EBF2);
    Color textColor = isTopRated ? Colors.white : AppColors.textDarkTeal;
    Color subTextColor = isTopRated ? Colors.white70 : Colors.grey;

    return GestureDetector(
      onTap: () {
        // ============ التعديل هنا فقط ============
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailsScreen(
              doctor: doc,
            ), // نبعت بيانات الدكتور للصفحة الجديدة
          ),
        );
        // =======================================
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(doc['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isTopRated)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc['specialty'],
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(
                        4,
                        (index) => const Icon(
                          Icons.star,
                          color: Color(0xFFFFB84C),
                          size: 14,
                        ),
                      ),
                      const Icon(
                        Icons.star_border,
                        color: Color(0xFFFFB84C),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "(${doc['reviews']})",
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: subTextColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        doc['location'],
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 70),
                Text(
                  "\$${doc['price']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
