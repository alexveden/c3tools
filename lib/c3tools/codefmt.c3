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
    List(<Token>) token_cache;
    int _indent_level;
    bool _print_lex;
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
    self.token_cache.new_init();
    return self;
}

fn void CodeFmt.free(&self) {
    self.buf.free();
    self.state_stack.free();
    self.token_cache.free();
}

fn String! CodeFmt.format(&self, String contents, bool print_lex = false) {
    self._print_lex = print_lex;
    self.buf.clear();
    self.state_stack.clear();

    Lexer lexer;
	lexer::init(&lexer, contents);
	while LOOP: (lexer.next_token()) {
	    if (print_lex) lexer.token.print(new_line: true);

	    if (lexer.token.type == EOF) {
	        if (self.state_stack.len() != 0) {
	            self.@fail(&lexer.token, "Not all code structures resolved, or bad file format")!;
	        }
	        self.newline();
	        break LOOP;
	    }

		if (self.state_stack.len() == 0) {
		    switch(lexer.token.type) {
                case FN:
                    self.enter_state(&CodeFmt.format_fn, &lexer.token)!;
                case EMPTY_LINE:
                    break;
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

macro CodeFmt.trace(&self, $msg, args...) {
    if (!self._print_lex) return;

    io::eprintf("\t\t%s (%s:%d): ", $$FUNC, $$FILE, $$LINE);
    io::eprintfn($msg, ...args);
}

macro void CodeFmt.write(&self, String format, args...) {
    self.buf.appendf(format, ...args);
}

macro void CodeFmt.newline(&self) {
    self.buf.append("\n");
    for(int i = 0; i < self._indent_level; i++) {
        // TODO: add tabs too
        self.buf.append(" ");
        self.buf.append(" ");
        self.buf.append(" ");
        self.buf.append(" ");
    }
}

macro void CodeFmt.dump_token_cache(&self) {
    self.trace("dump_token_cache");
    foreach(t: self.token_cache) {
        self.write(t.value);
    }
    self.token_cache.clear();
}

macro void CodeFmt.indent(&self) {
    self._indent_level++;
}

macro void CodeFmt.dedent(&self) {
    assert(self._indent_level > 0);
    self._indent_level--;
}

def CodeFmtFn = fn bool! (CodeFmt* self, Token* t, NodeParserState* state);


struct CodeFmtState {
    CodeFmtFn state_fn;
    NodeParserState state;
}

fn bool! CodeFmt.format_statement(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            self.trace("ENTRY");
            self.newline();
            self.write("%s", lexer::token_type_to_string(t.type));
            state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case EOS:
                    return true;
                default:
                    self.write(" %s", t.value);
            }
        default:
            unreachable();
    }

    return false;
}
fn bool! CodeFmt.format_fn_scope(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LBRACE);
            self.trace("ENTRY");
            self.newline();
            self.write("{");
            self.indent();
            state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case RETURN:
                    return self.enter_state(&CodeFmt.format_statement, t);
                case EOS:
                    self.write(";");
                case RBRACE:
                    if (state.scope_depth == 0) {
                        self.dedent();
                        self.newline();
                        self.write("}");
                        return true;
                    }
                default:
                    self.@fail(t, "unexpected token")!;
            }
        default:
            self.trace("format_fn_args default");
            
    }
    return false;
}
fn bool! CodeFmt.format_fn_args(CodeFmt* self, Token* t, NodeParserState* state) {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LPAREN);
            assert(self.token_cache.len() == 0, "forgot dump_token_cache?");
            self.trace("ENTRY");
            nextcase STATE: state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case RPAREN:
                    self.token_cache.push(*t);

                    self.dump_token_cache();
                    return true;
                case IDENT:
                    if (state.scope_depth == 1) {
                        self.token_cache.push(Token{.type = SPACE, .value = " "});
                    }
                    nextcase default;
                default:
                    self.token_cache.push(*t);
                    break;
            }
        default:
            self.trace("format_fn_args default");
            
    }

    return false;
}


fn bool! CodeFmt.format_fn(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == FN);
            self.trace("ENTRY");
            self.write("fn");
            state.transition(RETURN);
        case RETURN:
            self.trace("RETURN");
            switch(t.type) {
                case AT_IDENT:
                case IDENT:
                    if (state.scope_depth == 0 && state.last_token != DOT) self.write(" ");
                    nextcase default;
                case TYPE_IDENT:
                    if (state.scope_depth == 0) self.write(" ");
                    nextcase default;
                case LPAREN:
                    nextcase STATE: state.transition(VAR);
                default:
                    self.write("%s", t.value);
            }
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case LPAREN:
                    state.transition(VAR);
                    return self.enter_state(&CodeFmt.format_fn_args, t);
                case AT_IDENT:
                    nextcase STATE: state.transition(AT_IDENT);
                case LBRACE:
                    state.transition(SCOPE);
                    return self.enter_state(&CodeFmt.format_fn_scope, t);
                default:
                    break;
            }
        case AT_IDENT: // regular function attributes
            self.trace("AT_IDENT");
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
            self.trace("SCOPE");
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
            self.newline();
            return true;
        default:
            unreachable();
    }
    return false;
}
