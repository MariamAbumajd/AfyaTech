import 'package:flutter/material.dart';
import 'app_colorspart2.dart';

// ==========================================
// 1. الشاشة الأولى: نموذج الطلب (Request Form)
// ==========================================
class PriorityRequestScreen extends StatefulWidget {
  const PriorityRequestScreen({super.key});

  @override
  State<PriorityRequestScreen> createState() => _PriorityRequestScreenState();
}

class _PriorityRequestScreenState extends State<PriorityRequestScreen> {
  // قائمة الحالات الطبية
  final List<Map<String, dynamic>> _conditions = [
    {
      "title": "Severe Pain",
      "icon": Icons.error_outline,
      "desc": "Intense pain requiring immediate attention",
    },
    {
      "title": "High Fever",
      "icon": Icons.local_fire_department_outlined,
      "desc": "Temperature above normal range",
    },
    {
      "title": "Breathing Difficulty",
      "icon": Icons.air,
      "desc": "Trouble breathing or shortness of breath",
    },
    {
      "title": "Elderly Patient",
      "icon": Icons.elderly,
      "desc": "Senior citizen requiring priority care",
    },
    {
      "title": "Child Case",
      "icon": Icons.child_care,
      "desc": "Pediatric case needing urgent attention",
    },
    {
      "title": "Sudden Weakness",
      "icon": Icons.show_chart,
      "desc": "Unexpected loss of strength or energy",
    },
    {
      "title": "Other",
      "icon": Icons.description_outlined,
      "desc": "Specify your urgent condition below",
    },
  ];

  int _selectedIndex = -1; // لا شيء مختار في البداية
  final _descriptionController = TextEditingController();

  // دالة للتحقق من صحة البيانات (Validation)
  bool _isFormValid() {
    if (_selectedIndex == -1) return false; // لم يتم اختيار أي حالة
    if (_selectedIndex == 6 && _descriptionController.text.trim().isEmpty)
      return false; // اختار Other ولم يكتب شيئاً
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // تفعيل الزر بناءً على الـ Validation
    final bool isButtonEnabled = _isFormValid();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Priority Medical Request",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tell us your urgent condition",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Your Condition",
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textDarkTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // 1. شبكة الخيارات
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: _conditions.length,
              itemBuilder: (context, index) {
                final condition = _conditions[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFDECEC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentOrange
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            condition['icon'],
                            color: isSelected
                                ? AppColors.accentOrange
                                : AppColors.primaryTeal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          condition['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSelected
                                ? AppColors.accentOrange
                                : AppColors.textDarkTeal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          condition['desc'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? AppColors.accentOrange.withOpacity(0.8)
                                : Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. حقل الوصف (يظهر فقط عند اختيار "Other")
            if (_selectedIndex == 6) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  onChanged: (_) =>
                      setState(() {}), // تحديث الواجهة عند الكتابة لتفعيل الزر
                  decoration: const InputDecoration(
                    hintText: "Please describe your urgent condition...",
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. الجزء السفلي (الزر والملاحظة)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECEC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.accentOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Request Medical Priority",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkTeal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "This request will notify the clinic immediately.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  // زر الإرسال (مع Validation)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled
                          ? () {
                              // تحديد النص المرسل
                              String condition =
                                  _conditions[_selectedIndex]['title'];
                              if (condition == "Other") {
                                condition = _descriptionController.text;
                              }
                              // الانتقال للصفحة التالية
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrioritySuccessScreen(
                                    condition: condition,
                                  ),
                                ),
                              );
                            }
                          : null, // الزر معطل (Disabled)
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Send Priority Request",
                        style: TextStyle(
                          color: isButtonEnabled ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // الملاحظة الخضراء
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Urgent conditions only.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. الشاشة الثانية: التأكيد (Success Screen)
// ==========================================
class PrioritySuccessScreen extends StatelessWidget {
  final String condition;
  const PrioritySuccessScreen({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              "Your Request is Now\nPriority",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "The clinic and your doctor have been notified.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "PRIORITY ACTIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Reported Condition",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    condition,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // زر المتابعة
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PriorityTrackingScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "View Live Updates",
                  style: TextStyle(
                    color: AppColors.primaryTeal,
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
}

// ==========================================
// 3. الشاشة الثالثة: التتبع (Live Updates - المحسنة)
// ==========================================
class PriorityTrackingScreen extends StatelessWidget {
  const PriorityTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Priority Status",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "PRIORITY ACTIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Live Updates",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkTeal,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildTimelineItem("Request Received", "Just now", true, true),
            _buildTimelineItem("Doctor Notified", "Processing...", false, true),
            _buildTimelineItem("Preparing Room", "Pending...", false, false),

            const Spacer(),

            // === الإضافة الجديدة: قسم الطوارئ والنصائح ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3), // خلفية حمراء فاتحة جداً
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.emergencyRed.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.emergencyRed),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "While you wait, try to stay calm and seated. If condition worsens:",
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // كود الاتصال (url_launcher)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Calling Emergency Services..."),
                          ),
                        );
                      },
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text(
                        "Call Emergency (911)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergencyRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.primaryTeal,
                ),
                label: const Text(
                  "Return to Home",
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    bool isCompleted,
    bool showLine,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryTeal.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isCompleted ? AppColors.primaryTeal : Colors.grey,
              ),
            ),
            if (showLine)
              Container(width: 2, height: 40, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppColors.textDark : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }
}
