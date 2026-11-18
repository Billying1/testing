import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tuan5/firebase_options.dart';
import 'package:tuan5/screens/auth_pages/login_page.dart';

Future<void> openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: LoginPage()));
  await tester.pumpAndSettle();
}

Future<void> openRegister(WidgetTester tester) async {
  await openLogin(tester);
  await tester.ensureVisible(find.text('Register'));
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();
}

Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.hitTestable().evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> submitRegister(
  WidgetTester tester,
  String email,
  String pass,
) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Test User');
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), '0901234567');
  await tester.enterText(fields.at(3), pass);
  await tester.ensureVisible(find.text('I agree to the Terms'));
  await tester.tap(find.text('I agree to the Terms'));
  await tester.pump();
  await tester.ensureVisible(find.text('REGISTER'));
  await tester.tap(find.text('REGISTER'));
}

Future<void> submitLogin(WidgetTester tester, String email, String pass) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), pass);
  final loginButton = find.widgetWithText(ElevatedButton, 'LOGIN');
  await tester.ensureVisible(loginButton);
  await tester.tap(loginButton);
}

Future<void> cleanupUser(String email, String pass) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: pass,
    );
    final user = credential.user;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();
  } on FirebaseAuthException catch (error) {
    debugPrint('Test cleanup skipped: ${error.code}');
  } catch (error) {
    debugPrint('Test cleanup failed: $error');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  tearDown(() async {
    await FirebaseAuth.instance.signOut();
  });

  group('Network test cases', () {
    testWidgets(
      'REG-TC-01: register with valid data',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openRegister(tester);
        await submitRegister(tester, email, 'Abc123');

        expect(await waitFor(tester, find.text('Register Success')), isTrue);
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'REG-TC-07: duplicate email is rejected',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openRegister(tester);
        await submitRegister(tester, email, 'Abc123');
        expect(await waitFor(tester, find.text('Register Success')), isTrue);

        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Register'));
        await tester.tap(find.text('Register'));
        await tester.pumpAndSettle();
        await submitRegister(tester, email, 'Abc123');

        expect(
          await waitFor(tester, find.text('Email already exists')),
          isTrue,
        );
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets('REG-TC-11: empty password', (tester) async {
      final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
      await openRegister(tester);
      await submitRegister(tester, email, '');

      expect(
        await waitFor(tester, find.text('Password >= 6 characters')),
        isTrue,
      );
      await cleanupUser(email, '');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets(
      'LOG-TC-03: invalid email format',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openLogin(tester);
        await submitLogin(tester, 'testmail.com', 'Abc123');

        expect(await waitFor(tester, find.text('Invalid email')), isTrue);
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets('LOG-TC-05: short password', (tester) async {
      final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
      await openLogin(tester);
      await submitLogin(tester, 'tester01@mail.com', 'Ab123');

      expect(
        await waitFor(
          tester,
          find.text('Password must be at least 6 characters'),
        ),
        isTrue,
      );
      await cleanupUser(email, 'Ab123');
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets(
      'REG-TC-13: register with six-character password',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openRegister(tester);
        await submitRegister(tester, email, 'Ab1234');

        expect(await waitFor(tester, find.text('Register Success')), isTrue);
        await cleanupUser(email, 'Ab1234');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'REG-TC-06: invalid email address',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openRegister(tester);
        await submitRegister(tester, 'a@b', 'Abc123');

        expect(
          await waitFor(tester, find.text('Invalid email address')),
          isTrue,
        );
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'REG-TC-08: trim email around registration',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openRegister(tester);
        await submitRegister(tester, ' $email ', 'Abc123');

        expect(await waitFor(tester, find.text('Register Success')), isTrue);
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: 'Abc123');
        expect(credential.user, isNotNull);
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'REG-TC-19: saved registration fields',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        try {
          await openRegister(tester);
          await submitRegister(tester, email, 'Abc123');

          expect(await waitFor(tester, find.text('Register Success')), isTrue);
          final credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: 'Abc123');
          final user = credential.user;
          expect(user, isNotNull);

          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
          expect(snapshot.exists, isTrue);
          final data = snapshot.data()!;
          expect(data['fullName'], 'Test User');
          expect(data['email'], email);
          expect(data['phone'], '0901234567');
          expect(data['gender'], 'Male');
          expect(data['city'], 'Ho Chi Minh');
          expect(data['avatar'], 'https://i.pravatar.cc/300');
          expect(data.containsKey('password'), isFalse);
        } finally {
          await cleanupUser(email, 'Abc123');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'REG-TC-17-save: saved female Can Tho registration fields',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        try {
          await openRegister(tester);
          await tester.ensureVisible(find.text('Female'));
          await tester.tap(find.text('Female'));
          final city = find.byType(DropdownButtonFormField<String>);
          await tester.ensureVisible(city);
          await tester.tap(city);
          await tester.pumpAndSettle();
          expect(find.text('Can Tho'), findsWidgets);
          await tester.tap(find.text('Can Tho').last);
          await tester.pumpAndSettle();
          await submitRegister(tester, email, 'Abc123');

          expect(await waitFor(tester, find.text('Register Success')), isTrue);
          final credential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: 'Abc123');
          final user = credential.user;
          expect(user, isNotNull);

          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
          expect(snapshot.exists, isTrue);
          final data = snapshot.data()!;
          expect(data['gender'], 'Female');
          expect(data['city'], 'Can Tho');
        } finally {
          await cleanupUser(email, 'Abc123');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets('REG-TC-14: six-space password must be rejected', (tester) async {
      final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
      try {
        await openRegister(tester);
        await submitRegister(tester, email, '      ');
        await tester.pump(const Duration(seconds: 2));
        // A registration error is required. A success means this is a real FAIL.
        expect(find.text('Register Success'), findsNothing);
        final error = find.text('Password >= 6 characters').evaluate().isNotEmpty ||
            find.byType(SnackBar).evaluate().isNotEmpty;
        expect(error, isTrue,
            reason: 'Six whitespace characters must be rejected with an error');
      } finally {
        await cleanupUser(email, '      ');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets(
      'LOG-TC-08: trim email around login',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openLogin(tester);
        await submitLogin(tester, ' tester01@mail.com ', 'Abc123');

        expect(await waitFor(tester, find.text('Login Success')), isTrue);
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'LOG-TC-09: case-insensitive email login',
      (tester) async {
        final email = 'auto${DateTime.now().millisecondsSinceEpoch}@mail.com';
        await openLogin(tester);
        await submitLogin(tester, 'TESTER01@MAIL.COM', 'Abc123');

        expect(await waitFor(tester, find.text('Login Success')), isTrue);
        await cleanupUser(email, 'Abc123');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'LOG-TC-01: login with valid account',
      (tester) async {
        await openLogin(tester);
        await submitLogin(tester, 'tester01@mail.com', 'Abc123');

        expect(await waitFor(tester, find.text('Login Success')), isTrue);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets('LOG-TC-06: wrong password', (tester) async {
      await openLogin(tester);
      await submitLogin(tester, 'tester01@mail.com', 'Wrong123');

      final error = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Incorrect password' ||
                widget.data == 'No account found for that email'),
      );
      expect(
        await waitFor(tester, error),
        isTrue,
        reason: 'no error message appeared',
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets('LOG-TC-07: unregistered email', (tester) async {
      await openLogin(tester);
      await submitLogin(tester, 'nobody@mail.com', 'Abc123');

      expect(
        await waitFor(tester, find.text('No account found for that email')),
        isTrue,
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
