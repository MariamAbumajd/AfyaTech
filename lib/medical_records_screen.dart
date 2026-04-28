import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'app_colorspart2.dart';
import 'search_records_screen.dart';
import '../backend/auth_service.dart';
import '../backend/storage_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String? documentId; // معلمة اختيارية من الإشعارات

  const MedicalRecordsScreen({super.key, this.documentId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  int _selectedFilterIndex = 0;
  bool _isLoading = false;
  String? _userInitials;
  String? _userName;
  Map<String, dynamic>? _specificDocument; // مستند محدد من الإشعارات
  
  final List<String> _filters = [
    "Prescriptions",
    "Lab Tests",
    "X-Rays & Imaging",
    "Medical History",
    "Surgical Appointments",
    "Uploaded Documents",
  ];

  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadSpecificDocumentIfNeeded();
  }

  // 🔹 جلب بيانات المستخدم
  void _getUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final userName = await authService.getCurrentUserName();
      if (userName.length >= 2) {
        setState(() {
          _userInitials = userName.substring(0, 2).toUpperCase();
          _userName = userName;
        });
      }
    } catch (e) {
      print("Error getting user data: $e");
    }
  }

  // 🔹 جلب مستند محدد إذا كان هناك documentId من الإشعارات
  void _loadSpecificDocumentIfNeeded() async {
    if (widget.documentId != null && widget.documentId!.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        
        final docSnapshot = await _firestore
            .collection('medical_records')
            .doc(widget.documentId)
            .get();
        
        if (docSnapshot.exists) {
          setState(() {
            _specificDocument = docSnapshot.data();
            _isLoading = false;
          });
          
          // تحديد الفلتر المناسب بناءً على نوع المستند
          _selectAppropriateFilter(_specificDocument?['recordType']);
        } else {
          setState(() => _isLoading = false);
          print("Document not found: ${widget.documentId}");
        }
      } catch (e) {
        print("Error loading document: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 تحديد الفلتر المناسب بناءً على نوع المستند
  void _selectAppropriateFilter(String? recordType) {
    if (recordType == null) return;
    
    final type = recordType.toLowerCase();
    int index = 5; // Default: Uploaded Documents
    
    if (type.contains('prescription')) {
      index = 0;
    } else if (type.contains('lab') || type.contains('test')) {
      index = 1;
    } else if (type.contains('xray') || type.contains('imaging')) {
      index = 2;
    } else if (type.contains('history')) {
      index = 3;
    } else if (type.contains('surgery')) {
      index = 4;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _selectedFilterIndex = index);
      }
    });
  }

  // 🔹 رفع ملف إلى التخزين
  Future<void> _uploadMedicalFile(String fileType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('Please login to upload files');
        return;
      }

      final originalName = pickedFile.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = originalName.split('.').last.toLowerCase();
      final newFileName = "${fileType}_$timestamp.$fileExtension";
      
      print('📤 Uploading file: $newFileName');

      final storageService = StorageService();
      final fileUrl = await storageService.uploadMedicalFile(
        user.uid,
        File(pickedFile.path),
        customName: newFileName,
      );

      final fileSize = await File(pickedFile.path).length();
      
      await _firestore.collection('medical_records').add({
        'userId': user.uid,
        'userName': _userName ?? 'User',
        'fileType': fileType,
        'recordType': _getFirestoreRecordType(fileType),
        'fileName': newFileName,
        'originalFileName': originalName,
        'fileUrl': fileUrl,
        'uploadedAt': Timestamp.now(),
        'status': 'pending_review',
        'fileSize': fileSize,
        'formattedDate': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        'displayName': _getDisplayName(originalName),
      });

      _showSuccessDialog('✅ File uploaded successfully!');
      
      setState(() {});

    } catch (e) {
      print('❌ Upload error: $e');
      _showErrorDialog('Failed to upload file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 تحويل نوع الملف لنوع Firestore
  String _getFirestoreRecordType(String fileType) {
    switch (fileType) {
      case 'lab_test':
        return 'lab_test';
      case 'xray':
        return 'imaging';
      case 'document':
        return 'document';
      default:
        return fileType;
    }
  }

  // 🔹 الحصول على اسم العرض
  String _getDisplayName(String originalName) {
    if (originalName.length > 20) {
      return '${originalName.substring(0, 15)}...';
    }
    return originalName;
  }

  // 🔹 الحصول على سجل البيانات من Firestore
  Stream<QuerySnapshot> _getMedicalRecordsStream(String recordType) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('medical_records')
        .where('userId', isEqualTo: user.uid)
        .where('recordType', isEqualTo: recordType)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // 🔹 الحصول على نوع السجل الحالي
  String _getCurrentRecordType() {
    switch (_selectedFilterIndex) {
      case 0: return 'prescription';
      case 1: return 'lab_test';
      case 2: return 'imaging';
      case 3: return 'medical_history';
      case 4: return 'surgery';
      case 5: return 'document';
      default: return 'document';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordType = _getCurrentRecordType();
    
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
          "My Medical Records",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan,
              shape: BoxShape.circle,
            ),
            child: Text(
              _userInitials ?? 'JD',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),

                // شريط البحث
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchRecordsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            "Search in your medical records...",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // قائمة الفلاتر
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilterIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryCyan
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryCyan.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  color: isSelected ? AppColors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // المحتوى الديناميكي
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRecordsSection(recordType),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecordsSection(String recordType) {
    // عرض المستند المحدد إذا كان موجوداً
    if (_specificDocument != null && widget.documentId != null) {
      return Column(
        children: [
          // إشعار بأنه يتم عرض مستند محدد
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryCyan, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryCyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Viewing specific document from notification",
                    style: TextStyle(
                      color: AppColors.textDarkTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() => _specificDocument = null);
                  },
                ),
              ],
            ),
          ),
          
          // عرض المستند المحدد
          _buildSpecificDocumentCard(_specificDocument!),
          
          const SizedBox(height: 20),
          
          // عرض باقي السجلات
          Expanded(
            child: _buildMedicalRecordsStream(recordType),
          ),
          
          _buildUploadSection(),
        ],
      );
    }
    
    // العرض الطبيعي بدون مستند محدد
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMedicalRecordsStream(recordType),
        ),
        _buildUploadSection(),
      ],
    );
  }

  Widget _buildSpecificDocumentCard(Map<String, dynamic> document) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(document),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.primaryCyan, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForRecordType(document['recordType']?.toString() ?? ''),
                color: AppColors.primaryCyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document['displayName']?.toString() ?? 'Medical Document',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDarkTeal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "From notification: ${document['formattedDate']?.toString() ?? 'Unknown date'}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap to view details",
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.notifications_active,
              color: AppColors.primaryCyan,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          "Quick Upload",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkTeal,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildUploadButton(
              "Lab Test",
              Icons.science_outlined,
              AppColors.accentOrange,
              () => _uploadMedicalFile('lab_test'),
            ),
            const SizedBox(width: 10),
            _buildUploadButton(
              "X-Ray",
              Icons.camera_alt_outlined,
              AppColors.accentOrange,
              () => _uploadMedicalFile('xray'),
            ),
            const SizedBox(width: 10),
            _buildUploadButton(
              "Document",
              Icons.note_add_outlined,
              AppColors.accentOrange,
              () => _uploadMedicalFile('document'),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMedicalRecordsStream(String recordType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMedicalRecordsStream(recordType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoRecordsView();
        }

        final records = snapshot.data!.docs;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final doc = records[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRecordCardFromFirestore(data);
          },
        );
      },
    );
  }

  Widget _buildRecordCardFromFirestore(Map<String, dynamic> data) {
    final fileName = data['displayName'] ?? 
                    data['originalFileName'] ?? 
                    data['fileName']?.toString() ?? 
                    'Medical Document';
    final uploadedAt = data['uploadedAt'];
    final fileSize = data['fileSize'] as int? ?? 0;
    final recordType = data['recordType']?.toString() ?? 'document';
    final status = data['status']?.toString() ?? 'pending_review';
    final formattedDate = data['formattedDate'] ?? _formatDate(uploadedAt);
    
    return _buildRecordCard(
      fileName,
      'Uploaded: $formattedDate',
      _formatFileSize(fileSize),
      _getIconForRecordType(recordType),
      isFile: true,
      statusText: _getStatusText(status),
      onTap: () => _navigateToDetailScreen(data),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown Date';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    
    return 'Unknown Date';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  IconData _getIconForRecordType(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'prescription':
        return Icons.medication_outlined;
      case 'lab_test':
        return Icons.science_outlined;
      case 'imaging':
      case 'xray':
        return Icons.image_outlined;
      case 'medical_history':
        return Icons.history_outlined;
      case 'surgery':
        return Icons.local_hospital_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'View';
    }
  }

  Widget _buildNoRecordsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Medical Records Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You can upload your first medical document using the buttons below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetailScreen(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailScreen(
          record: data,
        ),
      ),
    );
  }

  Widget _buildUploadButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    String title,
    String subtitle,
    String dateOrTag,
    IconData icon, {
    bool isFile = false,
    String? statusText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryCyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDarkTeal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateOrTag,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isFile)
              Column(
                children: [
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    color: AppColors.primaryCyan,
                    size: 24,
                  ),
                  if (statusText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// شاشة تفاصيل السجل
class RecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const RecordDetailScreen({super.key, required this.record});

  String _getSafeString(dynamic value, {String defaultValue = 'Unknown'}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  IconData _getIconForRecordType() {
    final type = _getSafeString(record['recordType']).toLowerCase();
    
    if (type.contains('lab') || type.contains('test')) {
      return Icons.science_outlined;
    } else if (type.contains('prescription') || type.contains('medication')) {
      return Icons.medication_outlined;
    } else if (type.contains('xray') || type.contains('imaging')) {
      return Icons.image_outlined;
    } else if (type.contains('surgery') || type.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (type.contains('history')) {
      return Icons.history_outlined;
    } else {
      return Icons.description_outlined;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    
    final statusMap = {
      'pending_review': 'Pending Review',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'uploaded': 'Uploaded',
      'processing': 'Processing',
    };
    
    return statusMap[status.toLowerCase()] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getSafeString(record['displayName'] ?? record['originalFileName'], 
                      defaultValue: 'Medical Record');
    final recordType = _getSafeString(record['recordType'], 
                       defaultValue: 'document').toUpperCase();
    final date = _getSafeString(record['formattedDate'], 
                    defaultValue: 'Unknown Date');
    final userName = _getSafeString(record['userName'], 
                     defaultValue: 'User');
    final fileSize = _getSafeString(record['fileSize'], 
                     defaultValue: '0');
    final status = _formatStatus(record['status']?.toString());
    final fileUrl = record['fileUrl']?.toString();
    final fileSizeFormatted = _formatFileSize(int.tryParse(fileSize) ?? 0);
    
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
          "Record Details",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForRecordType(),
                      size: 50,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkTeal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recordType,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildDetailRow(Icons.calendar_today, "Upload Date", date),
                  const SizedBox(height: 15),
                  _buildDetailRow(
                    Icons.person_outline,
                    "Uploaded By",
                    userName,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow(
                    Icons.storage,
                    "File Size",
                    fileSizeFormatted,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow(
                    Icons.info_outline,
                    "Status",
                    status,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (fileUrl != null && fileUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('File URL: $fileUrl');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening file: $title'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "Download / View File",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 15),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkTeal,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}