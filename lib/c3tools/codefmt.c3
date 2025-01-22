module c3tools::codefmt;
import c3tools::codegen;
import c3tools::lexer;
import std::collections::list;


struct CodeFmt {
    int max_line_width;
    DString buf;
}

enum CodeFmtStatus @private{
    MODULE,
    TYPEDEF,
    FUNC,
    DOC,
    DOC_CONTR,
}

struct CodeFmtState @private {
    CodeFmtStatus state;
}


<*
@require max_line_width >= 80 : "too short"
@require max_line_width <= 120 : "too long"
*>
fn CodeFmt CodeFmt.new_init(int max_line_width=80) @operator(construct) {
    CodeFmt self = {
        .max_line_width = max_line_width
    };
    self.buf.new_init(); 
    return self;
}

fn void CodeFmt.free(&self) {
    self.buf.free();
}

fn String! CodeFmt.format(&self, String contents, bool print_lex = false) {
    self.buf.clear();

    Lexer lexer;
	lexer::init(&lexer, contents);
	while LOOP: (lexer.next_token()) {
	    if (print_lex) lexer.token.print();

		// if (!node_fn) {
		    // switch(self.lexer.token.type) {
      //           case MODULE:
      //       }
        // }
    }

    return "";
}

