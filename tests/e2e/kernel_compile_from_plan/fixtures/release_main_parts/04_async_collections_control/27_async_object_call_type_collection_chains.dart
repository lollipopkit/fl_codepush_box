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
  var out = <String>['release-async-object-call-type-head'];
  try {
    final marker = await ready;
    final user = User('release-async-object-call-type-user', marker);
    final box = Box<String>(user.label);
    final dynamic dynamicGreeter = greeter;
    final isString = candidate is String;
    final casted = candidate as String;
    out = [
      ...out,
      'release-async-object-call-type-is-$isString',
      dynamicGreeter.surround(
        casted,
        prefix: 'release-async-object-call-type-candidate-',
        suffix: box.value,
      ),
    ];
    switch (await tierReady) {
      case 'gold' when !await enabled:
        out = [
          ...out,
          'release-async-object-call-type-user-${user.label}',
          for (final name in names)
            dynamicGreeter.surround(
              name,
              prefix: 'release-async-object-call-type-for-',
              suffix: marker,
            ),
        ];
        break;
      case 'blocked':
        throw 'release-async-object-call-type-blocked';
      default:
        out = [...out, 'release-async-object-call-type-default-${box.value}'];
    }
  } catch (e) {
    final marker = await recovery;
    out = [...out, 'release-async-object-call-type-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'release-async-object-call-type-cleanup-$marker'];
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
  var out = <String, Object>{'mode': 'release-async-named-object-map-head'};
  try {
    final marker = await ready;
    final config = Config(
      name: label('release-async-named-object-map-name'),
      label: marker,
    );
    switch (await tierReady) {
      case 'gold' when !await enabled:
        out = {
          ...out,
          'config': config,
          for (final entry in labels.entries)
            'release-async-named-object-map-${entry.key}': Config(
              name: entry.key,
              label: label(entry.value),
            ),
        };
        break;
      case 'blocked':
        throw 'release-async-named-object-map-blocked';
      default:
        out = {
          ...out,
          'box': Box<String>('release-async-named-object-map-default'),
        };
    }
  } catch (e) {
    final marker = await recovery;
    out = {
      ...out,
      'caught': 'release-async-named-object-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'release-async-named-object-map-cleanup-$marker'};
  }
  return out;
}
