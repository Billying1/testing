import 'package:flutter/material.dart';

import '../../models/charging_station.dart';
import '../../screens/main_pages/comments_page.dart';

class SelectedStationCard extends StatelessWidget {
  final ChargingStation station;
  final bool favorite;
  final VoidCallback onFavoriteTap;

  const SelectedStationCard({
    super.key,
    required this.station,
    required this.favorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6D0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.ev_station,
              color: Color(0xFF5A9B1F),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${station.city} • ${station.address}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  station.power.isEmpty
                      ? 'Đang cập nhật công suất'
                      : 'Công suất ${station.power}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? Colors.redAccent : Colors.black45,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsPage(
                        stationId: station.id,
                        stationName: station.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.comment_outlined),
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
