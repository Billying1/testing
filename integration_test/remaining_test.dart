import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tuan5/firebase_options.dart';
import 'package:tuan5/screens/auth_pages/login_page.dart';
import 'package:tuan5/screens/auth_pages/splash_page.dart';
import 'package:tuan5/screens/main_pages/add_station_page.dart';
import 'package:tuan5/screens/main_pages/scaffold_page.dart';
import 'package:tuan5/services/auth_service.dart';
import 'package:tuan5/services/station_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final originalFlutterErrorOnError = FlutterError.onError;

  setUpAll(() async {
    FlutterError.onError = (details) {
      final exception = details.exception;
      final isTileSocketError =
          exception is SocketException &&
          (exception.message.contains('tile.openstreetmap.org') ||
              details.stack.toString().contains('tile.openstreetmap.org'));
      final isTileImageError =
          exception is NetworkImageLoadException &&
          exception.uri.host == 'tile.openstreetmap.org';
      if (!isTileSocketError && !isTileImageError) {
        originalFlutterErrorOnError?.call(details);
      }
    };
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  tearDownAll(() {
    FlutterError.onError = originalFlutterErrorOnError;
  });

  tearDown(() async {
    await FirebaseAuth.instance.signOut();
  });

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openRegister(WidgetTester tester) async {
    await openLogin(tester);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
  }

  Future<bool> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  String visibleMessage(WidgetTester tester) {
    final snackBars = find.byType(SnackBar);
    if (snackBars.evaluate().isNotEmpty) {
      final text = find.descendant(
        of: snackBars.last,
        matching: find.byType(Text),
      );
      if (text.evaluate().isNotEmpty) {
        return (text.last.evaluate().single.widget as Text).data ?? '';
      }
    }
    final texts = find.byType(Text).evaluate();
    if (texts.isNotEmpty) {
      return texts
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .lastWhere((value) => value.isNotEmpty, orElse: () => '');
    }
    return '';
  }

  Future<void> report(
    String id,
    WidgetTester tester,
    Future<String> Function() testBody,
  ) async {
    try {
      final message = await testBody();
      // ignore: avoid_print
      print('$id: PASS - $message');
    } catch (error) {
      final message = visibleMessage(tester);
      // ignore: avoid_print
      print('$id: FAIL - ${message.isEmpty ? error : message}');
      rethrow;
    }
  }

  Future<void> fillRegistration(
    WidgetTester tester, {
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), fullName);
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), phone);
    await tester.enterText(fields.at(3), password);
  }

  Future<void> tapRegister(WidgetTester tester) async {
    await tester.ensureVisible(find.text('I agree to the Terms'));
    await tester.tap(find.text('I agree to the Terms'));
    await tester.ensureVisible(find.text('REGISTER'));
    await tester.tap(find.text('REGISTER'));
  }

  Future<void> cleanupUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        await user.delete();
      }
    } on FirebaseAuthException {
      // The test may have intentionally verified that this account was not created.
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> login(WidgetTester tester) async {
    await openLogin(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'tester01@mail.com');
    await tester.enterText(fields.at(1), 'Abc123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
    expect(
      await waitFor(tester, find.text('Electric Vehicle Charging Stations')),
      isTrue,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddStation(WidgetTester tester) async {
    await login(tester);
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm trạm sạc'));
    await tester.pumpAndSettle();
  }

  Future<void> fillStation(
    WidgetTester tester, {
    required String name,
    required String city,
    required String address,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), city);
    await tester.enterText(fields.at(2), address);
  }

  testWidgets('REG-TC-03: blank full name is rejected', (tester) async {
    final email = 'auto${DateTime.now().microsecondsSinceEpoch}@mail.com';
    await report('REG-TC-03', tester, () async {
      try {
        await openRegister(tester);
        await fillRegistration(
          tester,
          fullName: '   ',
          email: email,
          phone: '0901234567',
          password: 'Abc123',
        );
        await tapRegister(tester);
        expect(await waitFor(tester, find.text('Enter Full Name')), isTrue);
        expect(FirebaseAuth.instance.currentUser, isNull);
        return 'Enter Full Name';
      } finally {
        await cleanupUser(email, 'Abc123');
      }
    });
  });

  testWidgets('REG-TC-10: alphabetic phone is rejected', (tester) async {
    final email = 'auto${DateTime.now().microsecondsSinceEpoch}@mail.com';
    await report('REG-TC-10', tester, () async {
      try {
        await openRegister(tester);
        await fillRegistration(
          tester,
          fullName: 'Test User',
          email: email,
          phone: 'abcdef',
          password: 'Abc123',
        );
        await tapRegister(tester);
        expect(await waitFor(tester, find.text('Invalid Phone')), isTrue);
        expect(FirebaseAuth.instance.currentUser, isNull);
        return 'Invalid Phone';
      } finally {
        await cleanupUser(email, 'Abc123');
      }
    });
  });

  testWidgets('REG-TC-12: short password is rejected', (tester) async {
    final email = 'auto${DateTime.now().microsecondsSinceEpoch}@mail.com';
    await report('REG-TC-12', tester, () async {
      try {
        await openRegister(tester);
        await fillRegistration(
          tester,
          fullName: 'Test User',
          email: email,
          phone: '0901234567',
          password: 'Ab123',
        );
        await tester.ensureVisible(find.text('I agree to the Terms'));
        await tester.tap(find.text('I agree to the Terms'));
        await tester.ensureVisible(find.text('REGISTER'));
        await tester.tap(find.text('REGISTER'));
        expect(
          await waitFor(tester, find.text('Password >= 6 characters')),
          isTrue,
        );
        expect(FirebaseAuth.instance.currentUser, isNull);
        return 'Password >= 6 characters';
      } finally {
        await cleanupUser(email, 'Ab123');
      }
    });
  });

  testWidgets('REG-TC-17-save: save female Can Tho fields', (tester) async {
    final email = 'auto${DateTime.now().microsecondsSinceEpoch}@mail.com';
    await report('REG-TC-17-save', tester, () async {
      try {
        await openRegister(tester);
        await tester.tap(find.text('Female'));
        final cityDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(cityDropdown);
        final cityOption = find.text('Can Tho');
        await tester.scrollUntilVisible(
          cityOption,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        if (cityOption.evaluate().isEmpty) {
          // ignore: avoid_print
          print(
            'REG-TC-17-save dropdown item texts: '
            '${find.byType(Text).evaluate().map((element) => (element.widget as Text).data).whereType<String>().toList()}',
          );
        }
        expect(cityOption, findsWidgets);
        await tester.tap(cityOption.last);
        await fillRegistration(
          tester,
          fullName: 'Test User',
          email: email,
          phone: '0901234567',
          password: 'Abc123',
        );
        await tapRegister(tester);
        expect(await waitFor(tester, find.text('Register Success')), isTrue);
        final user = FirebaseAuth.instance.currentUser;
        expect(user, isNotNull);
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        final data = snapshot.data()!;
        expect(data['gender'], 'Female');
        expect(data['city'], 'Can Tho');
        return 'Register Success';
      } finally {
        await cleanupUser(email, 'Abc123');
      }
    });
  });

  testWidgets('LOG-TC-11: forgot password sends reset link', (tester) async {
    await report('LOG-TC-11', tester, () async {
      await openLogin(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'tester01@mail.com',
      );
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send Link'));
      const message = 'Password reset link sent. Check your email.';
      expect(await waitFor(tester, find.text(message)), isTrue);
      return message;
    });
  });

  testWidgets('LOG-TC-16: remember me keeps email after logout', (
    tester,
  ) async {
    await report('LOG-TC-16', tester, () async {
      await openLogin(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'tester01@mail.com',
      );
      await tester.tap(find.text('Remember me?'));
      await tester.enterText(find.byType(TextFormField).at(1), 'Abc123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      expect(
        await waitFor(tester, find.text('Electric Vehicle Charging Stations')),
        isTrue,
      );
      await AuthService.logout();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();
      final emailFields = find.byType(TextFormField);
      if (emailFields.evaluate().isEmpty) {
        debugDumpApp();
      }
      expect(emailFields, findsWidgets);
      final emailField = emailFields.first;
      expect(
        tester.widget<TextFormField>(emailField).controller!.text,
        'tester01@mail.com',
      );
      return 'tester01@mail.com kept on Login screen';
    });
  });

  testWidgets('LOG-TC-17: login survives a fresh app pump', (tester) async {
    await report('LOG-TC-17', tester, () async {
      await login(tester);
      await tester.pumpWidget(const MaterialApp(home: SlashPage()));
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Electric Vehicle Charging Stations'), findsOneWidget);
      return 'Home';
    });
  });

  testWidgets('LOG-TC-18: repeated wrong passwords are throttled', (
    tester,
  ) async {
    final email = 'auto${DateTime.now().microsecondsSinceEpoch}@mail.com';
    await report('LOG-TC-18', tester, () async {
      try {
        await openRegister(tester);
        await fillRegistration(
          tester,
          fullName: 'Disposable User',
          email: email,
          phone: '0901234567',
          password: 'Abc123',
        );
        await tapRegister(tester);
        expect(await waitFor(tester, find.text('Register Success')), isTrue);
        await AuthService.logout();

        int? throttledAttempt;
        for (var attempt = 1; attempt <= 10; attempt++) {
          await openLogin(tester);
          await tester.enterText(find.byType(TextFormField).at(0), email);
          await tester.enterText(find.byType(TextFormField).at(1), 'Wrong123');
          final loginButton = find.widgetWithText(ElevatedButton, 'LOGIN');
          tester
              .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
              .hideCurrentSnackBar();
          await tester.pumpAndSettle();
          expect(loginButton.hitTestable(), findsOneWidget);
          await tester.tap(loginButton);
          await tester.pumpAndSettle();
          if (find
              .text('Too many attempts. Please try again later')
              .evaluate()
              .isNotEmpty) {
            throttledAttempt = attempt;
            break;
          }
        }
        expect(throttledAttempt, isNotNull);
        return 'Too many attempts. Please try again later (attempt $throttledAttempt)';
      } finally {
        await cleanupUser(email, 'Abc123');
      }
    });
  });

  testWidgets('STN-TC-01: add a valid station', (tester) async {
    const name = 'Integration Test Station';
    await report('STN-TC-01', tester, () async {
      await openAddStation(tester);
      await fillStation(
        tester,
        name: name,
        city: 'Ho Chi Minh City',
        address: '1 Le Loi',
      );
      await tester.tap(find.text('Lưu trạm'));
      expect(await waitFor(tester, find.text('Đã thêm trạm sạc mới')), isTrue);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(AddStationPage), findsNothing);
      expect(
        StationRepository.instance.stations.any(
          (station) => station.name == name,
        ),
        isTrue,
      );
      return 'Đã thêm trạm sạc mới';
    });
  });

  testWidgets('STN-TC-06: nonexistent address is rejected', (tester) async {
    await report('STN-TC-06', tester, () async {
      await openAddStation(tester);
      await fillStation(
        tester,
        name: 'Unknown Station',
        city: 'Nowhere',
        address: 'This address definitely does not exist 999999',
      );
      await tester.tap(find.text('Lưu trạm'));
      const message =
          'Không tìm thấy vị trí cho địa chỉ này, vui lòng kiểm tra lại.';
      expect(await waitFor(tester, find.text(message)), isTrue);
      return message;
    });
  });

  testWidgets('STN-TC-10: station remains listed after app pump', (
    tester,
  ) async {
    const name = 'Persistent Integration Station';
    await report('STN-TC-10', tester, () async {
      await openAddStation(tester);
      await fillStation(
        tester,
        name: name,
        city: 'Ho Chi Minh City',
        address: '1 Le Loi',
      );
      await tester.tap(find.text('Lưu trạm'));
      expect(await waitFor(tester, find.text('Đã thêm trạm sạc mới')), isTrue);
      await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
      await tester.pumpAndSettle();
      expect(
        StationRepository.instance.stations.any(
          (station) => station.name == name,
        ),
        isTrue,
      );
      return name;
    });
  });

  testWidgets('STN-TC-11: double save creates one station', (tester) async {
    const name = 'Double Save Integration Station';
    await report('STN-TC-11', tester, () async {
      final before = StationRepository.instance.stations
          .where((station) => station.name == name)
          .length;
      await openAddStation(tester);
      await fillStation(
        tester,
        name: name,
        city: 'Ho Chi Minh City',
        address: '1 Le Loi',
      );
      final save = find.text('Lưu trạm');
      await tester.tap(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final after = StationRepository.instance.stations
          .where((station) => station.name == name)
          .length;
      expect(after - before, 1);
      return 'one station created';
    });
  });
}
