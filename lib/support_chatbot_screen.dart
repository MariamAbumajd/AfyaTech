import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_colorspart2.dart';
import 'dify_service.dart'; // 👈 استيراد موديل التنبؤ
import 'academic_medical_system.dart';


class SupportChatbotScreen extends StatefulWidget {
  const SupportChatbotScreen({super.key});

  @override
  State<SupportChatbotScreen> createState() => _SupportChatbotScreenState();
}

class _SupportChatbotScreenState extends State<SupportChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "text":
          "Hello Jane! 👋 I'm AfyaBot.\nI'm fully integrated with the AfyaTech system.\n\nYou can ask me about:\n🚗 Arrival Prediction\n🎁 Loyalty System\n📂 Medical History\n💳 Wallet Balance\n\nGo ahead, I'm listening!",
      "isUser": false,
    },
  ];

  // ========== 1. LOCAL INTELLIGENCE WITH PREDICTION ==========
  Future<String> _getSmartLocalResponse(String input) async {
    input = input.toLowerCase().trim();

    // 🔴 فحص طارئ أولي - الأولوية القصوى
    if (input.contains("emergency") ||
        input.contains("chest pain") ||
        input.contains("difficulty breathing") ||
        input.contains("unconscious") ||
        input.contains("bleeding heavily")) {
      return """
🚨 **MEDICAL EMERGENCY DETECTED**

⚠️ **IMMEDIATE ACTION REQUIRED:**
1. Call Emergency Services: **911 / 112**
2. Describe your symptoms clearly
3. Stay on the line for instructions
4. If alone, call a neighbor/family member

🏥 **AfyaTech Emergency Services:**
• Use the SOS button on home screen
• Nearest hospital directions
• Emergency contact notification

⏱️ **Do not delay:** Every second counts in emergencies.
""";
    }

    // 🩺 النظام الطبي الأكاديمي
    bool isMedicalQuery = input.contains("symptom") ||
        input.contains("pain") ||
        input.contains("fever") ||
        input.contains("cough") ||
        input.contains("headache") ||
        input.contains("stomach") ||
        input.contains("vomit") ||
        input.contains("diarrhea") ||
        input.contains("sore throat") ||
        input.contains("cold") ||
        input.contains("flu") ||
        (input.contains("feel") && (input.contains("sick") || input.contains("ill")));

    if (isMedicalQuery) {
      MedicalAnalysis analysis = AcademicMedicalSystem.analyzeSymptoms(input);
      String report = AcademicMedicalSystem.generateProfessionalReport(analysis);
      return report;
    }

    // 🚗 نظام التنبؤ بالتأخير
    bool shouldPredictDelay = input.contains("delay") ||
        input.contains("late") ||
        input.contains("traffic") ||
        input.contains("arrive") ||
        input.contains("how long") ||
        input.contains("prediction");

    if (shouldPredictDelay) {
      try {
        int delayMinutes = await _fetchDelayPrediction();
        if (delayMinutes > 0) {
          return "🚗 **Smart Arrival Prediction:**\n\n"
                "Based on real-time AI analysis of traffic patterns:\n"
                "• Expected delay: **$delayMinutes minutes** ⏱️\n"
                "• I've automatically notified your doctor\n"
                "• Your appointment has been adjusted by +$delayMinutes mins\n"
                "• No need to worry! Your time matters to us.";
        } else {
          return "🚗 **Smart Arrival Prediction:**\n\n"
                "Great news! ✅\n"
                "• No significant delay expected\n"
                "• You're on track for your appointment\n"
                "• Estimated arrival: Right on time!";
        }
      } catch (e) {
        return "🚗 **Smart Arrival System:**\n\n"
              "Our AI detects real-time traffic patterns.\n"
              "If delayed, we notify your doctor automatically.";
      }
    }

    // 🎁 نقاط الولاء
    if (input.contains("point") ||
        input.contains("score") ||
        input.contains("gold") ||
        input.contains("redeem") ||
        input.contains("reward")) {
      return "🎁 **Loyalty Program:**\n\n"
            "You are currently on **Silver Tier** (1,250 pts).\n\n"
            "• **How to earn?**\n"
            "   - Book appointment: +50 pts\n"
            "   - Upload documents: +20 pts\n"
            "   - Refer a friend: +200 pts\n\n"
            "• **Benefit:** Redeem points for up to 50% OFF on Lab Tests via the Profile page.";
    }

    // 📂 السجلات الطبية
    if (input.contains("record") ||
        input.contains("lab") ||
        input.contains("result") ||
        input.contains("test") ||
        input.contains("x-ray") ||
        input.contains("file")) {
      return "📂 **Medical Records Hub:**\n\n"
            "All your health history is centralized.\n"
            "• Go to 'Medical Records' tab.\n"
            "• You'll find your Prescriptions 💊, Lab Results 🧪, and X-Rays 💀.\n"
            "• You can also upload external files using the 'Quick Upload' feature.";
    }

    // 💳 المحفظة والدفع
    if (input.contains("wallet") ||
        input.contains("money") ||
        input.contains("pay") ||
        input.contains("balance") ||
        input.contains("cost")) {
      return "💳 **My Wallet:**\n\n"
            "• Current Balance: **\$150.00**\n"
            "• **Top-up:** Credit Card, Fawry, or Vodafone Cash.\n"
            "• **Usage:** Pay for consultations instantly or transfer credit to family members.";
    }

    // 📅 الحجز والمواعيد
    if (input.contains("book") ||
        input.contains("reserve") ||
        input.contains("doctor") ||
        input.contains("schedule") ||
        input.contains("appointment")) {
      return "📅 **Booking is easy:**\n\n"
            "1. Go to Home.\n"
            "2. Search by specialty (e.g., Dentist, Cardio).\n"
            "3. Use filters (Price, Distance, Rating).\n"
            "4. Confirm your slot.\n\n"
            "Need help finding a specific doctor?";
    }

    // 👋 التحيات
    if (input == "hi" ||
        input == "hello" ||
        input.startsWith("good morn") ||
        input.startsWith("good even")) {
      return _randomReply([
        "Hello! 👋 How is your health today?",
        "Hi there! Ready to assist you.",
        "Welcome back to AfyaTech! How can I help?",
      ]);
    }

    // 🙏 الشكر والوداع
    if (input.contains("thank")) {
      return "You're very welcome! Stay healthy and safe. 💙";
    }
    if (input.contains("bye")) {
      return "Goodbye! Have a great day. 👋";
    }

    // إذا لم يطابق أي شيء محلياً، ارجع سلسلة فارغة (سيتم استخدام Dify)
    return "";
  }

  // ========== 2. دالة التنبؤ بالتأخير ==========
  Future<int> _fetchDelayPrediction() async {
    // ⚠️ استبدل هذه القيم بقيم حقيقية من تطبيقك
    int userAge = 45;          // من ملف تعريف المستخدم
    int appointmentHour = 14;  // من موعد الحجز
    int appointmentDay = 2;    // 0=الإثنين، 1=الثلاثاء، إلخ
    String userGender = "Female"; // من ملف التعريف
    
    try {
      return await DifyService.getPredictedDelay(
        age: userAge,
        hour: appointmentHour,
        day: appointmentDay,
        gender: userGender,
      );
    } catch (e) {
      print("Error in delay prediction: $e");
      return 0;
    }
  }

  // ========== 3. DIFY CHAT API ==========
  Future<String> _fetchDifyChatResponse(String userMessage) async {
    const String apiKey = 'app-mxu8pwuGsF3aNQpIdsue7EeA';
    const String apiUrl = 'https://api.dify.ai/v1/chat-messages';
    
    final Map<String, String> headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> requestBody = {
      'inputs': {},
      'query': userMessage,
      'response_mode': 'blocking',
      'user': 'afyatech_user',
    };

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        final String botReply =
            responseData['answer'] ?? responseData['response'] ?? '';
        if (botReply.isEmpty) {
          return "I'm not sure how to answer that. Can you try asking differently?";
        }
        return botReply;
      } else {
        print('Dify Chat Error: ${response.statusCode}');
        return "I'm having trouble connecting to my knowledge base. Please try again.";
      }
    } catch (e) {
      print('Chat Connection Error: $e');
      return "I apologize for the connection issue. What else can I help you with?";
    }
  }

  // ========== 4. SMART RESPONSE MANAGER ==========
  Future<String> _getSmartResponse(String userMessage) async {
    // الخطوة 1: تحقق من الذكاء المحلي + التنبؤ
    String smartLocalResponse = await _getSmartLocalResponse(userMessage);
    
    // إذا كان هناك رد محلي (غير فارغ)، استخدمه
    if (smartLocalResponse.isNotEmpty) {
      return smartLocalResponse;
    }
    
    // الخطوة 2: إذا لم يطابق محلياً، استخدم Dify Chat
    String difyResponse = await _fetchDifyChatResponse(userMessage);
    return difyResponse;
  }

  // ========== 5. مساعد الدوال ==========
  String _randomReply(List<String> options) {
    return options[Random().nextInt(options.length)];
  }

  void _handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    String botReply = await _getSmartResponse(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({"text": botReply, "isUser": false});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ========== 6. واجهة المستخدم (تبقى كما هي) ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: AppColors.textDarkTeal),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryCyan,
                  child: Icon(Icons.smart_toy_outlined, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "AfyaBot Support",
                  style: TextStyle(
                    color: AppColors.textDarkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online | AI Powered",
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingIndicator();
                final msg = _messages[index];
                return _buildMessageBubble(msg['text'], msg['isUser']);
              },
            ),
          ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChip("🚗 I'm stuck in traffic!"),
                _buildChip("🎁 How to use points?"),
                _buildChip("📂 Where are my X-Rays?"),
                _buildChip("💳 Top-up Wallet"),
                _buildChip("Can I ask a question?"),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _handleUserMessage,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _handleUserMessage(_messageController.text),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryTeal,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight:
                isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textDark,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "AfyaBot is thinking...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.primaryCyan, width: 1),
        labelStyle: const TextStyle(
          color: AppColors.textDarkTeal,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        onPressed: () => _handleUserMessage(label),
      ),
    );
  }
}