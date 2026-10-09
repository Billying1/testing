import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      selectedItemColor: const Color(0xFF5A9B1F),
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined),
          label: "Định vị",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: "Yêu thích",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.route_outlined),
          label: "Lộ trình",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper_outlined),
          label: "Tin tức",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: "Xem thêm",
        ),
      ],
    );
  }
}
