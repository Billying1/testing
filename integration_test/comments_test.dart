import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuan5/screens/main_pages/comments_page.dart';
import 'package:tuan5/services/preference_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('AUTO-COM-01 empty comment is not added', (t) async {
    const id = 'automation-comment-empty';
    await t.pumpWidget(const MaterialApp(home: CommentsPage(stationId: id, stationName: 'Test Station')));
    await t.pumpAndSettle();
    await t.tap(find.text('Gửi'));
    await t.pump();
    expect(await PreferenceService.getComments(id), isEmpty);
  });

  testWidgets('AUTO-COM-02 post comment and show it', (t) async {
    const id = 'automation-comment-valid';
    await t.pumpWidget(const MaterialApp(home: CommentsPage(stationId: id, stationName: 'Test Station')));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Charging works well');
    await t.tap(find.text('Gửi'));
    await t.pumpAndSettle();
    expect(find.text('Charging works well'), findsOneWidget);
  });
}
