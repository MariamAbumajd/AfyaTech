import 'package:flutter/material.dart';

class SpecialtiesList extends StatelessWidget {
  const SpecialtiesList({super.key});

  @override
  Widget build(BuildContext context) {
    final specialties = [
      {
        'name': 'Cardiology',
        'icon': Icons.favorite_border,
        'count': '12 doctors',
        'color': const Color(0xFFFFE5E5),
      },
      {
        'name': 'Pediatrics',
        'icon': Icons.child_care,
        'count': '8 doctors',
        'color': const Color(0xFFE9F7EF),
      },
      {
        'name': 'Neurology',
        'icon': Icons.psychology,
        'count': '10 doctors',
        'color': const Color(0xFFF3E5E4),
      },
      {
        'name': 'Eye',
        'icon': Icons.visibility,
        'count': '6 doctors',
        'color': const Color(0xFFC6E4F2),
      },
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specialties.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final item = specialties[index];
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item['color'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: const Color(0xFF088F8F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    color: Color(0xFF088F8F),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item['count'] as String,
                  style: const TextStyle(
                    color: Color(0xFF088F8F),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}