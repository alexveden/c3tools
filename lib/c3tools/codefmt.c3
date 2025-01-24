module c3tools::codefmt;
import c3tools::codegen;
import c3tools::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;


struct CodeFmt {
    usz max_line_width;
    DString buf;
    List(<CodeFmtState>) state_stack;
    List(<Token>) _token_cache;
    usz _indent_level;
    usz _line_used;
    bool _print_lex;
    Lexer _lexer;
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
    self._token_cache.new_init();
    return self;
}

fn void CodeFmt.free(&self) {
    self.buf.free();
    self.state_stack.free();
    self._token_cache.free();
}

fn String! CodeFmt.format(&self, String contents, bool print_lex = false) {
    self._print_lex = print_lex;
    self.buf.clear();
    self.state_stack.clear();

	lexer::init(&self._lexer, contents);

	while LOOP: (self._lexer.next_token()) {
	    if (print_lex) self._lexer.token.print(new_line: true);

	    if (self._lexer.token.type == EOF) {
	        if (self.state_stack.len() != 0) {
	            self.@fail(&self._lexer.token, "Not all code structures resolved, or bad file format")!;
	        }
	        self.newline();
	        break LOOP;
	    }

		if (self.state_stack.len() == 0) {
		    switch(self._lexer.token.type) {
                case FN:
                    self.enter_state(&CodeFmt.format_fn, &self._lexer.token)!;
                case EMPTY_LINE:
                    break;
                default: 
	                self.@fail(&self._lexer.token, "Unexpected global token type")!;
            } 
            continue LOOP;
        } 

        while (
            self.state_stack.len() > 0 
            && self.state_stack[^1].state_fn(self, &self._lexer.token, &self.state_stack[^1].state)!
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
        "Patially formatted code:\n```\n%s```", 
        self.buf.str_view()
    );
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
    usz len = self.buf.appendf(format, ...args)!!;
    self._line_used += (int)len;
}

macro void CodeFmt.newline(&self) {
    self.buf.append("\n");
    self._line_used = 0;
    for(int i = 0; i < self._indent_level; i++) {
        // TODO: add tabs too
        self.buf.append("    ");
        self._line_used += 4;
    }
}

macro void CodeFmt.statement_add(&self, Token t) {
    assert(t.type != EOS, "EOS should not be there");
    TokenType prev_t = self._token_cache.len() > 0 ? self._token_cache[^1].type : TokenType.INVALID_TOKEN; 
    bool pre_space = false;
    bool post_space = false;

    switch(t.type) {
		case DIV:
		case EQ:
		case GREATER:
		case LESS:
		case MINUS:
		case MOD:
		case PLUS:
		case STAR:
		case BIT_AND_ASSIGN:
		case BIT_OR_ASSIGN:
		case BIT_XOR_ASSIGN:
		case CT_AND:
		case CT_OR:
		case CT_CONCAT:
		case DIV_ASSIGN:
		case ELVIS:
		case EQEQ:
		case GREATER_EQ:
		case IMPLIES:
		case LESS_EQ:
		case MINUS_ASSIGN:
		case MULT_ASSIGN:
		case MOD_ASSIGN:
		case NOT_EQUAL:
		case PLUS_ASSIGN:
		case QUESTQUEST:
		case SHL:
		case SHR:
		case SHL_ASSIGN:
		case SHR_ASSIGN:
            post_space = true;
            pre_space = true;
        case COMMA:
        case RETURN:
            post_space = true;
        case IDENT:
            switch(prev_t){
                case TYPE_IDENT:
                    pre_space = true;
                default:
                    break;
            }
        default:
            break;
    }

    if (pre_space) self._token_cache.push(TOKEN_SPACE);
    self._token_cache.push(t);
    if (post_space) self._token_cache.push(TOKEN_SPACE);
}

macro void! CodeFmt.statement_dump(&self) {
    usz token_len = 0;
    usz break_len = 0;
    int break_pos = -1;
    bool is_assignment = false;
    bool has_magic_comma = false;
    TokenType last_non_space_tok = INVALID_TOKEN;
    NodeParserState tmpstate;

    foreach(i, t: self._token_cache) {
        tmpstate.check(&t);

        token_len += t.value.len;
        switch TOP: (t.type) {
		    case BIT_AND_ASSIGN:
		    case BIT_OR_ASSIGN:
		    case BIT_XOR_ASSIGN:
		    case DIV_ASSIGN:
		    case MINUS_ASSIGN:
		    case MULT_ASSIGN:
		    case MOD_ASSIGN:
		    case PLUS_ASSIGN:
		    case SHL_ASSIGN:
		    case SHR_ASSIGN:
		    case EQ:
		        // if it's an assignment use only RHS part for splitting
		        is_assignment = true;
		        break_pos = -1;
		        break_len = 0;
		    case LPAREN:
                if (break_pos != -1 ) nextcase default;
                if (tmpstate.scope_depth != 1) nextcase default;
                // if (i == 0) nextcase default;
                break_pos = (int)i;
                break_len = 0;

                // // NOTE: check if it's look like a call
                // switch(tmpstate.last_token) {
                //     case IDENT:
                //     case CT_IDENT:
                //     case AT_IDENT:
                //     default:
                //         nextcase TOP: default;
                // }
		    case RPAREN:
                if (break_pos == -1 ) nextcase default;
                if (tmpstate.scope_depth != 0) nextcase default;
                if (last_non_space_tok == COMMA) has_magic_comma = true;
            default:
                if(break_pos != -1) break_len += t.value.len;
                if(t.type != SPACE) last_non_space_tok = t.type;
        }
    }

    self.trace("statement_dump: _line_used: %d, cache_len: %d, break_pos: %d break_len: %d last_non_space_tok: %s",
        self._line_used, token_len, break_pos, break_len, last_non_space_tok
    );
    if (!has_magic_comma && self._line_used + token_len <= self.max_line_width) {
        // Fits in line no wrapping needed
        foreach(i, t: self._token_cache) {
            if (i < self._token_cache.len()-1){
                self.write("%s", t.value);
            } else {
                // skip spaces before semicolon
                if(t.type != SPACE) self.write("%s", t.value);
            }
        }
    } else {
        tmpstate = NodeParserState{};
        bool is_multiline = (has_magic_comma ||
                             break_len + (self._indent_level + 1) * 4 > self.max_line_width);
        TokenType brake_type = INVALID_TOKEN;

        bool should_break = false;
        foreach(t: self._token_cache) {
            // NOTE: using this only for checking internal scope_depth
            tmpstate.check(&t);
            switch(t.type){
                case LPAREN:
                    if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                        self.write("%s", t.value);
                        self.indent();
                        brake_type = RPAREN;
                        should_break = true;
                    } else {
                        self.write("%s", t.value);
                    }
                case brake_type:
                    if (tmpstate.scope_depth == 0) {
                        self.dedent()!;
                        self.newline();
                        should_break = false;
                        brake_type = INVALID_TOKEN;
                        self.write("%s", t.value);
                    } else {
                        self.write("%s", t.value);
                    }
                case COMMA:
                    if (!is_multiline) nextcase default;

                    if (tmpstate.scope_depth == 1) {
                        self.write("%s", t.value);
                        should_break = true;
                    } else {
                        self.write("%s", t.value);
                    }
                case SPACE:
                    if (!is_multiline) nextcase default;
                    if (tmpstate.last_token == COMMA) break;
                    nextcase default;
                default:
                    if (should_break) {
                        self.newline();
                        should_break = false;
                    }
                    self.write("%s", t.value);
            }
        }
    }
    self._token_cache.clear();
}

macro void CodeFmt.indent(&self) {
    self.trace("indent");
    self._indent_level++;
}

macro void! CodeFmt.dedent(&self) {
    self.trace("dedent");
    if(self._indent_level == 0) {
        self.@fail(&self._lexer.token, "indentation error")!;
    }
    self._indent_level--;
}

def CodeFmtFn = fn bool! (CodeFmt* self, Token* t, NodeParserState* state);


struct CodeFmtState {
    CodeFmtFn state_fn;
    NodeParserState state;
}

const Token TOKEN_SPACE = Token{.type = SPACE, .value = " "};

fn bool! CodeFmt.format_statement(CodeFmt* self, Token* t, NodeParserState* state) {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(self._token_cache.len() == 0, "forgot statement_dump?");
            self.trace("ENTRY");
            self.newline();
            nextcase state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case EOS:
                    self.statement_dump()!;
                    return true;
                default:
                    self.statement_add(*t);
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
                case EOS:
                    self.write(";");
                case RBRACE:
                    if (state.scope_depth == 0) {
                        self.dedent()!;
                        self.newline();
                        self.write("}");
                        return true;
                    }
                default:
                    // self.@fail(t, "unexpected token")!;
                    return self.enter_state(&CodeFmt.format_statement, t);
            }
        default:
            unreachable();
            
    }
    return false;
}
fn bool! CodeFmt.format_fn_args(CodeFmt* self, Token* t, NodeParserState* state) {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LPAREN);
            assert(self._token_cache.len() == 0, "forgot statement_dump?");
            self.trace("ENTRY");
            nextcase STATE: state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case RPAREN:
                    self._token_cache.push(*t);

                    self.statement_dump()!;
                    return true;
                case COMMA:
                    self._token_cache.push(*t);
                    if (state.scope_depth == 1) {
                        self._token_cache.push(TOKEN_SPACE);
                    }
                case IDENT:
                    if (state.scope_depth == 1 && state.last_token != COMMA) {
                        self._token_cache.push(TOKEN_SPACE);
                    }
                    nextcase default;
                default:
                    self._token_cache.push(*t);
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
                    self._lexer.extend_current_attribute();
                    self.write(" ");
                    self.write("%s", t.value);
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
