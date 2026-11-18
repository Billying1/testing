// Additional UI cases missing from network_auth_test.dart and remaining_test.dart.
// Keep the original two files. Run all three with: flutter test integration_test --reporter expanded
// Skipped cases are explicitly documented; they are NOT passed tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuan5/screens/auth_pages/login_page.dart';
import 'package:tuan5/screens/main_pages/add_station_page.dart';
import 'package:tuan5/services/station_repository.dart';
import 'package:tuan5/services/geocoding_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> loginScreen(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: LoginPage()));
    await t.pumpAndSettle();
  }

  Future<void> registerScreen(WidgetTester t) async {
    await loginScreen(t);
    await t.tap(find.text('Register'));
    await t.pumpAndSettle();
  }

  Future<void> stationScreen(WidgetTester t) async {
    await t.pumpWidget(const MaterialApp(home: AddStationPage()));
    await t.pumpAndSettle();
  }

  Future<void> registrationFields(WidgetTester t, {
    String name = 'Test User', String email = 'example@example.com',
    String phone = '0901234567', String password = 'Abc123',
  }) async {
    final f = find.byType(TextFormField);
    await t.enterText(f.at(0), name);
    await t.enterText(f.at(1), email);
    await t.enterText(f.at(2), phone);
    await t.enterText(f.at(3), password);
  }

  Future<void> pressRegister(WidgetTester t, {bool acceptTerms = true}) async {
    if (acceptTerms) {
      await t.ensureVisible(find.text('I agree to the Terms'));
      await t.tap(find.text('I agree to the Terms'));
      await t.pump();
    }
    await t.ensureVisible(find.text('REGISTER'));
    await t.tap(find.text('REGISTER'));
    await t.pump();
  }

  Future<void> stationFields(WidgetTester t, {
    String name = 'Test Station', String city = 'Ho Chi Minh City',
    String address = 'Ben Thanh Market',
  }) async {
    final f = find.byType(TextFormField);
    await t.enterText(f.at(0), name);
    await t.enterText(f.at(1), city);
    await t.enterText(f.at(2), address);
  }

  Future<void> pressStationSave(WidgetTester t) async {
    final save = find.text('Lưu trạm');
    await t.ensureVisible(save);
    await t.tap(save);
    await t.pump();
  }

  Future<void> openReset(WidgetTester t) async {
    await loginScreen(t);
    await t.tap(find.text('Forgot Password?'));
    await t.pumpAndSettle();
  }

  // Registration: local form-validation tests do NOT create Firebase users.
  testWidgets('REG-TC-02: reject empty full name', (t) async {
    await registerScreen(t);
    await registrationFields(t, name: '');
    await pressRegister(t);
    expect(find.text('Enter Full Name'), findsOneWidget);
  });
  testWidgets('REG-TC-04: reject empty email', (t) async {
    await registerScreen(t);
    await registrationFields(t, email: '');
    await pressRegister(t);
    expect(find.text('Enter Email'), findsOneWidget);
  });
  testWidgets('REG-TC-05: reject email missing @', (t) async {
    await registerScreen(t);
    await registrationFields(t, email: 'testmail.com');
    await pressRegister(t);
    expect(find.text('Invalid Email'), findsOneWidget);
  });
  testWidgets('REG-TC-09: reject empty phone', (t) async {
    await registerScreen(t);
    await registrationFields(t, phone: '');
    await pressRegister(t);
    expect(find.text('Enter Phone'), findsOneWidget);
  });
  testWidgets('REG-TC-15: require agreement to terms', (t) async {
    await registerScreen(t);
    await registrationFields(t);
    await pressRegister(t, acceptTerms: false);
    expect(find.text('Please agree to the Terms'), findsOneWidget);
  });
  testWidgets('REG-TC-16: verify registration defaults', (t) async {
    await registerScreen(t);
    expect(find.text('Male'), findsWidgets);
    final dropdown = t.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(dropdown.initialValue, 'Ho Chi Minh');
    final f = t.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(f[4].controller!.text, 'https://i.pravatar.cc/300');
    final checkbox = t.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(checkbox.value, isFalse);
  });
  testWidgets('REG-TC-18: password visibility toggle', (t) async {
    await registerScreen(t);
    final p = find.byType(TextFormField).at(3);
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isTrue);
    await t.ensureVisible(p);
    await t.tap(find.byIcon(Icons.visibility));
    await t.pump();
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isFalse);
    await t.tap(find.byIcon(Icons.visibility_off));
    await t.pump();
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isTrue);
  });
  testWidgets('REG-TC-21: back to login without registering', (t) async {
    await registerScreen(t);
    await t.ensureVisible(find.text('BACK TO LOGIN'));
    await t.tap(find.text('BACK TO LOGIN'));
    await t.pumpAndSettle();
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('BACK TO LOGIN'), findsNothing);
  });

  // Login: local UI tests.
  testWidgets('LOG-TC-02: reject empty login email', (t) async {
    await loginScreen(t);
    await t.enterText(find.byType(TextFormField).at(1), 'Abc123');
    await t.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await t.pump();
    expect(find.text('Please enter email'), findsOneWidget);
  });
  testWidgets('LOG-TC-04: reject empty login password', (t) async {
    await loginScreen(t);
    await t.enterText(find.byType(TextFormField).at(0), 'example@example.com');
    await t.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    await t.pump();
    expect(find.text('Please enter password'), findsOneWidget);
  });
  testWidgets('LOG-TC-10: login password visibility toggle', (t) async {
    await loginScreen(t);
    final p = find.byType(TextFormField).at(1);
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isTrue);
    await t.tap(find.byIcon(Icons.visibility));
    await t.pump();
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isFalse);
    await t.tap(find.byIcon(Icons.visibility_off));
    await t.pump();
    expect(t.widget<EditableText>(find.descendant(of: p, matching: find.byType(EditableText))).obscureText, isTrue);
  });
  testWidgets('LOG-TC-12: reset password requires email', (t) async {
    await openReset(t);
    await t.tap(find.text('Send Link'));
    await t.pump();
    expect(find.text('Please enter your email'), findsOneWidget);
  });
  testWidgets('LOG-TC-13: reset password rejects missing @', (t) async {
    await openReset(t);
    await t.enterText(find.byType(TextFormField).last, 'testmail.com');
    await t.tap(find.text('Send Link'));
    await t.pump();
    expect(find.text('Invalid email'), findsOneWidget);
  });
  testWidgets('LOG-TC-14: cancel reset password dialog', (t) async {
    await openReset(t);
    expect(find.text('Reset Password'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Reset Password'), findsNothing);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
  testWidgets('LOG-TC-20: register link navigates to registration', (t) async {
    await loginScreen(t);
    await t.tap(find.text('Register'));
    await t.pumpAndSettle();
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('BACK TO LOGIN'), findsOneWidget);
  });

  // Station: direct screen testing avoids external Firebase login for validation.
  testWidgets('STN-TC-02: reject empty station name', (t) async {
    await stationScreen(t);
    await stationFields(t, name: '');
    await pressStationSave(t);
    expect(find.text('Vui lòng nhập thông tin'), findsOneWidget);
  });
  testWidgets('STN-TC-03: reject empty station city', (t) async {
    await stationScreen(t);
    await stationFields(t, city: '');
    await pressStationSave(t);
    expect(find.text('Vui lòng nhập thông tin'), findsOneWidget);
  });
  testWidgets('STN-TC-04: reject empty station address', (t) async {
    await stationScreen(t);
    await stationFields(t, address: '');
    await pressStationSave(t);
    expect(find.text('Vui lòng nhập thông tin'), findsOneWidget);
  });
  testWidgets('STN-TC-05: reject whitespace in all required fields', (t) async {
    await stationScreen(t);
    await stationFields(t, name: '   ', city: '   ', address: '   ');
    await pressStationSave(t);
    expect(find.text('Vui lòng nhập thông tin'), findsNWidgets(3));
  });
  testWidgets('STN-TC-07: verify default power and operator', (t) async {
    await stationScreen(t);
    final dropdowns = t.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    ).toList();
    expect(dropdowns.length, 2);
    expect(dropdowns[0].initialValue, '60 kW');
    expect(dropdowns[1].initialValue, 'VinFast');
  });
  testWidgets('STN-TC-08: selected power and operator are stored', (t) async {
    final before = StationRepository.instance.stations.length;
    const name = 'Auto Power Selection Case';
    await t.pumpWidget(MaterialApp(home: AddStationPage(
      lookupAddress: (query) async => const GeocodeResult(
        latitude: 10.77, longitude: 106.70, displayName: 'Test location'),
    )));
    await t.pumpAndSettle();
    await stationFields(t, name: name);
    final selects = find.byType(DropdownButtonFormField<String>);
    await t.ensureVisible(selects.at(0));
    await t.tap(selects.at(0));
    await t.pumpAndSettle();
    await t.tap(find.text('180 kW').last);
    await t.pumpAndSettle();
    await t.ensureVisible(selects.at(1));
    await t.tap(selects.at(1));
    await t.pumpAndSettle();
    await t.tap(find.text('Đối tác').last);
    await t.pumpAndSettle();
    try {
      await pressStationSave(t);
      await t.pumpAndSettle();
      expect(StationRepository.instance.stations.length, before + 1);
      final station = StationRepository.instance.stations.last;
      expect(station.name, name);
      expect(station.power, '180 kW');
      expect(station.network, 'Đối tác');
    } finally {
      final matches = StationRepository.instance.stations.where((s) => s.name == name);
      for (final station in matches.toList()) {
        StationRepository.instance.removeStation(station.id);
      }
    }
  });

  testWidgets('STN-TC-09: geocoding network error does not save station (simulated)', (t) async {
    final before = StationRepository.instance.stations.length;
    await t.pumpWidget(MaterialApp(home: AddStationPage(
      lookupAddress: (query) async => throw Exception('Network unavailable'),
    )));
    await t.pumpAndSettle();
    await stationFields(t);
    await pressStationSave(t);
    await t.pumpAndSettle();
    expect(find.textContaining('Lỗi khi tìm vị trí:'), findsOneWidget);
    expect(StationRepository.instance.stations.length, before);
  });

  // Offline tests require a device-level network toggle and are intentionally
  // skipped rather than giving false positive PASS results.
  testWidgets('REG-TC-20: offline registration [DEVICE NETWORK REQUIRED]',
      (t) async {}, skip: true);
  testWidgets('LOG-TC-19: offline login [DEVICE NETWORK REQUIRED]',
      (t) async {}, skip: true);

}
