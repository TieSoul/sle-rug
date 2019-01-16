module Eval

import AST;
import Check;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
	TEnv t = collect(f);
	VEnv env = ();
	for (v <- t) {
		switch (v.\type) {
			case tint(): env[v.name] = vint(0);
			case tbool(): env[v.name] = vbool(false);
			case tstr(): env[v.name] = vstr("");
		}
	}
	return env;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  VEnv result = venv;
  for (q <- f.questions) {
  	result += eval(q, inp, venv);
  }; 
  return result;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  VEnv result = ();
  if (q has condition) { // conditional block
  	if (eval(q.condition, venv).b) {
  		for (qu <- q.ifQuestions) {
  			result += eval(qu, inp, venv);
  		}
  	} else if (q has elseQuestions) {
  		for (qu <- q.elseQuestions) {
  			result += eval(qu, inp, venv);
  		}
  	}
  }
  if (q has questions) { // non-conditional block
	for (qu <- q.questions) {
		result += eval(qu, inp, venv);
	}
  }
  if (q has computation) {
  	result[q.name] = eval(q.computation, venv);
  }
  else if (q has name && inp.question == q.name) {
  	result[q.name] = inp.\value;
  }
  return result;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case integer(int n): return vint(n);
    case string(str s): return vstr(s);
    case boolean(bool b): return vbool(b);
    
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case eq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv));
    case neq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    
    default: throw "Unsupported expression <e>";
  }
}