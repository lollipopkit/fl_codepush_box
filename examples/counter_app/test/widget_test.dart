import 'package:fcb_counter_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathsChannel = MethodChannel('dev.fcb.code_push/paths');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathsChannel, (call) async {
      if (call.method == 'getPaths') {
        return <String, String>{
          'cacheDir': '/tmp/fcb-test-cache',
          'baselineArtifactPath': '/tmp/fcb-test-libapp.so',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathsChannel, null);
  });

  testWidgets('counter renders current source values and increments', (
    tester,
  ) async {
    await tester.pumpWidget(const CounterApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Counter: 42'), findsOneWidget);
    expect(find.text('Status: patched'), findsOneWidget);
    expect(find.text('Widget tree: patched widget tree'), findsOneWidget);
    expect(find.text('Field status: base-field'), findsOneWidget);
    expect(find.text('Quad: 42'), findsOneWidget);
    expect(find.text('Method channel'), findsOneWidget);
    expect(find.text('/tmp/fcb-test-cache'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Counter: 43'), findsOneWidget);
  });
}
