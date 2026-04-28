import 'package:flutter/material.dart';
import 'home_screen.dart';

class CheckInSuccessScreen extends StatelessWidget {
  final String qrId;
  final String? appointmentId;

  const CheckInSuccessScreen({
    super.key,
    required this.qrId,
    this.appointmentId,
  });

  // ============ تعريف الألوان بالقيم الثابتة ============
  static const Color textDarkTeal = Color(0xFF088F8F);
  static const Color primaryCyan = Color(0xFF4DBFD8);
  static const Color accentOrange = Color(0xFFF4A261);
  static const Color white = Colors.white;
  // =====================================================

  // === Navigation Logic ===
  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // === UI Helper ===
  Widget _buildFileItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textDarkTeal.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textDarkTeal, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // === QR Info Card ===
  Widget _buildQRInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
   border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Scan Details:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textDarkTeal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow("QR ID", qrId),
          const SizedBox(height: 8),
          _buildInfoRow("Time", _getCurrentTime()),
          if (appointmentId != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow("Appointment ID", appointmentId!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          value.length > 15 ? '${value.substring(0, 15)}...' : value,
          style: const TextStyle(
            color: textDarkTeal,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Check-In Complete",
          style: TextStyle(
            color: textDarkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => _goToHome(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 1. كارت النجاح الأخضر
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "Check-In Successful",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "QR Code scanned at ${_getCurrentTime()}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 إضافة كارت معلومات الـ QR الجديد
            _buildQRInfoCard(),

            const SizedBox(height: 20),

            // 2. العنوان (Your Medical File Includes)
            const Text(
              "Your Medical File Includes:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDarkTeal,
              ),
            ),
            const SizedBox(height: 15),

            // 3. القائمة
            _buildFileItem(Icons.person_outline, "Personal Information"),
            _buildFileItem(Icons.monitor_heart_outlined, "Chronic Diseases"),
            _buildFileItem(Icons.science_outlined, "Lab Tests & Analysis"),
            _buildFileItem(Icons.medication_outlined, "Prescriptions"),
            _buildFileItem(Icons.calendar_month_outlined, "Previous Visits"),

            const SizedBox(height: 30),

            // 4. كارت الخطوة القادمة (Next Step)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chair_alt,
                      color: primaryCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Next Step",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textDarkTeal,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Please proceed to the waiting area. You will be notified when it is your turn to enter the doctor's room.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (appointmentId != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: textDarkTeal.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info,
                                  size: 14,
                                  color: textDarkTeal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Appointment: ${appointmentId!.substring(0, 8)}...",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: textDarkTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 5. زر العودة (Back to Home Button)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _goToHome(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    color: white,
                    fontWeight: FontWeight.bold,
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
}