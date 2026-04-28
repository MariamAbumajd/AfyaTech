import 'package:afyatech/notification_screen.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:afyatech/backend/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'doctors_screen.dart';
import 'profile_screen.dart';
import 'tracking_screen.dart';
import 'check_in_screen.dart';
import 'medical_records_screen.dart';
import 'priority_request_flow.dart';  // تأكد من وجود هذا الملف

// استيراد الـ Widgets المنفصلة
import 'widgets/header_widget.dart';
import 'widgets/search_widget.dart';
import 'widgets/promo_banner_widget.dart';
import 'widgets/section_header_widget.dart';
import 'widgets/virtual_queue_card.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/specialties_list.dart';
import 'widgets/emergency_widget.dart';  // الملف الجديد

// للحفاظ على الـ AppColors كما هي
class AppColors {
  static const Color background = Color(0xFFF7F8FA);
  static const Color primaryTeal = Color(0xFF0A8E9C);
  static const Color textDarkTeal = Color(0xFF088F8F);
  static const Color accentOrange = Color(0xFFF4A261);
  static const Color lightBlue = Color(0xFFC6E4F2);
  static const Color emergencyRed = Color(0xFFFF4444);
  static const Color white = Colors.white;

  static Color? get textDark => null;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  Future<String> getUserName() async {
    try {
      return await _authService.getCurrentUserName();
    } catch (e) {
      print("Error in getUserName: $e");
      return "User";
    }
  }

  void _onBackPressed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onNotificationPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationScreen(),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MedicalRecordsScreen(),
          ),
        );
        break;
    }
  }

  void _onSearchChanged(String value) {
    print("Searching for: $value");
    // يمكنك إضافة منطق البحث هنا
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              getUserName: getUserName,
              onBackPressed: _onBackPressed,
              onNotificationPressed: _onNotificationPressed,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchWidget(onSearchChanged: _onSearchChanged),
                    const SizedBox(height: 24),
                    const PromoBannerWidget(),
                    const SizedBox(height: 24),
                    SectionHeaderWidget(title: "Specialties", onSeeAll: () {}),
                    const SizedBox(height: 12),
                    const SpecialtiesList(),
                    const SizedBox(height: 24),
                    SectionHeaderWidget(
                      title: "Recommended Doctors",
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildDoctorsList(),
                    const SizedBox(height: 24),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection("queue")
                          .doc("current")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildQueueLoading();
                        }
                        
                        if (snapshot.hasError) {
                          return _buildQueueError(snapshot.error.toString());
                        }
                        
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return _buildQueueEmpty();
                        }
                        
                        final data = snapshot.data!.data()!;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrackingScreen(
                                  doctor: {
                                    'name': data['doctorName'] ?? 'Dr. Unknown',
                                    'specialization': data['specialization'] ?? 'General',
                                    'clinic': data['clinic'] ?? 'Unknown Clinic',
                                  },
                                  queueNumber: data['currentPosition'] ?? 0,
                                ),
                              ),
                            );
                          },
                          child: VirtualQueueCard(
                            currentPosition: data['currentPosition'] ?? 0,
                            nextPatient: data['nextPatient'] ?? 0,
                            estimatedTime: data['estimatedTime'] ?? '-- minutes',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildMedicalCard(),
                    const SizedBox(height: 24),
                    const EmergencyWidget(),  // Widget الطوارئ الجديد
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildDoctorsList() {
    final doctors = [
      {
        'name': 'Dr. Ahmed Hassan',
        'spec': 'General Practitioner',
        'rating': '4.9',
        'exp': '15 years',
        'image': 'assets/Item2.jpg',
      },
      {
        'name': 'Dr. Fatima',
        'spec': 'Cardiologist',
        'rating': '5.0',
        'exp': '12 years',
        'image': 'assets/Item3.jpg',
      },
      {
        'name': 'Dr. Sara',
        'spec': 'Pediatrician',
        'rating': '4.8',
        'exp': '10 years',
        'image': 'assets/Item4.jpg',
      },
    ];

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doc = doctors[index];
          return Container(
            width: 180,
            margin: EdgeInsets.only(
              right: index == doctors.length - 1 ? 0 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: AppColors.lightBlue,
                    child: Image.asset(
                      doc['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => Container(
                        color: AppColors.lightBlue,
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDarkTeal,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc['spec']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doc['rating']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDarkTeal,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              doc['exp']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textDarkTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicalCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckInScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4DBFD8), Color(0xFF0A8E9C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DBFD8).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Medical Card",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Access your digital medical card",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "View QR Code",
                      style: TextStyle(
                        color: Color(0xFF0A8E9C),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 45,
                color: Color(0xFF0A8E9C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueLoading() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryTeal),
            SizedBox(height: 16),
            Text(
              "Loading queue data...",
              style: TextStyle(
                color: AppColors.textDarkTeal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueError(String error) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              "Connection Error",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error.length > 50 ? "${error.substring(0, 50)}..." : error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueEmpty() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue,
              color: AppColors.primaryTeal,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              "No Active Queue",
              style: TextStyle(
                color: AppColors.textDarkTeal,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Check back later for queue updates",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}