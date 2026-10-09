import 'package:flutter/material.dart';

import '../widgets/brand_row.dart';
import '../widgets/info_card.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final news = [
      (
        'EVCS mở rộng thêm 50 trạm sạc nhanh',
        'Mạng lưới phủ dày hơn tại các tuyến quốc lộ.',
      ),
      (
        'Tối ưu tìm kiếm theo thời gian thực',
        'Trạng thái trạm được cập nhật trực tiếp mỗi phút.',
      ),
      (
        'Ưu đãi cho tài xế đặt lịch trước',
        'Giảm thời gian chờ tại các điểm đông xe.',
      ),
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
              itemCount: news.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = news[index];
                return InfoCard(
                  icon: Icons.newspaper,
                  title: item.$1,
                  subtitle: item.$2,
                  trailing: 'Mới',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}