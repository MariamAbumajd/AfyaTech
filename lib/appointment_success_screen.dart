import 'package:flutter/material.dart';
// تأكدي أن هذا الملف موجود وصحيح
import 'home_screen.dart'; // للرجوع للصفحة الرئيسية

class AppointmentSuccessScreen extends StatelessWidget {
  // ============ 1. تعريف المتغيرات المطلوبة ============
  final Map<String, dynamic> doctor;
  final String date;
  final String time;
  final String type;
    final String appointmentId;  // نوع الموعد (عيادة / أونلاين)
  // ===================================================

  const AppointmentSuccessScreen({
    super.key,
    // ============ 2. استقبال البيانات في الـ Constructor ============
    required this.doctor,
    required this.date,
    required this.time,
    required this.type,
       required this.appointmentId,
    // ==============================================================
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // إضافة Scroll لتجنب Overflow في الشاشات الصغيرة
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 1. رأس الصفحة
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2F1), // AppColors.lightTealBg
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryTeal,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Appointment Confirmed",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors
                            .textDarkTeal, // تم التعديل لاستخدام اللون الصحيح
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your visit has been successfully booked.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. كارت تفاصيل الحجز (ديناميكي الآن)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // معلومات الطبيب
                    Row(
                      children: [
                        // صورة الطبيب (من البيانات المستلمة)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // جعل الصورة دائرية
                          child: Image.asset(
                            doctor['image'], // استخدام المتغير
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => const CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor['name'], // استخدام المتغير
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                            Text(
                              doctor['specialty'], // استخدام المتغير
                              style: TextStyle(
                                color: AppColors.primaryTeal.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              doctor['location'] ?? 'Online', // استخدام المتغير
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Color(0xFFEEEEEE)),
                    ),

                    // تفاصيل الموعد (من البيانات المستلمة)
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      "Appointment Type",
                      type,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      "Date",
                      date,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, "Time", time),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.attach_money,
                      "Consultation Fee",
                      "\$${doctor['price']}",
                      isBoldValue: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. ملاحظة الوصول
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA), // AppColors.noteBg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Please arrive 10 minutes early before your appointment.",
                  style: TextStyle(
                    color: AppColors.primaryTeal.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. بانر النقاط المكتسبة
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // AppColors.lightTealBg
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You Earned Points!",
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          "+50",
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 5. زر العودة للرئيسية (هام جداً)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // العودة للصفحة الرئيسية ومسح كل الصفحات السابقة
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // شريط التنقل السفلي (اختياري - يمكن حذفه إذا كان الزر يكفي)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isBoldValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryTeal, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 15,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
