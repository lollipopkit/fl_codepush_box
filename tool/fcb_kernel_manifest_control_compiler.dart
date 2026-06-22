part of 'fcb_kernel_manifest.dart';

extension _RestrictedBytecodeControlCompiler on _RestrictedBytecodeCompiler {
  void compileListForIn(Map<String, Object?> spec) {
    final receiver = spec['receiver'];
    final source = spec['source'];
    final local = spec['local'];
    final item = spec['item'];
    if (receiver is! Map || source is! Map) {
      stderr.writeln('list_for_in expression requires receiver and source');
      exit(2);
    }
    Map<String, Object?>? localSpec;
    if (local != null || item != null) {
      if (local is! Map || item is! Map) {
        stderr.writeln('mapped list_for_in requires local and item');
        exit(2);
      }
      localSpec = local.cast<String, Object?>();
      if (localSpec['id'] is! int) {
        stderr.writeln('mapped list_for_in local requires id');
        exit(2);
      }
    }
    final resultLocal = allocateLocal();
    final iteratorLocal = allocateLocal();
    final itemLocal = item == null ? null : allocateLocal();
    compileExpr(receiver.cast<String, Object?>());
    op(_opStoreLocal);
    u8(resultLocal);
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    if (itemLocal == null || localSpec == null) {
      op(_opLoadLocal);
      u8(resultLocal);
      op(_opLoadLocal);
      u8(iteratorLocal);
      callDynamic('get:current', 0);
    } else {
      op(_opLoadLocal);
      u8(iteratorLocal);
      callDynamic('get:current', 0);
      op(_opStoreLocal);
      u8(itemLocal);
      op(_opLoadLocal);
      u8(resultLocal);
      final localId = localSpec['id'] as int;
      final previous = scopedLocals[localId];
      scopedLocals[localId] = itemLocal;
      compileExpr((item as Map).cast<String, Object?>());
      if (previous == null) {
        scopedLocals.remove(localId);
      } else {
        scopedLocals[localId] = previous;
      }
    }
    callDynamic('add', 1);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    op(_opLoadLocal);
    u8(resultLocal);
  }

  void compileMapForIn(Map<String, Object?> spec) {
    final receiver = spec['receiver'];
    final source = spec['source'];
    final local = spec['local'];
    final key = spec['key'];
    final value = spec['value'];
    if (receiver is! Map || source is! Map) {
      stderr.writeln('map_for_in expression requires receiver and source');
      exit(2);
    }
    Map<String, Object?>? localSpec;
    if (local != null || key != null || value != null) {
      if (local is! Map || key is! Map || value is! Map) {
        stderr.writeln('mapped map_for_in requires local, key, and value');
        exit(2);
      }
      localSpec = local.cast<String, Object?>();
      if (localSpec['id'] is! int) {
        stderr.writeln('mapped map_for_in local requires id');
        exit(2);
      }
    }
    final resultLocal = allocateLocal();
    final iteratorLocal = allocateLocal();
    final entryLocal = allocateLocal();
    compileExpr(receiver.cast<String, Object?>());
    op(_opStoreLocal);
    u8(resultLocal);
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('get:current', 0);
    op(_opStoreLocal);
    u8(entryLocal);
    op(_opLoadLocal);
    u8(resultLocal);
    if (localSpec == null) {
      op(_opLoadLocal);
      u8(entryLocal);
      callDynamic('get:key', 0);
      op(_opLoadLocal);
      u8(entryLocal);
      callDynamic('get:value', 0);
    } else {
      final localId = localSpec['id'] as int;
      final previous = scopedLocals[localId];
      scopedLocals[localId] = entryLocal;
      compileExpr((key as Map).cast<String, Object?>());
      compileExpr((value as Map).cast<String, Object?>());
      if (previous == null) {
        scopedLocals.remove(localId);
      } else {
        scopedLocals[localId] = previous;
      }
    }
    callDynamic('[]=', 2);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    op(_opLoadLocal);
    u8(resultLocal);
  }

  void compileYieldForIn(Map<String, Object?> spec) {
    final source = spec['source'];
    final local = spec['local'];
    final body = spec['body'];
    final beforeBreak = spec['before_break'];
    final breakCondition = spec['break_condition'];
    if (source is! Map) {
      stderr.writeln('yield_for_in expression requires source');
      exit(2);
    }
    if (beforeBreak != null && beforeBreak is! Map) {
      stderr.writeln('yield_for_in before_break must be an expression');
      exit(2);
    }
    if (breakCondition != null && breakCondition is! Map) {
      stderr.writeln('yield_for_in break_condition must be an expression');
      exit(2);
    }
    if (beforeBreak != null && breakCondition == null) {
      stderr.writeln('yield_for_in before_break requires break_condition');
      exit(2);
    }
    Map<String, Object?>? localSpec;
    if (local != null) {
      if (local is! Map) {
        stderr.writeln('yield_for_in local must be an object');
        exit(2);
      }
      localSpec = local.cast<String, Object?>();
      if (localSpec['id'] is! int || body is! Map) {
        stderr.writeln('yield_for_in local mode requires local id and body');
        exit(2);
      }
    } else if (body != null) {
      stderr.writeln('yield_for_in body requires local');
      exit(2);
    }
    final iteratorLocal = allocateLocal();
    final currentLocal = localSpec == null ? null : allocateLocal();
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('get:current', 0);
    if (localSpec == null) {
      op(_opYield);
    } else {
      op(_opStoreLocal);
      u8(currentLocal!);
      final id = localSpec['id'] as int;
      final name = localSpec['name'];
      if (name is String && name.trim().isNotEmpty) {
        debugLocals.add({'slot': currentLocal, 'name': name.trim()});
      }
      final previous = scopedLocals[id];
      scopedLocals[id] = currentLocal;
      if (breakCondition is Map) {
        if (beforeBreak is Map) {
          compileExpr(beforeBreak.cast<String, Object?>());
          op(_opPop);
        }
        compileExpr(breakCondition.cast<String, Object?>());
        op(_opJumpIfFalse);
        final continuePatch = reserveU16();
        op(_opJump);
        final breakPatch = reserveU16();
        patchU16(continuePatch, code.length);
        compileExpr((body as Map).cast<String, Object?>());
        if (previous == null) {
          scopedLocals.remove(id);
        } else {
          scopedLocals[id] = previous;
        }
        op(_opPop);
        op(_opJump);
        u16(loopStart);
        patchU16(breakPatch, code.length);
        patchU16(endPatch, code.length);
        loadConst({'type': 'Null', 'value': null});
        return;
      }
      compileExpr((body as Map).cast<String, Object?>());
      if (previous == null) {
        scopedLocals.remove(id);
      } else {
        scopedLocals[id] = previous;
      }
      op(_opPop);
    }
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    loadConst({'type': 'Null', 'value': null});
  }

  void callDynamic(String method, int argc) {
    op(_opCallDynamic);
    u16(addConst({'type': 'String', 'value': method}));
    u8(argc);
  }

  void compileSetLocal(Map<String, Object?> spec) {
    final id = spec['id'];
    final value = spec['value'];
    if (id is! int || value is! Map) {
      stderr.writeln('set_local expression requires id and value');
      exit(2);
    }
    final index = scopedLocals[id];
    if (index == null) {
      stderr.writeln('unknown set_local target $id');
      exit(2);
    }
    compileExpr(value.cast<String, Object?>());
    op(_opStoreLocal);
    u8(index);
    loadConst({'type': 'Null', 'value': null});
  }

  void compileWhileLoop(Map<String, Object?> spec) {
    final condition = spec['condition'];
    final body = spec['body'];
    final beforeBreak = spec['before_break'];
    final breakCondition = spec['break_condition'];
    final beforeContinue = spec['before_continue'];
    final continueCondition = spec['continue_condition'];
    final continueBody = spec['continue_body'];
    if (condition is! Map || body is! Map) {
      stderr.writeln('while_loop expression requires condition and body');
      exit(2);
    }
    if (beforeBreak != null && beforeBreak is! Map) {
      stderr.writeln('while_loop before_break must be an expression');
      exit(2);
    }
    if (breakCondition != null && breakCondition is! Map) {
      stderr.writeln('while_loop break_condition must be an expression');
      exit(2);
    }
    if (beforeBreak != null && breakCondition == null) {
      stderr.writeln('while_loop before_break requires break_condition');
      exit(2);
    }
    if (beforeContinue != null && beforeContinue is! Map) {
      stderr.writeln('while_loop before_continue must be an expression');
      exit(2);
    }
    if (continueCondition != null && continueCondition is! Map) {
      stderr.writeln('while_loop continue_condition must be an expression');
      exit(2);
    }
    if (continueBody != null && continueBody is! Map) {
      stderr.writeln('while_loop continue_body must be an expression');
      exit(2);
    }
    if (beforeContinue != null && continueCondition == null) {
      stderr.writeln('while_loop before_continue requires continue_condition');
      exit(2);
    }
    if (continueCondition != null && continueBody == null) {
      stderr.writeln('while_loop continue_condition requires continue_body');
      exit(2);
    }
    final loopStart = code.length;
    compileExpr(condition.cast<String, Object?>());
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    if (continueCondition is Map) {
      if (beforeContinue is Map) {
        compileExpr(beforeContinue.cast<String, Object?>());
        op(_opPop);
      }
      compileExpr(continueCondition.cast<String, Object?>());
      op(_opJumpIfFalse);
      final bodyPatch = reserveU16();
      if ((continueBody as Map)['null'] != true) {
        compileExpr(continueBody.cast<String, Object?>());
        op(_opPop);
      }
      op(_opJump);
      u16(loopStart);
      patchU16(bodyPatch, code.length);
    }
    if (breakCondition is Map) {
      if (beforeBreak is Map) {
        compileExpr(beforeBreak.cast<String, Object?>());
        op(_opPop);
      }
      compileExpr(breakCondition.cast<String, Object?>());
      op(_opJumpIfFalse);
      final continuePatch = reserveU16();
      op(_opJump);
      final breakPatch = reserveU16();
      patchU16(continuePatch, code.length);
      compileExpr(body.cast<String, Object?>());
      op(_opPop);
      op(_opJump);
      u16(loopStart);
      patchU16(breakPatch, code.length);
      patchU16(endPatch, code.length);
      loadConst({'type': 'Null', 'value': null});
      return;
    }
    compileExpr(body.cast<String, Object?>());
    op(_opPop);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    loadConst({'type': 'Null', 'value': null});
  }

  void compileLet(Map<String, Object?> spec) {
    final locals = spec['locals'];
    final body = spec['body'];
    if (locals is! List || body is! Map) {
      stderr.writeln('let expression requires locals and body');
      exit(2);
    }

    final previous = <int, int?>{};
    for (final item in locals) {
      if (item is! Map) {
        stderr.writeln('let local must be an object');
        exit(2);
      }
      final local = item.cast<String, Object?>();
      final id = local['id'];
      final name = local['name'];
      final value = local['value'];
      if (id is! int || value is! Map) {
        stderr.writeln('let local requires id and value');
        exit(2);
      }
      final localIndex = allocateLocal();
      compileExpr(value.cast<String, Object?>());
      op(_opStoreLocal);
      u8(localIndex);
      if (name is String && name.trim().isNotEmpty) {
        debugLocals.add({'slot': localIndex, 'name': name.trim()});
      }
      previous[id] = scopedLocals[id];
      scopedLocals[id] = localIndex;
    }
    compileExpr(body.cast<String, Object?>());
    for (final id in previous.keys.toList().reversed) {
      final old = previous[id];
      if (old == null) {
        scopedLocals.remove(id);
      } else {
        scopedLocals[id] = old;
      }
    }
  }

  void compileTryCatch(Map<String, Object?> spec) {
    final body = spec['body'];
    final catchBody = spec['catch'];
    final catchLocal = spec['catch_local'];
    if (body is! Map || catchBody is! Map || catchLocal is! int) {
      stderr.writeln('try_catch expression requires body/catch/catch_local');
      exit(2);
    }

    op(_opTryBegin);
    final handlerPatch = reserveU16();
    final endOperandPatch = reserveU16();
    compileExpr(body.cast<String, Object?>());
    op(_opJump);
    final endJumpPatch = reserveU16();

    patchU16(handlerPatch, code.length);
    final catchLocalIndex = allocateLocal();
    op(_opStoreLocal);
    u8(catchLocalIndex);
    final previous = scopedLocals[catchLocal];
    scopedLocals[catchLocal] = catchLocalIndex;
    compileExpr(catchBody.cast<String, Object?>());
    if (previous == null) {
      scopedLocals.remove(catchLocal);
    } else {
      scopedLocals[catchLocal] = previous;
    }

    patchU16(endOperandPatch, code.length);
    patchU16(endJumpPatch, code.length);
  }

  void compileTryFinally(Map<String, Object?> spec) {
    final body = spec['body'];
    final finalizer = spec['finally'];
    if (body is! Map || finalizer is! Map) {
      stderr.writeln('try_finally expression requires body/finally');
      exit(2);
    }
    final preserveValue = spec['value'] == true;
    final valueLocal = preserveValue ? allocateLocal() : null;

    op(_opTryFinally);
    final finallyPatch = reserveU16();
    final endOperandPatch = reserveU16();
    compileExpr(body.cast<String, Object?>());
    if (valueLocal != null) {
      op(_opStoreLocal);
      u8(valueLocal);
    }
    op(_opJump);
    final endJumpPatch = reserveU16();

    patchU16(finallyPatch, code.length);
    compileExpr(finalizer.cast<String, Object?>());
    op(_opPop);
    op(_opEndFinally);

    patchU16(endOperandPatch, code.length);
    patchU16(endJumpPatch, code.length);
    if (valueLocal != null) {
      op(_opLoadLocal);
      u8(valueLocal);
    } else {
      loadConst({'type': 'Null', 'value': null});
    }
  }
}
