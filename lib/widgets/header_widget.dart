import 'package:flutter/material.dart';
import 'package:afyatech/backend/auth_service.dart';

class HeaderWidget extends StatelessWidget {
  final Future<String> Function() getUserName;
  final VoidCallback onBackPressed;
  final VoidCallback onNotificationPressed;

  const HeaderWidget({
    super.key,
    required this.getUserName,
    required this.onBackPressed,
    required this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      color: const Color(0xFFF7F8FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF088F8F),
                  size: 22,
                ),
                onPressed: onBackPressed,
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/Logo.jpg'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Color(0xFF088F8F),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  FutureBuilder(
                    future: getUserName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData) {
                        return const Text(
                          "Loading...",
                          style: TextStyle(
                            color: Color(0xFF088F8F),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return Text(
                        snapshot.data!,
                        style: const TextStyle(
                          color: Color(0xFF088F8F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 🔧 **الجزء المعدل هنا**
          Stack(
            children: [
              // 🔧 **تغيير: من Container إلى IconButton**
              IconButton(
                padding: const EdgeInsets.all(8), // 🔧 أضف padding
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white, // 🔧 خلفية بيضاء
                  shape: const CircleBorder(), // 🔧 شكل دائري
                  elevation: 2, // 🔧 ظل خفيف
                ),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF088F8F),
                ),
                onPressed: onNotificationPressed, // 🔧 هذا السطر المهم!
              ),
              // النقطة الحمراء للإشعارات غير المقروءة
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4A261), // لون برتقالي
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}