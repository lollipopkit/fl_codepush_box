import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FcbCodePush {
  FcbCodePush._();

  static final FcbCodePush instance = FcbCodePush._();

  static const MethodChannel _pathsChannel =
      MethodChannel('dev.fcb.code_push/paths');

  DynamicLibrary? _library;

  Future<bool> configure({
    required String appId,
    required String releaseVersion,
    required String publicKey,
    required String serverUrl,
    String channel = 'stable',
    String? platform,
    String arch = 'arm64-v8a',
    String? cacheDir,
    String? orgId,
    String clientId = 'default',
    String? baselineArtifactPath,
  }) async {
    final selectedPlatform = platform ?? _defaultPlatform();
    final platformPaths =
        selectedPlatform == 'android' || selectedPlatform == 'ios'
            ? await _platformPaths(selectedPlatform)
            : const <String, String>{};
    final selectedCacheDir = cacheDir ??
        platformPaths['cacheDir'] ??
        _defaultCacheDir(selectedPlatform);
    final selectedBaselineArtifactPath =
        baselineArtifactPath ?? platformPaths['baselineArtifactPath'];
    if (!_isValidConfiguration(
      appId: appId,
      releaseVersion: releaseVersion,
      publicKey: publicKey,
      serverUrl: serverUrl,
      platform: selectedPlatform,
      arch: arch,
      cacheDir: selectedCacheDir,
      orgId: orgId,
      baselineArtifactPath: selectedBaselineArtifactPath,
      clientId: clientId,
    )) {
      return false;
    }

    final init = _lookupInit();
    final setServerUrl = _lookupStringSetter('fcb_set_server_url');
    if (init == null || setServerUrl == null) {
      return false;
    }

    final params = calloc<_FcbInitParams>();
    final appIdPtr = appId.toNativeUtf8();
    final channelPtr = channel.toNativeUtf8();
    final releaseVersionPtr = releaseVersion.toNativeUtf8();
    final platformPtr = selectedPlatform.toNativeUtf8();
    final archPtr = arch.toNativeUtf8();
    final cacheDirPtr = selectedCacheDir.toNativeUtf8();
    final publicKeyPtr = publicKey.toNativeUtf8();
    final serverUrlPtr = serverUrl.toNativeUtf8();
    final orgIdPtr = orgId?.toNativeUtf8();
    final clientIdPtr = clientId.toNativeUtf8();
    final baselinePtr = selectedBaselineArtifactPath?.toNativeUtf8();
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
      if (orgIdPtr != null) {
        final setOrgId = _lookupStringSetter('fcb_set_org_id');
        if (setOrgId != null && setOrgId(orgIdPtr.cast()) != 0) {
          return false;
        }
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
      if (orgIdPtr != null) {
        calloc.free(orgIdPtr);
      }
      calloc.free(clientIdPtr);
      if (baselinePtr != null) {
        calloc.free(baselinePtr);
      }
    }
  }

  bool _isValidConfiguration({
    required String appId,
    required String releaseVersion,
    required String publicKey,
    required String serverUrl,
    required String platform,
    required String arch,
    required String cacheDir,
    required String? orgId,
    required String clientId,
    required String? baselineArtifactPath,
  }) {
    final requiredValues = [
      appId,
      releaseVersion,
      publicKey,
      serverUrl,
      clientId
    ];
    if (requiredValues.any((value) => value.trim().isEmpty)) {
      return false;
    }
    final uri = Uri.tryParse(serverUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    const platforms = {'android', 'ios', 'macos', 'linux', 'windows'};
    const arches = {
      'arm64-v8a',
      'armeabi-v7a',
      'x86',
      'x86_64',
      'arm64',
      'amd64'
    };
    if (!platforms.contains(platform) || !arches.contains(arch)) {
      return false;
    }
    if (cacheDir.trim().isEmpty) {
      return false;
    }
    if (orgId != null && orgId.trim().isEmpty) {
      return false;
    }
    final cacheDirectory = Directory(cacheDir);
    try {
      if (!cacheDirectory.existsSync()) {
        cacheDirectory.createSync(recursive: true);
      }
    } catch (_) {
      return false;
    }
    if (baselineArtifactPath != null &&
        baselineArtifactPath.isNotEmpty &&
        !File(baselineArtifactPath).existsSync()) {
      return false;
    }
    return true;
  }

  Future<int?> currentPatchNumber() async {
    final fn = _lookupInt('fcb_current_patch_number');
    return fn == null ? null : fn();
  }

  Future<int?> lastKnownGoodPatchNumber() async {
    final fn = _lookupInt('fcb_last_known_good_patch_number');
    if (fn == null) {
      return null;
    }
    final value = fn();
    return value > 0 ? value : null;
  }

  Future<List<CrashRollbackEvent>> crashRollbackHistory(
      {int limit = 10}) async {
    try {
      final lib = _library ??= _openLibrary();
      final fn = lib.lookupFunction<Pointer<Char> Function(Int32),
          Pointer<Char> Function(int)>('fcb_crash_rollback_history_json');
      final ptr = fn(limit);
      if (ptr == nullptr) {
        return const <CrashRollbackEvent>[];
      }
      final decoded = jsonDecode(ptr.cast<Utf8>().toDartString());
      if (decoded is! List) {
        return const <CrashRollbackEvent>[];
      }
      return decoded
          .whereType<Map<String, Object?>>()
          .map(CrashRollbackEvent.fromJson)
          .toList(growable: false);
    } catch (error, stack) {
      _debugLookupError('fcb_crash_rollback_history_json', error, stack);
      return const <CrashRollbackEvent>[];
    }
  }

  Future<InterpreterStats?> interpreterStats() async {
    try {
      final lib = _library ??= _openLibrary();
      final fn = lib.lookupFunction<
          Int32 Function(Pointer<Uint64>, Pointer<Uint64>),
          int Function(
              Pointer<Uint64>, Pointer<Uint64>)>('fcb_get_interpreter_stats');
      final interpreted = calloc<Uint64>();
      final aot = calloc<Uint64>();
      try {
        if (fn(interpreted, aot) != 0) {
          return null;
        }
        return InterpreterStats(
          interpretedFunctionCalls: interpreted.value,
          aotFunctionCalls: aot.value,
        );
      } finally {
        calloc.free(interpreted);
        calloc.free(aot);
      }
    } catch (error, stack) {
      _debugLookupError('fcb_get_interpreter_stats', error, stack);
      return null;
    }
  }

  Future<void> cancelPendingOperations() async {
    final fn = _lookupInt('fcb_cancel_pending_operations');
    fn?.call();
  }

  Future<bool> isUpdateAvailable() async {
    final result = await checkForUpdate();
    return result.patchAvailable;
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    final result = _callNativeStatus('fcb_check_for_update_blocking');
    if (!result.available) {
      return UpdateCheckResult(patchAvailable: false, reason: result.reason);
    }
    if (result.code < 0) {
      return UpdateCheckResult(
        patchAvailable: false,
        reason: _nativeFailureReason('native update check', result.code),
      );
    }
    final patchNumber = result.code > 0 ? _lastCheckPatchNumber() : null;
    return UpdateCheckResult(
      patchAvailable: result.code > 0,
      patchNumber: patchNumber,
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
        reason: _nativeFailureReason('native update download', result.code),
      );
    }
    return DownloadResult(
      success: result.code > 0,
      reason: result.code > 0 ? null : 'no patch installed',
    );
  }

  Future<bool> isNewPatchReadyToInstall() async {
    final result = _callNativeStatus('fcb_is_new_patch_ready_to_install');
    return result.available && result.code > 0;
  }

  Future<void> markLaunchSuccessful() async {
    final fn = _lookupInt('fcb_mark_launch_success');
    fn?.call();
  }

  Future<void> markLaunchFailure(int patchNumber, String reason) async {
    try {
      final lib = _library ??= _openLibrary();
      final fn = lib.lookupFunction<Int32 Function(Int32, Pointer<Char>),
          int Function(int, Pointer<Char>)>('fcb_mark_launch_failure');
      final reasonPtr = reason.toNativeUtf8();
      try {
        fn(patchNumber, reasonPtr.cast());
      } finally {
        calloc.free(reasonPtr);
      }
    } catch (error, stack) {
      _debugLookupError('fcb_mark_launch_failure', error, stack);
    }
  }

  Future<void> restartApp() async {
    try {
      await _pathsChannel.invokeMethod<void>('restart');
    } catch (error, stack) {
      _debugLookupError('restart', error, stack);
    }
  }

  Future<Map<String, String>> platformPaths() async {
    return _platformPaths(_defaultPlatform());
  }

  Future<String?> launchBytecodePatchPath() async {
    final fn = _lookupLaunchPatch();
    if (fn == null) {
      return null;
    }
    final patch = calloc<_FcbLaunchPatch>();
    try {
      if (fn(patch) != 0 || patch.ref.hasPatch == 0) {
        return null;
      }
      final backend = _stringFromCharPointer(patch.ref.backend);
      if (backend != 'bytecode') {
        return null;
      }
      return _stringFromCharPointer(patch.ref.bytecodePath);
    } finally {
      calloc.free(patch);
    }
  }

  _NativeStatus _callNativeStatus(String symbol) {
    final fn = _lookupInt(symbol);
    if (fn == null) {
      return _NativeStatus.unavailable('native symbol $symbol is unavailable');
    }
    return _NativeStatus.available(fn());
  }

  String _nativeFailureReason(String operation, int code) {
    final error = _lastError();
    if (error == null || error.isEmpty) {
      return '$operation failed with code $code';
    }
    return '$operation failed with code $code: $error';
  }

  String? _lastError() {
    try {
      final lib = _library ??= _openLibrary();
      final fn = lib.lookupFunction<Pointer<Char> Function(),
          Pointer<Char> Function()>('fcb_last_error');
      final ptr = fn();
      if (ptr == nullptr) {
        return null;
      }
      return ptr.cast<Utf8>().toDartString();
    } catch (error, stack) {
      _debugLookupError('fcb_last_error', error, stack);
      return null;
    }
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

  int? _lastCheckPatchNumber() {
    final fn = _lookupInt('fcb_last_check_patch_number');
    if (fn == null) {
      return null;
    }
    final value = fn();
    return value > 0 ? value : null;
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

  int Function(Pointer<_FcbLaunchPatch>)? _lookupLaunchPatch() {
    try {
      final lib = _library ??= _openLibrary();
      return lib.lookupFunction<Int32 Function(Pointer<_FcbLaunchPatch>),
          int Function(Pointer<_FcbLaunchPatch>)>('fcb_get_launch_patch');
    } catch (error, stack) {
      _debugLookupError('fcb_get_launch_patch', error, stack);
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

  String? _stringFromCharPointer(Pointer<Char> ptr) {
    if (ptr == nullptr) {
      return null;
    }
    return ptr.cast<Utf8>().toDartString();
  }

  DynamicLibrary _openLibrary() {
    // On iOS the updater is a static library linked into the app binary.
    // All its symbols are available in the current process image.
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    for (final path in _candidateLibraryPaths()) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {
        // Keep trying platform loader paths below.
      }
    }
    if (Platform.isMacOS) {
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

  List<String> _candidateLibraryPaths() {
    // Development-time roots: current package, package when run from repo root,
    // and package when run from an example app.
    final names = <String>[];
    if (Platform.isMacOS || Platform.isIOS) {
      names.add('libfcb_updater.dylib');
    } else if (Platform.isAndroid || Platform.isLinux) {
      names.add('libfcb_updater.so');
    } else if (Platform.isWindows) {
      names.add('fcb_updater.dll');
    }
    final roots = <String>[
      Directory.current.path,
      '${Directory.current.path}/packages/fcb_code_push',
      '${Directory.current.path}/../packages/fcb_code_push',
    ];
    // Platform filenames match the artifacts produced by the native build tools.
    final paths = [
      for (final root in roots)
        for (final name in names) '$root/native/$name',
    ];
    assert(() {
      for (final path in paths) {
        debugPrint('FCB native candidate library path: $path');
      }
      return true;
    }());
    return paths;
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

  Future<Map<String, String>> _platformPaths(String platform) async {
    try {
      final paths = await _pathsChannel.invokeMapMethod<String, String>(
        'getPaths',
      );
      return paths ?? const <String, String>{};
    } catch (error, stack) {
      _debugLookupError('$platform paths', error, stack);
      return const <String, String>{};
    }
  }

  String _defaultCacheDir(String platform) {
    if (platform == 'android') {
      final temp = Directory.systemTemp.path;
      final parent = Directory(temp).parent.path;
      if (temp.endsWith('/cache')) {
        return '$parent/code_cache/fcb';
      }
      return '$temp/fcb';
    }
    return '.fcb/cache';
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

final class _FcbLaunchPatch extends Struct {
  @Int32()
  external int hasPatch;

  @Int32()
  external int patchNumber;

  external Pointer<Char> backend;
  external Pointer<Char> artifactPath;
  external Pointer<Char> bytecodePath;
  external Pointer<Char> manifestPath;
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

class CrashRollbackEvent {
  const CrashRollbackEvent({
    required this.patchNumber,
    required this.bootAttempts,
    required this.timestamp,
    this.isReported = false,
    this.lastKnownGoodPatchNumber,
  });

  factory CrashRollbackEvent.fromJson(Map<String, Object?> json) {
    return CrashRollbackEvent(
      patchNumber: (json['patch_number'] as num?)?.toInt() ?? 0,
      bootAttempts: (json['boot_attempts'] as num?)?.toInt() ?? 0,
      lastKnownGoodPatchNumber:
          (json['last_known_good_patch_number'] as num?)?.toInt(),
      timestamp: json['timestamp']?.toString() ?? '',
      isReported: json['is_reported'] == true,
    );
  }

  final int patchNumber;
  final int bootAttempts;
  final int? lastKnownGoodPatchNumber;
  final String timestamp;
  final bool isReported;
}

class InterpreterStats {
  const InterpreterStats({
    required this.interpretedFunctionCalls,
    required this.aotFunctionCalls,
  });

  final int interpretedFunctionCalls;
  final int aotFunctionCalls;

  double get interpreterRatio {
    final total = interpretedFunctionCalls + aotFunctionCalls;
    if (total == 0) {
      return 0;
    }
    return interpretedFunctionCalls / total;
  }
}
