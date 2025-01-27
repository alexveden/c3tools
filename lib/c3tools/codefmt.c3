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

	    if (self._is_paused && t.type != EOF ) {
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
	if (!self._is_paused && 
	    self.state_stack.len() > 0 && 
	    self.cache_statement_len() > 0) return false;

	switch(t.type) {
	    case COMMENT_SINGLE:
	    case COMMENT_MULTI:
	        if (self._is_paused) {
	            // Do a direct write
	            self.buf.append(t.value);
	        } else {
	            self.newline();
	            self.write("%s", t.value);
	        }
	    case COMMENT_SINGLE_INLINE:
	    case COMMENT_MULTI_INLINE:
	        if (self._is_paused) {
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

    return self.state_stack[^1].state_fn(self, t, &self.state_stack[^1].state)!;
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
    if (self._is_paused) return;

    usz len = self.buf.appendf(format, ...args)!!;
    self._line_used += (int)len;
}

<*
Writes a new line into internal buffer with proper indentation
*>
macro void CodeFmt.newline(&self) @private {
    if (self._is_paused) return;

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
    if (self._is_paused) return;

    // assert(t.type != EOS, "EOS should not be there");
    usz cache_len = self.cache_statement_len();
    TokenType prev_t = cache_len > 0 ? self.__token_cache[^1].type : TokenType.INVALID_TOKEN; 
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
		case AND:
		case OR:
		case AMP:
		case BIT_OR:
		case BIT_XOR:
            post_space = true;
            pre_space = true;
        case COMMA:
        case COLON:
        case RETURN:
        case NEXTCASE:
        case CATCH:
        case TRY:
            post_space = true;
        case IDENT:
            switch(prev_t){
                case TYPE_IDENT:
                    pre_space = true;
                default:
                    break;
            }
        case EOS:
            switch(prev_t){
                case LPAREN:
                case EOS:
                    break;
                default:
                    post_space = true;
                    break;
            }
        default:
            break;
    }

    if (auto_space && pre_space) self.__token_cache.push(TOKEN_SPACE);
    self.__token_cache.push(*t);
    if (auto_space && post_space) self.__token_cache.push(TOKEN_SPACE);
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
Asses if current token can be used for multi-line split
*>
macro bool CodeFmt.can_split_multiline(&self, Token* t, TokenType wrap_rule) {
    TokenType tt = t.type;
    // if (tt == COMMENT_SINGLE || tt == COMMENT_MULTI) return true;

    switch(wrap_rule) {
        case INVALID_TOKEN:
            return (tt == COMMA || tt == OR || tt == AND);
        case COMMA:
            return (tt == COMMA);
        case BOOL:
            return (tt == OR || tt == AND);
        case EOS:
            return (tt == EOS);
        case COLON:
            return (tt == COLON);
        default:
            return false;
    }
}

<*
Format and dump composite statement into aligned code. 
*>
macro void! CodeFmt.cache_statement_dump(&self, TokenType wrap_rule = INVALID_TOKEN) @private {
    if (self.cache_statement_len() == 0) return;

    usz token_len = 0;
    usz break_len = 0;
    int break_pos = -1;
    bool is_assignment = false;
    bool has_magic_comma = false;
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
        self.@cache_statement_iter(; usz i, Token* t) {
            if (self._print_lex) io::eprintf("%s ", t.type);

            if (i < self.cache_statement_len()-1){
                self.write("%s", t.value);
            } else {
                // skip spaces before last semicolon of the line
                if(t.type != SPACE) self.write("%s", t.value);
            }
        };
    } else {
        // NOTE: Wrapping is needed!

        tmpstate = NodeParserState{};
        bool is_multiline = (has_magic_comma ||
                             break_len + (self._indent_level + 1) * 4 > self.max_line_width);
        TokenType brake_type = INVALID_TOKEN;

        bool should_break = false;
        bool skip_next_space = false;
        self.@cache_statement_iter(; usz i, Token* t) {
            if (self._print_lex) io::eprintf("%s ", t.type);
            tmpstate.check(t); // this is used only for current scope_depth

            switch TOP: (t.type){
                case LBRACE:
                    self.write("%s", t.value);
                    if (tmpstate.scope_depth <= 1 || tmpstate.prev_scope(2) == LBRACE) {
                        self.indent();
                        self.newline();
                    }
                case RBRACE:
                    if (tmpstate.scope_depth == 0 || tmpstate.prev_scope(1) == LBRACE) {
                        self.dedent()!;
                        if (!has_magic_comma) self.newline();
                    }
                    nextcase default;
                case LPAREN:
                    if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                        self.write("%s", t.value);
                        self.indent();
                        brake_type = RPAREN;
                        should_break = true;
                        skip_next_space = false;
                    } else {
                        nextcase default;
                    }
                case brake_type:
                    if (tmpstate.scope_depth == 0) {
                        self.dedent()!;
                        self.newline();
                        should_break = false;
                        skip_next_space = false;
                        brake_type = INVALID_TOKEN;
                        self.write("%s", t.value);
                    } else {
                        nextcase default;
                    }
                case SPACE:
                    if (is_multiline && skip_next_space) {
                        skip_next_space = false;
                        break;
                    } 
                    nextcase default;
                case COMMENT_SINGLE:
                case COMMENT_MULTI:
                    self.newline();
                    self.write("%s", t.value);
                case COMMENT_SINGLE_INLINE:
                case COMMENT_MULTI_INLINE:
                    self.write(" %s", t.value);
                default:
                    if (is_multiline && self.can_split_multiline(t, wrap_rule))  {
                        if (tmpstate.scope_depth == 1 || tmpstate.prev_scope(1) == LBRACE) {
                            self.write("%s", t.value);
                            should_break = true;
                            skip_next_space = true;
                            break;
                        } 
                    } 
                    if (should_break) {
                        self.newline();
                        should_break = false;
                    }
                    self.write("%s", t.value);
            }
        };
    }

    if (self._print_lex) io::eprintf("\n");
    self.cache_statement_clear();
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
            return &CodeFmt.format_fn;
        case DOCS_START:
            return &CodeFmt.format_docstring;
        case DOCS_END:
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
                    if (state.scope_depth == 0 && state.last_token != EMPTY_LINE) {
                        self.newline();
                    }
                    break;
                case RBRACE:
                    // TODO: possible end of scope
                    assert(state.scope_depth == 0);
                    break;
                case DOCS_END:
                    break;
                default:
                    CodeFmtFn fmt_fn = self.global_formatter_dispatch(t)!;
                    assert(fmt_fn != null);
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
            assert(t.type == FN);
            self.trace("ENTRY");
            self.write("\nfn");
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
                default:
                    self.@fail(t, "unexpected token in funcion scope")!;
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

                    self.cache_statement_dump(wrap_rule: COMMA)!;
                    self.trace("EXIT");
                    return true;
                case COMMA:
                    self.cache_statement_add(t, false);
                    if (state.scope_depth == 1) {
                        self.cache_statement_add(&TOKEN_SPACE, false);
                    }
                case IDENT:
                    if (state.scope_depth == 1 && state.last_token != COMMA) {
                        self.cache_statement_add(&TOKEN_SPACE, false);
                    }
                    nextcase default;
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
                case LBRACE:
                    if (state.initial_token == FOR) {
                        self.cache_statement_dump()!;
                        self.write(" ");
                        return self.push_run_state(&CodeFmt.format_code_scope, t);
                    } else {
                        nextcase default;
                    }
                case RBRACE:
                case RBRAPIPE:
                    if (state.initial_token != FOR) {
                        self.cache_statement_add(t);
                    } else {
                        state.transition(EOS);
                    }
                case EOS:
                    if (state.scope_depth != 0) {
                        // check if we not at @body @macro(foo; some) { }
                        if(state.scope_depth != 1 || state.prev_scope(1) != LPAREN) {
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


fn bool! CodeFmt.format_docstring(CodeFmt* self, Token* t, NodeParserState* state) @private {

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:         // initial state
            assert(t.type == DOCS_START);
            self.trace("ENTRY");
            self.newline();
            self.write("%s", t.value);
            state.transition(SCOPE);
        case SCOPE:                // return type 
            self.trace("SCOPE");
            switch(t.type) {
                case DOCS_END:
                    self.write("%s", t.value);
                    return true;
                default:
                    // self.write("%s", t.value);
                    self.write("'?'");
            }
        default:
            unreachable();
    }
    return false;
}
