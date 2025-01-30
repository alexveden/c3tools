module c3tools::codefmt;
import c3tools::codegen;
import c3tools::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;


<*
Code Formatter Object
*>
struct CodeFmt {
    Lexer _lexer;
    DString buf;
    List(<CodeFmtState>) state_stack;
    List(<Token>) __token_cache;
    usz max_line_width;
    usz _indent_level;
    usz _line_used;
    bool _print_lex;
    bool _is_paused;
}


<*
CodeFmt processing function signature
*>
def CodeFmtFn = fn bool! (CodeFmt* self, Token* t, NodeParserState* state);


<*
Item for code formatting state stack
*>
struct CodeFmtState {
    CodeFmtFn state_fn;
    NodeParserState state;
    usz token_cache_start;
}

<* Simple white space synthetic token *>
const Token TOKEN_SPACE = Token{.type = SPACE, .value = " "};

/*
*                  CODE FORMATTER OBJECT
*/

<*
Code formatter constructor

@require max_line_width >= 80 : "too short"
@require max_line_width <= 120 : "too long"
*>
fn CodeFmt CodeFmt.new_init(int max_line_width=80) @operator(construct) {
    CodeFmt self = {
        .max_line_width = max_line_width
    };
    self.buf.new_init(); 
    self.state_stack.new_init();
    self.__token_cache.new_init();
    return self;
}

<* 
Code formatter destructor
*>
fn void CodeFmt.free(&self) {
    self.buf.free();
    self.state_stack.free();
    self.__token_cache.free();
    *self = {};
}

<*
Formats code chunk and return str view of internal buffer. 

NOTE: result will live until next CodeFmt.format() or CodeFmt.free() call 
*>
fn String! CodeFmt.format(&self, String contents, bool print_lex = false) {
    self._print_lex = print_lex;
    self.buf.clear();
    self.state_stack.clear();

	lexer::init(&self._lexer, contents);
	self._lexer.set_whitespace_mode(false);

    // Default scope formatter
	self.push_run_state(&CodeFmt.format_global_file_scope, null)!;

	while LOOP: (self._lexer.next_token()) {
	    Token * t = &self._lexer.token;
	    if (print_lex) t.print(new_line: true);

	    switch(t.type) {
	        case COMMENT_SINGLE:
	        case COMMENT_MULTI:
	        case COMMENT_SINGLE_INLINE:
	        case COMMENT_MULTI_INLINE:
	            if (self.format_comment(t)!) continue LOOP;
	        case SPACE:
	        default:
	            break;
	    }

        if(t.type != SPACE && self.run_state(t)!) {
            self.pop_state()!;

            // Ending one state, may trigger cascade parent exit
            if(self.run_state(t)!) {
                self.pop_state()!;
            }
        }

	    if (self._lexer.is_whitespace_mode && t.type != EOF ) {
	        // NOTE: Printing raw when // fmt: off
	        assert(self.cache_statement_len() == 0, "cache_statement_dump must be called befor fmt: off");
	        assert(t.value.len > 0);
	        self.buf.append(t.value);
	    }
    }

	if (self.state_stack.len() != 0) {
	    self.@fail(&self._lexer.token, "Not all code structures resolved, or bad file syntax")!;
	}

    self._is_paused = false;
    self._lexer.set_whitespace_mode(false);
    return self.buf.str_view();
}

<* Generic comment processor if there is not cache_statement pending + fmt: off handler *>
fn bool! CodeFmt.format_comment(&self, Token* t) {
    if (t.type == COMMENT_SINGLE) {
        if (t.value.starts_with("// fmt: off") && !self._is_paused) {
            self.cache_statement_dump()!;
            self.newline();
            self.write("%s", t.value);

            self._lexer.set_whitespace_mode(true);
            self._is_paused = true;
            return true;
        }
        if (t.value.starts_with("// fmt: on") && self._is_paused) {
            self._lexer.set_whitespace_mode(false);
            self._is_paused = false;
            self.write("%s", t.value);
            self.newline();
	        if(self.state_stack.len() > 0) {
	            self.state_stack[^1].state.current_token = EMPTY_LINE;
	        } 
            return true;
        } 
    }

    // We have existing caches statements, let cache_statement_dump() handle this 
	if (!self._lexer.is_whitespace_mode && 
	    self.state_stack.len() > 0 && 
	    self.cache_statement_len() > 0) return false;

	switch(t.type) {
	    case COMMENT_SINGLE:
	    case COMMENT_MULTI:
	        if (self._lexer.is_whitespace_mode) {
	            // Do a direct write
	            self.buf.append(t.value);
	        } else {
	            self.newline();
	            self.write("%s", t.value);
	        }
	    case COMMENT_SINGLE_INLINE:
	    case COMMENT_MULTI_INLINE:
	        if (self._lexer.is_whitespace_mode) {
	            self.buf.append(t.value);
	        } else {
	            self.write("  %s", t.value);
	        }
	    default:
	        unreachable("%s: `%s`", t.type, t.value);
	}

	self.trace("COMMENT");

    return true;
}

<*
Pushes new state handler function to stack. Allows parsing sub-structs, etc...
*>
fn bool! CodeFmt.push_run_state(&self, CodeFmtFn new_state, Token* t, TokenType initial_token = INVALID_TOKEN) @private {
    if (self.state_stack.len() > 0) {
        assert(self.cache_statement_len() == 0, "you must cache_statement_dump, before next state");
    }

    if (initial_token == INVALID_TOKEN) {
        initial_token = (t != null) ? t.type : TokenType.INVALID_TOKEN;
    }
    CodeFmtState state = {
        .state_fn = new_state,
        .token_cache_start = self.__token_cache.len(),
        .state.initial_token = initial_token,
    };
    self.state_stack.push(state);
    return self.run_state(t);
}

<*
Pops last state from state_stack
*>
fn void! CodeFmt.pop_state(&self) @private {
    assert(self.cache_statement_len() == 0, "cache_statement is not empty, forgot dump?");

    self.state_stack.remove_last();
}

<*
Runs last state in the state_stack with current token
*>
fn bool! CodeFmt.run_state(&self, Token* t) @private {
	if(self.state_stack.len() == 0) return false;
	CodeFmtFn state_fn = self.state_stack[^1].state_fn;
    bool result = state_fn(self, t, &self.state_stack[^1].state)!;
    return result;
}

<*
Emits formatting procedure error with debug message
*>
macro bool! CodeFmt.@fail(&self, Token* t, String msg) @private {
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

<* 
Debug logging (only when self._print_lex = true)
*>
macro CodeFmt.trace(&self, $msg, args...) @private {
    if (!self._print_lex) return;

    io::eprintf("\t\t%s (%s:%d): ", $$FUNC, $$FILE, $$LINE);
    io::eprintfn($msg, ...args);
}

<*
Writes code chunk into internal buffer
*>
macro void CodeFmt.write(&self, String format, args...) @private {
    if (self._lexer.is_whitespace_mode) return;

    usz len = self.buf.appendf(format, ...args)!!;
    self._line_used += (int)len;
}

<*
Writes a new line into internal buffer with proper indentation
*>
macro void CodeFmt.newline(&self) @private {
    if (self._lexer.is_whitespace_mode) return;

    self.buf.append("\n");
    self._line_used = 0;
    for(int i = 0; i < self._indent_level; i++) {
        // TODO: add tabs too
        self.buf.append("    ");
        self._line_used += 4;
    }
}

<*
Increase code indent
*>
macro void CodeFmt.indent(&self) @private {
    self.trace("indent");
    self._indent_level++;
}

<*
Decreases code indent
*>
macro void! CodeFmt.dedent(&self) @private {
    self.trace("dedent");
    if(self._indent_level == 0) {
        self.@fail(&self._lexer.token, "indentation error")!;
    }
    self._indent_level--;
}


/*
*                  CODE WRAP FUNCTIONS
*/
<* 
Adds a token to composite statement cache for further formatting.
*>
macro void CodeFmt.cache_statement_add(&self, Token *t, bool auto_space = true) @private {
    if (self._lexer.is_whitespace_mode) return;
    if (t.type == EMPTY_LINE) return;

    usz cache_len = self.cache_statement_len();
    TokenType prev_t = cache_len > 0 ? self.__token_cache[^1].type : TokenType.INVALID_TOKEN; 
    bool pre_space = false;

    switch TOP: (t.type) {
        case COMMA:
        case COLON:
        case MINUSMINUS:
        case PLUSPLUS:
        case SCOPE:
        case QUESTQUEST:
        case QUESTION:
            break;
		case EQ:
		case DIV:
		case GREATER:
		case LESS:
		case MINUS:
		case MOD:
		case PLUS:
		case CT_AND:
		case CT_OR:
		case CT_CONCAT:
		case DIV_ASSIGN:
		case ELVIS:
		case EQEQ:
		case GREATER_EQ:
		case IMPLIES:
		case LESS_EQ:
		case NOT_EQUAL:
		case SHL:
		case SHR:
		case AND:
		case OR:
		case BIT_OR:
		case BIT_XOR:
		case BIT_AND_ASSIGN:
		case BIT_OR_ASSIGN:
		case BIT_XOR_ASSIGN:
		case MINUS_ASSIGN:
		case MULT_ASSIGN:
		case MOD_ASSIGN:
		case PLUS_ASSIGN:
		case SHL_ASSIGN:
		case SHR_ASSIGN:
            pre_space = true;
        case DOT:
            switch(prev_t){
                case COMMA:
                    pre_space = true;
                default:
                    break;
            }
        case IDENT:
            switch(prev_t){
                case TYPE_IDENT:
                case STAR:
                case RBRACKET:
                    pre_space = true;
                case RPAREN:
                    if(self.@cache_statement_prev_is_binexp()) pre_space = true;
                case AMP: // likely &var 
                    break;
                default:
                    if (is_require_space(prev_t)) pre_space = true;
            }
        case AMP: // *
            switch(prev_t){
                case RPAREN:
                    // distinguish casting and regular expression
                    if(self.@cache_statement_prev_is_binexp()) pre_space = true;
                    break;
                default:
                    pre_space = true;
            }
		case STAR: // *
            switch(prev_t){
                case LPAREN:
                case RPAREN:
                case TYPE_IDENT:
                case STAR:
                case LBRACKET:
                    break;
                default:
                    pre_space = true;
            }
        case LVEC:
        case LGENPAR:
            break;
        case LPAREN:
        case RPAREN:
        case LBRACKET:
        case RBRACKET:
            switch(prev_t){
                case STAR: // cast (int*)
                case IDENT: // call(list)
                case EOS: // call(list)
                case COLON: // slice [:]
                case RGENPAR: // >)
                case RVEC: // >]
                    break;
                case AMP:
                    if(self.@cache_statement_prev_is_binexp()) pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case LBRACE:
            switch(prev_t){
                case COMMA:
                    pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case EOS:
            switch(prev_t){
                case LPAREN:
                case EOS:
                    break;
                default:
                    break;
            }
        default:
            if (is_require_space(prev_t))  pre_space = true;
    }

    if (auto_space && pre_space) self.__token_cache.push(TOKEN_SPACE);
    self.__token_cache.push(*t);
}

<*
Check if previous token type requires a space after it (in general case)
*>
macro bool is_require_space(TokenType prev_t) @local {
    switch(prev_t) {
		case DIV:
		case GREATER:
		case LESS:
		case MINUS:
		case MOD:
		case PLUS:
		case STAR:
		case AMP:
		case CT_AND:
		case CT_OR:
		case CT_CONCAT:
		case DIV_ASSIGN:
		case ELVIS:
		case EQEQ:
		case GREATER_EQ:
		case IMPLIES:
		case LESS_EQ:
		case NOT_EQUAL:
		case QUESTQUEST:
		case SHL:
		case SHR:
		case AND:
		case OR:
		case BIT_OR:
		case BIT_XOR:
		case RETURN:
		case EOS:
		case IDENT:
		case COMMA:
		case EQ:
		case BIT_AND_ASSIGN:
		case BIT_OR_ASSIGN:
		case BIT_XOR_ASSIGN:
		case MINUS_ASSIGN:
		case MULT_ASSIGN:
		case MOD_ASSIGN:
		case PLUS_ASSIGN:
		case SHL_ASSIGN:
		case SHR_ASSIGN:
		case CATCH:
		case VAR:
		case NEXTCASE:
		case INLINE:
		case BREAK:
		case CONTINUE:
		case RVEC:
		case RGENPAR:
		case TRY:
		case FN:
		case COLON:
		    return true;
		default: 
		    return false;
    }
}

<*
Resolves ambiguity conflict for casting (void)&some and expression (1 | 2) & some
*>
macro bool CodeFmt.@cache_statement_prev_is_binexp(&self) @private {
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;

    bool has_expr = false;
    bool has_scope = false;
    int scope = 0;

    for (usz i = self.__token_cache.len(); i-- > start_len; )
    {
        Token* t = &self.__token_cache[i];
        switch(t.type) {
            case RPAREN:
                scope++;
                has_scope = true;
            case LPAREN:
                scope--;
                if (has_scope && scope == 0) {
                    return has_expr;
                }
            case TYPE_IDENT:
            case STAR:
            case AMP:
            case SPACE:
            case LVEC:
            case RVEC:
            case LGENPAR:
            case RGENPAR:
                // distinguish casting and non meaningful ops
                break;
		    case BIT_AND_ASSIGN:
		    case BIT_OR_ASSIGN:
		    case BIT_XOR_ASSIGN:
		    case MINUS_ASSIGN:
		    case MULT_ASSIGN:
		    case MOD_ASSIGN:
		    case PLUS_ASSIGN:
		    case SHL_ASSIGN:
		    case SHR_ASSIGN:
		    case EQ:
		        // assignment operator reached
		        return has_expr;
            default:
                has_expr = true;
        }
    }
    return has_expr;
}

macro void! CodeFmt.cache_statement_dump(&self, TokenType wrap_rule = INVALID_TOKEN) @private {
    if (self.cache_statement_len() == 0) return;

    usz token_len = 0;
    usz break_len = 0;
    int break_pos = -1;
    bool is_assignment = false;
    bool has_magic_comma = false;
    bool is_struct_design = false;
    TokenType last_non_space_tok = INVALID_TOKEN;
    NodeParserState tmpstate;

    // NOTE:
    // Decide when we should start wrapping and if it's necessary
    // Ignore LHS of assignment expression
    self.@cache_statement_iter(; usz i, Token* t) {
        tmpstate.check(t);

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
		        if (tmpstate.scope_depth == 0) {
		            // NOTE: use only first assignment (struct designated initializers case)
		            is_assignment = true;
		            break_pos = -1;
		            break_len = 0;
		        }
		    case LBRACE:
		    case LPAREN:
                if (break_pos != -1 ) nextcase default;
                if (tmpstate.scope_depth != 1) nextcase default;
                // if (i == 0) nextcase default;
                break_pos = (int)i;
                break_len = 0;
		    case RBRACE:
		    case RPAREN:
                if (break_pos == -1 ) nextcase default;
                if (tmpstate.scope_depth != 0) nextcase default;
                if (last_non_space_tok == COMMA) has_magic_comma = true;
            // NOTE: single line comments in statements forcing multi-line print 
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
                has_magic_comma = true;
            case DOT:
                if (tmpstate.scope_depth == 1){
                    if (tmpstate.last_token == LBRACE || tmpstate.last_token == COMMA) {
                        is_struct_design = true;
                    }
                }
                nextcase default;
            default:
                if(break_pos != -1) break_len += t.value.len;
                if(t.type != SPACE) last_non_space_tok = t.type;
        }
    };

    self.trace("cache_statement_dump: _line_used: %d, cache_len: %d, break_pos: %d break_len: %d last_non_space_tok: %s",
        self._line_used, token_len, break_pos, break_len, last_non_space_tok
    );

    if (!has_magic_comma && self._line_used + token_len <= self.max_line_width) {
        // NOTE: Fits in line no wrapping needed write as is with standard formatting.

        tmpstate = NodeParserState{};
        self.@cache_statement_iter(; usz i, Token* t) 
        {
            tmpstate.check(t); // this is used only for current scope_depth
            if (self._print_lex) io::eprintf("%s ", t.type);

            
            bool skip_write = false;
            if (t.type == SPACE && tmpstate.prev_scope(1) == LBRACKET) {
                // // This is a place for weird edge cases with space :(
                // if (tmpstate.prev_scope(1)  == LBRACKET && tmpstate.last_token == COLON) {
                    // slice case int_arr[a:b]
                // }
                skip_write = true;
            }
            
            if (!skip_write) self.write("%s", t.value);
        };
    } else {
        // NOTE: Wrapping is needed!

        bool is_multiline = (has_magic_comma ||
                             break_len + (self._indent_level + 1) * 4 > self.max_line_width);

        if (is_struct_design) {
            // hierarchical struct initialization
            self.cache_statement_dump_struct_init(is_multiline, wrap_rule)!;        
        } else {
            // generic if/for/ func call or statement
            self.cache_statement_dump_generic(is_multiline, wrap_rule)!;        
        }
        
    }

    if (self._print_lex) io::eprintf("\n");
    self.cache_statement_clear();
}

macro void! CodeFmt.cache_statement_dump_struct_init(&self, bool is_multiline, TokenType wrap_rule){
    NodeParserState tmpstate = NodeParserState{};
    TokenType brake_type = INVALID_TOKEN;
    self.@cache_statement_iter(; usz i, Token* t) {
        if (self._print_lex) io::eprintf("%s ", t.type);
        tmpstate.check(t); // this is used only for current scope_depth

        switch TOP: (t.type){
            case LBRACE:
                self.write("%s", t.value);
                self.indent();
            case RBRACE:
                self.dedent()!; 
                self.newline();
                self.write("%s", t.value);
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
                self.newline();
                self.write("%s", t.value);
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
                self.write(" %s", t.value);
            case DOT:
                if (tmpstate.last_token == LBRACE) self.newline();

                if (is_multiline){
                    if (tmpstate.last_token == COMMA) self.newline();
                }
                self.write("%s", t.value);
            case SPACE: 
                if (is_multiline){
                    if (tmpstate.last_token != COMMA) self.write("%s", t.value);
                } else {
                    self.write("%s", t.value);
                }
                tmpstate.current_token = tmpstate.last_token;
            default:
                self.write("%s", t.value);
        }
    };
}

macro void! CodeFmt.cache_statement_dump_generic(&self, bool is_multiline, TokenType wrap_rule){
    NodeParserState tmpstate = NodeParserState{};
    TokenType brake_type = INVALID_TOKEN;
    self.@cache_statement_iter(; usz i, Token* t) {
        if (self._print_lex) io::eprintf("%s ", t.type);
        tmpstate.check(t); // this is used only for current scope_depth

        switch TOP: (t.type){
            case LPAREN:  // Function params and conditions splitting
                if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                    self.write("%s", t.value);
                    self.indent();
                    brake_type = RPAREN;
                } else {
                    nextcase default;
                }
            case LBRACE:  // Array initializers splitting
                if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                    self.write("%s", t.value);
                    self.indent();
                    self.newline();
                    brake_type = RBRACE;
                } else {
                    // if (tmpstate.scope_depth == 2 
                    //     && brake_type == RBRACE 
                    //     && tmpstate.last_token == COMMA)
                    // {
                    //     self.newline();
                    //     self.write("%s", t.value);
                    // } else {
                    // }
                    nextcase default;
                }
            case brake_type:
                if (tmpstate.scope_depth == 0) {
                    self.dedent()!;
                    self.newline();
                    brake_type = INVALID_TOKEN;
                    self.write("%s", t.value);
                } else {
                    nextcase default;
                }
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
                self.newline();
                self.write("%s", t.value);
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
                self.write(" %s", t.value);
            default:
                if (is_multiline) {
                    if (self.split_multiline(&tmpstate, wrap_rule))  {
                        if (tmpstate.current_token == SPACE) {
                            // self.write("$");
                            tmpstate.current_token = tmpstate.last_token;
                        } else {
                            self.newline();
                            self.write("%s", t.value);
                        }
                    } else {
                        self.write("%s", t.value);
                    }
                } else {
                    switch(tmpstate.last_token) {
                        case LBRACE:
                            if (tmpstate.scope_depth == 1 && brake_type == RBRACE) {
                                self.newline();
                            } 
                            nextcase default;
                        case LPAREN:
                            if (tmpstate.scope_depth == 1 && brake_type == RPAREN) {
                                self.newline();
                            } 
                            nextcase default;
                        default:
                            self.write("%s", t.value);
                    }

                }
        }
    };
}

<*
Check if previous token triggers multi-line split
*>
macro bool CodeFmt.split_multiline(&self, NodeParserState* state, TokenType wrap_rule) {
    TokenType tt = state.last_token;
    switch(state.last_token) {
        case COMMENT_SINGLE_INLINE:
        case COMMENT_MULTI:
        case COMMENT_SINGLE:
            return true;
        case LPAREN:
            if (state.scope_depth == 1) return true;
        default:
            break;
    }
    if (state.scope_depth == 2) {
        switch (state.current_token){
            case LBRACE:   //aray initializers { [1..23] = 2}
            case LBRACKET: // array of structs { {1, 2}, {2, 4}}
                break;
            default:
                return false;
        }
    } else if (state.scope_depth != 1) return false;

    switch(wrap_rule) {
        case INVALID_TOKEN:
            return (state.last_token == COMMA || state.last_token == OR || state.last_token == AND);
        case COMMA:
            return (state.last_token == COMMA);
        case BOOL:
            return (state.last_token == OR || state.last_token == AND);
        case EOS:
            return (state.last_token == EOS);
        case COLON:
            return (state.last_token == COLON);
        default:
            return false;
    }
}

<*
Define appropriate code wrapping rule for token type
*>
macro TokenType CodeFmt.cache_statement_wrap_rule(&self, TokenType initial_token)
{
    switch(initial_token) {
        case FOR:
            return EOS;
        case FOREACH:
        case FOREACH_R:
            return COLON;
        case IF:
        case WHILE:
        case DO:
        case DEFER:
        case SWITCH:
        case ELSE:
            return BOOL;
        default: 
            // typically it's COMMA + BOOL
            return INVALID_TOKEN;
    }
}

<*
Cache size for current formatter state
*>
macro usz CodeFmt.cache_statement_len(&self) @private {
    if(self.state_stack.len() == 0) return 0;

    usz start_len = self.state_stack[^1].token_cache_start;
    assert(self.__token_cache.len() >= start_len);

    return self.__token_cache.len() - start_len;
}

<*
Iterate to each cached tokens available by only CURRENT stack
*>
macro CodeFmt.@cache_statement_iter(&self; @body(idx, token)) @private {
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    for(usz i = start_len; i < self.__token_cache.len(); i++){
        @body(i, &self.__token_cache[i]);
    }
}

<*
Clear cache statements for current stack
*>
macro void CodeFmt.cache_statement_clear(&self) @private {
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    while(self.__token_cache.len() > start_len){
        self.__token_cache.remove_last()!!;
    }
}

/*
*                  PROCESSING FUNCTIONS
*/

<*
Returns appropriate formatter function/state for global level statements
*>
fn CodeFmtFn! CodeFmt.global_formatter_dispatch(CodeFmt* self, Token *t) @private {
    switch(t.type) {
        case FN:
        case MACRO:
            return &CodeFmt.format_fn;
        case STRUCT:
        case UNION:
        case BITSTRUCT:
            return &CodeFmt.format_structural;
        case ENUM:
        case FAULT:
            return &CodeFmt.format_enumerable;
        case DOCS_START:
            return &CodeFmt.format_docstring;
        case DOCS_END:
        case EOS:
            break;
        default:
            self.@fail(t, "unsupported global token")!;
    }
    return null;
}

<*
Returns special formatter function for in-scope token.
*>
fn CodeFmtFn! CodeFmt.local_formatter_dispatch(CodeFmt* self, Token *t) @private {
    switch(t.type) {
        case IF:
        case ELSE:
        case FOR:
        case FOREACH:
        case FOREACH_R:
        case WHILE:
        case DO:
        case DEFER:
        case SWITCH:
            return &CodeFmt.format_statement_code_flow;
        case ASM:
            return &CodeFmt.format_asm;
	    case CT_FOR:               // $for
	    case CT_FOREACH:           // $foreach
	    case CT_IF:                // $if
	    case CT_SWITCH:            // $switch
            return &CodeFmt.format_comptime_code_flow;
        default:
            return null;
    }
}

<*
Formatter for generic file contents
*>
fn bool! CodeFmt.format_global_file_scope(CodeFmt* self, Token* t, NodeParserState* state) @private {
    // initialization with null token
    if (state.current_state == INVALID_TOKEN){
        assert(t == null);
        assert(state != null);
        self.trace("ENTRY");
        state.transition(SCOPE);
        return false;
    }

    switch STATE: (state.check(t)){
        case SCOPE:                // generic file content
            self.trace("SCOPE");
            switch(t.type) {
                case EOF:
                    if (state.scope_depth == 0 && state.last_token != EMPTY_LINE) {
                        self.newline();
                    }
                    self.trace("EXIT");
	                return true;
                case EMPTY_LINE:
                    if (state.scope_depth == 0) {
                        switch(state.last_token){
                            case EMPTY_LINE:
                                break;
                            case DOCS_END:
                            case EOS:
                                state.current_token = state.last_token;
                                break;
                            default:
                                self.newline();
                        }
                    }
                    break;
                case DOCS_END:
                    break;
                case EOS:
                case RBRACE:
                    if(state.scope_depth != 0) self.@fail(t, "scope was not properly closed?")!;
                    break;
                default:
                    CodeFmtFn fmt_fn = self.global_formatter_dispatch(t)!;
                    if(fmt_fn == null) self.@fail(t, "unknown global scope statement")!;
                    switch(state.last_token){
                        case EMPTY_LINE:
                            break;
                        default:
                            self.newline();
                    }
                    self.push_run_state(fmt_fn, t)!;
            }
        default:
            unreachable();
    }
    return false;
}

<*
Callable code formatter (fn/macros)

Format steps: format_fn_args -> format_code_scope -> foreach(format_generic_statement: statements)
*>
fn bool! CodeFmt.format_fn(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:         // initial state
            assert(t.type == FN || t.type == MACRO);
            self.trace("ENTRY");
            self.write("%s", t.value);
            state.transition(RETURN);
        case RETURN:                // return type 
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
                case EMPTY_LINE:
                    break;
                default:
                    self.write("%s", t.value);
            }
        case VAR:    // arguments
            self.trace("VAR");
            switch(t.type) {
                case LPAREN:
                    state.transition(VAR);
                    return self.push_run_state(&CodeFmt.format_fn_args, t);
                case AT_IDENT:
                    nextcase STATE: state.transition(AT_IDENT);
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                case RPAREN:
                    if (state.scope_depth != 0) self.@fail(t, "unfinished scope")!;
                    break;
                case EMPTY_LINE:
                    break;
                case IMPLIES:           // => 
                    nextcase STATE: state.transition(IMPLIES);
                default:
                    self.@fail(t, "unexpected token in funcion args")!;
            }
        case AT_IDENT: // function attributes
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
                case EMPTY_LINE:
                    break;
                default:
                    self.@fail(t, "unexpected token in funcion attributes")!;
            }
        case SCOPE: // function scope { ... }
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:           // {
                    if (state.scope_depth != 1) self.@fail(t, "bad scope")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_code_scope, t);
                case RBRACE:
                    if (state.scope_depth != 0) self.@fail(t, "unfinished scope")!;
                    self.newline();
                    self.trace("EXIT");
                    return true;
                case EMPTY_LINE:
                    break;
                default:
                    self.@fail(t, "unexpected token in funcion scope")!;
            }
        case IMPLIES: // lambda func
            self.trace("IMPLIES");
            switch(t.type) {
                case IMPLIES:
                    self.write(" %s ", t.value);
                    break;
                case EMPTY_LINE:
                    break;
                case EOS:
                    self.cache_statement_add(t);
                    self.cache_statement_dump()!;
                    self.newline();
                    return true;
                default:
                    self.cache_statement_add(t);
            }
        default:
            unreachable();
    }
    return false;
}

<*
Formatting fn/macro arguments 
*>
fn bool! CodeFmt.format_fn_args(CodeFmt* self, Token* t, NodeParserState* state) @private {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LPAREN);
            self.trace("ENTRY");
            nextcase STATE: state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case RPAREN:
                    self.cache_statement_add(t, false);

                    if (state.scope_depth == 0) {
                        if (state.initial_token == FOR) {
                            // @body macro definition
                            self.cache_statement_dump(wrap_rule: EOS)!;
                        } else {
                            self.cache_statement_dump(wrap_rule: COMMA)!;
                        }
                        self.trace("EXIT");
                        return true;
                    }
                case EOS:
                    // Typically in @body macro def
                    state.initial_token = FOR;
                    self.cache_statement_add(t, false);
                    self.cache_statement_add(&TOKEN_SPACE, false);
                case COMMA:
                    self.cache_statement_add(t, false);
                    if (state.scope_depth == 1) {
                        self.cache_statement_add(&TOKEN_SPACE, false);
                    }
                case IDENT:
                    if (state.scope_depth == 1 && 
                        state.last_token != COMMA && 
                        state.last_token != LPAREN
                    ) {
                        self.cache_statement_add(&TOKEN_SPACE, false);
                    }
                    nextcase default;
                case EMPTY_LINE:
                    break;
                default:
                    self.cache_statement_add(t, false);
                    break;
            }
        default:
            self.trace("format_fn_args default");
            
    }

    return false;
}

<*
Formatting generic code scope ({ ... } inside a function)
*>
fn bool! CodeFmt.format_code_scope(CodeFmt* self, Token* t, NodeParserState* state) @private {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LBRACE || t.type == LBRAPIPE);
            assert(state.scope_depth == 1);
            self.trace("ENTRY");
            self.write("%s", t.value);
            self.indent();
            state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case CT_ENDFOREACH:
                case CT_ENDFOR:
                case CT_ENDSWITCH:
                case CT_ENDIF:
                case EOS:
                    // returned back by format_generic_statement()
                    break;
                case RBRAPIPE:
                case RBRACE:
                    if (state.scope_depth == 0) {
                        self.dedent()!;
                        if (state.initial_token == SWITCH) self.dedent()!;
                        self.newline();
                        self.write("%s", t.value);
                        self.trace("EXIT");
                        return true;
                    } else {
                        // Specially for `case FOO: { .. some .. }`
                        if (state.initial_token == SWITCH)  self.indent();
                    }
                case LBRACE:
                    if (state.initial_token == SWITCH && state.last_token == COLON){
                        self.dedent()!;
                        self.write(" ");
                    } else {
                        self.newline();
                    }
                    return self.push_run_state(&CodeFmt.format_code_scope, t);
                case CASE:
                case DEFAULT:
                    if (state.scope_depth == 1) {
                        state.initial_token = SWITCH;
                        if (state.last_token == LBRACE){
                           self.indent(); // extra indent, at first case
                        }
                        nextcase STATE: state.transition(CASE);
                    } else {
                        self.@fail(t, "unexpected case/default statement")!;
                    }
                case EMPTY_LINE:
                    if (state.last_token != EMPTY_LINE) {
                        self.newline();
                    }
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null){
                        // Not a keyword or anything special, just a statement
                        if (t.type == LPAREN) {
                            // NOTE: casting case, e.g. (void)free(data);
                            // prevent open LPAREN to influence current scope_depth
                            state.check_scope(RPAREN); // remove LPAREN scope
                        }
                        self.newline();
                        return self.push_run_state(&CodeFmt.format_generic_statement, t);
                    } else {                    
                        // Special keyword or statement
                        return self.push_run_state(new_local_state, t);
                    }
            }
        case CASE:
            self.trace("CASE");
            switch(t.type) {
                case CASE:
                    self.dedent()!;
                    self.newline();
                    self.write("%s ", t.value);
                case DEFAULT:
                    self.dedent()!;
                    self.newline();
                    self.write("%s", t.value);
                case COLON:
                    self.cache_statement_dump()!;
                    self.write(":", t.value);
                    self.indent();
                    state.transition(SCOPE);
                default:
                    self.cache_statement_add(t);
                    break;
            }
        default:
            unreachable();
            
    }
    return false;
}

<*
Formatting individual (generic statements) ending with ;
*>
fn bool! CodeFmt.format_generic_statement(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            self.trace("ENTRY");
            nextcase state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case LBRAPIPE:
                    state.initial_token = FOR;
                    nextcase LBRACE;
                case FN:
                    state.initial_token = FN;
                    nextcase default;
                case LBRACE:
                    if (state.initial_token == FOR || state.initial_token == FN) {
                        self.cache_statement_dump()!;
                        if (state.initial_token == FN){
                            self.newline();
                        } else {
                            self.write(" ");
                        }
                        return self.push_run_state(&CodeFmt.format_code_scope, t);
                    } else {
                        nextcase default;
                    }
                case RBRACE:
                case RBRAPIPE:
                    if(state.initial_token == FN) {
                        break;
                    } else if (state.initial_token != FOR) {
                        self.cache_statement_add(t);
                    } else {
                        state.transition(EOS);
                    }
                case EOS:
                    if (state.scope_depth != 0) {
                        // check if we not at @body @macro(foo; some) { }
                        if(state.scope_depth != 1 || state.prev_scope(1) != LPAREN) {
                            self.cache_statement_dump()!;
                            self.@fail(t, "unclosed scope")!;
                        }

                        self.cache_statement_add(t);
                        state.initial_token = FOR;

                        return false;
                    } else {
                        self.cache_statement_dump()!;
                        self.write(";");
                        self.trace("EXIT");
                        return true;
                    }
                default:
                    self.cache_statement_add(t);
            }
        case EOS:
            // NOTE: special state for expecting closing ; for @body macro / {| block |}

            self.trace("EOS");
            switch(t.type) {
                case BANG:
                    self.write("!");
                case BANGBANG:
                    self.write("!!");
                case EOS:
                    self.write(";");
                    self.trace("EXIT");
                    return true;
                default:
                    self.@fail(t, "unexpected token after @body macro or expr block")!;
                    break;
            };
        default:
            unreachable();
    }

    return false;
}

<*
Formatting of generic code flow statement block (for, while, if, foreach, switch, defer)
*>
fn bool! CodeFmt.format_statement_code_flow(CodeFmt* self, Token* t, NodeParserState* state) @private {
    assert(state.initial_token != INVALID_TOKEN);

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            self.trace("ENTRY");
            switch(t.type) {
                case FOR:
                case FOREACH:
                case FOREACH_R:
                case IF:
                case WHILE:
                case DO:
                case DEFER:
                case SWITCH:
                    self.newline();
                    self.write("%s ", t.value);
                case ELSE:
                    // else goes into single line
                    self.write(" else");
                default: 
                    unreachable();
            }

            state.transition(CONST_IDENT);
        case CONST_IDENT:
            self.trace("CONST_IDENT");
            switch(t.type) {
                case CONST_IDENT:  // LABEL
                    self.write("%s", t.value);
                case IF: // else if
                    self.write(" %s ", t.value);
                case ELSE: // single else
                case COLON: // LABEL: colon
                    self.write("%s ", t.value);
                case CATCH:
                case TRY:
                    self.write("%s", t.value);
                case LPAREN:
                    nextcase STATE: state.transition(VAR);
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                default:
                    // maybe `defer io::print()`?
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                    if (state.initial_token != DEFER) self.@fail(t, "invalid token")!;
                    nextcase STATE: state.transition(IMPLIES);
            }
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case RPAREN:
                    self.cache_statement_add(t);
                    if (state.scope_depth == 0){
                        TokenType wrap_rule = self.cache_statement_wrap_rule(state.initial_token);
                        self.cache_statement_dump(wrap_rule)!;
                        state.transition(SCOPE);
                    }
                default:
                    if (state.scope_depth > 0){
                        self.cache_statement_add(t);
                    } else {
                        self.write("%s", t.value);
                    }
            }
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:
                    if (state.scope_depth != 1) self.@fail(t, "invalid scope")!;
                    self.write(" ");
                    return self.push_run_state(&CodeFmt.format_code_scope, t);
                case RBRACE:
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                    self.trace("EXIT");
                    return true;
                case AT_IDENT:
                    if (t.value == "@jump") {
                        self.write(" %s", t.value);
                    } else {
                        nextcase default;
                    }
                default:
                    // if (foo) no_brace_expr;
                    nextcase STATE: IMPLIES;
            }
        case IMPLIES:
            self.trace("IMPLIES");
            switch(t.type) {
                case EOS:
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                    self.trace("EXIT");
                    return true;
                default:
                    self.write(" ");
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null){
                        // Not a keyword or anything special, just a statement
                        return self.push_run_state(&CodeFmt.format_generic_statement, t);
                    } else {                    
                        // Special keyword or statement
                        return self.push_run_state(new_local_state, t);
                    }
            }
        default:
            unreachable();
    }

    return false;
}

<*
Formatting generic doc string with contracts
*>
fn bool! CodeFmt.format_docstring(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:         // initial state
            assert(t.type == DOCS_START);
            self.trace("ENTRY");
            self.write("%s", t.value);
            state.transition(SCOPE);
        case SCOPE: // contract scope
            self.trace("SCOPE");
            switch(t.type) {
                case DOCS_END:
                    nextcase STATE: state.transition(EOS);
                case AT_IDENT:
                    self.write("%s", t.value);
                    switch(t.value) {
                        case "@param":  
                            state.transition(VAR);
                        case "@require":  
                            state.transition(ASSERT);
                        case "@ensure": 
                            state.transition(ASSERT);
                        case "@return": 
                            state.transition(RETURN);
                        default: 
                            state.transition(AT_IDENT);
                    }
                default:
                    self.@fail(t, "expected doc contract, or *>")!;
            }
        case AT_IDENT: // generic contract (any other)
            switch(t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.write("%s", t.value);
                    state.transition(SCOPE);
                default:
                    self.write(" %s", t.value);
            }
        case ASSERT:  // @require / @ensure
            switch(t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.write("%s", t.value);
                    state.transition(SCOPE);
                case COMMA:
                case DOT:
                case LPAREN:
                case RPAREN:
                    self.write("%s", t.value);
                default:
                    switch(state.last_token) {
                        case BANG:
                        case LPAREN:
                        case DOT:
                        case RPAREN:
                            self.write("%s", t.value);

                        default:
                            self.write(" %s", t.value);
                    }
            }
        case RETURN:  // @return[!]
            switch(t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.write("%s", t.value);
                    state.transition(SCOPE);
                case BANG:
                    self.write("%s", t.value);
                case TYPE_IDENT:
                    self.write(" %s", t.value);
                case DOT:
                case CONST_IDENT:
                case COMMA:
                    self.write("%s", t.value);
                default:
                    self.write(" %s", t.value);
            }
        case VAR:  // @param
            switch(t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.write("%s", t.value);
                    state.transition(SCOPE);
                case LBRACKET:
                    self.write(" %s", t.value);
                case RBRACKET:
                    self.write("%s", t.value);
                default:
                    if (state.scope_depth == 1) self.write(" ");
                    self.write("%s", t.value);
            }
        case EOS:
            self.write("%s", t.value);
            return true;
        default:
            unreachable();
    }
    return false;
}

<*
Formatting of compile time code flow statement block ($for, $if, $foreach, $switch)
*>
fn bool! CodeFmt.format_comptime_code_flow(CodeFmt* self, Token* t, NodeParserState* state) @private {
    assert(state.initial_token != INVALID_TOKEN);

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            self.trace("ENTRY");
            switch(t.type) {
	            case CT_FOR:               // $for
	            case CT_FOREACH:           // $foreach
	            case CT_IF:                // $if
	            case CT_SWITCH:            // $switch
                    self.newline();
                    self.write("%s ", t.value);
                default: 
                    unreachable();
            }

            state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case CT_CASE:
                case CT_DEFAULT:
                    if (self.cache_statement_len() != 0 || state.initial_token != CT_SWITCH) {
                        self.@fail(t, "unexpected $case/$default")!;
                    }
                    self.indent();
                    self.indent();
                    nextcase STATE: state.transition(SCOPE);
                case COLON:
                case RPAREN:
                    self.cache_statement_add(t);
                    if (state.scope_depth == 0){
                        TokenType wrap_rule = self.cache_statement_wrap_rule(state.initial_token);
                        self.cache_statement_dump(wrap_rule)!;
                        self.indent();
                        state.transition(SCOPE);
                        if (state.initial_token == CT_SWITCH) self.indent();
                    }
                default:
                    self.cache_statement_add(t);
            }
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case EOS:
                    // Fallback from format_generic_statement
                    break;
                case LBRACE:
                    if (state.scope_depth != 1) self.@fail(t, "invalid scope")!;
                    self.write(" ");
                    return self.push_run_state(&CodeFmt.format_code_scope, t);
                case RBRACE:
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                case CT_CASE:
                case CT_DEFAULT:
                    self.dedent()!;
                    nextcase STATE: state.transition(CASE);
                case CT_ELSE:
                    self.dedent()!;
                    self.newline();
                    self.write("%s", t.value);
                    self.indent();
                case CT_ENDFOREACH:
                    if (state.initial_token == CT_FOREACH) nextcase INVALID_TOKEN;
                case CT_ENDFOR:
                    if (state.initial_token == CT_FOR) nextcase INVALID_TOKEN;
                case CT_ENDSWITCH:
                    if (state.initial_token == CT_SWITCH) {
                        self.dedent()!;
                        nextcase INVALID_TOKEN;
                    }
                case CT_ENDIF:
                    if (state.initial_token == CT_IF) nextcase INVALID_TOKEN;
                case INVALID_TOKEN: // temp placeholder case
                    self.dedent()!;
                    self.newline();
                    self.write("%s", t.value);
                    return true;                        
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null){
                        // Not a keyword or anything special, just a statement
                        if (t.type == LPAREN) {
                            // NOTE: casting case, e.g. (void)free(data);
                            // prevent open LPAREN to influence current scope_depth
                            state.check_scope(RPAREN); // remove LPAREN scope
                        }
                        self.newline();
                        return self.push_run_state(&CodeFmt.format_generic_statement, t);
                    } else {                    
                        // Special keyword or statement
                        return self.push_run_state(new_local_state, t);
                    }
            }
        case CASE:
            self.trace("CASE");
            switch(t.type) {
                case CT_CASE:
                    self.newline();
                    self.write("%s ", t.value);
                case CT_DEFAULT:
                    self.newline();
                    self.write("%s", t.value);
                case COLON:
                    self.indent();
                    self.cache_statement_add(t);
                    if (state.scope_depth == 0){
                        self.cache_statement_dump()!;
                        state.transition(SCOPE);
                    }
                default:
                    self.cache_statement_add(t);
            }
        default:
            unreachable();
    }

    return false;
}

<* Asm block with automatically disabled formatting *>
fn bool! CodeFmt.asm_non_fmt_block(CodeFmt* self, Token* t, NodeParserState* state) @private {
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            assert(t.type == LBRACE);
            self.trace("ENTRY");
            nextcase STATE: state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:
                    if (state.scope_depth == 1) {
                        // { will be printed by raw printer
                        self.write(" ");
                        // print asm block as is without formatting
                        self._lexer.set_whitespace_mode(true);
                    }
                case RBRACE:
                    if (state.scope_depth == 0) {
                        // enable formatting, unless there is // fmt: off 
                        if (!self._is_paused) self._lexer.set_whitespace_mode(false);
                        self.write("}");
                        return true;
                    }
                default:
                    break;
            }
        default:
            unreachable();
    }
    return false;
}

<*
Formatting asm() and asm { block }
*>
fn bool! CodeFmt.format_asm(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            self.trace("ENTRY");
            self.newline();
            self.write("%s", t.value);
            state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch(t.type) {
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                case EOS:
                    self.write("%s", t.value);
                    self.trace("EXIT");
                    return true;
                default:
                    self.write("%s", t.value);
            }
        case SCOPE:
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:
                    if (state.scope_depth == 1) {
                        return self.push_run_state(&CodeFmt.asm_non_fmt_block, t);
                    }
                case RBRACE:
                    if (state.scope_depth == 0) {
                        return true;
                    }
                default:
                    break;
            }
        default:
            unreachable();
    }

    return false;
}

<*
Formatter for struct / union / bitstruct contents
*>
fn bool! CodeFmt.format_structural(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:         // initial state
            assert(t.type == STRUCT || t.type == UNION || t.type == BITSTRUCT);
            self.trace("ENTRY"); 
            self.write("%s", t.value);
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:                // struct type name and other meta header stuff
            self.trace("TYPE_IDENT");
            switch(t.type) {
                case AT_IDENT:  // struct attrs
                    self._lexer.extend_current_attribute();
                    nextcase default;
                case IDENT:  // substruct name
                case TYPE_IDENT:
                    nextcase default;
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                case EMPTY_LINE:
                    break;
                default:
                    if (state.scope_depth == 0 && t.type != RBRACKET) {
                        self.write(" %s", t.value);
                    } else {
                        self.write("%s", t.value);
                    }
            }
        case SCOPE: // struct scope {}
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:           // {
                    self.newline();
                    self.write("{");
                    self.indent();
                case RBRACE:
                    self.dedent()!;
                    self.newline();
                    self.write("}");
                    if (state.scope_depth == 0) {
                        self.trace("EXIT");
                        if (self.state_stack.len() == 2){
                            // NOTE: printing new line only at exit from top struct
                            self.newline();
                        }
                        return true;
                    } 
                case EMPTY_LINE:
                    break;
                case EOS:
                    self.cache_statement_add(t);
                    self.cache_statement_dump()!;
                case STRUCT:
                case UNION:
                case BITSTRUCT:
                    if (self.cache_statement_len() != 0) self.@fail(t, "unexpected keyword")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_structural, t);

                default:
                    if (self.cache_statement_len() == 0){
                        self.newline();
                    }
                    self.cache_statement_add(t);
            }
        default:
            unreachable();
    }
    return false;
}

<*
Formatter for enums, faults
*>
fn bool! CodeFmt.format_enumerable(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:         // initial state
            assert(t.type == ENUM);
            self.trace("ENTRY"); 
            self.write("%s", t.value);
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:                // enum type name
            self.trace("TYPE_IDENT");
            switch(t.type) {
                case AT_IDENT:  // attrs
                    self._lexer.extend_current_attribute();
                    nextcase default;
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                case LPAREN:
                    self.write(" ");
                    nextcase STATE: state.transition(VAR);
                case EMPTY_LINE:
                    break;
                default:
                    self.write(" %s", t.value);
            }
        case VAR: // enum associated vars
            switch(t.type) {
                case RPAREN:
                    self.cache_statement_add(t);
                    if (state.scope_depth == 0) {
                        self.cache_statement_dump(wrap_rule: COMMA)!;
                        state.transition(TYPE_IDENT);
                    }
                default:
                    self.cache_statement_add(t);

            }
        case SCOPE: // enum scope {}
            self.trace("SCOPE");
            switch(t.type) {
                case LBRACE:           // {
                    if (state.scope_depth == 1) {
                        self.newline();
                        self.write("{");
                        self.indent();
                    } else {
                        self.cache_statement_add(t);
                    }
                case RBRACE:
                    if (state.scope_depth == 0) {
                        self.cache_statement_dump(wrap_rule: COMMA)!;
                        self.dedent()!;
                        self.newline();
                        self.write("}");
                        self.newline();
                        self.trace("EXIT");
                        return true;
                    } else {
                        self.cache_statement_add(t);
                    }
                case EMPTY_LINE:
                    break;
                case COMMA:
                    self.cache_statement_add(t);
                    if (state.scope_depth == 1){
                        self.cache_statement_dump()!;
                    }
                default:
                    if (self.cache_statement_len() == 0){
                        self.newline();
                    }
                    self.cache_statement_add(t);
            }
        default:
            unreachable();
    }
    return false;
}

