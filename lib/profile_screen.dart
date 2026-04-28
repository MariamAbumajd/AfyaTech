import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colorspart2.dart';
import 'login_screen.dart';
import 'rewards_screen.dart';
import 'edit_personal_info_screen.dart';
import 'change_password_screen.dart';
import 'my_wallet_screen.dart';
import 'support_chatbot_screen.dart';
import 'medical_preferences_screen.dart';
import 'theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // جلب بيانات المستخدم من Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          // إذا لم يكن هناك بيانات، أنشئ بيانات افتراضية
          await _createDefaultUserData(user);
        }
        
        // جلب نقاط المكافآت
        await _loadUserPoints(user.uid);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDefaultUserData(User user) async {
    final defaultData = {
      'name': user.displayName ?? user.email?.split('@').first ?? 'User',
      'email': user.email ?? '',
      'phone': '',
      'bloodType': 'Unknown',
      'medicalId': 'MED-${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'profileImage': '',
      'walletBalance': 0.0,
      'points': 0,
    };
    
    await _firestore.collection('users').doc(user.uid).set(defaultData);
    
    setState(() {
      _userData = defaultData;
      _isLoading = false;
    });
  }

  Future<void> _loadUserPoints(String userId) async {
    try {
      final pointsDoc = await _firestore
          .collection('user_points')
          .doc(userId)
          .get();
      
      if (pointsDoc.exists) {
        setState(() {
          _points = pointsDoc.data()?['points'] ?? 0;
        });
      } else {
        // إنشاء سجل نقاط جديد
        await _firestore.collection('user_points').doc(userId).set({
          'points': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error loading points: $e');
    }
  }

  Future<void> _updateWalletBalance(double newBalance) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // تحديث البيانات المحلية
      setState(() {
        _userData?['walletBalance'] = newBalance;
      });
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(isDarkMode),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.getPrimary(isDarkMode)),
              const SizedBox(height: 20),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userName = _userData?['name'] ?? 'User';
    final userEmail = _userData?['email'] ?? '';
    final medicalId = _userData?['medicalId'] ?? 'Unknown ID';
    final bloodType = _userData?['bloodType'] ?? 'Unknown';
    final walletBalance = _userData?['walletBalance'] ?? 0.0;
    final initials = _getInitials(userName);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextDarkTeal(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: TextStyle(
            color: AppColors.getTextDarkTeal(isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(
              Icons.local_hospital,
              color: AppColors.getTextDarkTeal(isDarkMode).withOpacity(0.5),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. الهيدر (صورة - اسم - فصيلة دم - زر تعديل)
            _buildProfileHeader(
              isDarkMode,
              userName,
              medicalId,
              bloodType,
              initials,
            ),

            const SizedBox(height: 25),

            // 2. كارت نقاط الولاء (Rewards Card)
            _buildRewardsCard(isDarkMode, _points),

            const SizedBox(height: 25),

            // 3. قائمة الإعدادات
            _buildSettingsItem(
              icon: Icons.edit_outlined,
              title: "Edit Personal Information",
              subtitle: "Update your profile details",
              isDarkMode: isDarkMode,
              onTap: () => _navigateTo(context, const EditPersonalInfoScreen()),
            ),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: "Change Password",
              subtitle: "Secure your account",
              isDarkMode: isDarkMode,
              onTap: () => _navigateTo(context, const ChangePasswordScreen()),
            ),
            _buildSettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: "My Wallet",
              subtitle: "Balance: \$${walletBalance.toStringAsFixed(2)}",
              isDarkMode: isDarkMode,
              onTap: () => _navigateTo(context, MyWalletScreen(
                initialBalance: walletBalance,
                onBalanceUpdated: _updateWalletBalance,
              )),
            ),
            _buildSettingsItem(
              icon: Icons.support_agent,
              title: "Support Chatbot",
              subtitle: "24/7 AI assistance",
              isDarkMode: isDarkMode,
              onTap: () => _navigateTo(context, const SupportChatbotScreen()),
            ),
            _buildSettingsItem(
              icon: Icons.settings_accessibility,
              title: "Medical Preferences",
              subtitle: "Health settings & alerts",
              isDarkMode: isDarkMode,
              onTap: () =>
                  _navigateTo(context, const MedicalPreferencesScreen()),
            ),

            // === Dark Mode Switch ===
            GestureDetector(
              onTap: () {
                themeProvider.toggleTheme(!isDarkMode);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getCard(isDarkMode),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.03),
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
                        color: AppColors.getPrimary(isDarkMode).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: AppColors.getPrimary(isDarkMode),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      isDarkMode ? "Dark Mode" : "Light Mode",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getText(isDarkMode),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isDarkMode,
                      activeColor: AppColors.getPrimary(isDarkMode),
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. زر تسجيل الخروج (Logout)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _auth.signOut();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Logged out successfully"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error logging out: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.emergencyRed),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFF3A2D2D)
                      : const Color(0xFFFDECEC),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    } else if (name.isNotEmpty) {
      return name.substring(0, 1);
    }
    return 'U';
  }

  // === Helper Widgets ===

  Widget _buildProfileHeader(
    bool isDarkMode,
    String userName,
    String medicalId,
    String bloodType,
    String initials,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCard(isDarkMode),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Firebase storage support
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(isDarkMode).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextDarkTeal(isDarkMode),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Name & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextDarkTeal(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: $medicalId",
                      style: TextStyle(
                          color: AppColors.getTextSecondary(isDarkMode),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Blood Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8E1E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Blood Type: $bloodType",
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
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
          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _navigateTo(context, const EditPersonalInfoScreen()),
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: const Text(
                "Edit Profile",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDarkMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(bool isDarkMode, int points) {
    final progress = (points / 1600).clamp(0.0, 1.0);
    final pointsToGold = 1600 - points;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E3527)
            : const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Health Rewards",
            style: TextStyle(
              color: AppColors.getPrimary(isDarkMode),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$points",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextDarkTeal(isDarkMode),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "Points",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextSecondary(isDarkMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.white,
              color: AppColors.getPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pointsToGold > 0 
                ? "$pointsToGold points to Gold Level"
                : "Congratulations! You reached Gold Level!",
            style: TextStyle(
                fontSize: 11, 
                color: AppColors.getTextSecondary(isDarkMode),
                fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RewardsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getAccent(isDarkMode),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Redeem Points",
                style: TextStyle(
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCard(isDarkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.03),
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
                color: AppColors.getPrimary(isDarkMode).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: AppColors.getPrimary(isDarkMode), size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getText(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.getTextSecondary(isDarkMode)),
          ],
        ),
      ),
    );
  }
}