module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str text, str name, AType t)
  | computedQuestion(str text, str name, AType t, AExpr computation)
  | ifThen(AExpr condition, list[AQuestion] questions)
  | ifThenElse(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  | block(list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | integer(int n)
  | string(str s)
  | boolean(bool b)
  | not(AExpr expr)
  
  | mul(AExpr lhs, AExpr lhs)
  | div(AExpr lhs, AExpr lhs)
  | add(AExpr lhs, AExpr lhs)
  | sub(AExpr lhs, AExpr lhs)
  
  | leq(AExpr lhs, AExpr lhs)
  | lt(AExpr lhs, AExpr lhs)
  | geq(AExpr lhs, AExpr lhs)
  | gt(AExpr lhs, AExpr lhs)
  | eq(AExpr lhs, AExpr lhs)
  | neq(AExpr lhs, AExpr lhs)
  | and(AExpr lhs, AExpr lhs)
  | or(AExpr lhs, AExpr lhs)
  ;

data AType(loc src = |tmp:///|)
  = strType()
  | intType()
  | boolType();
