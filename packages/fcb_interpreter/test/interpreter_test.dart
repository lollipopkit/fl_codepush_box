import 'dart:convert';
import 'package:fcb_interpreter/fcb_interpreter.dart';
import 'package:test/test.dart';

BytecodeModule _makeModule({
  List<String> stringPool = const [],
  List<int> intPool = const [],
  List<double> doublePool = const [],
  required List<Map<String, dynamic>> functions,
}) {
  return BytecodeModule(
    version: 1,
    appId: 'test',
    releaseVersion: '1.0.0+1',
    patchNumber: 1,
    stringPool: stringPool,
    intPool: intPool,
    doublePool: doublePool,
    functions: functions
        .map((f) => BytecodeFunction(
              name: f['name'] as String,
              paramCount: f['param_count'] as int,
              localCount: f['local_count'] as int,
              code: (f['code'] as List).cast<int>(),
            ))
        .toList(),
  );
}

void main() {
  group('FcbInterpreter', () {
    test('loadInt and return', () {
      // LoadInt 0, Return
      final module = _makeModule(
        intPool: [42],
        functions: [
          {
            'name': 'getAnswer',
            'param_count': 0,
            'local_count': 1,
            'code': [0x13, 0x00, 0x00, 0x01], // LoadInt 0, Return
          }
        ],
      );
      final interp = FcbInterpreter(module);
      final result = interp.call('getAnswer', []);
      expect(result.success, isTrue);
      expect(result.value, equals(42));
    });

    test('add two integers', () {
      // LoadInt 0, LoadInt 1, Add, Return
      final module = _makeModule(
        intPool: [10, 20],
        functions: [
          {
            'name': 'add',
            'param_count': 0,
            'local_count': 1,
            'code': [
              0x13, 0x00, 0x00, // LoadInt 0 (10)
              0x13, 0x00, 0x01, // LoadInt 1 (20)
              0x20, // Add
              0x01, // Return
            ],
          }
        ],
      );
      final interp = FcbInterpreter(module);
      final result = interp.call('add', []);
      expect(result.success, isTrue);
      expect(result.value, equals(30));
    });

    test('multiply with parameters', () {
      // LoadLocal 0, LoadLocal 1, Multiply, Return
      final module = _makeModule(
        functions: [
          {
            'name': 'multiply',
            'param_count': 2,
            'local_count': 3,
            'code': [
              0x60, 0x00, // LoadLocal 0
              0x60, 0x01, // LoadLocal 1
              0x22, // Multiply
              0x01, // Return
            ],
          }
        ],
      );
      final interp = FcbInterpreter(module);
      final result = interp.call('multiply', [6, 7]);
      expect(result.success, isTrue);
      expect(result.value, equals(42));
    });

    test('string operations', () {
      final module = _makeModule(
        stringPool: ['hello', ' world'],
        functions: [
          {
            'name': 'greet',
            'param_count': 0,
            'local_count': 1,
            'code': [
              0x15, 0x00, 0x00, // LoadString 0 ("hello")
              0x15, 0x00, 0x01, // LoadString 1 (" world")
              0x80, // StringConcat
              0x01, // Return
            ],
          }
        ],
      );
      final interp = FcbInterpreter(module);
      final result = interp.call('greet', []);
      expect(result.success, isTrue);
      expect(result.value, equals('hello world'));
    });

    test('conditional jump if false', () {
      // if (x > 10) { return 1 } else { return 0 }
      // LoadLocal 0, LoadInt 10, GreaterThan, JumpIfFalse else, LoadInt 1, Return, else: LoadInt 0, Return
      final module = _makeModule(
        intPool: [10, 1, 0],
        functions: [
          {
            'name': 'isBig',
            'param_count': 1,
            'local_count': 2,
            'code': [
              0x60, 0x00, // LoadLocal 0 (param)
              0x13, 0x00, 0x00, // LoadInt 0 (10)
              0x34, // GreaterThan
              0x03, 0x00, 0x0F, // JumpIfFalse offset 15 (else branch)
              0x13, 0x00, 0x01, // LoadInt 1 (1)
              0x01, // Return
              // else:
              0x13, 0x00, 0x02, // LoadInt 2 (0)
              0x01, // Return
            ],
          }
        ],
      );
      final interp = FcbInterpreter(module);
      expect(interp.call('isBig', [20]).value, equals(1));
      expect(interp.call('isBig', [5]).value, equals(0));
    });

    test('negate and logical not', () {
      final module = _makeModule(
        intPool: [5],
        functions: [
          {
            'name': 'negate',
            'param_count': 1,
            'local_count': 2,
            'code': [
              0x60, 0x00, // LoadLocal 0
              0x25, // Negate
              0x01, // Return
            ],
          },
          {
            'name': 'not',
            'param_count': 1,
            'local_count': 2,
            'code': [
              0x60, 0x00, // LoadLocal 0
              0x40, // LogicalNot
              0x01, // Return
            ],
          },
        ],
      );
      final interp = FcbInterpreter(module);
      expect(interp.call('negate', [5]).value, equals(-5));
      expect(interp.call('not', [true]).value, equals(false));
      expect(interp.call('not', [false]).value, equals(true));
    });

    test('list operations', () {
      // Create a list [1, 2, 3] and return its length
      final module = _makeModule(
        intPool: [1, 2, 3],
        functions: [
          {
            'name': 'listLen',
            'param_count': 0,
            'local_count': 1,
            'code': [
              0x70, // ListNew
              0x13, 0x00, 0x00, // LoadInt 0 (1)
              0x71, // ListAdd
              0x13, 0x00, 0x01, // LoadInt 1 (2)
              0x71, // ListAdd
              0x13, 0x00, 0x02, // LoadInt 2 (3)
              0x71, // ListAdd
              0x75, // ListLength
              0x01, // Return
            ],
          },
        ],
      );
      final interp = FcbInterpreter(module);
      final result = interp.call('listLen', []);
      expect(result.success, isTrue);
      expect(result.value, equals(3));
    });
  });

  group('FcbDispatcher', () {
    test('no patch returns null', () {
      final dispatcher = FcbDispatcher();
      expect(dispatcher.hasPatch, isFalse);
      expect(dispatcher.call('foo', []), isNull);
    });

    test('load module and call function', () {
      final module = _makeModule(
        intPool: [42],
        functions: [
          {
            'name': 'getAnswer',
            'param_count': 0,
            'local_count': 1,
            'code': [0x13, 0x00, 0x00, 0x01],
          }
        ],
      );
      final bytes = utf8.encode(jsonEncode({
        'version': 1,
        'app_id': 'test',
        'release_version': '1.0.0+1',
        'patch_number': 1,
        'string_pool': [],
        'int_pool': [42],
        'double_pool': [],
        'functions': [
          {
            'name': 'getAnswer',
            'param_count': 0,
            'local_count': 1,
            'code': [0x13, 0x00, 0x00, 0x01],
          }
        ],
      }));
      final dispatcher = FcbDispatcher();
      expect(dispatcher.loadModule(bytes), isTrue);
      expect(dispatcher.hasPatch, isTrue);
      expect(dispatcher.hasFunction('getAnswer'), isTrue);
      expect(dispatcher.call('getAnswer', []), equals(42));
    });

    test('clear module resets state', () {
      final module = _makeModule(
        intPool: [1],
        functions: [
          {
            'name': 'one',
            'param_count': 0,
            'local_count': 1,
            'code': [0x13, 0x00, 0x00, 0x01],
          }
        ],
      );
      final bytes = utf8.encode(jsonEncode({
        'version': 1,
        'app_id': 'test',
        'release_version': '1.0.0+1',
        'patch_number': 1,
        'string_pool': [],
        'int_pool': [1],
        'double_pool': [],
        'functions': [
          {
            'name': 'one',
            'param_count': 0,
            'local_count': 1,
            'code': [0x13, 0x00, 0x00, 0x01],
          }
        ],
      }));
      final dispatcher = FcbDispatcher();
      dispatcher.loadModule(bytes);
      dispatcher.clearModule();
      expect(dispatcher.hasPatch, isFalse);
      expect(dispatcher.call('one', []), isNull);
    });
  });
}
