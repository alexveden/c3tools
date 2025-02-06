module c3tools::codefmt;
import c3tools::ast::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;

/*
*                  PROCESSING FUNCTIONS
*/
<*
 Returns appropriate formatter function/state for global level statements
*>
fn CodeFmtFn! CodeFmt.global_formatter_dispatch(CodeFmt* self, Token* t) @private
{
    switch (t.type) {
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
        case INTERFACE:
            return &CodeFmt.format_interface;
        case DOCS_START:
            return &CodeFmt.format_docstring;
        case DOCS_END:
        case EOS:
            break;
        case EXTERN:
            return &CodeFmt.format_generic_extern;
        case DEF:
        case DISTINCT:
        case MODULE:
        case CONST:
        case IMPORT:
        default:
            return &CodeFmt.format_generic_statement;
    }
    return null;
}

<*
 Returns special formatter function for in-scope token.
*>
fn CodeFmtFn! CodeFmt.local_formatter_dispatch(CodeFmt* self, Token* t) @private
{
    switch (t.type) {
        case IF:
        case ELSE:
        case FOR:
        case FOREACH:
        case FOREACH_R:
        case WHILE:
        case DEFER:
        case SWITCH:
            return &CodeFmt.format_statement_code_flow;
        case ASM:
            return &CodeFmt.format_asm;
        case CT_FOR:  // $for
        case CT_FOREACH:  // $foreach
        case CT_IF:  // $if
        case CT_SWITCH:  // $switch
            return &CodeFmt.format_comptime_code_flow;
        default:
            return null;
    }
}

<* Generic comment processor if there is not cache_statement pending + fmt: off handler *>
fn bool! CodeFmt.format_comment_or_empty(&self, NodeParserState* state, Token* t)
{
    if (t.type == COMMENT_SINGLE) {
        if (t.value.starts_with("// fmt: off") && !self._is_paused) {
            self.cache_statement_dump()!;
            if (!self._is_empty_line) self.newline();
            self.write("%s", t.value.trim_right());

            self._lexer.set_whitespace_mode(true);
            self._is_paused = true;
            return true;
        }
        if (t.value.starts_with("// fmt: on") && self._is_paused) {
            self._lexer.set_whitespace_mode(false);
            self._is_paused = false;
            self._is_empty_line = true;
            self.write("%s", t.value.trim_right());
            self._is_inline_comment = true;
            if (self.state_stack.len() > 0) {
                self.state_stack[^1].state.current_token = EMPTY_LINE;
            }
            state.current_token = EMPTY_LINE;
            return true;
        }
    }

    // We have existing caches statements, let cache_statement_dump() handle this
    if (
        !self._lexer.is_whitespace_mode &&
        self.state_stack.len() > 0 &&
        self.cache_statement_len() > 0
    ) {
        self.trace("COMMENT PASSED");
        // doesn't allow empty lines, just skip them
        return t.type == EMPTY_LINE;
    }

    switch (t.type) {
        case EMPTY_LINE:
            if (state.last_token == EMPTY_LINE) {
                return true;
            }
            if (state.scope_depth == 0) {
                switch (state.last_token) {
                    case EOS:
                    case COMMENT_SINGLE_INLINE:
                    case COMMENT_MULTI_INLINE:
                    case COMMENT_MULTI:
                    case COMMENT_SINGLE:
                        break;
                    case DOCS_END:
                        self._is_empty_line = true;
                        break;
                    case RBRACE:
                    default:
                        return true;
                }
            }
            if (self._lexer.is_whitespace_mode) {
                // Do a direct write
                self.buf.append("\n");
            } else {
                self.newline(is_empty: true);
            }
            return true;
        case EOF:
            self.trace("COMMENT EOF");
            if (self._is_paused) return false;
            if (self.buf.len() > 0 && self.buf.char_at(self.buf.len() - 1) != '\n') {
                self.buf.append("\n");
            }
            return false;

        case COMMENT_SINGLE:
        case COMMENT_MULTI:
            if (self._lexer.is_whitespace_mode) {
                // Do a direct write
                self.buf.append(t.value);
            } else {
                if (!self._is_empty_line) self.newline();
                self.write("%s", t.value.trim_right());
            }
            self._is_empty_line = false;
            self._is_inline_comment = t.type == COMMENT_SINGLE;
        case COMMENT_SINGLE_INLINE:
        case COMMENT_MULTI_INLINE:
            if (self._lexer.is_whitespace_mode) {
                self.buf.append(t.value);
            } else {
                self.write("  %s", t.value.trim_right());
            }
            self._is_empty_line = false;
            self._is_inline_comment = t.type == COMMENT_SINGLE_INLINE;
        default:
            unreachable("%s: `%s`", t.type, t.value);
    }

    self.trace("COMMENT DUMP");

    return true;
}

<*
 Formatter for generic file contents
*>
fn bool! CodeFmt.format_global_file_scope(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    // initialization with null token
    if (state.current_state == INVALID_TOKEN) {
        assert(t == null);
        assert(state != null);
        self.trace("ENTRY");
        state.transition(SCOPE);
        return false;
    }
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case SCOPE:  // generic file content
            self.trace("SCOPE");
            switch (t.type) {
                case EOF:
                    self.trace("EXIT");
                    return true;
                case DOCS_END:
                    break;
                case EOS:
                case RBRACE:
                    if (state.scope_depth != 0) self.@fail(t, "scope was not properly closed?")!;
                    break;
                default:
                    CodeFmtFn fmt_fn = self.global_formatter_dispatch(t)!;
                    if (fmt_fn == null) self.@fail(t, "unknown global scope statement")!;

                    if (!self._is_empty_line) {
                        // Prevent doubling empty lines
                        self.newline();
                    } else {
                        // we must reset line width to avoid doing multi-line for ()
                        self._line_used = 0;
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
fn bool! CodeFmt.format_fn(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == FN || t.type == MACRO || t.type == EXTERN);
            self.trace("ENTRY");
            self.write("%s", t.value);
            // usually `extern fn`
            if (t.type != EXTERN) {
                state.transition(RETURN);
            } else {
                // 'extern '
                self.write(" ", t.value);
            }
        case RETURN:  // return type
            self.trace("RETURN");
            switch (t.type) {
                case AT_IDENT:
                case IDENT:
                    if (state.scope_depth == 0 && state.last_token != DOT) self.write(" ");
                    nextcase default;
                case TYPE_IDENT:
                case TYPEID:
                    if (state.scope_depth == 0) self.write(" ");
                    nextcase default;
                case LPAREN:
                    nextcase STATE: state.transition(VAR);
                default:
                    self.write("%s", t.value);
            }
        case VAR:  // arguments
            self.trace("VAR");
            switch (t.type) {
                case LPAREN:
                    state.transition(VAR);
                    return self.push_run_state(&CodeFmt.format_fn_args, t);
                case AT_IDENT:
                case AT_TYPE_IDENT:
                    nextcase STATE: state.transition(AT_IDENT);
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                case RPAREN:
                    if (state.scope_depth != 0) self.@fail(t, "unfinished scope")!;
                    break;
                case IMPLIES:  // =>
                    nextcase STATE: state.transition(IMPLIES);
                case EOS:
                    self.write(";");
                    return true;
                default:
                    self.@fail(t, "unexpected token in funcion args")!;
            }
        case AT_IDENT:  // function attributes
            self.trace("AT_IDENT");
            switch (t.type) {
                case AT_IDENT:
                case AT_TYPE_IDENT:
                    self._lexer.extend_current_attribute();
                    self.write(" ");
                    self.write("%s", t.value);
                    break;
                case IMPLIES:  // =>
                    nextcase STATE: state.transition(IMPLIES);
                case LBRACE:  // {
                    if (state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                case EOS:
                    self.write(";");
                    return true;
                default:
                    self.@fail(t, "unexpected token in funcion attributes")!;
            }
        case SCOPE:  // function scope { ... }
            self.trace("SCOPE");
            switch (t.type) {
                case LBRACE:  // {
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
        case IMPLIES:  // lambda func
            self.trace("IMPLIES");
            switch (t.type) {
                case IMPLIES:
                    self.write(" %s ", t.value);
                    break;
                case EOS:
                    self.cache_statement_add(state, t);
                    self.cache_statement_dump(no_split: true)!;
                    return true;
                default:
                    self.cache_statement_add(state, t);
            }
        default:
            unreachable();
    }
    return false;
}

<*
 Formatting fn/macro arguments 
*>
fn bool! CodeFmt.format_fn_args(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            assert(t.type == LPAREN);
            self.trace("ENTRY");
            nextcase STATE: state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch (t.type) {
                case RPAREN:
                    self.cache_statement_add(state, t);

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
                    nextcase default;
                default:
                    self.cache_statement_add(state, t);
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
fn bool! CodeFmt.format_code_scope(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            assert(t.type == LBRACE || t.type == LBRAPIPE);
            assert(state.scope_depth == 1);
            self.trace("ENTRY");
            self.write("%s", t.value);
            self.indent();
            state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
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
                        if (state.initial_token == SWITCH) self.indent();
                    }
                case LBRAPIPE:
                    // NOTE: LBRAPIPE - return with EOS, so we remove it from stack now
                    if (state.initial_token != LBRAPIPE) state.check_scope(RBRAPIPE);
                    nextcase default;
                case LBRACE:
                    if (state.initial_token == SWITCH && state.last_token == COLON) {
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
                        if (state.last_token == LBRACE) {
                            self.indent();  // extra indent, at first case
                        }
                        nextcase STATE: state.transition(CASE);
                    } else {
                        self.@fail(t, "unexpected case/default statement")!;
                    }
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null) {
                        // Not a keyword or anything special, just a statement
                        if (t.type == LPAREN) {
                            // NOTE: casting case, e.g. (void)free(data);
                            // prevent open LPAREN to influence current scope_depth
                            state.check_scope(RPAREN);  // remove LPAREN scope
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
            switch (t.type) {
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
                    self.cache_statement_add(state, t);
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
fn bool! CodeFmt.format_generic_statement(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            self.trace("ENTRY");
            nextcase state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
                case LBRAPIPE:
                    if (state.initial_token != LBRAPIPE) {
                        // case for int i = {| return 0; |}
                        state.initial_token = FOR;
                    }
                    nextcase LBRACE;
                case DOT:
                    if (state.initial_token == STRUCT && state.last_token == COMMA) {
                        self.cache_statement_dump_struct_init(
                            is_multiline: true, wrap_rule: COMMA
                        )!;
                        self.newline();
                    }
                    nextcase default;
                case DO:
                case FN:
                    if (state.last_token == EQ && state.prev_scope(1) == LBRACE) {
                        // = {.my_func = fn void () ...}
                        self.cache_statement_dump_struct_init(
                            is_multiline: true, wrap_rule: COMMA
                        )!;
                        state.initial_token = STRUCT;
                        self.write(" %s ", t.value);
                        break;
                    } else {
                        state.initial_token = t.type;
                    }
                    nextcase default;
                case LBRACE:
                    switch (state.initial_token) {
                        case AT_IDENT:
                            // distinguish @some_macro({ <-- and @some_macro() { <--
                            if (state.scope_depth != 1) break;
                            self.cache_statement_dump()!;
                            self.write(" ");
                            return self.push_run_state(&CodeFmt.format_code_scope, t);
                        case STRUCT:
                            // self.cache_statement_dump_struct_init(is_multiline: true, wrap_rule: COMMA)!;
                            self.cache_statement_dump()!;
                            self.write(" ");
                            return self.push_run_state(&CodeFmt.format_code_scope, t);
                        case FN:
                            self.cache_statement_dump()!;
                            self.write(" ");
                            return self.push_run_state(&CodeFmt.format_code_scope, t);
                        case FOR:
                        case DO:
                            self.cache_statement_dump()!;
                            self.write(" ");
                            return self.push_run_state(&CodeFmt.format_code_scope, t);
                        case LBRAPIPE:
                            self.cache_statement_dump()!;
                            return self.push_run_state(&CodeFmt.format_code_scope, t);
                        default:
                            if (state.last_token == RPAREN) {
                                if (!self._resolve__prev_is_cast()) {
                                    // Not a cast
                                    // mem::@scoped(&allocator){ @body(); };
                                    state.initial_token = FOR;
                                    nextcase FOR;
                                } else {
                                    // looks like a cast
                                    // Foo[] xyz2 = (Foo[])(int[]) { 1, 2 };
                                    // return $typeof(*mat) { .m = val * ($Type)mat.m };
                                    break;  // nextcase default
                                }
                            }
                    }
                    nextcase default;
                case WHILE:
                    if (self.cache_statement_len() == 0) {
                        self.write(" %s", t.value);
                    } else {
                        nextcase default;
                    }
                case RBRACE:
                case RBRAPIPE:
                    switch (state.initial_token) {
                        case AT_IDENT:
                            if (state.scope_depth != 0) nextcase default;
                        case FN:
                        case DO:
                            break;
                        case STRUCT:
                            if (self._is_cascade_call) break;
                            self.cache_statement_dump_struct_init(
                                is_multiline: true, wrap_rule: COMMA
                            )!;
                            self.dedent()!;
                            self.newline();
                            self.write("%s", t.value);
                        case FOR:
                        case LBRAPIPE:
                            if (self._is_cascade_call) break;
                            nextcase default;
                        default:
                            self.cache_statement_add(state, t);
                    }
                case EOS:
                    if (state.scope_depth != 0) {
                        // check if we not at @body @macro(foo; some) { }
                        if (state.scope_depth != 1 || state.prev_scope(1) != LPAREN) {
                            self.cache_statement_dump()!;
                            self.@fail(t, "unclosed scope")!;
                        }

                        self.cache_statement_add(state, t);
                        state.initial_token = FOR;

                        return false;
                    } else {
                        self.cache_statement_add(state, t);
                        self.cache_statement_dump()!;
                        self.trace("EXIT");
                        return true;
                    }
                default:
                    self.cache_statement_add(state, t);
            }
        case EOS:
            // NOTE: special state for expecting closing ; for @body macro / {| block |}

            self.trace("EOS");
            switch (t.type) {
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
            }
        default:
            unreachable();
    }

    return false;
}

<*
 Formatting for extern ...
*>
fn bool! CodeFmt.format_generic_extern(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            assert(t.type == EXTERN);
            self.trace("ENTRY");
            self.write("%s ", t.value);
            state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
                case FN:
                    return self.push_run_state(&CodeFmt.format_fn, t);
                case EOS:
                    return true;
                default:
                    return self.push_run_state(&CodeFmt.format_generic_statement, t);

            }
        default:
            unreachable();
    }

    return false;
}

<*
 Formatting of generic code flow statement block (for, while, if, foreach, switch, defer)
*>
fn bool! CodeFmt.format_statement_code_flow(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(state.initial_token != INVALID_TOKEN);
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            self.trace("ENTRY");
            switch (t.type) {
                case FOREACH_R:
                    state.initial_token = FOREACH;
                    nextcase FOREACH;
                case FOR:
                case FOREACH:
                case IF:
                case WHILE:
                case DO:
                case DEFER:
                case SWITCH:
                    self.newline();
                    self.write("%s", t.value);
                case ELSE:
                    // else goes into single line
                    self.write(" else");
                default:
                    unreachable();
            }

            state.transition(CONST_IDENT);
        case CONST_IDENT:
            self.trace("CONST_IDENT");
            switch (t.type) {
                case CONST_IDENT:  // LABEL
                    self.write(" %s", t.value);
                case IF:  // else if
                    self.write(" %s", t.value);
                case ELSE:  // single else
                case COLON:  // LABEL: colon
                    self.write("%s", t.value);
                case CATCH:
                case TRY:
                    // defer try / defer catch
                    self.write(" %s", t.value);
                case LPAREN:
                    nextcase STATE: state.transition(VAR);
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                default:
                    // maybe `defer io::print()`?
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                    if (state.initial_token != DEFER) self.@fail(t, "invalid token")!;
                    self.write(" ");
                    nextcase STATE: state.transition(IMPLIES);
            }
        case VAR:  // if/switch/for parens (...)
            self.trace("VAR");
            switch (t.type) {
                case LPAREN:
                    // entry condition state
                    if (state.scope_depth == 1) self.write(" ");
                    nextcase default;
                case RPAREN:
                    self.cache_statement_add(state, t);
                    if (state.scope_depth == 0) {
                        TokenType wrap_rule = self.cache_statement_wrap_rule(state.initial_token);
                        self.cache_statement_dump(wrap_rule)!;
                        state.transition(SCOPE);
                    }
                case COLON:
                    nextcase default;
                default:
                    if (state.initial_token == DEFER && t.type == TYPE_IDENT) {
                        // likely defer (void)call();
                        nextcase STATE: state.transition(IMPLIES);
                    }
                    self.cache_statement_add(state, t);
            }
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
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
                    self.write(" ");
                    nextcase STATE: state.transition(IMPLIES);
            }
        case IMPLIES:
            self.trace("IMPLIES");
            switch (t.type) {
                case EOS:
                    if (state.scope_depth != 0) self.@fail(t, "invalid scope")!;
                    if (!self._is_cascade_call) {
                        self.cache_statement_add(state, t);
                        self.cache_statement_dump(no_split: true)!;
                        self.trace("EXIT");
                    }
                    return true;
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null) {
                        self.cache_statement_add(state, t);
                    } else {
                        self.cache_statement_dump(no_split: true)!;
                        self._skip_next_new_line = true;
                        return self.push_run_state(new_local_state, t);
                    }
            }
        default:
            unreachable();
    }

    return false;
}

<*
 Docstring cleanup and re-formatting routine
*>
fn bool CodeFmt.format_docstring_text_write(&self, Token* t)
{
    self.write("<*");

    bool has_new_line = false;
    bool is_multiline = t.value.ends_with("\n");

    bool is_new_line = true;
    bool is_in_code = false;
    int count = 0;
    for LOOP: (usz i = 2; i < t.value.len; i++) {
        char c = t.value[i];
        if (is_new_line && !is_in_code) {
            switch (c) {
                case ' ':
                case '\t':
                    continue LOOP;
                case '\n':
                    has_new_line = true;
                case '`':
                    if (i < t.value.len - 3) {
                        if (t.value[i + 1] == '`' && t.value[i + 2] == '`') {
                            is_in_code = true;
                            self.newline();
                            self.buf.append(c);
                            continue LOOP;
                        }
                    }
                    nextcase default;
                default:
                    // first char + append space to it
                    is_new_line = false;
                    if (has_new_line || (is_multiline && count == 0)) {
                        self.newline();
                        has_new_line = false;
                    }
                    count++;
                    self.buf.append(' ');
                    self.buf.append(c);
            }
        } else {
            switch (c) {
                case '\n':
                    is_new_line = true;
                    has_new_line = false;
                    self.newline(is_empty: true);
                case '`':
                    if (is_in_code && i < t.value.len - 3) {
                        if (t.value[i + 1] == '`' && t.value[i + 2] == '`') {
                            is_in_code = false;
                            is_new_line = false;
                        }
                    }
                    nextcase default;
                default:
                    self.buf.append(c);
            }
        }

    }
    if (is_multiline && count == 0) self.newline();

    return is_multiline && count > 0;
}

<*
 Formatting generic doc string with contracts
*>
fn bool! CodeFmt.format_docstring(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == DOCS_START);
            assert(state.initial_token == DOCS_START);
            self.trace("ENTRY");
            if (self.format_docstring_text_write(t)) {
                // marker of multiline doc
                state.initial_token = DOCS_EOL;
            }
            state.transition(SCOPE);
        case SCOPE:  // contract scope
            self.trace("SCOPE");
            switch (t.type) {
                case DOCS_EOL:
                    self.newline();
                case DOCS_END:
                    nextcase STATE: state.transition(EOS);
                case AT_IDENT:
                    if (state.initial_token == DOCS_EOL) {
                        self.newline();
                        state.initial_token = DOCS_START;
                    }

                    self.write(" %s", t.value);
                    switch (t.value) {
                        case "@param":
                            state.transition(VAR);
                        case "@require":
                        case "@ensure":
                            self.write(" ");
                            state.transition(ASSERT);
                        case "@return":
                            state.transition(RETURN);
                        default:
                            state.transition(AT_IDENT);
                    }
                default:
                    self.@fail(t, "expected doc contract, or *>")!;
            }
        case AT_IDENT:  // generic contract (any other)
            switch (t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.newline();
                    state.transition(SCOPE);
                default:
                    self.write(" %s", t.value);
            }
        case ASSERT:  // @require / @ensure
            switch (t.type) {
                case DOCS_END:
                    self.cache_statement_dump()!;
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.cache_statement_dump(no_split: true)!;
                    self.newline();
                    state.transition(SCOPE);
                case COLON:
                case STRING:
                case RAW_STRING:
                    self.cache_statement_dump(no_split: true)!;
                    self.write(" %s", t.value);
                default:
                    self.cache_statement_add(state, t);
            }
        case RETURN:  // @return[!]
            switch (t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.newline();
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
            switch (t.type) {
                case DOCS_END:
                    self.write(" ");
                    nextcase STATE: state.transition(EOS);
                case DOCS_EOL:
                    self.newline();
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
 Formatting $switch: $case / $default scopes
*>
fn bool! CodeFmt.format_comptime_switch_body(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);
    assert(state.initial_token != INVALID_TOKEN);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            self.trace("ENTRY");
            switch (t.type) {
                case CT_CASE:
                case CT_DEFAULT:
                    nextcase STATE: state.transition(CASE);
                default:
                    unreachable();
            }
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
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
                case CT_ENDFOREACH:
                case CT_ENDFOR:
                case CT_ENDIF:
                    break;
                case CT_ENDSWITCH:
                    self.dedent()!;
                    self.dedent()!;
                    self.newline();
                    self.write("%s", t.value);
                    return true;
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null) {
                        // Not a keyword or anything special, just a statement
                        if (t.type == LPAREN) {
                            // NOTE: casting case, e.g. (void)free(data);
                            // prevent open LPAREN to influence current scope_depth
                            state.check_scope(RPAREN);  // remove LPAREN scope
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
            switch (t.type) {
                case CT_CASE:
                    self.newline();
                    self.write("%s ", t.value);
                case CT_DEFAULT:
                    self.newline();
                    self.write("%s", t.value);
                case COLON:
                    self.indent();
                    if (state.scope_depth == 0) {
                        self.cache_statement_dump()!;
                        self.write(":");
                        state.transition(SCOPE);
                    } else {
                        self.cache_statement_add(state, t);
                    }
                default:
                    self.cache_statement_add(state, t);
            }
        default:
            unreachable();
    }

    return false;
}

<*
 Formatting of compile time code flow statement block ($for, $if, $foreach, $switch)
*>
fn bool! CodeFmt.format_comptime_code_flow(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);
    assert(state.initial_token != INVALID_TOKEN);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            self.trace("ENTRY");
            self.newline();
            switch (t.type) {
                case CT_FOR:  // $for
                case CT_FOREACH:  // $foreach
                case CT_IF:  // $if
                    self.write("%s ", t.value);
                case CT_SWITCH:  // $switch
                    self.write("%s", t.value);
                default:
                    unreachable();
            }

            state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch (t.type) {
                case CT_CASE:
                case CT_DEFAULT:
                    self.indent();
                    self.indent();
                    nextcase STATE: state.transition(SCOPE);
                case COLON:
                    if (state.scope_depth == 0 && state.initial_token == CT_IF) {
                        self.cache_statement_dump(wrap_rule: BOOL)!;
                        self.write("%s", t.value);
                        self.indent();
                        state.transition(SCOPE);
                    } else {
                        nextcase default;
                    }
                case LPAREN:
                    if (state.scope_depth == 1 && state.initial_token == CT_SWITCH) {
                        self.write(" ");
                    }
                    nextcase default;
                case RPAREN:
                    if (state.scope_depth == 0 && state.initial_token != CT_IF) {
                        TokenType wrap_rule = self.cache_statement_wrap_rule(state.initial_token);
                        self.cache_statement_dump(wrap_rule)!;
                        self.write("%s", t.value);
                        self.indent();
                        state.transition(SCOPE);
                        if (state.initial_token == CT_SWITCH) self.indent();
                    } else {
                        self.cache_statement_add(state, t);
                    }
                default:
                    self.cache_statement_add(state, t);
            }
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
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
                    return self.push_run_state(&CodeFmt.format_comptime_switch_body, t);
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
                        return true;
                    }
                case CT_ENDIF:
                    if (state.initial_token == CT_IF) nextcase INVALID_TOKEN;
                case INVALID_TOKEN:  // temp placeholder case
                    if (self._is_cascade_call) break;
                    self.dedent()!;
                    self.newline();
                    self.write("%s", t.value);
                    return true;
                default:
                    CodeFmtFn new_local_state = self.local_formatter_dispatch(t)!;
                    if (new_local_state == null) {
                        // Not a keyword or anything special, just a statement
                        if (t.type == LPAREN) {
                            // NOTE: casting case, e.g. (void)free(data);
                            // prevent open LPAREN to influence current scope_depth
                            state.check_scope(RPAREN);  // remove LPAREN scope
                        }
                        self.newline();
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

<* Asm block with automatically disabled formatting *>
fn bool! CodeFmt.asm_non_fmt_block(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            assert(t.type == LBRACE);
            self.trace("ENTRY");
            nextcase STATE: state.transition(SCOPE);
        case SCOPE:
            self.trace("SCOPE");
            switch (t.type) {
                case LBRACE:
                    if (state.scope_depth == 1) {
                        // { will be printed by raw printer
                        self.newline();
                        // print asm block as is without formatting
                        self._lexer.set_whitespace_mode(true);
                    }
                case RBRACE:
                    if (state.scope_depth == 0) {
                        // enable formatting, unless there is // fmt: off
                        if (!self._is_paused) self._lexer.set_whitespace_mode(false);
                        // it's safe to write even we have inline comment
                        self._is_inline_comment = false;
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
fn bool! CodeFmt.format_asm(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:
            self.trace("ENTRY");
            self.newline();
            self.write("%s", t.value);
            state.transition(VAR);
        case VAR:
            self.trace("VAR");
            switch (t.type) {
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
            switch (t.type) {
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
fn bool! CodeFmt.format_structural(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == STRUCT || t.type == UNION || t.type == BITSTRUCT);
            self.trace("ENTRY");
            self.cache_statement_add(state, t);
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:  // struct type name and other meta header stuff
            self.trace("TYPE_IDENT");
            switch (t.type) {
                case AT_IDENT:  // struct attrs
                    self._lexer.extend_current_attribute();
                    nextcase default;
                case LBRACE:
                    self.cache_statement_dump()!;
                    nextcase STATE: state.transition(SCOPE);
                default:
                    self.cache_statement_add(state, t);
            }
        case SCOPE:  // struct scope {}
            self.trace("SCOPE");
            switch (t.type) {
                case LBRACE:  // {
                    return self.push_run_state(&CodeFmt.format_structural_scope, t);
                case RBRACE:
                    if (state.scope_depth == 0) {
                        self.trace("EXIT");
                        if (self.state_stack.len() == 2) {
                            // NOTE: printing new line only at exit from top struct
                            self.newline();
                        }
                        return true;
                    }
                    nextcase default;
                default:
                    self.@fail(t, "unexpected struct scope keyword")!;
            }
        default:
            unreachable();
    }
    return false;
}

<*
 Formatter for struct / union / bitstruct contents
*>
fn bool! CodeFmt.format_structural_scope(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == LBRACE);
            self.trace("ENTRY");
            self.newline();
            self.write("{");
            self.indent();
            state.transition(SCOPE);
        case SCOPE:  // struct scope {}
            self.trace("SCOPE");
            switch (t.type) {
                case RBRACE:
                    self.dedent()!;
                    self.newline();
                    self.write("}");
                    if (state.scope_depth == 0) {
                        self.trace("EXIT");
                        return true;
                    }
                case EOS:
                    self.cache_statement_add(state, t);
                    self.cache_statement_dump()!;
                case STRUCT:
                case UNION:
                case BITSTRUCT:
                    if (self.cache_statement_len() != 0) self.@fail(t, "unexpected keyword")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_structural, t);
                case DOCS_START:
                    if (self.cache_statement_len() != 0) self.@fail(t, "unexpected keyword")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_docstring, t);
                case DOCS_END:
                    break;
                default:
                    if (self.cache_statement_len() == 0) {
                        self.newline();
                    }
                    self.cache_statement_add(state, t);
            }
        default:
            unreachable();
    }
    return false;
}

<*
 Formatter for enums, faults
*>
fn bool! CodeFmt.format_enumerable(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == ENUM || t.type == FAULT);
            self.trace("ENTRY");
            self.write("%s", t.value);
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:  // enum type name
            self.trace("TYPE_IDENT");
            switch (t.type) {
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
        case VAR:  // enum associated vars
            switch (t.type) {
                case RPAREN:
                    self.cache_statement_add(state, t);
                    if (state.scope_depth == 0) {
                        self.cache_statement_dump(wrap_rule: COMMA)!;
                        state.transition(TYPE_IDENT);
                    }
                default:
                    self.cache_statement_add(state, t);

            }
        case SCOPE:  // enum scope {}
            self.trace("SCOPE");
            switch (t.type) {
                case LBRACE:  // {
                    if (state.scope_depth == 1) {
                        self.newline();
                        self.write("{");
                        self.indent();
                    } else {
                        self.cache_statement_add(state, t);
                        if (state.scope_depth == 2) {
                            self.__token_cache.push(TOKEN_SPACE);
                        }
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
                        if (state.scope_depth == 1) {
                            self.__token_cache.push(TOKEN_SPACE);
                        }
                        self.cache_statement_add(state, t);
                    }
                case DOCS_START:
                    if (self.cache_statement_len() != 0) self.@fail(t, "unexpected keyword")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_docstring, t);
                case DOCS_END:
                    break;
                case COMMA:
                    self.cache_statement_add(state, t);
                    if (state.scope_depth == 1) {
                        self.cache_statement_dump()!;
                    }
                default:
                    if (self.cache_statement_len() == 0) {
                        self.newline();
                    }
                    self.cache_statement_add(state, t);
            }
        default:
            unreachable();
    }
    return false;
}

<*
 Formatter for interfaces
*>
fn bool! CodeFmt.format_interface(CodeFmt* self, Token* t, NodeParserState* state) @private
{
    assert(t.type != EMPTY_LINE);

    switch STATE: (state.check(t)) {
        case INVALID_TOKEN:  // initial state
            assert(t.type == INTERFACE);
            self.trace("ENTRY");
            self.write("%s", t.value);
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:  // enum type name
            self.trace("TYPE_IDENT");
            switch (t.type) {
                case AT_IDENT:  // attrs
                    self._lexer.extend_current_attribute();
                    nextcase default;
                case LBRACE:
                    nextcase STATE: state.transition(SCOPE);
                default:
                    self.write(" %s", t.value);
            }
        case SCOPE:  // interface scope {}
            self.trace("SCOPE");
            switch (t.type) {
                case LBRACE:  // {
                    if (state.scope_depth != 1) self.@fail(t, "unexpeced interface scope")!;
                    self.newline();
                    self.write("{");
                    self.indent();
                case RBRACE:
                    if (state.scope_depth != 0) self.@fail(t, "unexpeced interface scope")!;
                    self.dedent()!;
                    self.newline();
                    self.write("}");
                    self.newline();
                    self.trace("EXIT");
                    return true;
                case FN:
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_fn, t);
                case DOCS_START:
                    if (self.cache_statement_len() != 0) self.@fail(t, "unexpected keyword")!;
                    self.newline();
                    return self.push_run_state(&CodeFmt.format_docstring, t);
                case DOCS_END:
                    break;
                case EOS:
                    // returned by fn processor
                    break;
                default:
                    if (state.scope_depth != 0) self.@fail(t, "unexpeced interface token")!;
            }
        default:
            unreachable();
    }
    return false;
}
