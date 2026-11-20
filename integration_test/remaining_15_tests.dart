import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tuan5/screens/auth_pages/register_page.dart';
import 'package:tuan5/screens/auth_pages/login_page.dart';
import 'package:tuan5/screens/main_pages/add_station_page.dart';
import 'package:tuan5/screens/main_pages/map_page.dart';
import 'package:tuan5/screens/main_pages/favorite_page.dart';
import 'package:tuan5/screens/widgets/station_marker.dart';
import 'package:tuan5/screens/widgets/station_card.dart';
import 'package:tuan5/services/geocoding_service.dart';
import 'package:tuan5/services/station_repository.dart';

// Targeted integration checks for 15 outstanding Excel IDs.
// The two tests explicitly marked skip require an injectable/mockable AuthService
// to verify actual request count or submitted email without network side effects.
// A failing assertion is an actual outcome; do not mark it Pass in the report.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final repo = StationRepository.instance;

  Future<void> show(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> fillRegistration(WidgetTester tester, {
    String name = 'Test User',
    String email = 'valid@example.com',
  }) async {
    final fields = find.byType(TextFormField);
    expect(fields, findsAtLeastNWidgets(4));
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), '0912345678');
    await tester.enterText(fields.at(3), 'safePassword123');
    await tester.pump();
  }

  // Form validation only: avoids creating real Firebase user accounts.
  Future<bool> registrationFormValid(WidgetTester tester) async {
    final state = tester.state<FormState>(find.byType(Form).first);
    final valid = state.validate();
    await tester.pump();
    return valid;
  }

  Future<void> openStationForm(
    WidgetTester tester,
    Future<GeocodeResult?> Function(String) lookup,
  ) async {
    await show(tester, Scaffold(
      body: Builder(builder: (context) => ElevatedButton(
        onPressed: () => Navigator.push<void>(context, MaterialPageRoute(
          builder: (_) => AddStationPage(lookupAddress: lookup),
        )),
        child: const Text('OPEN FORM'),
      )),
    ));
    await tester.tap(find.text('OPEN FORM'));
    await tester.pumpAndSettle();
    expect(find.byType(AddStationPage), findsOneWidget);
  }

  Future<void> fillStation(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'QA Station');
    await tester.enterText(fields.at(1), 'Đà Nẵng');
    await tester.enterText(fields.at(2), 'Hải Châu');
    await tester.pump();
  }

  Future<void> saveStation(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Lưu trạm');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> openMap(WidgetTester tester) async {
    await show(tester, const Scaffold(body: HomePage()));
    expect(find.byType(FlutterMap), findsOneWidget);
  }

  // The marker widgets are instantiated from the repository. Their onTap
  // callbacks are tested through the widget tree; visible map placement may
  // vary by device/emulator and map tile availability.
  Finder markers() => find.byType(StationMarker, skipOffstage: false);

  Future<void> selectMarker(WidgetTester tester, String stationId) async {
    final marker = find.byWidgetPredicate((widget) =>
      widget is StationMarker && widget.station.id == stationId,
      skipOffstage: false,
    );
    expect(marker, findsOneWidget);
    final widget = tester.widget<StationMarker>(marker);
    // In a map, markers can be outside the device viewport. Triggering the
    // callback checks selection state but is NOT proof of a physical user tap.
    widget.onTap();
    await tester.pump(const Duration(milliseconds: 450));
  }

  void clearFavorites() => repo.favoriteIds.value = <String>{};

  testWidgets('REG-TC-22: reject email containing two at signs', (tester) async {
    await show(tester, const RegisterPage());
    await fillRegistration(tester, email: 'a@@example.com');
    expect(await registrationFormValid(tester), isFalse,
        reason: 'The form must reject multiple @ characters.');
  });

  testWidgets('REG-TC-23: reject email missing domain', (tester) async {
    await show(tester, const RegisterPage());
    await fillRegistration(tester, email: 'person@');
    expect(await registrationFormValid(tester), isFalse,
        reason: 'The form must reject an incomplete email domain.');
  });

  testWidgets('REG-TC-24: reject spaces inside email', (tester) async {
    await show(tester, const RegisterPage());
    await fillRegistration(tester, email: 'person name@example.com');
    expect(await registrationFormValid(tester), isFalse,
        reason: 'The form must reject whitespace inside an email address.');
  });

  testWidgets('REG-TC-25: Unicode name remains valid and unchanged', (tester) async {
    const name = 'Nguyễn Thị Ánh Đào';
    await show(tester, const RegisterPage());
    await fillRegistration(tester, name: name);
    expect(await registrationFormValid(tester), isTrue);
    final field = tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(field.controller?.text, name);
    // Does not claim that an account was created (that requires Auth mock).
  });

  testWidgets('REG-TC-26: repeated REGISTER clicks create only one request',
      (tester) async {
    // Needs injectable AuthService.register / a controllable Future to count
    // requests safely. Do not create real accounts in an automated test.
  }, skip: true);

  testWidgets('LOG-TC-25: password reset trims leading/trailing spaces',
      (tester) async {
    // UI can be opened, but verifying the submitted argument needs a mock
    // of AuthService.resetPassword rather than contacting Firebase.
  }, skip: true);

  testWidgets('STN-TC-14: null geocode result does not save a station', (tester) async {
    final before = repo.stations.map((station) => station.id).toSet();
    var calls = 0;
    await openStationForm(tester, (_) async { calls++; return null; });
    await fillStation(tester);
    await saveStation(tester);
    await tester.pump(const Duration(milliseconds: 350));
    expect(calls, 1);
    expect(repo.stations.map((s) => s.id).toSet(), before);
    expect(find.textContaining('Không tìm thấy vị trí'), findsOneWidget);
    expect(find.byType(AddStationPage), findsOneWidget);
  });

  testWidgets('STN-TC-16: repeated Save while geocoding makes one request', (tester) async {
    final pending = Completer<GeocodeResult?>();
    final before = repo.stations.map((s) => s.id).toSet();
    var calls = 0;
    await openStationForm(tester, (_) { calls++; return pending.future; });
    await fillStation(tester);
    await saveStation(tester);
    final saveButton = find.byType(ElevatedButton).last;
    expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    // Additional tap cannot activate a disabled button; check callback count.
    await tester.tap(saveButton);
    await tester.pump();
    expect(calls, 1);
    pending.complete(const GeocodeResult(
      latitude: 16.05, longitude: 108.22, displayName: 'Đà Nẵng',
    ));
    await tester.pumpAndSettle();
    expect(calls, 1);
    final added = repo.stations.where((s) => !before.contains(s.id)).toList();
    expect(added.length, 1);
    for (final s in added) { repo.removeStation(s.id); }
  });

  testWidgets('MAP-TC-01: map builds markers for all stations', (tester) async {
    await openMap(tester);
    expect(markers(), findsNWidgets(repo.stations.length));
    expect(find.byType(MarkerLayer), findsOneWidget);
  });

  testWidgets('MAP-TC-02: selecting marker displays station information', (tester) async {
    await openMap(tester);
    final station = repo.stations.first;
    await selectMarker(tester, station.id);
    final card = find.byType(SelectedStationCard);
    expect(card, findsOneWidget);
    expect(tester.widget<SelectedStationCard>(card).station.id, station.id);
    expect(find.text(station.name), findsWidgets);
  });

  testWidgets('MAP-TC-09: fit-all control remains usable', (tester) async {
    await openMap(tester);
    expect(markers(), findsNWidgets(repo.stations.length));
    final focusIcon = find.byIcon(Icons.filter_center_focus);
    expect(focusIcon, findsOneWidget);
    await tester.tap(focusIcon);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FlutterMap), findsOneWidget);
    // This is a smoke test, NOT a camera-bounds assertion.
  });

  testWidgets('MAP-TC-10: nearby button chooses nearest seeded station', (tester) async {
    await openMap(tester);
    final nearest = repo.stations.reduce((a, b) {
      double dist(dynamic s) =>
        (s.latitude - 16.08) * (s.latitude - 16.08) +
        (s.longitude - 108.18) * (s.longitude - 108.18);
      return dist(a) <= dist(b) ? a : b;
    });
    await tester.tap(find.text('Hoặc tìm trạm quanh đây'));
    await tester.pump(const Duration(milliseconds: 350));
    final card = find.byType(SelectedStationCard);
    expect(card, findsOneWidget);
    expect(tester.widget<SelectedStationCard>(card).station.id, nearest.id);
    expect(find.textContaining('gần vị trí của bạn nhất'), findsOneWidget);
  });

  testWidgets('FAV-TC-01: favorite from map appears in Favorites page', (tester) async {
    clearFavorites();
    addTearDown(clearFavorites);
    await openMap(tester);
    final station = repo.stations.first;
    await selectMarker(tester, station.id);
    final card = find.byType(SelectedStationCard);
    expect(card, findsOneWidget);
    tester.widget<SelectedStationCard>(card).onFavoriteTap();
    await tester.pump();
    expect(repo.isFavorite(station.id), isTrue);
    await show(tester, const Scaffold(body: FavoritesPage()));
    expect(find.text(station.name), findsOneWidget);
  });

  testWidgets('FAV-TC-02: remove favorite using map card callback', (tester) async {
    clearFavorites();
    addTearDown(clearFavorites);
    await openMap(tester);
    final station = repo.stations.first;
    await selectMarker(tester, station.id);
    var card = find.byType(SelectedStationCard);
    tester.widget<SelectedStationCard>(card).onFavoriteTap();
    await tester.pump();
    expect(repo.isFavorite(station.id), isTrue);
    card = find.byType(SelectedStationCard);
    tester.widget<SelectedStationCard>(card).onFavoriteTap();
    await tester.pump();
    expect(repo.isFavorite(station.id), isFalse);
    await show(tester, const Scaffold(body: FavoritesPage()));
    expect(find.text(station.name), findsNothing);
    expect(find.textContaining('Chưa có trạm nào'), findsOneWidget);
  });

 
testWidgets('FAV-TC-04: two map favorites appear in favorites list',
    (tester) async {
  clearFavorites();
  addTearDown(clearFavorites);

  await openMap(tester);

  final stationA = repo.stations.first;
  final stationB = repo.stations[1];

  for (final station in [stationA, stationB]) {
    await selectMarker(tester, station.id);

    // Find the active, visible station card.
    final cards = find.byType(SelectedStationCard);

    expect(cards, findsWidgets);

    final card = tester.widget<SelectedStationCard>(
      cards.last,
    );

    card.onFavoriteTap();
    await tester.pump();
  }

  // Both stations must be saved as favorites.
  expect(
    repo.favoriteIds.value,
    containsAll([stationA.id, stationB.id]),
  );

  // Open the favorites page.
  await show(
    tester,
    const Scaffold(body: FavoritesPage()),
  );

  // Verify both stations appear.
  expect(find.text(stationA.name), findsOneWidget);
  expect(find.text(stationB.name), findsOneWidget);
});
}