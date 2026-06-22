part of fcb_kernel_reader;

Map<String, Object?>? _yieldStatementExpr(
  YieldStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statement.isYieldStar) {
    final staticItems = _yieldStarStaticListExpr(
      statement.expression,
      params,
      libraryUri,
      locals,
    );
    if (staticItems != null) return staticItems;
    if (asyncKind == 'sync_star') {
      return _yieldStarDynamicIterableExpr(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
    }
    if (asyncKind == 'async_star') {
      final streamIterable = _finiteStreamDynamicSource(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
      if (streamIterable != null) {
        return {
          'yield_for_in': {'source': streamIterable},
        };
      }
      final stream = _yieldStarStreamExpr(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
      if (stream != null) return stream;
    }
    return null;
  }
  final value = _generatorValueExpr(
    statement.expression,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (value == null) return null;
  return {'yield': value};
}

Map<String, Object?>? _yieldStarStaticListExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final listItems =
      _expr(expression, params, libraryUri, locals)?['list'] ??
      _finiteStreamStaticListItems(expression, params, libraryUri, locals);
  if (listItems is! List) return null;
  final items = <Map<String, Object?>>[];
  for (final item in listItems) {
    if (item is! Map) return null;
    items.add({'yield': item.cast<String, Object?>()});
  }
  if (items.isEmpty) return {'null': true};
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?>? _yieldStarDynamicIterableExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final source = _expr(expression, params, libraryUri, locals);
  if (source == null || source['list'] is List || source['map'] is List) {
    return null;
  }
  return {
    'yield_for_in': {'source': source},
  };
}
