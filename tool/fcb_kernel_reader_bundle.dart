import 'dart:io';

const _kernelReaderParts = [
  'fcb_kernel_closure_audit.dart',
  'fcb_kernel_callback_inline.dart',
  'fcb_kernel_type_names.dart',
  'fcb_kernel_unsupported_audit.dart',
  'fcb_kernel_logical_expr.dart',
  'fcb_kernel_switch_expr.dart',
  'fcb_kernel_switch_statement_expr.dart',
  'fcb_kernel_async_expr.dart',
  'fcb_kernel_async_for_expr.dart',
  'fcb_kernel_async_loop_expr.dart',
  'fcb_kernel_collection_expr.dart',
  'fcb_kernel_collection_append_expr.dart',
  'fcb_kernel_generator_expr.dart',
  'fcb_kernel_generator_for_expr.dart',
  'fcb_kernel_generator_for_in_body_expr.dart',
  'fcb_kernel_generator_loop_expr.dart',
  'fcb_kernel_generator_stream_expr.dart',
  'fcb_kernel_generator_yield_expr.dart',
  'fcb_kernel_returning_closure.dart',
  'fcb_kernel_statement_expr.dart',
  'fcb_kernel_static_invocation_expr.dart',
  'fcb_kernel_reader_text.dart',
  'fcb_kernel_unary_binary_expr.dart',
];

File writeKernelReaderBundle(Directory temp) {
  final toolDir =
      Platform.environment['FCB_KERNEL_TOOL_DIR'] ??
      File.fromUri(Platform.script).parent.path;
  for (final part in _kernelReaderParts) {
    File(
      '${temp.path}/$part',
    ).writeAsStringSync(File('$toolDir/$part').readAsStringSync());
  }
  final file = File('${temp.path}/kernel_reader.dart');
  file.writeAsStringSync(
    File('$toolDir/fcb_kernel_reader.dart').readAsStringSync(),
  );
  return file;
}
