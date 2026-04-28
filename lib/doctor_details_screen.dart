import 'package:flutter/material.dart';
import 'app_colorspart2.dart';
import 'booking_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  // ============ 1. تجهيز البيانات (محاكاة الباك إند) ============
  // هذه القائمة تحاكي الـ JSON اللي هيرجعلك من الـ API
  // لما تشتغلي باك إند، هتمسحي البيانات دي وتخلي القائمة تيجي من الـ Model
  final List<Map<String, dynamic>> reviews = const [
    {
      "name": "Sarah Johnson",
      "date": "Nov 28, 2024",
      "rating": 5,
      "comment":
          "Dr. Chen is exceptional! He took the time to explain everything and made me feel comfortable throughout my treatment.",
    },
    {
      "name": "Robert Williams",
      "date": "Nov 25, 2024",
      "rating": 5,
      "comment":
          "Very knowledgeable and professional. Highly recommend for anyone with heart concerns.",
    },
    {
      "name": "Maria Garcia",
      "date": "Nov 20, 2024",
      "rating": 4,
      "comment":
          "Great doctor with a caring approach. Wait times can be long but worth it.",
    },
  ];
  // ==========================================================

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6EBF2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),

        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.medical_services_outlined,
              color: AppColors.textDarkTeal,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopProfileCard(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildAboutSection(),

                  // استدعاء قسم الريفيوهات الديناميكي
                  _buildReviewsCard(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // زر الحجز
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // ============ الانتقال لصفحة الحجز ============
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingScreen(doctor: doctor), // نمرر بيانات الدكتور
                    ),
                  );
                  // ============================================
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Book Appointment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: الكارت العلوي ---
  Widget _buildTopProfileCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFD6EBF2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(doctor['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDarkTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['location'] ?? "City Center",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(
                          4,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${doctor['rating']} (${doctor['reviews']})",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Consultation: \$${doctor['price']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.location_on_outlined,
              "123 Medical Plaza, New York, NY",
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.access_time, "Mon - Fri: 9:00 AM - 6:00 PM"),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.verified_outlined, "12 years exp."),
                _buildStatItem(Icons.people_outline, "2500+ patients"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${doctor['name']} is a board-certified ${doctor['specialty']} with over 12 years of experience. He specializes in preventive care and has helped thousands of patients.",
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Expertise",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip("Heart Disease"),
              _buildChip("Hypertension"),
              _buildChip("Arrhythmia"),
              _buildChip("Preventive Care"),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EBF2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textDarkTeal,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============ 2. بناء قسم الريفيو ديناميكياً ============
  Widget _buildReviewsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Patient Reviews",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkTeal,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "${doctor['rating']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDarkTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // === هنا السحر: تحويل القائمة إلى عناصر UI ===
            // بنستخدم reviews.map عشان نحول كل "داتا" لـ "شكل"
            ...reviews.map((review) {
              return Column(
                children: [
                  _buildReviewItem(
                    review['name'],
                    review['date'],
                    review['rating'],
                    review['comment'],
                  ),
                  // نضيف خط فاصل لو ده مش آخر عنصر
                  if (review != reviews.last) const Divider(height: 30),
                ],
              );
            }).toList(),

            // ============================================
            const SizedBox(height: 20),

            // زر عرض الكل
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  // مستقبلاً: هنا تروحي لصفحة كل الكومنتات
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "View all reviews",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت لتقييم واحد (تصميم الصف الواحد)
  Widget _buildReviewItem(
    String name,
    String date,
    int rating,
    String comment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
                fontSize: 14,
              ),
            ),
            Text(
              date,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // رسم النجوم ديناميكياً بناءً على التقييم
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              Icons.star,
              // لو رقم النجمة أقل من التقييم تبقى ذهبي، غير كدة رمادي
              color: index < rating ? Colors.amber : Colors.grey.shade300,
              size: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
