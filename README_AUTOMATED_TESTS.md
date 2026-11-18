# EV Charging Station / tuan5 — Extended integration test suite

## Included

- `integration_test/network_auth_test.dart`: original Firebase integration tests, with REG-TC-17 dropdown interaction and REG-TC-14 assertion improved.
- `integration_test/remaining_test.dart`: original existing tests, unchanged.
- `integration_test/coverage_extension_test.dart`: **24 additional named cases**, including two intentionally skipped device-level offline cases and one simulated offline geocoding case.
- `lib/screens/main_pages/add_station_page.dart`: **small optional injection point** (`lookupAddress`) used to make geocoding results deterministic in tests. Production behavior remains unchanged when omitted.
- `RUN_TESTS_WINDOWS.ps1`: runs all three test files individually and saves logs.

**Coverage map:** The union of test identifiers across the three integration test files includes all **51 IDs in your Word plan**: REG 01–21, LOG 01–14 and 16–20 (LOG-TC-15 is not in the document), STN 01–11. An ID present in a test does **not** mean it was executed successfully, nor that every part of its requirement was verified.

## Install

Copy `integration_test/` into `C:\DiDongNangCao\testing\integration_test\` (replace scripts when prompted), and copy the supplied `add_station_page.dart` into `C:\DiDongNangCao\testing\lib\screens\main_pages\` (back up your original first). Place `RUN_TESTS_WINDOWS.ps1` in the Flutter project root. Do not replace your other app files.

Start your Android emulator, then in PowerShell at the project root:

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File .\RUN_TESTS_WINDOWS.ps1
```

Logs are generated in `test-results/network_auth_test.log`, `test-results/remaining_test.log`, `test-results/coverage_extension_test.log`.

## Important limitations (do not record as PASS without verification)

1. `REG-TC-20`, `LOG-TC-19` are **skipped**. The full device's network must be disconnected and observed, or the Firebase transport must be mocked in a dedicated test. `STN-TC-09` simulates a geocoder exception through injection; it does **not** prove the device's actual offline behavior.
2. `STN-TC-10` in the original tests only checks that an entry survives a widget re-pump. It does **not** verify storage surviving a force-stop / cold restart. The app's `StationRepository` is memory-only. A full app-restart persistence test will likely fail until the app is changed to save stations durably.
3. Firebase tests require a properly configured **test Firebase project** and may create, authenticate and delete temporary users. Use test accounts only. Some Firebase failures are environment-dependent.
4. `LOG-TC-16` may continue to fail until Remember Me functionality is implemented. `STN-TC-11` may continue to fail if repeated taps can trigger multiple saves.
5. No SDK or Android emulator is available in the preparation environment. The new Dart tests have **not yet been compiled or executed** here. Run them on your device and upload the three logs; only actual execution can confirm Pass/Fail.
6. OpenStreetMap/Nominatim dependent tests in your original suite still depend on public external services and may be flaky. The new STN-TC-08 uses a controlled geocoding response for repeatability.
7. All 51 test IDs are mapped, but this is not a guarantee of 100% behavioral coverage. For example, existing `REG-TC-14`, `STN-TC-10`, and login handling should be checked against their actual expected results and environment.

Do not mark the skipped offline cases as tested or change the workbook's Pass/Fail values solely from the existence of these scripts.
