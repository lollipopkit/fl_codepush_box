Future<List<String>> asyncObjectCallTypeCollectionSwitchRecoveryCleanup(
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> names,
  Object candidate,
  Greeter greeter,
) async {
  var out = <String>['patched-async-object-call-type-head'];
  try {
    final marker = await ready;
    final user = User('patched-async-object-call-type-user', marker);
    final box = Box<String>(user.label);
    final dynamic dynamicGreeter = greeter;
    final isString = candidate is String;
    final casted = candidate as String;
    out = [
      ...out,
      'patched-async-object-call-type-is-$isString',
      dynamicGreeter.surround(
        casted,
        prefix: 'patched-async-object-call-type-candidate-',
        suffix: box.value,
      ),
    ];
    switch (await tierReady) {
      case 'gold' when !await enabled:
        out = [
          ...out,
          'patched-async-object-call-type-user-${user.label}',
          for (final name in names)
            dynamicGreeter.surround(
              name,
              prefix: 'patched-async-object-call-type-for-',
              suffix: marker,
            ),
        ];
        break;
      case 'blocked':
        throw 'patched-async-object-call-type-blocked';
      default:
        out = [...out, 'patched-async-object-call-type-default-${box.value}'];
    }
  } catch (e) {
    final marker = await recovery;
    out = [...out, 'patched-async-object-call-type-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'patched-async-object-call-type-cleanup-$marker'];
  }
  return out;
}

Future<Map<String, Object>> asyncNamedObjectStaticCallMapRecoveryCleanup(
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> labels,
) async {
  var out = <String, Object>{'mode': 'patched-async-named-object-map-head'};
  try {
    final marker = await ready;
    final config = Config(
      name: label('patched-async-named-object-map-name'),
      label: marker,
    );
    switch (await tierReady) {
      case 'gold' when !await enabled:
        out = {
          ...out,
          'config': config,
          for (final entry in labels.entries)
            'patched-async-named-object-map-${entry.key}': Config(
              name: entry.key,
              label: label(entry.value),
            ),
        };
        break;
      case 'blocked':
        throw 'patched-async-named-object-map-blocked';
      default:
        out = {
          ...out,
          'box': Box<String>('patched-async-named-object-map-default'),
        };
    }
  } catch (e) {
    final marker = await recovery;
    out = {
      ...out,
      'caught': 'patched-async-named-object-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'patched-async-named-object-map-cleanup-$marker'};
  }
  return out;
}
