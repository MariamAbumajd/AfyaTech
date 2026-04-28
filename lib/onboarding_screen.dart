import 'package:flutter/material.dart';
import 'dart:async';
import '../app_colors.dart'; // تأكدي إن الملف ده موجود ومساره صح
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // بيانات الصفحات (تم تحسين النصوص لتكون احترافية)
  final List<Map<String, String>> _onboardingData = [
    // Page 1: Welcome (لها تصميم خاص)
    // Page 2:
    {
      "title": "Instant Doctor Booking", // عنوان قصير وقوي
      "subtitle":
          "Find the best doctors nearby and book your appointment in seconds.", // شرح واضح
      "image": "",
    },
    // Page 3:
    {
      "title": "Pharmacy at Your Door",
      "subtitle":
          "Order your medicine with a single tap and get fast delivery to your home.",
      "image": "",
    },
    // Page 4:
    {
      "title": "Smart AI Health Assistant",
      "subtitle":
          "Let AI analyze your symptoms, track your records, and manage your schedule.",
      "image": "",
    },
  ];

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == 3;

    // الصفحة الأولى غامقة، والباقي فاتح
    Color backgroundColor = _currentPage == 0
        ? AppColors.secondaryDarkCyan
        : AppColors.primaryCyan;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. مساحة المحتوى العلوي (تأخذ 3 أرباع الشاشة)
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: 4,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const AnimatedWelcomePage();
                  } else {
                    return OnboardingContentPage(
                      title: _onboardingData[index - 1]["title"]!,
                      subtitle: _onboardingData[index - 1]["subtitle"]!,
                      // imagePath: _onboardingData[index - 1]["image"]!, // فعلي ده لما تحطي الصور
                    );
                  }
                },
              ),
            ),

            // 2. مساحة التحكم السفلي (الأزرار والنقاط)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                ), // هوامش جانبية مريحة
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
                  children: [
                    // مؤشر الصفحات (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) => buildDot(index)),
                    ),

                    const Spacer(), // مسافة مرنة تدفع الزر للأسفل
                    // الزر الرئيسي (Next / Start)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLastPage) {
                            // ============ التعديل هنا ============
                            // لو دي آخر صفحة، روح لصفحة الـ Sign Up
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                            // ====================================
                          } else {
                            // لو لسه مش آخر صفحة، اقلب للصفحة اللي بعدها
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage == 0
                              ? Colors.white
                              : AppColors.secondaryDarkCyan,
                          foregroundColor: _currentPage == 0
                              ? AppColors.secondaryDarkCyan
                              : Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isLastPage ? "Get Started" : "Next",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // زر التخطي (Skip)
                    // نستخدم Opacity لإخفائه بنعومة في آخر صفحة بدل ما يختفي فجأة
                    Opacity(
                      opacity: isLastPage ? 0.0 : 1.0,
                      child: TextButton(
                        onPressed: isLastPage
                            ? null
                            : () => _pageController.jumpToPage(3),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white70, // لون أبيض هادئ
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تصميم النقطة
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8, // النقطة النشطة عريضة
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ---------------------------------------------------------
// الصفحة الأولى: Welcome Screen (نصوص محسنة)
// ---------------------------------------------------------
class AnimatedWelcomePage extends StatefulWidget {
  const AnimatedWelcomePage({super.key});

  @override
  State<AnimatedWelcomePage> createState() => _AnimatedWelcomePageState();
}

class _AnimatedWelcomePageState extends State<AnimatedWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // ============ هنا التعديل ============
    Timer(const Duration(milliseconds: 300), () {
      // بنسأل: هل الصفحة لسه شغالة؟
      if (mounted) {
        _controller.forward();
      }
    });
    // ====================================
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // الأنيميشن
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // اللوجو
                  Image.asset(
                    'assets/Logo.jpg', // تأكدي من الاسم
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Afya Tech",
                    style: TextStyle(
                      fontSize: 36, // خط كبير
                      fontWeight: FontWeight.w900, // سميك جداً
                      color: AppColors.primaryCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // نصوص الترحيب (في المنتصف)
          const Text(
            "Healthcare Simplified", // عنوان قوي
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // الوصف
          const Text(
            "Manage your appointments, medicines, and records all in one place.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70, // لون هادئ للقراءة
              height: 1.5, // مسافة بين السطور
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// الصفحات الداخلية: Content Pages (توسط كامل)
// ---------------------------------------------------------
class OnboardingContentPage extends StatelessWidget {
  final String title;
  final String subtitle;
  // final String imagePath;

  const OnboardingContentPage({
    super.key,
    required this.title,
    required this.subtitle,
    // required this.imagePath
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // توسط عمودي لكل العناصر
        children: [
          const Spacer(),

          // الصورة
          Expanded(
            flex: 3,
            child: Center(
              // child: Image.asset(imagePath, fit: BoxFit.contain), // فعلي ده
              child: Container(
                // Placeholder
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // العنوان
          Text(
            title,
            textAlign: TextAlign.center, // نص في المنتصف
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // الشرح
          Text(
            subtitle,
            textAlign: TextAlign.center, // نص في المنتصف
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70, // أبيض شفاف قليلاً
              height: 1.5, // لراحة العين
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
