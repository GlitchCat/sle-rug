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
    = question(str label, AId var, AType varType)
    | computedQuestion(str label, AId var, AType varType, AExpr expr)
    | ifelse(AExpr cond, list[AQuestion] questions, list[AQuestion] elseQuestions)
    | \if(AExpr cond, list[AQuestion] questions)
    ;

//TODO: maybe same name for str, int & bool names of values?
// What about just the name literal?
data AExpr(loc src = |tmp:///|)
    = ref(AId id)
    | litBool(bool boolean) // We only have 3 literals, so no need to add an extra ADT
    | litInt(int integer)
    | litString(str string)
    | unaryPlus(AExpr expr) // Unary data types, to not store an irrelevant lhs
    | unaryMin(AExpr expr)
    | not(AExpr expr) //TODO: how to handle unary expressions?
    | mul(AExpr lhs, AExpr rhs)
    | div(AExpr lhs, AExpr rhs)
    | add(AExpr lhs, AExpr rhs)
    | sub(AExpr lhs, AExpr rhs)
    | gt(AExpr lhs, AExpr rhs)
    | lt(AExpr lhs, AExpr rhs)
    | geq(AExpr lhs, AExpr rhs)
    | leq(AExpr lhs, AExpr rhs)
    | eq(AExpr lhs, AExpr rhs)
    | neq(AExpr lhs, AExpr rhs)
    | and(AExpr lhs, AExpr rhs)
    | or(AExpr lhs, AExpr rhs)
    ;

data AId(loc src = |tmp:///|)
    = id(str name);

// emtry data types that specify what type a variable/data is, from Pico example code
data AType(loc src = |tmp:///|)
    = typeBool()
    | typeInt()
    | typeStr() //TODO: add unknow type?
    ;