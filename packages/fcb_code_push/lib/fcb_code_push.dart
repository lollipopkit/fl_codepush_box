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
    final result = _callNativeStatus('fcb_check_for_update_async');
    if (!result.available) {
      return UpdateCheckResult(patchAvailable: false, reason: result.reason);
    }
    if (result.code < 0) {
      return UpdateCheckResult(
        patchAvailable: false,
        reason: 'native update check failed with code ${result.code}',
      );
    }
    return UpdateCheckResult(
      patchAvailable: result.code > 0,
      reason: result.code > 0 ? null : 'no patch available',
    );
  }

  Future<DownloadResult> downloadUpdate() async {
    final result = _callNativeStatus('fcb_download_and_install_blocking');
    if (!result.available) {
      return DownloadResult(success: false, reason: result.reason);
    }
    if (result.code < 0) {
      return DownloadResult(
        success: false,
        reason: 'native update download failed with code ${result.code}',
      );
    }
    return const DownloadResult(success: true);
  }

  Future<bool> isNewPatchReadyToInstall() async {
    final result = _callNativeStatus('fcb_is_new_patch_ready_to_install');
    return result.available && result.code > 0;
  }

  Future<bool> requestRestartToApply() async {
    return isNewPatchReadyToInstall();
  }

  Future<void> markLaunchSuccessful() async {
    final fn = _lookupInt('fcb_mark_launch_success');
    fn?.call();
  }

  _NativeStatus _callNativeStatus(String symbol) {
    final fn = _lookupInt(symbol);
    if (fn == null) {
      return _NativeStatus.unavailable('native symbol $symbol is unavailable');
    }
    return _NativeStatus.available(fn());
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

class _NativeStatus {
  const _NativeStatus._(
      {required this.available, required this.code, this.reason});

  factory _NativeStatus.available(int code) {
    return _NativeStatus._(available: true, code: code);
  }

  factory _NativeStatus.unavailable(String reason) {
    return _NativeStatus._(available: false, code: -1, reason: reason);
  }

  final bool available;
  final int code;
  final String? reason;
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
