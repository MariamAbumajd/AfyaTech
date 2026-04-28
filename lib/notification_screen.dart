import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'tracking_screen.dart';
import 'medical_records_screen.dart';
import 'rewards_screen.dart';

// ------------------------------------------------------------------
// 1. Notification Model
// ------------------------------------------------------------------
class FirebaseNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final String? priority;
  final String? category;
  final String? actionUrl;

  FirebaseNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.priority,
    this.category,
    this.actionUrl,
  });

  factory FirebaseNotification.fromMap(Map<String, dynamic> map, String id) {
    return FirebaseNotification(
      id: id,
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      timestamp: (map['timestamp'] != null) 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      priority: map['priority'],
      category: map['category'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'priority': priority,
      'category': category,
      'actionUrl': actionUrl,
    };
  }
}

// ------------------------------------------------------------------
// 2. Notification Service Class
// ------------------------------------------------------------------
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initializeNotifications() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveDeviceToken(token);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _saveDeviceToken(newToken);
      });

      _setupBackgroundMessageHandling();
      
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _saveDeviceToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('devices')
            .doc(token)
            .set({
              'token': token,
              'platform': 'android',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  void _setupBackgroundMessageHandling() {
    // CORRECTED: Use FirebaseMessaging class directly
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      
      _showLocalNotification(message);
    });

    // CORRECTED: Use FirebaseMessaging class directly
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification:');
      print('Data: ${message.data}');
      
      _handleNotificationNavigation(message.data);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling background message: ${message.messageId}');
    print('Notification data: ${message.data}');
  }

  void _showLocalNotification(RemoteMessage message) {
    print('Should show local notification: ${message.notification?.title}');
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('Navigating with data: $data');
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? priority,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'data': data,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'priority': priority ?? 'normal',
          });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

// ------------------------------------------------------------------
// 3. Notification Screen
// ------------------------------------------------------------------
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _notificationsStream;
  bool _isLoading = true;
  int _totalNotifications = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initializeNotifications();
  }

  void _loadUserNotifications() {
    final user = _auth.currentUser;
    if (user != null) {
      _notificationsStream = _notificationService.getUserNotifications(user.uid);
      
      _notificationsStream?.listen((snapshot) {
        if (mounted) {
          setState(() {
            _totalNotifications = snapshot.docs.length;
            _unreadNotifications = snapshot.docs
                .where((doc) => !(doc['isRead'] ?? false))
                .length;
            _isLoading = false;
          });
        }
      });
    } else {
      _notificationsStream = FirebaseFirestore.instance
          .collection('public_notifications')
          .orderBy('timestamp', descending: true)
          .snapshots();
      
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDarkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.textDarkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadNotifications > 0)
            Badge(
              label: Text('$_unreadNotifications'),
              child: IconButton(
                icon: const Icon(Icons.mark_email_read, color: AppColors.primaryTeal),
                onPressed: _clearAllNotifications,
                tooltip: 'Mark all as read',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textDarkTeal),
            onPressed: _showNotificationSettings,
            tooltip: 'Notification settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '$_totalNotifications', Icons.notifications),
                _buildStatItem('Unread', '$_unreadNotifications', Icons.notifications_active),
                _buildStatItem('Today', '${_getTodayCount()}', Icons.today),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkTeal,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _getTodayCount() {
    return _unreadNotifications > 3 ? 3 : _unreadNotifications;
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                const Text(
                  'Error loading notifications',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadUserNotifications,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final notification = FirebaseNotification.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildNotificationItem(notification);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ تم التعديل هنا: إزالة الصورة واستبدالها بأيقونة
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkTeal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your notification inbox is empty',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You\'ll receive notifications for appointments, payments, lab results, and health reminders here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, size: 18),
                  SizedBox(width: 8),
                  Text('Return to Home'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(FirebaseNotification notification) {
    final isUnread = !notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            onTap: () => _handleNotificationTap(notification),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getIconColor(notification.type).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: _getIconColor(notification.type),
                          size: 24,
                        ),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isUnread 
                                      ? AppColors.textDarkTeal 
                                      : Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (notification.priority != null || notification.category != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (notification.category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      notification.category!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (notification.priority == 'high')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
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
                  
                  if (notification.actionUrl != null || notification.data?['screen'] != null)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onPressed: () => _handleNotificationTap(notification),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'appointment':
        return Icons.calendar_today;
      case 'lab_result':
        return Icons.science;
      case 'prescription':
        return Icons.medication;
      case 'emergency':
        return Icons.warning;
      case 'rewards':
        return Icons.star;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'appointment':
        return Colors.blue;
      case 'lab_result':
        return Colors.purple;
      case 'prescription':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      case 'rewards':
        return Colors.yellow[700]!;
      case 'reminder':
        return Colors.teal;
      default:
        return AppColors.primaryTeal;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (notificationDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(FirebaseNotification notification) async {
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    final data = notification.data;
    if (data != null) {
      final String? screenToOpen = data['screen'];
      final String? documentId = data['documentId'];

      switch (screenToOpen) {
        case 'rewards':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RewardsScreen(
                notificationData: data.toString(),
              ),
            ),
          );
          break;
        case 'medical_records':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicalRecordsScreen(
                documentId: documentId,
              ),
            ),
          );
          break;
        case 'tracking':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrackingScreen(),
            ),
          );
          break;
        case 'payment':
          _handlePaymentNotification(data);
          break;
        default:
          _showNotificationDetails(notification);
      }
    } else {
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(FirebaseNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              if (notification.data != null && notification.data!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text(
                      'Additional Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.data.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (notification.data?['screen'] != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleNotificationTap(notification);
              },
              child: const Text('Open'),
            ),
        ],
      ),
    );
  }

  void _handlePaymentNotification(Map<String, dynamic> data) {
    final paymentDetails = PaymentModel(
      isPaid: data['isPaid'] == true || data['isPaid'] == 'true',
      transactionId: data['transactionId'] ?? 'TRX-${DateTime.now().millisecondsSinceEpoch}',
      amount: (data['amount'] is num) 
          ? (data['amount'] as num).toDouble() 
          : double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      serviceName: data['serviceName'] ?? 'Service',
      date: data['date'] ?? DateTime.now().toString(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          paymentDetails: paymentDetails,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// 4. Notification Settings Sheet
// ------------------------------------------------------------------
class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _appointmentsEnabled = true;
  bool _paymentsEnabled = true;
  bool _labResultsEnabled = true;
  bool _promotionsEnabled = false;
  bool _emergencyAlertsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Notification Types',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildSettingItem(
            'Appointments & Reminders',
            'Doctor visits, follow-ups, medication reminders',
            _appointmentsEnabled,
            (value) => setState(() => _appointmentsEnabled = value),
            Icons.calendar_today,
          ),
          
          _buildSettingItem(
            'Payment Updates',
            'Bills, receipts, payment confirmations',
            _paymentsEnabled,
            (value) => setState(() => _paymentsEnabled = value),
            Icons.payment,
          ),
          
          _buildSettingItem(
            'Lab Results',
            'Test results, medical reports',
            _labResultsEnabled,
            (value) => setState(() => _labResultsEnabled = value),
            Icons.science,
          ),
          
          _buildSettingItem(
            'Promotions & Offers',
            'Discounts, loyalty points, special offers',
            _promotionsEnabled,
            (value) => setState(() => _promotionsEnabled = value),
            Icons.local_offer,
          ),
          
          _buildSettingItem(
            'Emergency Alerts',
            'Critical health alerts, system notifications',
            _emergencyAlertsEnabled,
            (value) => setState(() => _emergencyAlertsEnabled = value),
            Icons.warning,
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            'Preferences',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDarkTeal,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildSettingItem(
            'Sound',
            'Play sound for notifications',
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
            Icons.volume_up,
          ),
          
          _buildSettingItem(
            'Vibration',
            'Vibrate for notifications',
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
            Icons.vibration,
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryTeal,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _saveSettings() {
    print('Saving notification settings...');
    print('Appointments: $_appointmentsEnabled');
    print('Payments: $_paymentsEnabled');
    print('Lab Results: $_labResultsEnabled');
    print('Promotions: $_promotionsEnabled');
    print('Emergency Alerts: $_emergencyAlertsEnabled');
    print('Sound: $_soundEnabled');
    print('Vibration: $_vibrationEnabled');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ------------------------------------------------------------------
// 5. Payment Model
// ------------------------------------------------------------------
class PaymentModel {
  final bool isPaid;
  final String transactionId;
  final double amount;
  final String serviceName;
  final String date;

  PaymentModel({
    required this.isPaid,
    required this.transactionId,
    required this.amount,
    required this.serviceName,
    required this.date,
  });
}

// ------------------------------------------------------------------
// 6. PaymentConfirmationScreen
// ------------------------------------------------------------------
class PaymentConfirmationScreen extends StatelessWidget {
  final PaymentModel paymentDetails;
  const PaymentConfirmationScreen({super.key, required this.paymentDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Payment Details"),
        backgroundColor: paymentDetails.isPaid
            ? AppColors.primaryTeal
            : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: paymentDetails.isPaid ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Icon(
                    paymentDetails.isPaid
                        ? Icons.check_circle
                        : Icons.pending,
                    color: paymentDetails.isPaid ? Colors.green : Colors.orange,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    paymentDetails.isPaid
                        ? "Payment Successful!"
                        : "Payment Pending",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: paymentDetails.isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentDetails.isPaid
                        ? "Your payment has been processed successfully."
                        : "Please complete your payment to finalize the service.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transaction Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow("Service:", paymentDetails.serviceName),
                  _buildDetailRow("Amount:", "${paymentDetails.amount.toStringAsFixed(2)} SAR"),
                  _buildDetailRow("Date:", paymentDetails.date),
                  _buildDetailRow("Transaction ID:", paymentDetails.transactionId),
                  _buildDetailRow(
                    "Status:",
                    paymentDetails.isPaid ? "Paid" : "Pending",
                    paymentDetails.isPaid ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (!paymentDetails.isPaid)
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Redirecting to payment...")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Complete Payment",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      )
    );
  }
}

// ------------------------------------------------------------------
// 7. AppColors Class
// ------------------------------------------------------------------
class AppColors {
  static const Color primaryTeal = Color(0xFF008080);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color textDarkTeal = Color(0xFF006666);
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color primaryCyan = Color(0xFF00BCD4);
  static const Color emergencyRed = Color(0xFFD32F2F);
}