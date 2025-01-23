module c3tools::codefmt;
import c3tools::codegen;
import c3tools::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;


struct CodeFmt {
    int max_line_width;
    DString buf;
    List(<CodeFmtState>) state_stack;
    int indent;
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
    self.state_stack.new_init();
    return self;
}

fn void CodeFmt.free(&self) {
    self.buf.free();
    self.state_stack.free();
}

fn String! CodeFmt.format(&self, String contents, bool print_lex = false) {
    self.buf.clear();
    self.state_stack.clear();

    Lexer lexer;
	lexer::init(&lexer, contents);
	while LOOP: (lexer.next_token()) {
	    if (print_lex) lexer.token.print();

	    if (lexer.token.type == EOF) {
	        if (self.state_stack.len() != 0) {
	            self.@fail(&lexer.token, "Not all code structures resolved, or bad file format")!;
	        }
	        break LOOP;
	    }

		if (self.state_stack.len() == 0) {
		    switch(lexer.token.type) {
                case FN:
                    self.enter_state(&CodeFmt.format_fn, &lexer.token)!;
                default: 
	                self.@fail(&lexer.token, "Unexpected global token type")!;
            } 
            continue LOOP;
        } 

        while (
            self.state_stack.len() > 0 
            && self.state_stack[^1].state_fn(self, &lexer.token, &self.state_stack[^1].state)!
        ) {
            self.state_stack.remove_last();
        }
    }

    return self.buf.str_view();
}

fn bool! CodeFmt.enter_state(&self, CodeFmtFn new_state, Token* t) {
    CodeFmtState state = {.state_fn = new_state };
    self.state_stack.push(state);
    return self.state_stack[^1].state_fn(self, t, &self.state_stack[^1].state)!;
}

macro bool! CodeFmt.@fail(&self, Token* t, String msg) {
    io::eprintfn(
        "Error (%s:%d) at [Token: %s] line:col %d:%d - %s", 
        $$FILE, $$LINE, t.type, t.row, t.col, msg
    );
    return IoError.GENERAL_ERROR?;
}

macro void CodeFmt.write(&self, String format, args...) {
    self.buf.appendf(format, ...args);
}

def CodeFmtFn = fn bool! (CodeFmt* self, Token* t, NodeParserState* state);


struct CodeFmtState {
    CodeFmtFn state_fn;
    NodeParserState state;
}

fn bool! CodeFmt.format_fn_scope(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LBRACE);
            io::printfn("format_fn_scope entry");
            self.write("\n{");
            state.transition(SCOPE);
        case SCOPE:
            io::printfn("format_fn_args SCOPE");
            switch(t.type) {
                case RBRACE:
                    if (state.scope_depth == 0) {
                         self.write("\n}\n");
                         return true;
                    }
                default:
                    break;
            }
        default:
            io::printfn("format_fn_args default");
            
    }
    return false;
}
fn bool! CodeFmt.format_fn_args(CodeFmt* self, Token* t, NodeParserState* state) {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LPAREN);
            io::printfn("format_fn_args entry");
            self.write("(");
            state.transition(VAR);
        case VAR:
            io::printfn("format_fn_args VAR");
            switch(t.type) {
                case RPAREN:
                    self.write(")");
                    return true;
                default:
                    break;
            }
        default:
            io::printfn("format_fn_args default");
            
    }

    return false;
}


fn bool! CodeFmt.format_fn(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == FN);
            io::printfn("format_fn entry");
            self.write("fn ");
            state.transition(RETURN);
        case RETURN:
            io::printfn("format_fn RETURN");
            switch(t.type) {
                case AT_IDENT:
                    nextcase STATE: state.transition(IDENT);
                case DOT:
                    nextcase STATE: state.transition(IDENT);
                case IDENT:
                    if (state.scope_depth == 0) nextcase STATE: state.transition(IDENT);
                case TYPE_IDENT:
                    // function name, make a transition if no scope and ret_type is set
                    self.write("%s ", t.value);
                    state.transition(IDENT);
                default:
                    break;
            }
        case IDENT:
            io::printfn("format_fn INDENT");
            // function name 
            switch(t.type) {
                case AT_IDENT:
                case IDENT:
                case TYPE_IDENT:
                    // struct based functions may contain TypeName.func_name
                    self.write("%s ", t.value);
                    break;
                case LPAREN:
                    state.transition(VAR);
                    return self.enter_state(&CodeFmt.format_fn_args, t);
                default:
                    break;
            }
        case VAR:
            io::printfn("format_fn VAR");
            switch(t.type) {
                case AT_IDENT:
                    nextcase STATE: state.transition(AT_IDENT);
                case LPAREN:
                    state.transition(VAR);
                    return self.enter_state(&CodeFmt.format_fn_args, t);
                case LBRACE:
                    state.transition(SCOPE);
                    return self.enter_state(&CodeFmt.format_fn_scope, t);
                default:
                    break;
            }
        case AT_IDENT: // regular function attributes
            io::printfn("format_fn AT_IDENT");
            switch(t.type) {
                case AT_IDENT:
                    break;
                case IMPLIES:           // => 
                    nextcase STATE: state.transition(IMPLIES);
                case LBRACE:           // {
                    if (state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case SCOPE: // regular function scope { ... }
            io::printfn("format_fn SCOPE");
            switch(t.type) {
                case LBRACE:           // {
                    if (state.scope_depth == 1) {
                        return self.enter_state(&CodeFmt.format_fn_scope, t);
                    }
                case RBRACE:           
                    if (state.scope_depth == 0) {
                        nextcase STATE: state.transition(EOF);
                    }
                default:
                    break;
            }
        // case IMPLIES:  // lambda function fn () => ... @attr;
        //     switch(t.type) {
        //         case IMPLIES:           // => 
        //             node_func.iscope_start = t.offset;
        //         case EOS:           // ending semicolon
        //             if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
        //         default:
        //             break;
        //     }
        case EOF:
            return true;
        default:
            unreachable();
    }
    return false;
}
