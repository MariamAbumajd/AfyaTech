import 'package:flutter/material.dart';
import 'app_colorspart2.dart'; // تأكدي من المسار

class RewardsScreen extends StatefulWidget {
  final String? notificationData; // إضافة معلمة اختيارية للإشعارات

  const RewardsScreen({super.key, this.notificationData});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // 1. المتغيرات الديناميكية (State)
  int currentPoints = 1250; // رصيد النقاط الحالي
  final int goldLevelTarget = 1600; // الهدف للوصول للمستوى الذهبي

  // 2. قائمة العروض (بيانات وهمية تحاكي الباك إند)
  final List<Map<String, dynamic>> offers = [
    {
      "id": 1,
      "title": "Free Consultation",
      "subtitle": "One free doctor consultation (General)",
      "discount": "100% OFF",
      "points": 800,
      "icon": Icons.medical_services_outlined,
      "color": const Color(0xFFE0F2F1), // أخضر فاتح
      "iconColor": AppColors.primaryTeal,
      "isPopular": true,
    },
    {
      "id": 2,
      "title": "Lab Tests Discount",
      "subtitle": "20% off on all laboratory requests",
      "discount": "20% OFF",
      "points": 500,
      "icon": Icons.science_outlined,
      "color": const Color(0xFFE1F5FE), // أزرق فاتح
      "iconColor": Color(0xFF0288D1),
      "isPopular": false,
    },
    {
      "id": 3,
      "title": "X-Ray Discount",
      "subtitle": "50% discount on X-ray imaging services",
      "discount": "50% OFF",
      "points": 600,
      "icon": Icons.camera_alt_outlined,
      "color": const Color(0xFFFFF3E0), // برتقالي فاتح
      "iconColor": Color(0xFFEF6C00),
      "isPopular": true,
    },
    {
      "id": 4,
      "title": "Medication Voucher",
      "subtitle": "15% off on pharmacy purchases",
      "discount": "15% OFF",
      "points": 400,
      "icon": Icons.medication_outlined,
      "color": const Color(0xFFE8F5E9), // أخضر عشبي فاتح
      "iconColor": Colors.green,
      "isPopular": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // معالجة بيانات الإشعارات إذا وجدت
    _processNotificationData();
  }

  void _processNotificationData() {
    if (widget.notificationData != null && widget.notificationData!.isNotEmpty) {
      print('Notification data received in RewardsScreen: ${widget.notificationData}');
      // يمكنك هنا تحديث النقاط بناءً على بيانات الإشعار
      // مثال: إذا كان الإشعار عن إضافة نقاط
      if (widget.notificationData!.contains('points_added')) {
        setState(() {
          currentPoints += 100; // إضافة 100 نقطة كمثال
        });
      }
    }
  }

  // 3. دالة اللوجيك والتحقق (Validation Logic)
  void _redeemOffer(int cost, String offerName) {
    if (currentPoints >= cost) {
      // حالة النجاح: خصم النقاط وتحديث الواجهة
      setState(() {
        currentPoints -= cost;
      });
      _showFeedback(
        "Success! You redeemed: $offerName",
        Colors.green,
        Icons.check_circle,
      );
    } else {
      // حالة الفشل: نقاط غير كافية
      _showFeedback(
        "Insufficient Points! You need ${cost - currentPoints} more points.",
        AppColors.emergencyRed,
        Icons.error_outline,
      );
    }
  }

  // دالة لإظهار رسالة التنبيه (SnackBar)
  void _showFeedback(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // حساب نسبة التقدم (Progress)
    double progress = (currentPoints / goldLevelTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Rewards & Offers",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // عرض النقاط المصغر في الأعلى
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$currentPoints pts",
                style: const TextStyle(
                  color: AppColors.textDarkTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      // 4. حل مشكلة Overflow باستخدام SingleChildScrollView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // إشعار إذا كان هناك بيانات إشعار
            if (widget.notificationData != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.primaryTeal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Redirected from notification",
                        style: TextStyle(
                          color: AppColors.textDarkTeal,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 1. كارت النقاط الكبير
            _buildTopPointsCard(progress),

            const SizedBox(height: 30),

            // 2. عنوان القائمة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Available Offers",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkTeal,
                  ),
                ),
                Text(
                  "${offers.length} offers",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 3. توليد قائمة العروض ديناميكياً
            ...offers.map((offer) => _buildOfferCard(offer)).toList(),

            const SizedBox(height: 30),

            // 4. قسم "كيف تكسب نقاطاً"
            _buildHowToEarnSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // === UI Widgets ===

  Widget _buildTopPointsCard(double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A8E9C), Color(0xFF4DBFD8)], // تدرج تيل وسماوي
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.stars, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                "Your Available Points",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "$currentPoints pts", // رقم ديناميكي
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress, // النسبة ديناميكية
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${goldLevelTarget - currentPoints > 0 ? goldLevelTarget - currentPoints : 0} points to reach Gold Level",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: offer['color'], // لون الخلفية المتغير
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      offer['icon'],
                      color: offer['iconColor'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDarkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 180, // تحديد العرض لمنع Overflow للنص الطويل
                        child: Text(
                          offer['subtitle'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (offer['isPopular'])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text(
                        "Popular",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // الجزء السفلي (الخصم - النقاط - زر الاستبدال)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer['discount'],
                  style: TextStyle(
                    color: offer['iconColor'],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    "${offer['points']} points",
                    style: TextStyle(
                      color: AppColors.textDarkTeal.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () =>
                        _redeemOffer(offer['points'], offer['title']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Redeem",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How to Earn More Points?",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 10),
          _buildEarnPointItem("Complete scheduled appointments (+50 pts)"),
          _buildEarnPointItem("Refer friends to AfyaTech (+200 pts)"),
          _buildEarnPointItem("Complete health surveys (+30 pts)"),
          _buildEarnPointItem("Maintain wellness goals (+100 pts monthly)"),
        ],
      ),
    );
  }

  Widget _buildEarnPointItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.primaryCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ],
    ));
    }
  }
