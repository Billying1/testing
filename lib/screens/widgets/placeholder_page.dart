import 'package:flutter/material.dart';

class PlaceholderView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PlaceholderView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6D0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 44, color: const Color(0xFF5A9B1F)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
