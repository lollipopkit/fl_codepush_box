import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
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
    );
    expect(configured, hasNativeLib);
    expect(await codePush.currentPatchNumber(), hasNativeLib ? 0 : isNull);
    expect(await codePush.isNewPatchReadyToInstall(), isFalse);
    expect(await codePush.requestRestartToApply(), isFalse);
    expect(await codePush.launchBytecodePatchPath(), isNull);

    final check = await codePush.checkForUpdate();
    expect(check.patchAvailable, isFalse);
    expect(check.reason, isNotEmpty);

    final download = await codePush.downloadUpdate();
    expect(download.success, isFalse);
    expect(download.reason, isNotEmpty);

    await expectLater(codePush.markLaunchSuccessful(), completes);
  });
}
