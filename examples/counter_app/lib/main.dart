import 'package:fcb_code_push/fcb_code_push.dart';
import 'package:flutter/material.dart';

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

void main() {
  runApp(const CounterApp());
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  final _codePush = FcbCodePush.instance;
  bool _busy = true;
  bool _configured = false;
  int? _currentPatch;
  int _counter = 1;
  bool _ready = false;
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
      }
      await _refreshState();
    });
  }

  Future<void> _refreshState() async {
    _currentPatch = await _codePush.currentPatchNumber();
    _ready = await _codePush.isNewPatchReadyToInstall();
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
            const SizedBox(height: 16),
            _StatusTile(label: 'Configured', value: _configured ? 'yes' : 'no'),
            _StatusTile(label: 'Current patch', value: '${_currentPatch ?? 0}'),
            _StatusTile(label: 'Ready to apply', value: _ready ? 'yes' : 'no'),
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
