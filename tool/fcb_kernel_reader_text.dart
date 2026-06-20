part of fcb_kernel_reader;

String? _typeName(DartType type) => fcbKernelTypeName(type);

String _staticTargetName(Procedure target) {
  final library = target.enclosingLibrary.importUri.toString();
  final klass = target.enclosingClass;
  if (klass != null) {
    return '$library::class:${klass.name}.${target.name.text}';
  }
  return '$library::${target.name.text}';
}

String _constructorLibraryUri(Library library, String fallbackLibraryUri) {
  final uri = library.importUri;
  if (uri.scheme == 'package' || uri.scheme == 'dart') {
    return uri.toString();
  }
  return fallbackLibraryUri;
}

String _nodeText(Node? node) {
  if (node == null) return '';
  final buffer = StringBuffer();
  Printer(buffer, syntheticNames: NameSystem()).writeNode(node);
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
