module CST2AST

import Syntax;
import AST;
import Boolean;
import String;

import ParseTree;

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
  return form("<f.name>", [cst2ast(question) | Question question <- f.questions], src=f.src); 
}

default AQuestion cst2ast(Question q) {
    switch (q) {
        case (Question)`<Str s> <Id var> : <Type t>`:
            return question("<s>", cst2ast(var), cst2ast(t), src=q.src);
        case (Question)`<Str label> <Id var> : <Type t> = <Expr e>`:
            return computedQuestion("<label>", cst2ast(var), cst2ast(t), cst2ast(e), src=q.src);
        case (Question)`if (<Expr e>) {<Question* ifQs>} else {<Question* elseQs>}`:
            return ifelse(cst2ast(e), [cst2ast(q) | Question q <- ifQs], [cst2ast(q) | Question q <- elseQs], src=q.src);
        case (Question)`if (<Expr e>) {<Question* questions>}`:
            return \if(cst2ast(e), [cst2ast(q) | Question q <- questions], src=q.src);
        default: throw "Unhandled question: <q>";
    }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: 
        return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`<Bool b>`: 
        return litBool(fromString("<b>"), src=b.src);
    case (Expr)`<Int i>`: 
        return litInt(toInt("<i>"), src=i.src);
    case (Expr)`<Str s>`: 
        return litString("<s>", src=s.src);
    case (Expr)`( <Expr e> )`: 
        return cst2ast(e);
    case (Expr)`+ <Expr e>`: 
        return unaryPlus(cst2ast(e));
    case (Expr)`- <Expr e>`: 
        return unaryMin(cst2ast(e));
    case (Expr)`! <Expr e>`: 
        return not(cst2ast(e));
    case (Expr)`<Expr lhs> * <Expr rhs>`: 
        return mul(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> / <Expr rhs>`: 
        return div(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> + <Expr rhs>`: 
        return add(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> - <Expr rhs>`: 
        return sub(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \> <Expr rhs>`: 
        return gt(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \< <Expr rhs>`: 
        return lt(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: 
        return geq(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: 
        return leq(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> == <Expr rhs>`: 
        return eq(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> != <Expr rhs>`: 
        return neq(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> && <Expr rhs>`: 
        return and(cst2ast(lhs), cst2ast(rhs));
    case (Expr)`<Expr lhs> || <Expr rhs>`: 
        return or(cst2ast(lhs), cst2ast(rhs));
    
    default: throw "Unhandled expression: <e>";
  }
}


AId cst2ast(Id var) {
    return id("<var>", src=var.src);
}

default AType cst2ast(Type t) {
  switch (t) {
    case (Type)`boolean`: 
        return typeBool(src=t.src);
    case (Type)`integer`: 
        return typeInt(src=t.src);
    case (Type)`string`: 
        return typeStr(src=t.src);

    default: throw "Unhandled type: <t>";
  }
}