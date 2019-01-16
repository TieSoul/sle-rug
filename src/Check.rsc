module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv env = {};
  for (/AQuestion q := f) {
  	if (q has name) {
  		env += {<q.src, q.name, q.text, toType(q.t)>};
  	}
  }
  return env; 
}

Type toType(AType t) {
	switch (t) {
		case strType(): return tstr();
		case intType(): return tint();
		case boolType(): return tbool();
		default: throw "Unhandled type <t>";
	}
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	for (/AQuestion q := f) {
		msgs += check(q, tenv, useDef);
	}
	for (/AExpr e := f) {
		msgs += check(e, tenv, useDef);
	}
	return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	if (q has name) { // question or computedQuestion
		for (r <- tenv) {
			if (r.name == q.name && r.\type != toType(q.t)) {
				msgs += {error("Duplicate question: <q.name>", q.src)};
			}
			if (r.label == q.text && r.name != q.name) {
				msgs += {warning("Duplicate labels: <q.name> and <r.name>", q.src)};
			}
		}
	}
	if (q has computation) {
		if (typeOf(q.computation, tenv, useDef) != toType(q.t)) {
			msgs += {error("Computed question has mismatched type: <q.name>", q.src)};
		}
	}
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question: <x>", u) | useDef[u] == {} };
      
	case add(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for addition are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case sub(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for subtraction are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case mul(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for multiplication are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																			|| typeOf(lhs, tenv, useDef) != tint()};
	case div(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for division are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case leq(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case lt(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case geq(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case gt(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																		|| typeOf(lhs, tenv, useDef) != tint()};
	case eq(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)};
	case neq(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for comparison are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)};
	case and(AExpr lhs, AExpr rhs, src = loc u):
	
		msgs += { error("Arguments for and are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																|| typeOf(lhs, tenv, useDef) != tbool()};
	case or(AExpr lhs, AExpr rhs, src = loc u):
		msgs += { error("Arguments for or are wrongly typed", u) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) 
																|| typeOf(lhs, tenv, useDef) != tbool()};
    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case integer(int _): return tint();
    case string(str _): return tstr();
    case boolean(bool _): return tbool();
    
    case add(AExpr _, AExpr _): return tint();
    case sub(AExpr _, AExpr _): return tint();
    case mul(AExpr _, AExpr _): return tint();
    case div(AExpr _, AExpr _): return tint();
    
    case lt(AExpr _, AExpr _): return tbool();
    case leq(AExpr _, AExpr _): return tbool();
    case gt(AExpr _, AExpr _): return tbool();
    case geq(AExpr _, AExpr _): return tbool();
    case eq(AExpr _, AExpr _): return tbool();
    case neq(AExpr _, AExpr _): return tbool();
    
    case and(AExpr _, AExpr _): return tbool();
    case or(AExpr _, AExpr _): return tbool();
    
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

