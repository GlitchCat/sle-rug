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

//TODO: ?
// - deadlock
// - reachability (if statement always false)
// - dead code
// - non-determinism

// TODO: see QL.pdf under optional
// Type check conditions and variables: the expressions in conditions should be type
// correct and should ultimately be booleans. The assigned variables should be
// assigned consistently: each assignment should use the same type.

//TODO:
// - The type checker detects:
//    * reference to undefined questions
//    * duplicate question declarations with different types
//    * conditions that are not of the type boolean
//    * operands of invalid type to operators
//    * duplicate labels (warning)

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

    //TODO: collect all type information and add it to TEnv
    return tenv; 
}

// Starting point, checks a form and returns a set of all messages
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
    //TODO: set should give the location, as only then can type errors be unique
    set[Message] messages = {};

    // Check all the questions
    for(/ AQuestion q := f) {
        messages += check(q, tenv, useDef);
    }

    // Check all expressions, even recursively
    //TODO: could also do this within AQuestion?
    for(/ AExpr e := f) {
        messages += check(e, tenv, useDef);
    }

    //TODO: warn on unused AId?
    //TODO: warn on redefined? Or error?

    //TODO: Check if / else? Maybe do in Eval??


    return messages; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
    // Check questions here, against useDef and types etc
    set[Message] msgs = {};

    //TODO warn on duplicate labels
    //TODO: err on declared questions with the same name but different types.
    switch (q) {
        case question(str label, AId var, AType varType): 
            msgs += {};
        case computedQuestion(str label, AId var, AType varType, AExpr expr):
            msgs += checkType(expr, "computed question", typeOf(varType), tenv, useDef);
        case ifelse(AExpr cond, list[AQuestion] questions, list[AQuestion] elseQuestions):
            msgs += checkType(cond, "conditional statement `if-else`", tbool(), tenv, useDef);
        case \if(AExpr cond, list[AQuestion] questions):
            msgs += checkType(cond, "conditional statement `if`", tbool(), tenv, useDef);
    }

    return msgs; 
}




// TODO: basically type checks
// TODO: check if variable is even declared?
//TODO: Check operand compatibility with operators.
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
 
 

