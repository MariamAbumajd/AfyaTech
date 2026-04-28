import 'package:flutter/material.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF088F8F),
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: const [
              Text(
                "See All",
                style: TextStyle(fontSize: 12, color: Color(0xFF4DBFD8)),
              ),
              Icon(Icons.chevron_right, size: 16, color: Color(0xFF4DBFD8)),
            ],
          ),
        ),
      ],
    );
  }
}