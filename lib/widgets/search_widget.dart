import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final Function(String)? onSearchChanged;

  const SearchWidget({super.key, this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF0A8E9C), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search doctor or specialty...",
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Color(0xFF088F8F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: onSearchChanged,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0A8E9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, size: 20),
                color: const Color(0xFF0A8E9C),
                padding: EdgeInsets.zero,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}