import 'package:flutter/material.dart';

import '../../models/charging_station.dart';

class StationMarker extends StatelessWidget {
  final ChargingStation station;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const StationMarker({
    super.key,
    required this.station,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1.12 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.86),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                station.city,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.location_on,
                  size: selected ? 34 : 30,
                  color: selected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF6FAE23),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        size: 10,
                        color: favorite ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}