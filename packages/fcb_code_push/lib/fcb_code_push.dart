import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

class FcbCodePush {
  FcbCodePush._();

  static final FcbCodePush instance = FcbCodePush._();

  DynamicLibrary? _library;

  Future<bool> configure({
    required String appId,
    required String releaseVersion,
    required String publicKey,
    required String serverUrl,
    String channel = 'stable',
    String? platform,
    String arch = 'arm64-v8a',
    String cacheDir = '.fcb/cache',
    String clientId = 'default',
    String? baselineArtifactPath,
  }) async {
    final init = _lookupInit();
    final setServerUrl = _lookupStringSetter('fcb_set_server_url');
    if (init == null || setServerUrl == null) {
      return false;
    }

    final params = calloc<_FcbInitParams>();
    final appIdPtr = appId.toNativeUtf8();
    final channelPtr = channel.toNativeUtf8();
    final releaseVersionPtr = releaseVersion.toNativeUtf8();
    final platformPtr = (platform ?? _defaultPlatform()).toNativeUtf8();
    final archPtr = arch.toNativeUtf8();
    final cacheDirPtr = cacheDir.toNativeUtf8();
    final publicKeyPtr = publicKey.toNativeUtf8();
    final serverUrlPtr = serverUrl.toNativeUtf8();
    final clientIdPtr = clientId.toNativeUtf8();
    final baselinePtr = baselineArtifactPath?.toNativeUtf8();
    try {
      params.ref
        ..appId = appIdPtr.cast()
        ..channel = channelPtr.cast()
        ..releaseVersion = releaseVersionPtr.cast()
        ..platform = platformPtr.cast()
        ..arch = archPtr.cast()
        ..cacheDir = cacheDirPtr.cast()
        ..publicKeyPem = publicKeyPtr.cast()
        ..checkOnStartup = 0;
      if (init(params) != 0 || setServerUrl(serverUrlPtr.cast()) != 0) {
        return false;
      }
      final setClientId = _lookupStringSetter('fcb_set_client_id');
      if (setClientId != null && setClientId(clientIdPtr.cast()) != 0) {
        return false;
      }
      if (baselinePtr != null) {
        final setBaseline =
            _lookupStringSetter('fcb_set_baseline_artifact_path');
        if (setBaseline != null && setBaseline(baselinePtr.cast()) != 0) {
          return false;
        }
      }
      return true;
    } finally {
      calloc.free(params);
      calloc.free(appIdPtr);
      calloc.free(channelPtr);
      calloc.free(releaseVersionPtr);
      calloc.free(platformPtr);
      calloc.free(archPtr);
      calloc.free(cacheDirPtr);
      calloc.free(publicKeyPtr);
      calloc.free(serverUrlPtr);
      calloc.free(clientIdPtr);
      if (baselinePtr != null) {
        calloc.free(baselinePtr);
      }
    }
  }

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

  int Function(Pointer<_FcbInitParams>)? _lookupInit() {
    try {
      final lib = _library ??= _openLibrary();
      return lib.lookupFunction<Int32 Function(Pointer<_FcbInitParams>),
          int Function(Pointer<_FcbInitParams>)>('fcb_init');
    } catch (error, stack) {
      _debugLookupError('fcb_init', error, stack);
      return null;
    }
  }

  int Function(Pointer<Char>)? _lookupStringSetter(String symbol) {
    try {
      final lib = _library ??= _openLibrary();
      return lib.lookupFunction<Int32 Function(Pointer<Char>),
          int Function(Pointer<Char>)>(symbol);
    } catch (error, stack) {
      _debugLookupError(symbol, error, stack);
      return null;
    }
  }

  void _debugLookupError(String symbol, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('FCB native symbol lookup failed for $symbol: $error');
      debugPrint('$stack');
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

  String _defaultPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    return 'unknown';
  }
}

final class _FcbInitParams extends Struct {
  external Pointer<Char> appId;
  external Pointer<Char> channel;
  external Pointer<Char> releaseVersion;
  external Pointer<Char> platform;
  external Pointer<Char> arch;
  external Pointer<Char> cacheDir;
  external Pointer<Char> publicKeyPem;

  @Int32()
  external int checkOnStartup;
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
