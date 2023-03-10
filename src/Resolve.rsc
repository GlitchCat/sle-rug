module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

// Usage occurrence, all locations where a identifier(variable) is used
// these include variables in computed questions, if statements and ifelse 
Use uses(AForm f) {
    Use total = {};

    // add all references, which includes those in condition expressions
    // Or those in the expression of computed questions
    for(/ ref(AId id) := f) {
        total += {<id.src, id.name>};
    }

    return total; 
}

// Defining occurrene, which are all identifiers (variables) declarations
// Either defined in a normal or computer question.
Def defs(AForm f) {
    Def total = {};

    // add all normal question type descendants
    for(/ question(_, AId id, _) := f) {
        total += {<id.name, id.src>};
    }

    // add all computed question type descendants
    for(/ computedQuestion(_, AId id, _, _) := f) {
        total += {<id.name, id.src>};
    }

    return total; 
}