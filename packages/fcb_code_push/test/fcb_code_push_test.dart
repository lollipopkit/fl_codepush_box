import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('crash rollback event parses observability fields', () {
    final event = CrashRollbackEvent.fromJson({
      'patch_number': 42,
      'boot_attempts': 3,
      'last_known_good_patch_number': 7,
      'timestamp': '2026-06-17T00:00:00Z',
      'is_reported': true,
    });

    expect(event.patchNumber, 42);
    expect(event.bootAttempts, 3);
    expect(event.lastKnownGoodPatchNumber, 7);
    expect(event.timestamp, '2026-06-17T00:00:00Z');
    expect(event.isReported, isTrue);
  });

  test('crash rollback event defaults unreported for local history', () {
    final event = CrashRollbackEvent.fromJson({
      'patch_number': 42,
      'boot_attempts': 3,
      'timestamp': '2026-06-17T00:00:00Z',
    });

    expect(event.isReported, isFalse);
  });

  test('native library absence is non-fatal for MVP APIs', () async {
    final codePush = FcbCodePush.instance;

    final hasNativeLib = File('native/libfcb_updater.dylib').existsSync() ||
        File('native/libfcb_updater.so').existsSync() ||
        File('native/fcb_updater.dll').existsSync();
    final configured = await codePush.configure(
      appId: '00000000-0000-0000-0000-000000000001',
      releaseVersion: '1.0.0+1',
      publicKey: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      serverUrl: 'http://127.0.0.1:8080',
      orgId: 'acme',
    );
    expect(configured, hasNativeLib);
    expect(await codePush.currentPatchNumber(), hasNativeLib ? 0 : isNull);
    expect(await codePush.lastKnownGoodPatchNumber(), isNull);
    expect(await codePush.crashRollbackHistory(), isEmpty);
    final stats = await codePush.interpreterStats();
    if (stats != null) {
      expect(stats.interpreterRatio, 0);
    }
    expect(await codePush.isNewPatchReadyToInstall(), isFalse);
    expect(await codePush.launchBytecodePatchPath(), isNull);
    await expectLater(codePush.cancelPendingOperations(), completes);
    await expectLater(codePush.markLaunchFailure(0, 'test'), completes);

    final check = await codePush.checkForUpdate();
    expect(check.patchAvailable, isFalse);
    expect(check.reason, isNotEmpty);

    final download = await codePush.downloadUpdate();
    expect(download.success, isFalse);
    expect(download.reason, isNotEmpty);

    await expectLater(codePush.markLaunchSuccessful(), completes);
  });
}
