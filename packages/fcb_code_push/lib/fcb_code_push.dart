import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

class FcbCodePush {
  FcbCodePush._();

  static final FcbCodePush instance = FcbCodePush._();

  DynamicLibrary? _library;

  Future<int?> currentPatchNumber() async {
    final fn = _lookupInt('fcb_current_patch_number');
    return fn == null ? null : fn();
  }

  Future<bool> isUpdateAvailable() async {
    final result = await checkForUpdate();
    return result.patchAvailable;
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    return const UpdateCheckResult(
      patchAvailable: false,
      reason: 'native updater check is not wired in MVP package',
    );
  }

  Future<DownloadResult> downloadUpdate() async {
    return const DownloadResult(
      success: false,
      reason: 'native updater download is not wired in MVP package',
    );
  }

  Future<bool> isNewPatchReadyToInstall() async {
    return false;
  }

  Future<bool> requestRestartToApply() async {
    return false;
  }

  Future<void> markLaunchSuccessful() async {
    final fn = _lookupInt('fcb_mark_launch_success');
    fn?.call();
  }

  int Function()? _lookupInt(String symbol) {
    try {
      final lib = _library ??= _openLibrary();
      return lib.lookupFunction<Int32 Function(), int Function()>(symbol);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('FCB native symbol lookup failed for $symbol: $error');
        debugPrint('$stack');
      }
      return null;
    }
  }

  DynamicLibrary _openLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('libfcb_updater.dylib');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('libfcb_updater.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('fcb_updater.dll');
    }
    throw UnsupportedError('unsupported platform');
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.patchAvailable,
    this.patchNumber,
    this.reason,
  });

  final bool patchAvailable;
  final int? patchNumber;
  final String? reason;
}

class DownloadResult {
  const DownloadResult({required this.success, this.reason});

  final bool success;
  final String? reason;
}
