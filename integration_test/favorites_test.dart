import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/main_pages/favorite_page.dart';
import 'package:tuan5/services/station_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final repo = StationRepository.instance;
  final station = repo.stations.first;

  setUp(() => repo.favoriteIds.value = <String>{});
  tearDown(() => repo.favoriteIds.value = <String>{});

  testWidgets('AUTO-FAV-01 empty favorites shows placeholder', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: FavoritesPage())));
    await t.pump();
    expect(find.text('Chưa có trạm nào được lưu. Hãy chạm vào biểu tượng tim trên bản đồ.'), findsOneWidget);
  });

  testWidgets('AUTO-FAV-02 favorite appears and is removed', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: FavoritesPage())));
    repo.toggleFavorite(station.id);
    await t.pump();
    expect(find.text(station.name), findsWidgets);
    expect(repo.isFavorite(station.id), isTrue);
    repo.toggleFavorite(station.id);
    await t.pump();
    expect(repo.isFavorite(station.id), isFalse);
    expect(find.text('Chưa có trạm nào được lưu. Hãy chạm vào biểu tượng tim trên bản đồ.'), findsOneWidget);
  });
}
