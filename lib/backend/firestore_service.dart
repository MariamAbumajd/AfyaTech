import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة بيانات مستخدم جديد
  Future<void> addUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection("Users").doc(uid).set(data);
  }

  // تحديث بيانات المستخدم
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection("Users").doc(uid).update(data);
  }

  // جلب بيانات مستخدم
  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestore.collection("Users").doc(uid).get();
  }
   // 1. إضافة موعد جديد
  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    final appointmentId = _firestore.collection('appointments').doc().id;
    appointmentData['appointmentId'] = appointmentId;
    appointmentData['createdAt'] = FieldValue.serverTimestamp();
    
    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .set(appointmentData);
  }

  // 2. جلب موعد معين
  Future<DocumentSnapshot> getAppointment(String appointmentId) async {
    return await _firestore.collection('appointments').doc(appointmentId).get();
  }

  // 3. تحديث حالة الموعد
  Future<void> updateAppointmentStatus(
    String appointmentId, 
    String status
  ) async {
    await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  // 4. جلب كل مواعيد مستخدم معين
  Future<QuerySnapshot> getUserAppointments(String userId) async {
    return await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('date')
        .get();
  }

  // 5. جلب بيانات دكتور
  Future<DocumentSnapshot> getDoctor(String doctorId) async {
    return await _firestore.collection('doctors').doc(doctorId).get();
  }

  // 6. إضافة دكتور جديد
  Future<void> addDoctor(Map<String, dynamic> doctorData) async {
    final doctorId = doctorData['doctorId'] ?? _firestore.collection('doctors').doc().id;
    await _firestore.collection('doctors').doc(doctorId).set(doctorData);
  }

  // 7. دالة للبحث في المواعيد
  Future<QuerySnapshot> searchAppointments({
    String? userId,
    String? doctorId,
    String? status,
    String? date,
  }) async {
    Query query = _firestore.collection('appointments');
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (doctorId != null) {
      query = query.where('doctorId', isEqualTo: doctorId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (date != null) {
      query = query.where('date', isEqualTo: date);
    }
    
    return await query.get();
  }

}
