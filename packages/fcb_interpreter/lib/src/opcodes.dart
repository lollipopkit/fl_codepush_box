/// FCB bytecode opcodes, matching the Rust crate opcodes.
class OpCode {
  static const int return_ = 0x01;
  static const int jump = 0x02;
  static const int jumpIfFalse = 0x03;
  static const int jumpIfTrue = 0x04;

  static const int loadNull = 0x10;
  static const int loadTrue = 0x11;
  static const int loadFalse = 0x12;
  static const int loadInt = 0x13;
  static const int loadDouble = 0x14;
  static const int loadString = 0x15;

  static const int add = 0x20;
  static const int subtract = 0x21;
  static const int multiply = 0x22;
  static const int divide = 0x23;
  static const int modulo = 0x24;
  static const int negate = 0x25;

  static const int equal = 0x30;
  static const int notEqual = 0x31;
  static const int lessThan = 0x32;
  static const int lessEqual = 0x33;
  static const int greaterThan = 0x34;
  static const int greaterEqual = 0x35;

  static const int logicalNot = 0x40;

  static const int isInt = 0x50;
  static const int isDouble = 0x51;
  static const int isBool = 0x52;
  static const int isString = 0x53;
  static const int isNull = 0x54;

  static const int loadLocal = 0x60;
  static const int storeLocal = 0x61;

  static const int listNew = 0x70;
  static const int listAdd = 0x71;
  static const int mapNew = 0x72;
  static const int mapSet = 0x73;
  static const int listGet = 0x74;
  static const int listLength = 0x75;

  static const int stringConcat = 0x80;
  static const int stringInterpolate = 0x81;
  static const int toString_ = 0x82;
  static const int intParse = 0x83;
  static const int doubleParse = 0x84;
  static const int intToDouble = 0x85;
  static const int doubleToInt = 0x86;

  static const int mathAbs = 0x90;
  static const int mathMin = 0x91;
  static const int mathMax = 0x92;
  static const int mathSqrt = 0x93;
  static const int mathRound = 0x94;

  static const int callPatchable = 0xA0;
  static const int callCore = 0xA1;

  static String name(int op) {
    switch (op) {
      case return_: return 'Return';
      case jump: return 'Jump';
      case jumpIfFalse: return 'JumpIfFalse';
      case jumpIfTrue: return 'JumpIfTrue';
      case loadNull: return 'LoadNull';
      case loadTrue: return 'LoadTrue';
      case loadFalse: return 'LoadFalse';
      case loadInt: return 'LoadInt';
      case loadDouble: return 'LoadDouble';
      case loadString: return 'LoadString';
      case add: return 'Add';
      case subtract: return 'Subtract';
      case multiply: return 'Multiply';
      case divide: return 'Divide';
      case modulo: return 'Modulo';
      case negate: return 'Negate';
      case equal: return 'Equal';
      case notEqual: return 'NotEqual';
      case lessThan: return 'LessThan';
      case lessEqual: return 'LessEqual';
      case greaterThan: return 'GreaterThan';
      case greaterEqual: return 'GreaterEqual';
      case logicalNot: return 'LogicalNot';
      case isInt: return 'IsInt';
      case isDouble: return 'IsDouble';
      case isBool: return 'IsBool';
      case isString: return 'IsString';
      case isNull: return 'IsNull';
      case loadLocal: return 'LoadLocal';
      case storeLocal: return 'StoreLocal';
      case listNew: return 'ListNew';
      case listAdd: return 'ListAdd';
      case mapNew: return 'MapNew';
      case mapSet: return 'MapSet';
      case listGet: return 'ListGet';
      case listLength: return 'ListLength';
      case stringConcat: return 'StringConcat';
      case stringInterpolate: return 'StringInterpolate';
      case toString_: return 'ToString';
      case intParse: return 'IntParse';
      case doubleParse: return 'DoubleParse';
      case intToDouble: return 'IntToDouble';
      case doubleToInt: return 'DoubleToInt';
      case mathAbs: return 'MathAbs';
      case mathMin: return 'MathMin';
      case mathMax: return 'MathMax';
      case mathSqrt: return 'MathSqrt';
      case mathRound: return 'MathRound';
      case callPatchable: return 'CallPatchable';
      case callCore: return 'CallCore';
      default: return 'Unknown(0x${op.toRadixString(16)})';
    }
  }
}
