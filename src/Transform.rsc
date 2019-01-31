module Transform

import Syntax;
import Resolve;
import AST;
import List;
import Set;
import ParseTree;
import IO;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
	list[AQuestion] l = [];
	for (AQuestion q <- f.questions) {
		l += flatten(q, []);
	}
	return form(f.name, l);
}

list[AQuestion] flatten(AQuestion q, list[AExpr] conditions) {
	if (q has name) {
		return [ifThen(\join(conditions), [q])];
	}
	if (q has questions) {
		list[AQuestion] l = [];
		for (AQuestion q1 <- q.questions) {
			l += flatten(q1, conditions);
		}
		return l;
	}
	if (q has ifQuestions) {
		list[AQuestion] l = [];
		for (AQuestion q1 <- q.ifQuestions) {
			l += flatten(q1, conditions + [q.condition]);
		}
		if (q has elseQuestions) {
			for (AQuestion q1 <- q.elseQuestions) {
				l += flatten(q1, conditions + [not(q.condition)]);
			}
		}
		return l;
	}
}

AExpr \join(list[AExpr] conditions) {
	if (size(conditions) == 0) {
		return boolean(true);
	}
	AExpr e = head(conditions);
	conditions = tail(conditions);
	while (size(conditions) > 0) {
		e = and(e, head(conditions));
		conditions = tail(conditions);
	} 
	return e;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
	set[loc] occs = {useOrDef};
	if (isEmpty(useDef[useOrDef])) {
		// useOrDef is a defining occurrence
		set[loc] uses = { use | <use, useOrDef> <- useDef };
		occs += uses;
		occs += { def | <use, def> <- useDef, use in uses };
	} else {
		// useOrDef is a use
		set[loc] defs = useDef[useOrDef];
		occs += defs;
		occs += { use | <use, def> <- useDef, def in defs };
	}
	Ident newId;
	
	// let's check that newName is a valid identifier:
	try {
		newId = parse(#Ident, newName);
	} catch _: {
		throw "Identifier <newName> is not valid!";
	}
	
	// let's check that newName does not already exist:
	for (/Ident id := f) {
		if (id == newId) throw "Identifier <newId> already exists!";
	}
	
	return visit (f) {
		case Ident id => newId when !isEmpty([occ | occ <- occs, id@\loc <= occ]) // when the id is *contained* in the occurrence.
																				  // This is to catch idents occurring in defining questions.
	};
} 
 
 
 

