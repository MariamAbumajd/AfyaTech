import 'package:flutter/material.dart';
import 'app_colorspart2.dart';

class MedicalPreferencesScreen extends StatefulWidget {
  const MedicalPreferencesScreen({super.key});

  @override
  State<MedicalPreferencesScreen> createState() =>
      _MedicalPreferencesScreenState();
}

class _MedicalPreferencesScreenState extends State<MedicalPreferencesScreen> {
  // === متغيرات الحالة ===
  bool _appointmentReminders = true;
  bool _medicationAlerts = true;
  String _reminderTime = '1 hour before';
  bool _shareWithDoctors = true;
  bool _syncHealthApps = false;
  bool _showOnLockScreen = false;
  String _emergencyContact = "Not Set"; // القيمة الافتراضية
  bool _biometricAccess = false;
  double _textSize = 1.0;
  bool _voiceMode = false;

  // === 1. دالة التحقق (Validation Logic) ===
  bool _validateSettings() {
    // شرط: لا يمكن تفعيل العرض على شاشة القفل بدون تحديد جهة اتصال للطوارئ
    if (_showOnLockScreen && _emergencyContact == "Not Set") {
      _showFeedback(
        "⚠️ Error: Please select an Emergency Contact first!",
        isError: true,
      );
      return false; // فشل التحقق
    }

    // شرط: لا يمكن تفعيل المزامنة بدون تفعيل الصلاحيات (محاكاة)
    if (_syncHealthApps && !_biometricAccess) {
      _showFeedback(
        "⚠️ Security: Enable Biometric Access to sync health data.",
        isError: true,
      );
      return false;
    }

    return true; // نجاح التحقق
  }

  // === 2. دالة عرض المخرجات (Output Display) ===
  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Settings Summary",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              _summaryRow(
                "Reminders:",
                _appointmentReminders ? "ON ($_reminderTime)" : "OFF",
              ),
              _summaryRow("Meds Alerts:", _medicationAlerts ? "ON" : "OFF"),
              _summaryRow(
                "Sharing:",
                _shareWithDoctors ? "Doctors Only" : "Private",
              ),
              _summaryRow(
                "Sync Apps:",
                _syncHealthApps ? "Active" : "Inactive",
              ),
              _summaryRow(
                "Lock Screen:",
                _showOnLockScreen ? "Visible" : "Hidden",
              ),
              _summaryRow("Contact:", _emergencyContact),
              _summaryRow(
                "Biometrics:",
                _biometricAccess ? "Required" : "Optional",
              ),
              _summaryRow("Text Size:", "${(_textSize * 100).toInt()}%"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الديالوج
              Navigator.pop(context); // الرجوع للبروفايل
              _showFeedback(
                "✅ Preferences Saved Successfully!",
                isError: false,
              );
            },
            child: const Text(
              "Confirm & Save",
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // رسائل التنبيه (SnackBars)
  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.emergencyRed : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Medical Preferences",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDarkTeal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. التنبيهات
            _buildSectionHeader("Notifications & Alerts"),
            const SizedBox(height: 10),
            _buildPreferenceCard([
              _buildSwitchTile(
                "Appointment Reminders",
                "Get notified before visits",
                _appointmentReminders,
                (val) => setState(() => _appointmentReminders = val),
                Icons.calendar_today,
              ),
              if (_appointmentReminders) ...[
                _buildDivider(),
                _buildDropdownTile(),
              ],
              _buildDivider(),
              _buildSwitchTile(
                "Medication Alerts",
                "Reminders to take your pills",
                _medicationAlerts,
                (val) => setState(() => _medicationAlerts = val),
                Icons.medication,
              ),
            ]),

            const SizedBox(height: 25),

            // 2. الخصوصية والمزامنة
            _buildSectionHeader("Privacy & Data"),
            const SizedBox(height: 10),
            _buildPreferenceCard([
              _buildSwitchTile(
                "Share with Doctors",
                "Auto-share records with booked doctors",
                _shareWithDoctors,
                (val) => setState(() => _shareWithDoctors = val),
                Icons.person_search,
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Sync Health Data",
                "Link with Apple Health / Google Fit",
                _syncHealthApps,
                (val) {
                  if (!_biometricAccess && val == true) {
                    _showFeedback(
                      "⚠️ Enable Biometric Security first!",
                      isError: true,
                    );
                  } else {
                    setState(() => _syncHealthApps = val);
                  }
                },
                Icons.health_and_safety,
              ),
            ]),

            const SizedBox(height: 25),

            // 3. الطوارئ (Validation هنا)
            _buildSectionHeader("Emergency Access"),
            const SizedBox(height: 10),
            _buildPreferenceCard([
              _buildSwitchTile(
                "Show on Lock Screen",
                "Display Blood Type & Allergies when locked",
                _showOnLockScreen,
                (val) {
                  if (val == true && _emergencyContact == "Not Set") {
                    _showFeedback(
                      "⚠️ Please set an Emergency Contact first!",
                      isError: true,
                    );
                  } else {
                    setState(() => _showOnLockScreen = val);
                  }
                },
                Icons.screen_lock_portrait,
              ),
              _buildDivider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contact_phone,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: const Text(
                  "Emergency Contact",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  _emergencyContact,
                  style: TextStyle(
                    color: _emergencyContact == "Not Set"
                        ? Colors.red
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _emergencyContact =
                        "Mother (+20 123 456 789)"; // محاكاة اختيار رقم
                  });
                  _showFeedback("📞 Emergency Contact Updated!");
                },
              ),
            ]),

            const SizedBox(height: 25),

            // 4. إمكانية الوصول
            _buildSectionHeader("Accessibility"),
            const SizedBox(height: 10),
            _buildPreferenceCard([
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.text_fields,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Text Size for Reports",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _textSize,
                      min: 0.8,
                      max: 1.4,
                      divisions: 3,
                      activeColor: AppColors.primaryTeal,
                      label: "${(_textSize * 100).toInt()}%",
                      onChanged: (val) => setState(() => _textSize = val),
                    ),
                  ],
                ),
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Voice Mode",
                "Read medical instructions aloud",
                _voiceMode,
                (val) => setState(() => _voiceMode = val),
                Icons.record_voice_over,
              ),
            ]),

            const SizedBox(height: 25),

            // 5. الأمان
            _buildSectionHeader("Security"),
            const SizedBox(height: 10),
            _buildPreferenceCard([
              _buildSwitchTile(
                "Biometric Access",
                "Require FaceID/Fingerprint",
                _biometricAccess,
                (val) => setState(() => _biometricAccess = val),
                Icons.fingerprint,
              ),
            ]),

            const SizedBox(height: 40),

            // زر الحفظ (يستدعي التحقق والتلخيص)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_validateSettings()) {
                    _showSummaryDialog(); // إظهار ملخص البيانات (Output)
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Save Preferences",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // === Helper Widgets ===

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryTeal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryTeal, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildDropdownTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 52),
          const Text(
            "Reminder Time:",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _reminderTime,
            underline: Container(),
            style: const TextStyle(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.bold,
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryTeal,
            ),
            items:
                <String>[
                  '30 mins before',
                  '1 hour before',
                  '2 hours before',
                  '1 day before',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _reminderTime = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.shade200,
      indent: 60,
      endIndent: 20,
    );
  }
}