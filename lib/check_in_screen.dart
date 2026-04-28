import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart'; // 🔹 أضف هذا الاستيراد
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'app_colorspart2.dart';
import 'check_in_success_screen.dart';
import '../backend/auth_service.dart';

class CheckInScreen extends StatefulWidget {
  final String? appointmentId;

  const CheckInScreen({super.key, this.appointmentId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isSavingImage = false;
  String _qrData = '';
  String _qrId = '';
  String _userId = '';
  Map<String, dynamic>? _userData;
  
  final ScreenshotController _screenshotController = ScreenshotController();
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _generateUserQRCode();
  }

  Future<void> _generateUserQRCode() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        
        final userData = await authService.getUserData(user.uid);
        setState(() {
          _userData = userData ?? {
            'name': user.displayName ?? 'User',
            'email': user.email ?? '',
          };
        });
      }
      
      final qrPayload = {
        'userId': _userId,
        'appointmentId': widget.appointmentId ?? 'N/A',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'medical_checkin',
        'hospitalCode': 'AFYA001',
        'version': '1.0',
        'patientName': _userData?['name'] ?? 'Unknown',
        'patientEmail': _userData?['email'] ?? '',
      };
      
      setState(() {
        _qrData = jsonEncode(qrPayload);
        _qrId = 'QR-${DateTime.now().millisecondsSinceEpoch}';
        _statusMessage = 'QR Code generated successfully';
      });
      
      await _saveQRCodeToFirestore(qrPayload);
      setState(() => _isLoading = false);
      
    } catch (e) {
      print('❌ Error generating QR: $e');
      _showError('Failed to generate QR code');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQRCodeToFirestore(Map<String, dynamic> qrPayload) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.firestore
          .collection('qr_scans')
          .doc(_qrId)
          .set({
            'qrId': _qrId,
            'userId': _userId,
            'appointmentId': widget.appointmentId,
            'qrData': jsonEncode(qrPayload),
            'status': 'generated',
            'generatedAt': FieldValue.serverTimestamp(),
            'scannedAt': null,
            'scannedBy': null,
            'location': 'patient_device',
            'deviceInfo': {
              'platform': 'mobile',
              'timestamp': DateTime.now().toIso8601String(),
            },
          });
          
      print('✅ QR code saved to Firestore: $_qrId');
    } catch (e) {
      print('Error saving QR to Firestore: $e');
    }
  }

  // 🔹 **دالة حفظ صورة الـ QR Code في مجلد التطبيق**
  Future<void> _saveQRImageToApp() async {
    try {
      setState(() {
        _isSavingImage = true;
        _statusMessage = 'Saving QR code...';
      });
      
      // التحقق من الصلاحيات
      final permissionStatus = await Permission.storage.request();
      
      if (!permissionStatus.isGranted) {
        _showError('Storage permission is required to save QR code');
        setState(() => _isSavingImage = false);
        return;
      }
      
      // التقاط الصورة
      final imageBytes = await _screenshotController.captureFromWidget(
        _buildQRCodeWidget(),
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 500),
      );
      
      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception('Failed to capture QR code image');
      }
      
      // حفظ في مجلد التطبيق (Documents)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'Medical_QR_$_qrId.png';
      final filePath = '${appDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      // محاولة حفظ في مجلد الصور (Pictures) إن أمكن
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final picturesDir = Directory('${externalDir.path}/Pictures/AfyaTech');
          if (!await picturesDir.exists()) {
            await picturesDir.create(recursive: true);
          }
          
          final externalPath = '${picturesDir.path}/$fileName';
          await File(externalPath).writeAsBytes(imageBytes);
          print('✅ QR image also saved to: $externalPath');
        }
      } catch (e) {
        print('⚠️ Could not save to external storage: $e');
      }
      
      setState(() {
        _statusMessage = '✅ QR Code saved successfully!\nPath: $filePath';
      });
      
      _showSuccess('QR Code saved successfully!');
      
      // حفظ معلومات الصورة في Firestore
      await _saveImageInfoToFirestore(filePath);
      
    } catch (e) {
      print('❌ Error saving QR image: $e');
      _showError('Failed to save QR image: ${e.toString()}');
      setState(() {
        _statusMessage = '❌ Failed to save image';
      });
    } finally {
      setState(() => _isSavingImage = false);
    }
  }

  // 🔹 **دالة مشاركة صورة الـ QR Code (بديل عن الحفظ في المعرض)**
  Future<void> _shareQRImage() async {
    try {
      setState(() {
        _isSavingImage = true;
        _statusMessage = 'Preparing QR code for sharing...';
      });
      
      // التقاط الصورة
      final imageBytes = await _screenshotController.captureFromWidget(
        _buildQRCodeWidget(),
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 200),
      );
      
      if (imageBytes.isEmpty) {
        throw Exception('Failed to capture QR code image');
      }
      
      // حفظ مؤقت للصورة
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Medical_QR_Code_$_qrId.png';
      final filePath = '${tempDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      // مشاركة الصورة باستخدام share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '📱 My Medical QR Code - AfyaTech\n'
              '👤 Patient: ${_userData?['name'] ?? 'User'}\n'
              '🆔 ID: ${_userId.substring(0, min(_userId.length, 8))}...\n'
              '📅 Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}\n'
              '#AfyaTech #MedicalQR',
        subject: 'Medical QR Code - AfyaTech',
      );
      
      setState(() {
        _statusMessage = '✅ QR Code shared successfully!';
      });
      
      // حفظ سجل المشاركة في Firestore
      await _saveShareInfoToFirestore();
      
    } catch (e) {
      print('❌ Error sharing QR: $e');
      _showError('Failed to share QR code');
      setState(() {
        _statusMessage = '❌ Failed to share image';
      });
    } finally {
      setState(() => _isSavingImage = false);
    }
  }

  Future<void> _saveImageInfoToFirestore(String filePath) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.firestore
          .collection('qr_images')
          .doc(_qrId)
          .set({
            'qrId': _qrId,
            'userId': _userId,
            'appointmentId': widget.appointmentId,
            'savedAt': FieldValue.serverTimestamp(),
            'filePath': filePath,
            'device': 'mobile',
            'imageSize': '300x300',
            'format': 'PNG',
            'method': 'app_directory',
          });
          
      print('✅ QR image info saved to Firestore');
    } catch (e) {
      print('⚠️ Error saving image info to Firestore: $e');
    }
  }

  Future<void> _saveShareInfoToFirestore() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.firestore
          .collection('qr_shares')
          .doc('${_qrId}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'qrId': _qrId,
            'userId': _userId,
            'sharedAt': FieldValue.serverTimestamp(),
            'method': 'share_plus',
          });
          
      print('✅ QR share info saved to Firestore');
    } catch (e) {
      print('⚠️ Error saving share info to Firestore: $e');
    }
  }

  // 🔹 **بناء ويدجيت الـ QR Code للتقاط الصورة**
  Widget _buildQRCodeWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 280.0,
            foregroundColor: AppColors.textDarkTeal,
            errorStateBuilder: (cxt, err) {
              return const Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Error generating QR code",
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  'Patient ID: ${_userId.substring(0, min(_userId.length, 8))}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Generated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateReceptionScan() async {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await Future.delayed(const Duration(seconds: 2));
      
      await authService.firestore
          .collection('qr_scans')
          .doc(_qrId)
          .update({
            'status': 'scanned',
            'scannedAt': FieldValue.serverTimestamp(),
            'scannedBy': 'reception_desk_01',
          });
      
      final qrDoc = await authService.firestore
          .collection('qr_scans')
          .doc(_qrId)
          .get();
      
      if (qrDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckInSuccessScreen(
              qrId: _qrId,
              appointmentId: widget.appointmentId,
            ),
          ),
        );
      } else {
        _showError('QR validation failed');
        setState(() => _isScanning = false);
      }
      
    } catch (e) {
      _showError('Scan failed: $e');
      setState(() => _isScanning = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _refreshQRCode() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating new QR Code...';
    });
    await _generateUserQRCode();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryTeal),
              SizedBox(height: 20),
              Text('Generating your QR Code...'),
            ],
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userName = _userData?['name'] ?? currentUser?.displayName ?? 'User';
    final userEmail = _userData?['email'] ?? currentUser?.email ?? '';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Clinic Check-In",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryTeal),
            onPressed: _refreshQRCode,
            tooltip: 'Refresh QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildUserInfoCard(userName, userEmail),
            
            const SizedBox(height: 20),
            
            Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryCyan, AppColors.primaryTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Medical QR Code",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Text(
                      _qrId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    _buildQRCodeWidget(),
                    
                    const SizedBox(height: 30),
                    
                    if (_statusMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      "Show this QR code at reception for instant check-in",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    const Text(
                      "Code refreshes every 5 minutes",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60, 
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 🔹 **الأزرار المعدلة: حفظ ومشاركة**
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.save_alt,
                    label: 'Save to App',
                    color: AppColors.accentOrange,
                    onPressed: _saveQRImageToApp,
                    isLoading: _isSavingImage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Share QR',
                    color: AppColors.primaryCyan,
                    onPressed: _shareQRImage,
                    isLoading: _isSavingImage,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _simulateReceptionScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDarkTeal,
                  disabledBackgroundColor: AppColors.textDarkTeal.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isScanning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Simulate Reception Scan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'QR Code Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('Save', 'To app folder (Documents)'),
                  _buildInfoRow('Share', 'Via any app (WhatsApp, Email, etc.)'),
                  _buildInfoRow('Format', 'PNG - High Quality'),
                  _buildInfoRow('QR ID', _qrId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String userName, String userEmail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.substring(0, min(userName.length, 2)).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDarkTeal,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                
                if (widget.appointmentId != null && widget.appointmentId != 'N/A') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Appointment: ${widget.appointmentId!.substring(0, min(widget.appointmentId!.length, 8))}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'READY',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 20),
        label: isLoading 
            ? const Text('Processing...')
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textDarkTeal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
}