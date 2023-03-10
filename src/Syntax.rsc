module Syntax

extend lang::std::Layout;
extend lang::std::Id;
extend lang::std::ASCII;

/* CODE FOR TESTING SYNTAX
import ParseTree;
pt = parse(#start[Form], |project://sle-rug/examples/empty.myql|);

import vis::Text;
import IO;
println(prettyTree(pt));
*/

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
// TODO: single quotes maybe? For if and else statement keywords so they are not case-sensitive
// TODO: decide between using or not using Labelled syntaxes 
// TODO: maybe replace Expr in if/else with 'Cond' or something, with only booleans?
syntax Question
    = question: Str label Id var ":" Type // Normal question
    | computedQuestion: Str label Id var ":" Type "=" Expr //TODO: Implement Expr in such a way that it results in an actual value
    | ifelse: "if" "(" Expr cond ")" "{" Question* questions "}" "else" "{" Question* elseQuestions "}"
    | \if: "if" "(" Expr cond ")" "{" Question* questions "}"
    ;



// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
// Precedence C: https://en.cppreference.com/w/c/language/operator_precedence
// Precedence Java: https://introcs.cs.princeton.edu/java/11precedence/
// TODO: Maybe rename gt to greater etc. Longer names?
syntax Expr 
    = Id \ Reserved // true/false are reserved keywords.
    | Literal
    | bracket "(" Expr ")"
    > right (
          right unaryPlus: "+" Expr 
        | right unaryMin: "-" Expr
        | right not: "!" Expr
    ) 
    > left (
          left mul: Expr "*" Expr 
        | left div: Expr "/" Expr
    ) 
    > left (
          left add: Expr "+" Expr 
        | left sub: Expr "-" Expr
    )
    > left (
          left gt: Expr lhs "\>" Expr rhs
        | left lt: Expr lhs "\<" Expr rhs
        | left geq: Expr lhs "\>=" Expr rhs
        | left leq: Expr lhs "\<=" Expr rhs
    )
    > left (
          left eq: Expr "==" Expr 
        | left neq: Expr "!=" Expr
    )
    > left \and: Expr lhs "&&" Expr rhs
    > left \or: Expr lhs "||" Expr rhs
    ;

//TODO: maybe add if and else (or then??) etc? CHECK ONLINE
// Maybe if, else and type var names are allowed!!!
// At least, syntax is correct. Just give a warning!!
//TODO: maybe add type?
//FIXME: debug Expr using potential keywords, if ambiguity error then add to the reserved list.
// println(prettyTree(parse(#Expr, "true")));
keyword Reserved = "true" | "false";
// | "if" | "else" | Type


// syntax Value = 

syntax Type
    = \bool: "boolean"
    | \int: "integer"
    | \str: "string" //TODO: check if correct type name?
    ;


//TODO: Except for assignment, Expr operations are not possible?
// Maybe rename bool etc to BoolLiteral | IntLiteral
syntax Literal = Bool | Int | Str;

// String, between two " characters
syntax Str = "\"" ![\"]* "\"";

// Comment, any characters accepted until there is a newline at the end
lexical Comment = "//" ![\n]* $;

lexical Int = Digit+;

// lexical Bool = t: "true";

//TODO: maybe turn into keyword, to add to Reserved
lexical Bool
    = \false: "false" 
    | \true: "true" 
    ;



