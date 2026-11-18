# Run from the Flutter project root with an Android device or emulator online.
# Run: powershell -ExecutionPolicy Bypass -File .\RUN_TESTS_WINDOWS.ps1
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force -Path 'test-results' | Out-Null
flutter pub get
flutter devices
$files = @(
  'integration_test/network_auth_test.dart',
  'integration_test/remaining_test.dart',
  'integration_test/coverage_extension_test.dart'
)
foreach ($f in $files) {
  $name = [IO.Path]::GetFileNameWithoutExtension($f)
  Write-Host "Running $f"
  flutter test $f --reporter expanded *> "test-results/$name.log"
  Write-Host "Exit code: $LASTEXITCODE; log: test-results/$name.log"
}
Write-Host 'Completed. Upload the 3 .log files in test-results to ChatGPT.'
