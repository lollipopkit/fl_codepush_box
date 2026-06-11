import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native library absence is non-fatal for MVP APIs', () async {
    final codePush = FcbCodePush.instance;

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
