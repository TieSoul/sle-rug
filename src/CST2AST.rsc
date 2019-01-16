module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  switch (f) {
  	case (Form)`form <Ident n> <QuestionBlock qs>`: return form("<n>", cst2ast(qs), src=f@\loc);
  	default: throw "Unhandled form: <f>";
  }
}

list[AQuestion] cst2ast(QuestionBlock qs) {
	return [cst2ast(q) | /Question q := qs];
}

AQuestion cst2ast(Question q) {
  switch (q) {
  	case (Question)`<Str s> <Ident n> : <Type t>`: return question("<s>", "<n>", cst2ast(t), src=q@\loc);
  	case (Question)`<Str s> <Ident n> : <Type t> = <Expr e>`: return computedQuestion("<s>", "<n>", cst2ast(t), cst2ast(e), src=q@\loc);
  	case (Question)`if ( <Expr c> ) <QuestionBlock qs>`: return ifThen(cst2ast(c), cst2ast(qs), src=q@\loc);
  	case (Question)`if ( <Expr c> ) <QuestionBlock iqs> else <QuestionBlock eqs>`: return ifThenElse(cst2ast(c), cst2ast(iqs), cst2ast(eqs), src=q@\loc);
  	case (Question)`<QuestionBlock qs>`: return block(cst2ast(qs), src=q@\loc);
  	default: ;
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Ident x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Literal l>`: return cst2ast(l);
    case (Expr)`( <Expr e2> )`: return cst2ast(e2);
    case (Expr)`! <Expr e2>`: return not(cst2ast(e2), src=e@\loc);
	case (Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> + <Expr rhs>`: return add(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> \> <Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> \< <Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
	case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

AExpr cst2ast(Literal l) {
	switch (l) {
		case (Literal)`<Str s>`: return string("<s>", src=s@\loc);
		case (Literal)`<Int i>`: return integer(toInt("<i>"), src=i@\loc);
		case (Literal)`<Bool b>`: return boolean(strToBool("<b>"), src=b@\loc);
		
		default: throw "Unhandled literal: <l>";
	}
}

bool strToBool(str s) {
	switch (s) {
		case "true": return true;
		case "false": return false;
		default: throw "Illegal boolean value <s>";
	}
}

AType cst2ast(Type t) {
	switch (t) {
		case (Type)`integer`: return intType();
		case (Type)`string`: return strType();
		case (Type)`boolean`: return boolType();
		default: throw "Unhandled type: <t>";
	}
}
