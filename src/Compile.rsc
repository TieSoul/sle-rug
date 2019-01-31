module Compile

import AST;
import Resolve;
import Check;
import IO;
import Relation;
import List;
import Set;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
	jQuery = script(src("https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.3.1.min.js"));
	scr = script(src(f.src[extension="js"].file));
	list[HTML5Node] inputs = [];
	for (AQuestion q <- f.questions) {
		inputs += generateInputs(q);
	}
	return html(head(jQuery, scr), body(form(inputs)));
}

list[HTML5Node] generateInputs(AQuestion q) {
	if (q has name) {
		HTML5Node n;
		switch (q.t) {
			case strType(): n = input(\type("text"), name(q.name));
			case intType(): n = input(\type("number"), name(q.name));
			case boolType(): n = input(\type("checkbox"), name(q.name));
		}
		if (q has computation) {
			n.kids += [disabled("disabled")];
		}
		return [div(id(q.name), label(q.text, \for(q.name)), n, br())];
	}
	else if (q has ifQuestions) {
		list[HTML5Node] nodes = [];
		for (q1 <- q.ifQuestions) {
			nodes += generateInputs(q1);
		}
		if (q has elseQuestions) {
			for (q1 <- q.elseQuestions) {
				nodes += generateInputs(q1);
			}
		}
		return nodes;
	}
	else if (q has questions) {
		list[HTML5Node] nodes = [];
		for (q1 <- q.questions) {
			nodes += generateInputs(q1);
		}
		return nodes;
	}
}

str funcBody(AForm f) {
	TEnv t = collect(f);
	UseDef d = resolve(f);
	str result = "";
	rel[str name, AExpr condition] m = {};
	for (/AQuestion q := f) {
		if (q has computation) {
			result += computedQuestionToJS(q, t, d);
		}
		if (q has condition) {
			for (/AQuestion q1 := q.ifQuestions, q1 has name) {
				m += {<q1.name, q.condition>};
			}
			if (q has elseQuestions) {
				for (/AQuestion q1 := q.elseQuestions, q1 has name) {
					m += {<q1.name, not(q.condition)>};
				}
			}
		}
	}
	for (q <- domain(m)) {
		list[AExpr] conditions = toList(m[q]);
		AExpr condition = conditions[0];
		conditions = tail(conditions);
		while (size(conditions) > 0) {
			condition = and(condition, head(conditions));
			conditions = tail(conditions);
		}
		result += "if (<exprToJS(condition, t, d)>) { $(\'#<q>\').show(); } else { $(\'#<q>\').hide();}\n";
	}
	return result;
}

str initFunc(AForm f) {
	result = "";
	for (/AQuestion q := f) {
		if (q has name) {
			switch (q.t) {
				case intType(): result += "$(\'[name=<q.name>]\').val(0);\n";
				case strType(): result += "$(\'[name=<q.name>]\').val(\"\");\n";
				case boolType(): result += "$(\'[name=<q.name>]\').prop(\'checked\', false);\n";
			}
		}
	}
	return result;
}

str computedQuestionToJS(AQuestion q, TEnv t, UseDef d) {
	switch (typeOf(q.computation, t, d)) {
		case tint(): return "$(\'[name=<q.name>]\').val(<exprToJS(q.computation, t, d)>);\n";
		case tstr(): return "$(\'[name=<q.name>]\').val(<exprToJS(q.computation, t, d)>);\n";
		case tbool(): return "$(\'[name=<q.name>]\').prop(\'checked\', <exprToJS(q.computation, t, d)>);\n";
	}
}

str exprToJS(AExpr e, TEnv t, UseDef d) {
	switch (e) {
		case ref(str name): 
			switch (typeOf(e, t, d)) {
				case tint(): return "$(\'[name=<name>]\').val()";
				case tstr(): return "$(\'[name=<name>]\').val()";
				case tbool(): return "$(\'[name=<name>]\').is(\':checked\')";
			}
		case integer(int n): return "<n>";
		case string(str s): return "\"<s>\"";
		case boolean(bool b): 
			if (b) return "true"; else return false;
		case not(AExpr e): return "!(<exprToJS(e, t, d)>)";
		case add(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) + (<exprToJS(rhs, t, d)>)";
		case sub(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) - (<exprToJS(rhs, t, d)>)";
		case mul(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) * (<exprToJS(rhs, t, d)>)";
		case div(AExpr lhs, AExpr rhs): return "floor((<exprToJS(lhs, t, d)>) / (<exprToJS(rhs, t, d)>))";
		
		case leq(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) \<= (<exprToJS(rhs, t, d)>)";
		case lt(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) \< (<exprToJS(rhs, t, d)>)";
		case geq(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) \>= (<exprToJS(rhs, t, d)>)";
		case gt(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) \> (<exprToJS(rhs, t, d)>)";
		case eq(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) == (<exprToJS(rhs, t, d)>)";
		case neq(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) != (<exprToJS(rhs, t, d)>)";
		
		case and(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) && (<exprToJS(rhs, t, d)>)";
		case or(AExpr lhs, AExpr rhs): return "(<exprToJS(lhs, t, d)>) || (<exprToJS(rhs, t, d)>)";
	}
}

str form2js(AForm f) {
	result = "$(document).ready(function() {function func() { <funcBody(f)> }\n<initFunc(f)>func();\n";
	result += "$(\':input\').on(\'change\', function() { func() })\n})";
	return result;
}
