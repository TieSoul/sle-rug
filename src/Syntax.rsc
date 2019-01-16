module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Ident QuestionBlock; 
  
syntax QuestionBlock
  = "{" Question* "}";

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Ident ":" Type          // Question
  | Str Ident ":" Type "=" Expr // Computed question
  | "if" "(" Expr ")" QuestionBlock "else" QuestionBlock // if-then-else
  | "if" "(" Expr ")" QuestionBlock // if-then
  | QuestionBlock // block
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Ident
  | Literal
  | "(" Expr ")"
  | "!" Expr
  > left ( Expr "*" Expr
  		 | Expr "/" Expr )
  > left ( Expr "+" Expr
  		 | Expr "-" Expr )
  > left ( Expr "\<" Expr
  		 | Expr "\<=" Expr
  		 | Expr "\>" Expr
  		 | Expr "\>=" Expr )
  > left ( Expr "==" Expr
  		 | Expr "!=" Expr )
  > left   Expr "&&" Expr 
  > left   Expr "||" Expr;
  
lexical Ident = Id \ "true" \ "false";

syntax Type
  = "boolean"
  | "string"
  | "integer";

  
syntax Literal = Bool | Str | Int;
  
lexical Str = "\"" ( ![\"] | "\\\"" )* "\""; // double quotes need to be escaped.

lexical Int 
  = [\-]? [1-9][0-9]*
  | [\-]? [0];

lexical Bool = "true" | "false";



