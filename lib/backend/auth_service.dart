import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 **التعديل: جعله متغير مباشر بدلاً من دالة**
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔹 دالة للحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  
  // 🔹 دالة للحصول على userId
  String get userId => _auth.currentUser?.uid ?? '';
  
  // تسجيل مستخدم جديد مع حفظ الاسم
  Future<User?> signUp(String email, String password, String name) async {
    try {
      // 1. إنشاء المستخدم في Authentication
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. حفظ بيانات المستخدم في Firestore
      await _firestore
          .collection("users")
          .doc(cred.user!.uid)
          .set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': cred.user!.uid,
          });
      
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // تسجيل الدخول
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 🔹 **جديد: دالة لتغيير كلمة المرور الفعلية**
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔄 محاولة تغيير كلمة المرور...');
      
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'يجب تسجيل الدخول أولاً',
        };
      }
      
      final email = user.email;
      if (email == null) {
        return {
          'success': false,
          'error': 'لا يوجد بريد إلكتروني مرتبط بحسابك',
        };
      }
      
      // 🔹 1. إعادة المصادقة باستخدام كلمة المرور القديمة
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // 🔹 2. تغيير كلمة المرور إلى الجديدة
      await user.updatePassword(newPassword);
      
      // 🔹 3. حفظ سجل تغيير كلمة المرور في Firestore
      await _firestore
          .collection('password_changes')
          .doc('${user.uid}_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'userId': user.uid,
            'email': email,
            'changedAt': FieldValue.serverTimestamp(),
            'deviceInfo': 'mobile',
            'ipAddress': 'unknown',
          });
      
      print('✅ تم تغيير كلمة المرور بنجاح');
      
      return {
        'success': true,
        'message': 'تم تغيير كلمة المرور بنجاح',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ خطأ في تغيير كلمة المرور: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'كلمة المرور الحالية غير صحيحة';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور الجديدة ضعيفة جداً. يجب أن تكون 6 أحرف على الأقل';
          break;
        case 'requires-recent-login':
          errorMessage = 'يجب تسجيل الدخول مرة أخرى قبل تغيير كلمة المرور';
          break;
        default:
          errorMessage = 'فشل تغيير كلمة المرور: ${e.message}';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }

  // دالة لاسترجاع بيانات المستخدم من Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // دالة لإصلاح بيانات مستخدم موجود
  Future<void> fixExistingUserData(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }
      
      await _firestore
          .collection("users")
          .doc(user.uid)
          .set({
            'name': name,
            'email': user.email,
            'fixedAt': FieldValue.serverTimestamp(),
            'userId': user.uid,
          }, SetOptions(merge: true));
      
      print("Fixed user data for: ${user.email}");
    } catch (e) {
      print("Error fixing user data: $e");
      throw Exception("Failed to fix user data");
    }
  }

  // دالة للحصول على اسم المستخدم الحالي
  Future<String> getCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "User";
      
      final userData = await getUserData(user.uid);
      
      if (userData != null && userData.containsKey('name')) {
        return userData['name'];
      }
      
      if (user.email != null) {
        final email = user.email!;
        final namePart = email.split('@').first;
        return namePart[0].toUpperCase() + namePart.substring(1);
      }
      
      return "User";
    } catch (e) {
      print("Error getting current user name: $e");
      return "User";
    }
  }

  // دالة لحجز موعد جديد
  Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String appointmentType,
    required String date,
    required String time,
    required double price,
    required String clinicLocation,
    String notes = '',
    String symptoms = '',
  }) async {
    try {
      print('📅 محاولة حجز موعد...');
      
      // التحقق من تسجيل الدخول
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'يجب تسجيل الدخول أولاً',
        };
      }
      
      final userId = user.uid;
      
      // توليد ID فريد للموعد
      final appointmentId = _firestore.collection('appointments').doc().id;
      
      // بيانات الموعد
      final appointmentData = {
        'appointmentId': appointmentId,
        'userId': userId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'appointmentType': appointmentType,
        'date': date,
        'time': time,
        'status': 'pending',
        'paymentStatus': 'pending',
        'price': price,
        'clinicLocation': clinicLocation,
        'notes': notes,
        'symptoms': symptoms,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // حفظ الموعد في Firestore
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .set(appointmentData);
      
      print('✅ تم حجز الموعد بنجاح: $appointmentId');
      
      return {
        'success': true,
        'appointmentId': appointmentId,
        'message': 'تم حجز الموعد بنجاح',
        'data': appointmentData,
      };
    } catch (e) {
      print('❌ خطأ في حجز الموعد: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // دالة لمعالجة الدفع
  Future<Map<String, dynamic>> processPayment({
    required String appointmentId,
    required String paymentMethod,
    required double amount,
    String cardNumber = '',
    String cardHolder = '',
    String expiryDate = '',
  }) async {
    try {
      print('💳 معالجة الدفع للموعد: $appointmentId');
      
      // تحديث حالة الدفع
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
        'paymentDate': FieldValue.serverTimestamp(),
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // حفظ تفاصيل الدفع إذا كانت بطاقة
      if (paymentMethod == 'card') {
        await _firestore
            .collection('payments')
            .doc(appointmentId)
            .set({
          'appointmentId': appointmentId,
          'userId': _auth.currentUser!.uid,
          'paymentMethod': 'card',
          'amount': amount,
          'cardLast4': cardNumber.length > 4 ? cardNumber.substring(cardNumber.length - 4) : '',
          'paymentDate': FieldValue.serverTimestamp(),
        });
      }
      
      print('Appointment Done Successfully✅ ');
      
      return {
        'success': true,
        'message': 'Appointment Done Successfully',
      };
    } catch (e) {
      print('Error in Appointment Process❌   $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // دالة لجلب مواعيد المستخدم
  Stream<List<Map<String, dynamic>>> getUserAppointments() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();
    });
  }

  // دالة لحذف موعد
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      print('Appointment Cancelled Successfully✅  $appointmentId');
    } catch (e) {
      print('Appointment Error❌  $e');
    }
  }

  // 🔹 دالة إنشاء QR Code للمستخدم
  Future<String> generateUserQRCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // إنشاء QR Code فريد لكل مستخدم
      final qrData = {
        'userId': user.uid,
        'email': user.email,
        'createdAt': DateTime.now().toIso8601String(),
        'qrId': 'AFYA-${DateTime.now().millisecondsSinceEpoch}',
      };
      
      final qrDataString = jsonEncode(qrData);
      
      // حفظ بيانات الـ QR في Firestore
      await _firestore
          .collection('user_qr_codes')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'qrData': qrDataString,
            'lastGenerated': FieldValue.serverTimestamp(),
            'isActive': true,
          });
      
      return qrDataString;
    } catch (e) {
      print('Error generating QR code: $e');
      throw Exception('Failed to generate QR code');
    }
  }

  // 🔹 دالة للتحقق من صحة الـ QR Code
  Future<Map<String, dynamic>> validateQRCode(String qrData) async {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      final userId = decoded['userId'];
      final qrId = decoded['qrId'];
      
      // التحقق من وجود المستخدم
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {
          'valid': false,
          'error': 'User not found',
        };
      }
      
      // التحقق من الـ QR في قاعدة البيانات
      final qrDoc = await _firestore.collection('user_qr_codes').doc(userId).get();
      if (!qrDoc.exists) {
        return {
          'valid': false,
          'error': 'QR code not registered',
        };
      }
      
      final qrDataFromDB = qrDoc.data();
      final isActive = qrDataFromDB?['isActive'] ?? false;
      
      if (!isActive) {
        return {
          'valid': false,
          'error': 'QR code is inactive',
        };
      }
      
      // التحقق من وقت إنشاء الـ QR (لا يقبل قديم أكثر من 5 دقائق)
      final createdAt = DateTime.parse(decoded['createdAt']);
      final now = DateTime.now();
      final difference = now.difference(createdAt).inMinutes;
      
      if (difference > 5) {
        return {
          'valid': false,
          'error': 'QR code expired',
        };
      }
      
      return {
        'valid': true,
        'userId': userId,
        'userData': userDoc.data(),
        'message': 'QR code validated successfully',
      };
    } catch (e) {
      print('Error validating QR code: $e');
      return {
        'valid': false,
        'error': 'Invalid QR code format',
      };
    }
  }

  // 🔹 دالة مساعدة للحصول على Firestore instance
  FirebaseFirestore get firestore => _firestore;
}