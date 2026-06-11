import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native library absence is non-fatal for MVP APIs', () async {
    final codePush = FcbCodePush.instance;

    expect(
      await codePush.configure(
        appId: '00000000-0000-0000-0000-000000000001',
        releaseVersion: '1.0.0+1',
        publicKey: 'dev-public-key',
        serverUrl: 'http://127.0.0.1:8080',
      ),
      isFalse,
    );
    expect(await codePush.currentPatchNumber(), isNull);
    expect(await codePush.isNewPatchReadyToInstall(), isFalse);
    expect(await codePush.requestRestartToApply(), isFalse);

    final check = await codePush.checkForUpdate();
    expect(check.patchAvailable, isFalse);
    expect(check.reason, isNotEmpty);

    final download = await codePush.downloadUpdate();
    expect(download.success, isFalse);
    expect(download.reason, isNotEmpty);

    await expectLater(codePush.markLaunchSuccessful(), completes);
  });
}
