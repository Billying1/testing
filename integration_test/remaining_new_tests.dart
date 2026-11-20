import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/main_pages/add_station_page.dart';
import 'package:tuan5/screens/main_pages/map_page.dart';
import 'package:tuan5/services/geocoding_service.dart';
import 'package:tuan5/services/station_repository.dart';

// Additional UI integration tests for existing Not Run cases.
// These tests do NOT require live geocoding or Firebase.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final repo = StationRepository.instance;

  Future<void> openAdd(WidgetTester tester,
      Future<GeocodeResult?> Function(String) geocode) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => AddStationPage(lookupAddress: geocode),
          )),
          child: const Text('OPEN TEST FORM'),
        )),
      ),
    ));
    await tester.tap(find.text('OPEN TEST FORM'));
    await tester.pumpAndSettle();
    expect(find.byType(AddStationPage), findsOneWidget);
  }

  Future<void> fillStation(WidgetTester tester, {
    String name = 'QA Test Station',
    String city = 'Đà Nẵng',
    String address = 'Hải Châu',
  }) async {
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), city);
    await tester.enterText(fields.at(2), address);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Lưu trạm');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  int powerOf(String value) =>
      int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 0;

  Future<void> openMap(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HomePage()),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('trạm'), findsWidgets);
  }

  Future<void> filterDialog(WidgetTester tester) async {
    final filter = find.textContaining('Lọc trạm theo khu vực và công suất');
    final selected = find.textContaining('Đã chọn:');
    await tester.tap(filter.evaluate().isNotEmpty ? filter.first : selected.first);
    await tester.pumpAndSettle();
    expect(find.text('Lọc trạm sạc'), findsOneWidget);
  }

Future<void> chooseDropdown(
  WidgetTester tester,
  int index,
  String value,
) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).at(index);

  expect(dropdown, findsOneWidget);

  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  // Find the option inside the opened dropdown menu.
  final option = find.text(value).last;

  expect(
    option,
    findsOneWidget,
    reason: 'Dropdown option "$value" was not found.',
  );

  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
} 

  Future<void> applyFilter(WidgetTester tester) async {
    await tester.tap(find.text('Áp dụng'));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('STN-TC-12: whitespace-only address is rejected', (tester) async {
    var lookups = 0;
    await openAdd(tester, (_) async {
      lookups++;
      throw StateError('Should not geocode invalid form');
    });
    await fillStation(tester, address: '    ');
    await save(tester);
    expect(find.text('Vui lòng nhập thông tin'), findsWidgets);
    expect(lookups, 0);
    expect(find.byType(AddStationPage), findsOneWidget);
  });

  testWidgets('STN-TC-13: Unicode station name is saved without changes',
      (tester) async {
    const name = 'Trạm sạc thử nghiệm Đà Nẵng';
    final before = repo.stations.map((s) => s.id).toSet();
    await openAdd(tester, (_) async => const GeocodeResult(
      latitude: 16.05, longitude: 108.22, displayName: 'Đà Nẵng',
    ));
    try {
      await fillStation(tester, name: name);
      await save(tester);
      await tester.pumpAndSettle();
      expect(repo.stations.where((s) => s.name == name).length, 1);
      expect(repo.stations.singleWhere((s) => s.name == name).city, 'Đà Nẵng');
    } finally {
      for (final station in repo.stations.where((s) => !before.contains(s.id)).toList()) {
        repo.removeStation(station.id);
      }
    }
  });

  testWidgets('STN-TC-15: geocoding exception does not save station',
      (tester) async {
    final before = repo.stations.length;
    await openAdd(tester, (_) async => throw Exception('test geocode error'));
    await fillStation(tester);
    await save(tester);
    await tester.pump();
    expect(find.textContaining('Lỗi khi tìm vị trí:'), findsOneWidget);
    expect(repo.stations.length, before);
    expect(find.byType(AddStationPage), findsOneWidget);
  });

  testWidgets('STN-TC-16: Save disabled while geocoding is in progress',
      (tester) async {
    final pending = Completer<GeocodeResult?>();
    var calls = 0;
    final before = repo.stations.map((s) => s.id).toSet();
    await openAdd(tester, (_) {
      calls++;
      return pending.future;
    });
    await fillStation(tester);
    await save(tester);
    expect(calls, 1);
    final button = find.byType(ElevatedButton).last;
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    pending.complete(const GeocodeResult(
      latitude: 16.05, longitude: 108.22, displayName: 'Đà Nẵng',
    ));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(repo.stations.where((s) => !before.contains(s.id)).length, 1);
    for (final station in repo.stations.where((s) => !before.contains(s.id)).toList()) {
      repo.removeStation(station.id);
    }
  });

  testWidgets('MAP-TC-03: city filter changes visible station count',
      (tester) async {
    await openMap(tester);
    await filterDialog(tester);
    await chooseDropdown(tester, 0, 'Hà Nội');
    await applyFilter(tester);
    final count = repo.stations.where((s) => s.city == 'Hà Nội').length;
    expect(find.text('$count trạm'), findsOneWidget);
    expect(find.textContaining('Đã chọn: Hà Nội'), findsOneWidget);
  });

  testWidgets('MAP-TC-04: minimum power filter changes visible count',
      (tester) async {
    await openMap(tester);
    await filterDialog(tester);
    await chooseDropdown(tester, 1, '150 kW');
    await applyFilter(tester);
    final count = repo.stations.where((s) => powerOf(s.power) >= 150).length;
    expect(find.text('$count trạm'), findsOneWidget);
    expect(find.textContaining('150 kW'), findsWidgets);
  });

  testWidgets('MAP-TC-05: city and power filters work together',
      (tester) async {
    await openMap(tester);
    await filterDialog(tester);
    await chooseDropdown(tester, 0, 'Hà Nội');
    await chooseDropdown(tester, 1, '120 kW');
    await applyFilter(tester);
    final count = repo.stations.where((s) => s.city == 'Hà Nội' && powerOf(s.power) >= 120).length;
    expect(find.text('$count trạm'), findsOneWidget);
  });

  
testWidgets('MAP-TC-06: canceling filter keeps prior selection',
    (tester) async {
  await openMap(tester);

  // Step 1: Apply the Hanoi city filter.
  await filterDialog(tester);
  await chooseDropdown(tester, 0, 'Hà Nội');
  await applyFilter(tester);

  final count =
      repo.stations.where((s) => s.city == 'Hà Nội').length;

  expect(find.text('$count trạm'), findsOneWidget);
  expect(find.textContaining('Đã chọn: Hà Nội'), findsOneWidget);

  // Step 2: Reopen filters and change the minimum power.
  await filterDialog(tester);
  await chooseDropdown(tester, 1, '120 kW');

  // Step 3: Cancel without applying the change.
  await tester.tap(find.text('Hủy'));
  await tester.pumpAndSettle();

  // Step 4: Verify the original Hanoi filter remains.
  expect(find.text('$count trạm'), findsOneWidget);
  expect(find.textContaining('Đã chọn: Hà Nội'), findsOneWidget);

  // The canceled 120 kW change must not be applied.
  expect(find.textContaining('Đã chọn: Hà Nội'), findsOneWidget);
});


  testWidgets('MAP-TC-07: reset clears city and power filters',
      (tester) async {
    await openMap(tester);
    await filterDialog(tester);
    await chooseDropdown(tester, 0, 'Hà Nội');
    await chooseDropdown(tester, 1, '120 kW');
    await applyFilter(tester);
    await filterDialog(tester);
    await tester.tap(find.text('Đặt lại'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('${repo.stations.length} trạm'), findsOneWidget);
    expect(find.text('Lọc trạm theo khu vực và công suất'), findsOneWidget);
  });

  testWidgets('MAP-TC-08: a filter with zero matches shows zero stations',
      (tester) async {
    await openMap(tester);
    await filterDialog(tester);
    await chooseDropdown(tester, 0, 'Hà Nội');
    await chooseDropdown(tester, 1, '180 kW');
    await applyFilter(tester);
    final count = repo.stations.where((s) => s.city == 'Hà Nội' && powerOf(s.power) >= 180).length;
    expect(count, 0); // Seed data: neither Hanoi station is 180 kW.
    expect(find.text('0 trạm'), findsOneWidget);
  });
}
