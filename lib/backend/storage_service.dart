import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final supabase = Supabase.instance.client;

  // رفع ملف طبي للمريض مع إمكانية تحديد اسم مخصص
  Future<String> uploadMedicalFile(String uid, File file, {String? customName}) async {
    final fileName = customName ?? "medical_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
    final filePath = "medical_files/$uid/$fileName";

    try {
      print('📁 Uploading file: $fileName');
      print('📁 File path: $filePath');
      
      // قراءة الملف
      final fileBytes = await file.readAsBytes();
      
      // رفع الملف
      await supabase.storage
          .from('medical-bucket')
          .uploadBinary(
            filePath, 
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // الحصول على الرابط العام
      final urlResponse = supabase.storage
          .from('medical-bucket')
          .getPublicUrl(filePath);

      print('✅ File uploaded successfully');
      print('🔗 Public URL: $urlResponse');
      
      return urlResponse;
    } catch (e) {
      print('❌ Upload error: $e');
      
      // محاولة بديلة
      try {
        print('🔄 Trying alternative upload method...');
        final alternativePath = "medical_files/$uid/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
        
        await supabase.storage
            .from('medical-bucket')
            .upload(alternativePath, file);
            
        final altUrl = supabase.storage
            .from('medical-bucket')
            .getPublicUrl(alternativePath);
            
        return altUrl;
      } catch (e2) {
        print('❌ Alternative upload also failed: $e2');
        rethrow;
      }
    }
  }

  // دالة لجلب قائمة ملفات المستخدم
  Future<List<Map<String, dynamic>>> getUserMedicalFiles(String uid) async {
    try {
      final files = await supabase.storage
          .from('medical-bucket')
          .list(path: 'medical_files/$uid');
      
      return files.map((file) {
        return {
          'name': file.name,
          'url': supabase.storage
              .from('medical-bucket')
              .getPublicUrl('medical_files/$uid/${file.name}'),
        };
      }).toList();
    } catch (e) {
      print('Error getting user files: $e');
      return [];
    }
  }
}