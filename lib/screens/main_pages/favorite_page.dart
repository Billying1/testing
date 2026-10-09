import 'package:flutter/material.dart';

import '../../services/station_repository.dart';
import '../widgets/brand_row.dart';
import '../widgets/info_card.dart';
import '../widgets/placeholder_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = StationRepository.instance;

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: BrandRow(),
          ),
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: repository.favoriteIds,
              builder: (context, favoriteIds, _) {
                final favoriteStations = repository.stations
                    .where((station) => favoriteIds.contains(station.id))
                    .toList();

                if (favoriteStations.isEmpty) {
                  return const PlaceholderView(
                    icon: Icons.favorite_border,
                    title: 'Yêu thích',
                    description:
                        'Chưa có trạm nào được lưu. Hãy chạm vào biểu tượng tim trên bản đồ.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteStations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final station = favoriteStations[index];
                    return InfoCard(
                      icon: Icons.ev_station,
                      title: station.name,
                      subtitle: '${station.city} • ${station.address}',
                      trailing: station.power,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}