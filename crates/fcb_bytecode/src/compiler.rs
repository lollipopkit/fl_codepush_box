use crate::format::{BytecodeFunction, BytecodeModule, Constant, ConstantPool, OpCode};
use fcb_core::{err, Result};
use serde::Deserialize;
use std::collections::BTreeMap;

#[derive(Debug, Deserialize)]
pub struct SourceModule {
    pub functions: Vec<SourceFunction>,
}

#[derive(Debug, Deserialize)]
pub struct SourceFunction {
    pub name: String,
    #[serde(default)]
    pub params: Vec<String>,
    pub body: Expr,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum Expr {
    Int {
        int: i64,
    },
    Double {
        double: f64,
    },
    Bool {
        bool: bool,
    },
    String {
        string: String,
    },
    Null {
        null: bool,
    },
    List {
        list: Vec<Expr>,
    },
    Map {
        map: Vec<MapEntry>,
    },
    Arg {
        arg: String,
    },
    Local {
        local: String,
    },
    Let {
        #[serde(rename = "let")]
        let_: String,
        value: Box<Expr>,
        body: Box<Expr>,
    },
    Binary {
        op: String,
        left: Box<Expr>,
        right: Box<Expr>,
    },
    If {
        #[serde(rename = "if")]
        if_: Box<Expr>,
        then: Box<Expr>,
        #[serde(rename = "else")]
        else_: Box<Expr>,
    },
    While {
        #[serde(rename = "while")]
        while_: Box<Expr>,
        body: Box<Expr>,
        then: Box<Expr>,
    },
}

#[derive(Debug, Deserialize)]
pub struct MapEntry {
    pub key: Expr,
    pub value: Expr,
}

impl Expr {
    fn is_null_literal(&self) -> bool {
        matches!(self, Self::Null { null: true })
    }
}

pub fn compile_source_json(bytes: &[u8]) -> Result<BytecodeModule> {
    let source: SourceModule = serde_json::from_slice(bytes)?;
    compile_source(source)
}

pub fn compile_source(source: SourceModule) -> Result<BytecodeModule> {
    if source.functions.is_empty() {
        return Err(err("bytecode source must contain at least one function"));
    }
    let functions = source
        .functions
        .into_iter()
        .map(compile_function)
        .collect::<Result<Vec<_>>>()?;
    let module = BytecodeModule::new(functions);
    module.validate()?;
    Ok(module)
}

fn compile_function(function: SourceFunction) -> Result<BytecodeFunction> {
    if function.name.trim().is_empty() {
        return Err(err("bytecode function name must not be empty"));
    }
    let param_count = u8::try_from(function.params.len())
        .map_err(|_| err("bytecode function has more than 255 parameters"))?;
    let total_locals = (param_count as usize)
        .checked_add(1)
        .ok_or_else(|| err("bytecode local count overflow"))?;
    let local_count = u8::try_from(total_locals)
        .map_err(|_| err("bytecode local count exceeds u8 index space"))?;

    let mut builder = BytecodeBuilder::new();
    let mut scope = Scope::default();
    for (index, param) in function.params.iter().enumerate() {
        if scope.args.insert(param.clone(), index as u8).is_some() {
            return Err(err(format!("duplicate parameter {param}")));
        }
    }
    builder.compile_expr(&function.body, &mut scope)?;
    builder.op(OpCode::Return);

    Ok(BytecodeFunction {
        name: function.name,
        return_convention: "tagged".to_string(),
        param_count,
        local_count: scope.next_local.max(local_count),
        constants: builder.constants.into_vec(),
        code: builder.code,
    })
}

#[derive(Debug, Default)]
struct Scope {
    args: BTreeMap<String, u8>,
    locals: BTreeMap<String, u8>,
    next_local: u8,
}

impl Scope {
    fn push_local(&mut self, name: &str) -> Result<u8> {
        if self.locals.contains_key(name) || self.args.contains_key(name) {
            return Err(err(format!("duplicate local {name}")));
        }
        let index = self.next_local;
        self.next_local = self
            .next_local
            .checked_add(1)
            .ok_or_else(|| err("bytecode local count exceeds u8 index space"))?;
        self.locals.insert(name.to_string(), index);
        Ok(index)
    }
}

#[derive(Debug, Default)]
pub struct BytecodeBuilder {
    code: Vec<u8>,
    constants: ConstantPool,
}

impl BytecodeBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn code(&self) -> &[u8] {
        &self.code
    }

    pub fn op(&mut self, opcode: OpCode) {
        self.code.push(opcode as u8);
    }

    pub fn u8(&mut self, value: u8) {
        self.code.push(value);
    }

    pub fn u16(&mut self, value: u16) {
        self.code.extend_from_slice(&value.to_be_bytes());
    }

    pub fn load_const(&mut self, constant: Constant) -> Result<()> {
        let idx = self.constants.push(constant)?;
        self.op(OpCode::LoadConst);
        self.u16(idx);
        Ok(())
    }

    pub fn patch_jump_target(&mut self, pos: usize, target: usize) -> Result<()> {
        if pos + 1 >= self.code.len() {
            return Err(err(format!(
                "jump target patch position {pos} is out of bounds"
            )));
        }
        let target = u16::try_from(target)
            .map_err(|_| err(format!("jump target {target} exceeds u16 offset space")))?;
        let [hi, lo] = target.to_be_bytes();
        self.code[pos] = hi;
        self.code[pos + 1] = lo;
        Ok(())
    }

    pub fn make_list(&mut self, count: usize) -> Result<()> {
        let count = u16::try_from(count)
            .map_err(|_| err("bytecode list literal exceeds u16 element count"))?;
        self.op(OpCode::MakeList);
        self.u16(count);
        Ok(())
    }

    pub fn make_map(&mut self, count: usize) -> Result<()> {
        let count = u16::try_from(count)
            .map_err(|_| err("bytecode map literal exceeds u16 entry count"))?;
        self.op(OpCode::MakeMap);
        self.u16(count);
        Ok(())
    }

    fn compile_expr(&mut self, expr: &Expr, scope: &mut Scope) -> Result<()> {
        match expr {
            Expr::Int { int } => self.load_const(Constant::Int(*int)),
            Expr::Double { double } => self.load_const(Constant::Double(*double)),
            Expr::Bool { bool } => self.load_const(Constant::Bool(*bool)),
            Expr::String { string } => self.load_const(Constant::String(string.clone())),
            Expr::Null { null } if *null => self.load_const(Constant::Null),
            Expr::Null { .. } => Err(err("null literal must be true")),
            Expr::List { list } => {
                for item in list {
                    self.compile_expr(item, scope)?;
                }
                self.make_list(list.len())
            }
            Expr::Map { map } => {
                for entry in map {
                    self.compile_expr(&entry.key, scope)?;
                    self.compile_expr(&entry.value, scope)?;
                }
                self.make_map(map.len())
            }
            Expr::Arg { arg } => {
                let Some(index) = scope.args.get(arg) else {
                    return Err(err(format!("unknown parameter {arg}")));
                };
                self.op(OpCode::LoadArg);
                self.u8(*index);
                Ok(())
            }
            Expr::Local { local } => {
                let Some(index) = scope.locals.get(local) else {
                    return Err(err(format!("unknown local {local}")));
                };
                self.op(OpCode::LoadLocal);
                self.u8(*index);
                Ok(())
            }
            Expr::Let { let_, value, body } => {
                self.compile_expr(value, scope)?;
                let index = scope.push_local(let_)?;
                self.op(OpCode::StoreLocal);
                self.u8(index);
                self.compile_expr(body, scope)
            }
            Expr::Binary { op, left, right } => {
                self.compile_expr(left, scope)?;
                self.compile_expr(right, scope)?;
                let opcode = match op.as_str() {
                    "+" => OpCode::Add,
                    "-" => OpCode::Sub,
                    "*" => OpCode::Mul,
                    "/" => OpCode::Div,
                    ">" => OpCode::Greater,
                    "==" => OpCode::Equal,
                    _ => return Err(err(format!("unsupported bytecode binary operator {op}"))),
                };
                self.op(opcode);
                Ok(())
            }
            Expr::If { if_, then, else_ } => {
                self.compile_expr(if_, scope)?;
                self.op(OpCode::JumpIfFalse);
                let false_target_pos = self.code.len();
                self.u16(0);
                self.compile_expr(then, scope)?;
                self.op(OpCode::Jump);
                let end_target_pos = self.code.len();
                self.u16(0);
                let false_target = self.code.len();
                self.patch_jump_target(false_target_pos, false_target)?;
                self.compile_expr(else_, scope)?;
                let end_target = self.code.len();
                self.patch_jump_target(end_target_pos, end_target)?;
                Ok(())
            }
            Expr::While { while_, body, then } => {
                if !body.is_null_literal() {
                    return Err(err("restricted while body must currently evaluate to null"));
                }
                let loop_start = self.code.len();
                self.compile_expr(while_, scope)?;
                self.op(OpCode::JumpIfFalse);
                let exit_target_pos = self.code.len();
                self.u16(0);
                self.compile_expr(body, scope)?;
                self.op(OpCode::Jump);
                self.u16(
                    u16::try_from(loop_start)
                        .map_err(|_| err("loop start exceeds u16 offset space"))?,
                );
                let exit_target = self.code.len();
                self.patch_jump_target(exit_target_pos, exit_target)?;
                self.compile_expr(then, scope)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::compile_source_json;
    use crate::format::OpCode;

    #[test]
    fn compiles_if_else_function() {
        let module = compile_source_json(
            br#"{
              "functions": [{
                "name": "pricing.discount",
                "params": ["subtotal"],
                "body": {
                  "if": {"op": ">", "left": {"arg": "subtotal"}, "right": {"int": 100}},
                  "then": {"int": 90},
                  "else": {"int": 100}
                }
              }]
            }"#,
        )
        .expect("compile module");

        let function = &module.functions[0];
        assert!(function.code.contains(&(OpCode::JumpIfFalse as u8)));
        assert!(function.code.contains(&(OpCode::Return as u8)));
    }

    #[test]
    fn rejects_unsupported_operator() {
        let err = compile_source_json(
            br#"{
              "functions": [{
                "name": "bad",
                "params": ["x"],
                "body": {"op": "%", "left": {"arg": "x"}, "right": {"int": 2}}
              }]
            }"#,
        )
        .expect_err("unsupported operator should fail");

        assert!(err
            .to_string()
            .contains("unsupported bytecode binary operator"));
    }

    #[test]
    fn compiles_list_and_map_literals() {
        let module = compile_source_json(
            br#"{
              "functions": [
                {
                  "name": "values.list",
                  "params": [],
                  "body": {"list": [{"int": 1}, {"string": "two"}, {"bool": true}]}
                },
                {
                  "name": "values.map",
                  "params": [],
                  "body": {
                    "map": [
                      {"key": {"string": "count"}, "value": {"int": 2}},
                      {"key": {"string": "enabled"}, "value": {"bool": true}}
                    ]
                  }
                }
              ]
            }"#,
        )
        .expect("compile module");

        assert!(module.functions[0].code.contains(&(OpCode::MakeList as u8)));
        assert!(module.functions[1].code.contains(&(OpCode::MakeMap as u8)));
    }
}
