import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Uint8List encodeBinaryModule(Map<String, Object?> module) {
  final writer = _BinaryModuleWriter();
  writer.ascii('FCBM');
  writer.u32(module['version'] as int? ?? 1);
  final functions = module['functions'];
  if (functions is! List) {
    stderr.writeln('bytecode module functions must be a list');
    exit(2);
  }
  writer.u16(functions.length, 'function count');
  for (final item in functions) {
    if (item is! Map) {
      stderr.writeln('bytecode module function must be an object');
      exit(2);
    }
    final function = item.cast<String, Object?>();
    writer.string(function['name']?.toString() ?? '', 'function name');
    writer.u8(switch (function['return_convention']?.toString() ?? 'tagged') {
      'tagged' => 0,
      'unboxed_int64' => 1,
      final value => _unsupportedReturnConvention(value),
    });
    writer.u8(function['param_count'] as int? ?? 0);
    writer.u8(function['local_count'] as int? ?? 0);
    final constants = function['constants'];
    if (constants is! List) {
      stderr.writeln('bytecode function constants must be a list');
      exit(2);
    }
    writer.u16(constants.length, 'constant count');
    for (final constant in constants) {
      if (constant is! Map) {
        stderr.writeln('bytecode constant must be an object');
        exit(2);
      }
      writer.constant(constant.cast<String, Object?>());
    }
    final code = function['code'];
    if (code is! List) {
      stderr.writeln('bytecode function code must be a list');
      exit(2);
    }
    writer.u32(code.length);
    for (final byte in code) {
      if (byte is! int || byte < 0 || byte > 255) {
        stderr.writeln('bytecode code byte exceeds u8 range');
        exit(2);
      }
      writer.u8(byte);
    }
    final sourceMap = function['source_map'];
    final sourceMapEntries = sourceMap is List ? sourceMap : const [];
    writer.u16(sourceMapEntries.length, 'source map count');
    for (final entry in sourceMapEntries) {
      if (entry is! Map) {
        stderr.writeln('source_map entry must be an object');
        exit(2);
      }
      final sourceEntry = entry.cast<String, Object?>();
      writer.u32((sourceEntry['bytecode_offset'] as num?)?.toInt() ?? 0);
      writer.string(
        sourceEntry['source_location']?.toString() ?? '',
        'source location',
      );
    }
  }
  return writer.takeBytes();
}

Never _unsupportedReturnConvention(String value) {
  stderr.writeln('unsupported return_convention $value');
  exit(2);
}

class _BinaryModuleWriter {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  Uint8List takeBytes() => _bytes.takeBytes();

  void ascii(String value) {
    _bytes.add(value.codeUnits);
  }

  void string(String value, String label) {
    final bytes = utf8.encode(value);
    u16(bytes.length, label);
    _bytes.add(bytes);
  }

  void constant(Map<String, Object?> constant) {
    switch (constant['type']) {
      case 'Null':
        u8(0);
      case 'Int':
        u8(1);
        i64((constant['value'] as num?)?.toInt() ?? 0);
      case 'Double':
        u8(2);
        f64((constant['value'] as num?)?.toDouble() ?? 0);
      case 'Bool':
        u8(3);
        u8(constant['value'] == true ? 1 : 0);
      case 'String':
        u8(4);
        string(constant['value']?.toString() ?? '', 'string constant');
      default:
        stderr.writeln(
          'unsupported bytecode constant type ${constant['type']}',
        );
        exit(2);
    }
  }

  void u8(int value) {
    if (value < 0 || value > 0xff) {
      stderr.writeln('binary value exceeds u8 range');
      exit(2);
    }
    _bytes.add([value]);
  }

  void u16(int value, String label) {
    if (value < 0 || value > 0xffff) {
      stderr.writeln('$label exceeds u16 range');
      exit(2);
    }
    _bytes.add([(value >> 8) & 0xff, value & 0xff]);
  }

  void u32(int value) {
    if (value < 0 || value > 0xffffffff) {
      stderr.writeln('binary value exceeds u32 range');
      exit(2);
    }
    _bytes.add([
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ]);
  }

  void i64(int value) {
    final data = ByteData(8)..setInt64(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void f64(double value) {
    final data = ByteData(8)..setFloat64(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }
}
