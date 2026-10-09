import 'package:flutter/material.dart';

class BrandRow extends StatelessWidget {
  const BrandRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF8BD520),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.electric_car, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'EVCS.VN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
