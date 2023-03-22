module Check

import AST;
import Resolve;
import Message; // see standard library

//FIXME: DEBUG
import IO;

//TODO: message types of the Message std lib
// data Message = error(str msg, loc at)
            //  | warning(str msg, loc at)
            //  | info(str msg, loc at);
//TODO: also see https://www.rascal-mpl.org/docs/Library/util/IDEServices/#util-IDEServices-showMessage
// Either void logMessage(Message message) or void showMessage(Message message)

//TODO: ? Probs in Eval
// - deadlock
// - reachability (if statement always false)
// - dead code
// - non-determinism

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form
// It contains in : 
// - the location of the identifier.
// - the name of the identifier.
// - the label of the question.
// - the Type of the identifier
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
    TEnv tenv = {};

    // Add info for all the questions
    for(/ question(str label, AId var, AType varType) := f) {
        tenv += <var.src, var.name, label, typeOf(varType)>;
    }
    // Add info for all the computed questions
    for(/ computedQuestion(str label, AId var, AType varType, _) := f) {
        tenv += <var.src, var.name, label, typeOf(varType)>;
    }

    return tenv; 
}

// Starting point, checks a form and returns a set of all messages
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
    set[Message] messages = {};

    // Check all the questions
    for(/ AQuestion q := f) {
        messages += check(q, tenv, useDef);
    }

    // Check all expressions (so also AExpr parts of an expressions)
    for(/ AExpr e := f) {
        messages += check(e, tenv, useDef);
    }

    return messages; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
    // Check questions here, against useDef and types etc
    set[Message] msgs = {};

    //TODO: warn on unused AId?
    //TODO: Check if / else always false etc? Maybe do in Eval??

    switch (q) {
        case question(str label, AId var, AType varType): 
            msgs += checkQuestions(q, tenv, useDef);
        case computedQuestion(str label, AId var, AType varType, AExpr expr):
            msgs += checkType(expr, "computed question", typeOf(varType), tenv, useDef) + checkQuestions(q, tenv, useDef);
        case ifelse(AExpr cond, list[AQuestion] questions, list[AQuestion] elseQuestions):
            msgs += checkType(cond, "conditional statement `if-else`", tbool(), tenv, useDef);
        case \if(AExpr cond, list[AQuestion] questions):
            msgs += checkType(cond, "conditional statement `if`", tbool(), tenv, useDef);
    }

    return msgs; 
}

// Checks a (computed) question against other (computed) question(s):
// - error on duplicate question declarations with different types
// - warns on same question labels for different identifier
// - warns on different label for the same identifier
set[Message] checkQuestions(AQuestion q, TEnv tenv, UseDef useDef) {
    // does not work on conditionals, assumes we get a question
    assert(q is question || q is computedQuestion);

    set[Message] msgs = {};

    for(<loc def, str name, str label, Type \type> <- tenv) {
        if (q.var.src != def) { // Only check if not comparing the same question
            Type varType = typeOf(q.varType);
            if(q.var.name == name) { // same var
                if (varType != \type) { // diff type
                    msgs += {error("Mismatched types in duplicate identifier `<name>`: declared here as `<typeName(varType)>`, duplicate is `<typeName(\type)>`", q.varType.src)};
                }
                if (q.label != label) { // diff label
                    msgs += {warning("Duplicate identifier with different labels: labeled here as `<q.label>`, other label is `<label>`", q.var.src)};
            
                }
            } else if (q.label == label) { // Diff varname same label
                msgs += {warning("Duplicate label with different identifiers: identified here as `<q.var.name>`, other identifier is `<name>`", q.var.src)};
            
            }
        }
    }

    return msgs;
}


// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
    set[Message] msgs = {};
  
    //NOTE: useDef contains the locations of the identifier usage (in an expr) and its definition

    switch (e) {
        case ref(AId x):
            // identifier is used in an expression, but never declared
            msgs += { error("Use of undeclared identifier `<x.name>`", x.src) | useDef[x.src] == {} };
        case not(AExpr b):  msgs += checkType(b, "operation `not`", tbool(), tenv, useDef);
    }

    // Checks all integer expressions with two parameters
    if(/<opName:mul|div|add|sub>/(AExpr l, AExpr r) := e) {
        msgs += checkType(l, r, "operation `<opName>`", tint(), tenv, useDef);
    }
    // Check unary integer expressions
    if(/<opName:unaryPlus|unaryMin>/(AExpr unary) := e) {
        msgs += checkType(unary, "operation `<opName>`", tint(), tenv, useDef);
    }

    // Checks all boolean expressions with two parameters
    if(/<opName:gt|lt|geq|leq|equal|neq|and|or>/(AExpr unary) := e) {
        msgs += checkType(unary, "operation `<opName>`", tbool(), tenv, useDef);
    }
    

  return msgs; 
}


set[Message] checkType(AExpr lhs, AExpr rhs, str inWhat, Type expected, TEnv tenv, UseDef useDef) {
    return checkType(lhs, inWhat, expected, tenv, useDef) + checkType(rhs, inWhat, expected, tenv, useDef);
}

set[Message] checkType(AExpr e, str inWhat, Type expected, TEnv tenv, UseDef useDef) {

    Type exprType = typeOf(e, tenv, useDef);
    bool isUndefinedVar = e is ref && exprType == tunknown();
    // Check for mismatched types, except when are checking an undefined variable (is already checked)
    if(exprType != expected && !isUndefinedVar) {
        return { error("Mismatched types in <inWhat>: expected `<typeName(expected)>`, found `<typeName(exprType)>`", e.src) };
    }

    return {};
}

// convert a type to a string, e.g. its name
str typeName(Type t) {
    switch(t) {
        case tint(): return "integer";
        case tbool(): return "boolean";
        case tstr(): return "string";
    }
    // Unknown type, capitalised to give attention to this as it would be highly irregular
    return "UNKNOWN";
}

// Converts an AType to its related Type
Type typeOf(AType t) {
    switch(t) {
        case typeBool(): return tbool();
        case typeInt(): return tint();
        case typeStr(): return tstr();
        default: return tunknown();
    }
}

// returns the expected resulting type of the expression, so what the expression SHOULD return.
// It does NOT recursively check the sub-expression(s) for parameter type compatibility with this expression. 
// The type is tunknown() when it is not matched, or when a ref is not declared.
Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
        //TODO: improve? Only returns type if it is defined I believe?
        //TODO: CHECK WHAT THIS DOES EXACTLY AND NOTE IT DOWN
        //TODO: Have to check if it returns unknown, then print "Reference not defined" or something.
        if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
            return t;
        }

    // Literals
    case litBool(_):   return tbool();
    case litInt(_):    return tint();
    case litString(_): return tstr();
    // Integer return type expressions
    case unaryPlus(_): return tint();
    case unaryMin(_):  return tint();
    case mul(_, _):    return tint();
    case div(_, _):    return tint();
    case add(_, _):    return tint();
    case sub(_, _):    return tint();
    // Boolean return type expressions
    case not(_):       return tbool();
    case gt(_, _):     return tbool();
    case lt(_, _):     return tbool();
    case geq(_, _):    return tbool();
    case leq(_, _):    return tbool();
    case equal(_, _):  return tbool();
    case neq(_, _):    return tbool();
    case and(_, _):    return tbool();
    case or(_, _):     return tbool();
  }
  //TODO: should we rely on tunknown to give us a type mismatch?? Look at examples
  //FIXME: I THINK WE SHOULD CHECK THE ACTUAL TYPES USING A FOR LOOP AGAINST THE EXPECTED TYPE
  // Here we should check 
  return tunknown();
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

