import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/main_pages/scaffold_page.dart';
import 'package:tuan5/services/station_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final repo = StationRepository.instance;

  setUp(() => repo.favoriteIds.value = <String>{});
  tearDown(() => repo.favoriteIds.value = <String>{});

  Future<void> switchTab(WidgetTester tester, String label) async {
    // Restrict the finder to the bottom bar; other pages may contain
    // duplicate text for the same navigation label.
    final tab = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
    expect(tab, findsOneWidget);
    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('AUTO-INT-01 navigation map -> favorites -> route -> more',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
    await tester.pump(const Duration(milliseconds: 500));

    await switchTab(tester, 'Yêu thích');
    expect(
      find.text(
        'Chưa có trạm nào được lưu. Hãy chạm vào biểu tượng tim trên bản đồ.',
      ),
      findsOneWidget,
    );

    await switchTab(tester, 'Lộ trình');
    // The route page deliberately renders this text as both a heading
    // and the search button. Verify the uniquely identified button.
    expect(
      find.widgetWithText(ElevatedButton, 'Tìm trạm sạc theo lộ trình'),
      findsOneWidget,
    );

    await switchTab(tester, 'Xem thêm');
    expect(find.text('Thêm trạm sạc'), findsWidgets);
  });

  testWidgets('AUTO-INT-02 saved station -> favorite list -> removal',
      (tester) async {
    final station = repo.addStation(
      name: 'Automation Integrated Station',
      city: 'Đà Nẵng',
      address: 'Hải Châu',
      latitude: 16.05,
      longitude: 108.22,
      power: '60 kW',
    );
    try {
      repo.toggleFavorite(station.id);
      await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
      await tester.pump(const Duration(milliseconds: 500));
      await switchTab(tester, 'Yêu thích');
      expect(find.text('Automation Integrated Station'), findsWidgets);

      repo.toggleFavorite(station.id);
      await tester.pump();
      expect(find.text('Automation Integrated Station'), findsNothing);
    } finally {
      repo.removeStation(station.id);
    }
  });
}
