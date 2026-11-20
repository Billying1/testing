import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/main_pages/routes_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The page contains both a heading and a button with the same text.
  // Select the button by widget type so finders match exactly one widget.
  Finder searchButton() => find.widgetWithText(
        ElevatedButton,
        'Tìm trạm sạc theo lộ trình',
      );

  Future<void> showSearchButton(WidgetTester tester) async {
    final button = searchButton();
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.pump();
  }

  testWidgets('AUTO-ROU-01 route screen displays search', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoutesPage())),
    );
    await tester.pump();

    expect(find.text('Tìm trạm sạc theo lộ trình'), findsNWidgets(2));
    expect(searchButton(), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
  });

  testWidgets('AUTO-ROU-02 searching without departure displays error',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoutesPage())),
    );
    await tester.pump();

    await showSearchButton(tester);
    await tester.tap(searchButton());
    await tester.pump();

    expect(find.text('Vui lòng chọn điểm đi (A).'), findsOneWidget);
  });

  testWidgets('AUTO-ROU-03 setting departure enables route results',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoutesPage())),
    );
    await tester.pump();

    final departure = find.byType(DropdownButton<String>).first;
    await tester.ensureVisible(departure);
    await tester.tap(departure);
    await tester.pumpAndSettle();

    // Choose a city containing a known VinFast station in the sample data.
    final city = find.text('Hà Nội').last;
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();

    await showSearchButton(tester);
    await tester.tap(searchButton());
    await tester.pump();

    // Results may be below the fold in the scrollable list.
    await tester.scrollUntilVisible(
      find.textContaining('EVCS Cầu Giấy'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('EVCS Cầu Giấy'), findsWidgets);
  });
}
