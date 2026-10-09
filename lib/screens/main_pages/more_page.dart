import 'package:flutter/material.dart';

import '../widgets/brand_row.dart';
import '../widgets/info_card.dart';
import 'profile_page.dart';
import 'add_station_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Cài đặt tài khoản', Icons.person_outline),
      ('Thêm trạm sạc', Icons.add_location_alt_outlined),
    ];

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: BrandRow(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () {
                    if (item.$1 == 'Cài đặt tài khoản') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    } else if (item.$1 == 'Thêm trạm sạc') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddStationPage()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: InfoCard(
                    icon: item.$2,
                    title: item.$1,
                    subtitle: item.$1 == 'Thêm trạm sạc'
                        ? 'Đăng ký một trạm sạc mới'
                        : 'Mở để xem thêm tùy chọn',
                    trailing: 'Mở',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}