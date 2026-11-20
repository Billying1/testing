import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuan5/models/user_model.dart';
import 'package:tuan5/screens/main_pages/profile_page.dart';
import 'package:tuan5/services/preference_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceService.saveUser(UserModel(fullName: 'Automation Tester', email: 'profile@example.com', phone: '0901234567', password: '', avatar: '', gender: 'Male', city: 'Can Tho'));
  });

  testWidgets('AUTO-PRO-01 display existing profile', (t) async {
    await t.pumpWidget(const MaterialApp(home: ProfilePage()));
    await t.pumpAndSettle();
    expect(find.text('Automation Tester'), findsWidgets);
    expect(find.text('profile@example.com'), findsWidgets);
    expect(find.text('Can Tho'), findsWidgets);
  });

  testWidgets('AUTO-PRO-02 edit profile and persist changes', (t) async {
    await t.pumpWidget(const MaterialApp(home: ProfilePage()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.edit));
    await t.pump();
    await t.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Updated Tester');
    await t.tap(find.byIcon(Icons.check));
    await t.pumpAndSettle();
    expect(find.text('Updated Tester'), findsWidgets);
    expect((await PreferenceService.getUser())?.fullName, 'Updated Tester');
    expect((await PreferenceService.getUser())?.email, 'profile@example.com');
  });

  testWidgets('AUTO-PRO-03 blank name is rejected', (t) async {
    await t.pumpWidget(const MaterialApp(home: ProfilePage()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.edit));
    await t.pump();
    await t.enterText(find.widgetWithText(TextFormField, 'Full name'), '   ');
    await t.tap(find.byIcon(Icons.check));
    await t.pump();
    expect(find.text('Please enter full name'), findsOneWidget);
  });
}
