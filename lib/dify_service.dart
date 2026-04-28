import 'dart:convert';
import 'package:http/http.dart' as http;

class DifyService {
  // 👇 ضع مفتاح API الحقيقي هنا
  static const String _apiKey = 'app-mxu8pwuGsF3aNQpIdsue7EeA';
  
  // رابط موديل التنبؤ بالتأخير
  static const String _url = 'https://api.dify.ai/v1/workflows/run';

  /// دالة لاستدعاء موديل التنبؤ بالتأخير
  static Future<int> getPredictedDelay({
    required int age,
    required int hour,     // بنظام 24 ساعة
    required int day,      // (0=الإثنين, 1=الثلاثاء, ..., 6=الأحد)
    required String gender, // "Male" أو "Female"
  }) async {
    try {
      print("⏳ Sending request to Dify Prediction Model...");

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "inputs": {
            // أسماء المتغيرات يجب أن تتطابق مع إعدادات Dify
            "age": age,
            "scheduled_hour": hour,
            "day_of_week": day,
            "gender": gender
          },
          "response_mode": "blocking",
          "user": "afyatech_user"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String resultText = data['data']['outputs']['text'].toString();
        int minutes = int.tryParse(resultText) ?? 0;
        print("✅ AI Prediction: $minutes minutes delay");
        return minutes;
      } else {
        print("❌ Prediction Error: ${response.statusCode} - ${response.body}");
        return 0; // في حالة الخطأ
      }
    } catch (e) {
      print("❌ Prediction Connection Error: $e");
      return 0;
    }
  }
}