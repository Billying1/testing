import 'package:flutter/material.dart';

import './../main_pages/map_page.dart';
import './../main_pages/favorite_page.dart';
import './../main_pages/routes_page.dart';
import './../main_pages/new_page.dart';
import './../main_pages/more_page.dart';
import './../widgets/nav_widget.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FavoritesPage(),
    RoutesPage(),
    NewsPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}