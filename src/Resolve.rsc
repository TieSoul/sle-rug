module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

Use uses(AForm f) {
  Use us = {};
  for (/AExpr expr := f) { // usages are only in expressions
  	if (expr has name) { // if expr has name, it is ref(str name)
  		us += {<expr.src, expr.name>};
  	}
  }
  return us;
}

Def defs(AForm f) {
  Def ds = {};
  for (/AQuestion qst := f) { // Definitions are in questions
  	if (qst has name) { // only questions; not if, ifElse, blocks
  		ds += {<qst.name, qst.src>};
  	}
  }
  return ds; 
}