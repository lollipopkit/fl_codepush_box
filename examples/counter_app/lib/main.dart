import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter/material.dart';

import 'pricing_source.dart' as direct_source;

const _serverUrl = String.fromEnvironment(
  'FCB_SERVER_URL',
  defaultValue: 'http://127.0.0.1:8080',
);
const _appId = String.fromEnvironment('FCB_APP_ID');
const _publicKey = String.fromEnvironment('FCB_PUBLIC_KEY');
const _releaseVersion = String.fromEnvironment(
  'FCB_RELEASE_VERSION',
  defaultValue: '1.0.0+1',
);
const _channel = String.fromEnvironment('FCB_CHANNEL', defaultValue: 'stable');
const _platform =
    String.fromEnvironment('FCB_PLATFORM', defaultValue: 'android');
const _arch = String.fromEnvironment('FCB_ARCH', defaultValue: 'arm64-v8a');
const _cacheDir = String.fromEnvironment(
  'FCB_CACHE_DIR',
);
const _baselineArtifactPath = String.fromEnvironment('FCB_BASELINE_ARTIFACT');
const _autoInstallOnStartup =
    bool.fromEnvironment('FCB_AUTO_INSTALL_ON_STARTUP');

void main() {
  runApp(const CounterApp());
}

@pragma('vm:never-inline')
int _phaseDAdjustedInput() {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return 6;
  }
  return 5;
}

@pragma('vm:never-inline')
int _phaseDAdjustedCounterValue() =>
    direct_source.adjustedCounterValue(_phaseDAdjustedInput());

@pragma('vm:never-inline')
int _phaseDStaticCounterValue() =>
    direct_source.PricingEngine.staticCounterValue();

@pragma('vm:never-inline')
String _phaseDStatusLabel() => direct_source.statusLabel();

@pragma('vm:never-inline')
String _phaseDWidgetTreeLabel() => direct_source.widgetTreeLabel();

@pragma('vm:never-inline')
String _phaseDFieldStatusLabel(direct_source.PricingOffer offer) =>
    direct_source.fieldStatusLabel(
      offer,
    );

@pragma('vm:never-inline')
int _phaseDQuadInput(int value) {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return value + 1;
  }
  return value;
}

@pragma('vm:never-inline')
int _phaseDQuadCounterValue() => direct_source.quadCounterValue(
      _phaseDQuadInput(1),
      _phaseDQuadInput(2),
      _phaseDQuadInput(3),
      _phaseDQuadInput(4),
    );

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  final _codePush = FcbCodePush.instance;
  final _pricingOffer = direct_source.PricingOffer(
    baseLabel: 'base-field',
    patchLabel: 'patched-field',
  );
  bool _busy = true;
  bool _configured = false;
  int? _currentPatch;
  int? _lastKnownGoodPatch;
  List<CrashRollbackEvent> _rollbackHistory = const [];
  InterpreterStats? _interpreterStats;
  int _counter = 1;
  int _adjustedCounter = 8;
  int _staticMethodValue = 7;
  String _statusLabel = 'base';
  String _widgetTreeLabel = 'baseline widget tree';
  String _fieldStatusLabel = 'base-field';
  int _quadCounter = 10;
  bool _ready = false;
  bool _methodChannelReady = false;
  String _methodChannelCacheDir = 'unavailable';
  UpdateCheckResult? _check;
  DownloadResult? _download;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _run(() async {
      if (_appId.isNotEmpty && _publicKey.isNotEmpty) {
        _configured = await _codePush.configure(
          appId: _appId,
          releaseVersion: _releaseVersion,
          publicKey: _publicKey,
          serverUrl: _serverUrl,
          channel: _channel,
          platform: _platform,
          arch: _arch,
          cacheDir: _cacheDir.isEmpty ? null : _cacheDir,
          baselineArtifactPath:
              _baselineArtifactPath.isEmpty ? null : _baselineArtifactPath,
        );
        debugPrint('FCB configured result: $_configured');
      }
      _counter = direct_source.initialCounterValue();
      _adjustedCounter = _phaseDAdjustedCounterValue();
      _staticMethodValue = _phaseDStaticCounterValue();
      _statusLabel = _phaseDStatusLabel();
      _widgetTreeLabel = _phaseDWidgetTreeLabel();
      _fieldStatusLabel = _phaseDFieldStatusLabel(_pricingOffer);
      _quadCounter = _phaseDQuadCounterValue();
      debugPrint('FCB initialCounterValue result: $_counter');
      debugPrint('FCB adjustedCounterValue result: $_adjustedCounter');
      debugPrint('FCB staticCounterValue result: $_staticMethodValue');
      debugPrint('FCB statusLabel result: $_statusLabel');
      debugPrint('FCB widgetTreeLabel result: $_widgetTreeLabel');
      debugPrint('FCB fieldStatusLabel result: $_fieldStatusLabel');
      debugPrint('FCB quadCounterValue result: $_quadCounter');
      await _refreshState();
      if (_configured && _autoInstallOnStartup) {
        _check = await _codePush.checkForUpdate();
        if (_check!.patchAvailable) {
          _download = await _codePush.downloadUpdate();
        }
        await _refreshState();
      }
    });
  }

  Future<void> _refreshState() async {
    _currentPatch = await _codePush.currentPatchNumber();
    _lastKnownGoodPatch = await _codePush.lastKnownGoodPatchNumber();
    _rollbackHistory = await _codePush.crashRollbackHistory();
    _interpreterStats = await _codePush.interpreterStats();
    _ready = await _codePush.isNewPatchReadyToInstall();
    final platformPaths = await _codePush.platformPaths();
    _methodChannelCacheDir = platformPaths['cacheDir'] ?? 'unavailable';
    _methodChannelReady = _methodChannelCacheDir != 'unavailable';
    debugPrint(
      'FCB plugin method channel cacheDir result: $_methodChannelCacheDir',
    );
    debugPrint('FCB currentPatchNumber result: ${_currentPatch ?? 0}');
    debugPrint('FCB readyToInstall result: $_ready');
    if (_interpreterStats != null) {
      debugPrint(
        'FCB interpreterStats result: '
        '${_interpreterStats!.interpretedFunctionCalls}/'
        '${_interpreterStats!.aotFunctionCalls}/'
        '${_interpreterStats!.interpreterRatio.toStringAsFixed(6)}',
      );
    }
  }

  Future<void> _checkForUpdate() async {
    await _run(() async {
      _check = await _codePush.checkForUpdate();
      await _refreshState();
    });
  }

  Future<void> _downloadUpdate() async {
    await _run(() async {
      _download = await _codePush.downloadUpdate();
      await _refreshState();
    });
  }

  Future<void> _markLaunchSuccessful() async {
    await _run(() async {
      await _codePush.markLaunchSuccessful();
      await _refreshState();
    });
  }

  Future<void> _restartApp() async {
    await _codePush.restartApp();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
        debugPrint('FCB setState applied widget state');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FCB Counter')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Counter: $_counter',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('Adjusted: $_adjustedCounter',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Static method: $_staticMethodValue',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Status: $_statusLabel',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Widget tree: $_widgetTreeLabel',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Field status: $_fieldStatusLabel',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Quad: $_quadCounter',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _StatusTile(label: 'Configured', value: _configured ? 'yes' : 'no'),
            _StatusTile(
              label: 'Method channel',
              value: _methodChannelReady ? _methodChannelCacheDir : 'no',
            ),
            _StatusTile(label: 'Current patch', value: '${_currentPatch ?? 0}'),
            _StatusTile(
                label: 'Last known good', value: '${_lastKnownGoodPatch ?? 0}'),
            _StatusTile(label: 'Ready to apply', value: _ready ? 'yes' : 'no'),
            if (_interpreterStats != null)
              _StatusTile(
                label: 'Interpreter',
                value:
                    '${_interpreterStats!.interpretedFunctionCalls}/${_interpreterStats!.aotFunctionCalls} '
                    '(${(_interpreterStats!.interpreterRatio * 100).toStringAsFixed(2)}%)',
              ),
            if (_rollbackHistory.isNotEmpty)
              _StatusTile(
                label: 'Rollback history',
                value: _rollbackHistory
                    .take(5)
                    .map((event) =>
                        'p${event.patchNumber} attempts=${event.bootAttempts} '
                        'lkg=${event.lastKnownGoodPatchNumber ?? 0}')
                    .join('; '),
              ),
            if (_check != null)
              _StatusTile(
                label: 'Update',
                value: _check!.patchAvailable
                    ? 'patch ${_check!.patchNumber ?? '-'}'
                    : _check!.reason ?? 'none',
              ),
            if (_download != null)
              _StatusTile(
                label: 'Download',
                value: _download!.success
                    ? 'installed'
                    : _download!.reason ?? 'failed',
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _busy ? null : _checkForUpdate,
                  child: const Text('Check'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _downloadUpdate,
                  child: const Text('Download'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _markLaunchSuccessful,
                  child: const Text('Mark success'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _restartApp,
                  child: const Text('Restart'),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
