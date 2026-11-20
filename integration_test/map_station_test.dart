import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/main_pages/map_page.dart';
import 'package:tuan5/services/station_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AUTO-MAP-01 repository provides station data for map', (t) async {
    final stations = StationRepository.instance.stations;
    expect(stations, isNotEmpty);
    expect(stations.first.name, isNotEmpty);
    expect(stations.first.city, isNotEmpty);
  });

  testWidgets('AUTO-MAP-02 map screen opens filter dialog', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: HomePage())));
    // Map tiles may remain loading; do not wait on external tile server.
    await t.pump(const Duration(milliseconds: 500));
    final filter = find.text('Lọc trạm sạc');
    if (filter.evaluate().isNotEmpty) {
      await t.tap(filter.first);
    } else {
      // UI filter uses a tappable control; locate via its icon.
      final iconFilter = find.byIcon(Icons.tune);
      expect(iconFilter, findsWidgets);
      await t.tap(iconFilter.last);
    }
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Lọc trạm sạc'), findsWidgets);
    expect(find.text('Tỉnh / thành'), findsWidgets);
    expect(find.text('Công suất tối thiểu'), findsWidgets);
    await t.tap(find.text('Hủy'));
    await t.pump();
  });
}
