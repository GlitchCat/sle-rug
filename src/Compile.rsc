module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}


// Generates the layout/structure for the form and its questions
HTMLElement form2html(AForm f) {
    return html([
        head([
            meta(charset="utf-8"),
            meta(name="viewport", content="width=device-width, initial-scale=1"),
            title([text(f.name)]),
            link(\rel="stylesheet", \type="text/css", href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha2/dist/css/bootstrap.min.css")
        ]),
        body([
            div([
                header([h1([text(f.name)], class="text-body-emphasis")], class="d-flex align-items-center pb-3 mb-5 border-bottom"),
                main([
                    form(questions2html(f.questions), class="was-validated")
                ])
            ], class="col-lg-8 mx-auto p-4 py-md-5"),
            script([], src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha2/dist/js/bootstrap.bundle.min.js"),
            script([], src = "./" + f.src[extension="js"].file)
        ])
    ],
    lang="en");
}

// Generate a grouped form from a list of questions
list [HTMLElement] questions2html(list[AQuestion] questions) {
    list [HTMLElement] elements = [];
    for(q <- questions) {
        elements += question2html(q);
    }
    return elements;
}

//TODO: this works, maybe useful
// input(id=(true ? "trueVal" : "falseVal"));

HTMLElement question2html(question(str qtext, AId var, AType t)) {
    switch(t) {
        case typeBool(): return boolHTML(var, qtext, false);
        case typeInt(): return intHTML(var, qtext, false);
        case typeStr(): return strHTML(var, qtext, false);
        default: throw "Unhandled type: <t>";
    }
}

HTMLElement question2html(computedQuestion(str qtext, AId var, AType t, AExpr expr)) {
    switch(t) {
        case typeBool(): return boolHTML(var, qtext, true);
        case typeInt(): return intHTML(var, qtext, true);
        case typeStr(): return strHTML(var, qtext, true);
        default: throw "Unhandled type: <t>";
    }
}

//TODO: actually implement, hiding and computation etc
HTMLElement question2html(\if(AExpr cond, list[AQuestion] questions)) {
    return div([
        h1([text("IF")]),
        hr(class="border-2 border-top border-secondary"),
        div(questions2html(questions))
    ]);
}

//TODO: actually implement, hiding and computation etc
HTMLElement question2html(ifelse(AExpr cond, list[AQuestion] questions, list[AQuestion] elseQuestions)) {
    return div([
        h1([text("IF")]),
        hr(class="border-2 border-top border-secondary"),
        div(questions2html(questions)),
        h1([text("ELSE")]),
        hr(class="border-2 border-top border-secondary"),
        div(questions2html(elseQuestions))
    ]);
}

// Boolean input / computed question
HTMLElement boolHTML(AId var, str qtext, bool isComputed) {
    //TODO: id? Varname is not unique, so maybe use something else?
    HTMLElement inputCheckbox = input(\type="checkbox", class="form-check-input", id="TODO");

    if (isComputed) {
        inputCheckbox.readonly = "";
        inputCheckbox.disabled = "";
    }

    list[HTMLElement] checkbox = [
        br(),
        inputCheckbox,
        label([text("Yes")], class="form-check-label", \for="TODO")
    ];
    return labeledQuestionDivHTML(checkbox, qtext);
}

// Integer input / computed question
HTMLElement intHTML(AId var, str qtext, bool isComputed) {
    //TODO: id? Varname is not unique, so maybe use something else?
    //FIXME: no inputmode pattern, but not needed necessarily
    HTMLElement inputNumber = input(\type="number", pattern="[0-9]*", class="form-control", id="TODO", placeholder="0");

    //TODO: maybe set? inputNumber.\value = "0";
    if (isComputed) inputNumber.readonly = "";
    else inputNumber.required = "";

    return labeledQuestionDivHTML([inputNumber], qtext);
}

// String input / computed question
HTMLElement strHTML(AId var, str qtext, bool isComputed) {
    //TODO: id? Varname is not unique, so maybe use something else?
    HTMLElement inputText = input(\type="text", class="form-control", id="TODO", placeholder="text input");

    if (isComputed) inputText.readonly = "";
    else inputText.required = "";

    return labeledQuestionDivHTML([inputText], qtext);
}

//TODO: \for tag?
HTMLElement labeledQuestionDivHTML(list [HTMLElement] field, str fieldText) {
    return div(
        [label([text(fieldText[1..-1])], class="form-label")] + field, // Fixed backticks with string slicing
        class="mb-3"
    );
}

// Generates Javascript code from QL that handles variables, math and conditions
str form2js(AForm f) {
    //TODO: actually implement, hiding and computation etc
    return checkboxjs() + "";
}

// Sets not-computed question checkboxes to indeterminate initialle
str checkboxjs() {
    return  "document.querySelectorAll(\'.form-check-input[type=\"checkbox\"]:not([readonly])\')
            '   .forEach(checkbox =\> {
            '       checkbox.setCustomValidity(\"Either check or uncheck it\");
            '       checkbox.indeterminate = true;
            '       checkbox.style.backgroundColor = \"var(--bs-form-invalid-color)\";
            '       checkbox.addEventListener(\"change\", (event) =\> {
            '           checkbox.setCustomValidity(\"\");
            '           checkbox.style.backgroundColor = \'\';
            '    });
            '})";
}
