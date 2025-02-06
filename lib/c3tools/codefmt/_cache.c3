module c3tools::codefmt;
import c3tools::ast::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;

/*
*                  CODE WRAP FUNCTIONS
*/

<*
 Dumps and formats collected cache_statement_ array into code
*>
macro void! CodeFmt.cache_statement_dump(
    &self, TokenType wrap_rule = INVALID_TOKEN, bool no_split = false
) @private
{
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
                if (break_pos != -1) nextcase default;
                if (tmpstate.scope_depth != 1) nextcase default;
                break_pos = (int)i;
                break_len = 0;
            case RBRACE:
            case RPAREN:
                if (break_pos == -1) nextcase default;
                if (tmpstate.scope_depth != 0) nextcase default;
                if (last_non_space_tok == COMMA) has_magic_comma = true;
                // NOTE: single line comments in statements forcing multi-line print
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
                tmpstate.current_token = tmpstate.last_token;
                has_magic_comma = true;
            case SPACE:
                tmpstate.current_token = tmpstate.last_token;
                nextcase default;
            case DOT:
                if (tmpstate.scope_depth == 1) {
                    if (tmpstate.last_token == LBRACE || tmpstate.last_token == COMMA) {
                        is_struct_design = true;
                    }
                }
                nextcase default;
            default:
                if (break_pos != -1) break_len += t.value.len;
                if (t.type != SPACE) last_non_space_tok = t.type;
        }
    };

    self.trace(
        "cache_statement_dump: _line_used: %d, cache_len: %d, break_pos: %d break_len: %d last_non_space_tok: %s",
        self._line_used,
        token_len,
        break_pos,
        break_len,
        last_non_space_tok
    );

    if (no_split || (!has_magic_comma && self._line_used + token_len <= self.max_line_width)) {
        // NOTE: Fits in line no wrapping needed write as is with standard formatting.
        self.@cache_statement_iter(; usz i, Token* t) {
            if (self._print_lex) io::eprintf("%s ", t.type);
            switch (t.type) {
                case QUESTION:
                    if (self._resolve__next_question_is_error(i)) self.write(" ");
                    nextcase default;
                default:
                    self.write("%s", t.value);
            }
        };
        if (self._print_lex) io::eprintf("\n");
        self.cache_statement_clear();
    } else {
        // NOTE: Wrapping is needed!

        bool is_multiline = (
            has_magic_comma || break_len + (self._indent_level + 1) * 4 > self.max_line_width
        );

        if (is_struct_design) {
            // hierarchical struct initialization
            self.cache_statement_dump_struct_init(is_multiline, wrap_rule)!;
        } else {
            // generic if/for/ func call or statement
            self.cache_statement_dump_generic(is_multiline, wrap_rule)!;
        }

    }

}

<*
 Struct initializers dump MyStruct s = {.foo = 1, .sub = {.bar = 0}}
*>
macro void! CodeFmt.cache_statement_dump_struct_init(&self, bool is_multiline, TokenType wrap_rule) @private
{
    NodeParserState tmpstate = NodeParserState {};
    TokenType brake_type = INVALID_TOKEN;
    self.@cache_statement_iter(; usz i, Token* t) {
        if (self._print_lex) io::eprintf("%s ", t.type);
        tmpstate.check(t);  // this is used only for current scope_depth

        switch TOP: (t.type) {
            case LBRACE:
                if (is_multiline) {
                    if (tmpstate.last_token == COMMA) self.newline();
                    if (tmpstate.last_token == LBRACE) self.newline();
                }
                self.write("%s", t.value);
                self.indent();
            case RBRACE:
                self.dedent()!;
                if (tmpstate.last_token != LBRACE) self.newline();
                self.write("%s", t.value);
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
                self.newline();
                self.write("%s", t.value);
                tmpstate.current_token = tmpstate.last_token;
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
                self.write("  %s", t.value);
                tmpstate.current_token = tmpstate.last_token;
            case QUESTION:
                if (self._resolve__next_question_is_error(i)) self.write(" ");
                nextcase default;
            case SPACE:
                if (is_multiline) {
                    if (
                        tmpstate.last_token != COMMA &&
                        tmpstate.last_token != LBRACE &&
                        self._resolve__next_token(i) != RBRACE
                    ) {
                        self.write("%s", t.value);
                    }
                } else {
                    if (tmpstate.last_token != LBRACE && self._resolve__next_token(i) != RBRACE) {
                        self.write("%s", t.value);
                    }
                }
                tmpstate.current_token = tmpstate.last_token;
            default:
                switch (tmpstate.last_token) {
                    case DOT:
                    case COMMA:
                    case LBRACE:
                        if (tmpstate.last_token == LBRACE) self.newline();

                        if (is_multiline) {
                            if (tmpstate.last_token == COMMA && tmpstate.prev_scope(1) == LBRACE) {
                                self.newline();
                            }
                        }
                        self.write("%s", t.value);
                    default:
                        self.write("%s", t.value);
                }
        }
    };
    if (self._print_lex) io::eprintf("\n");
    self.cache_statement_clear();
}

<*
 Generic statement dumper
*>
macro void! CodeFmt.cache_statement_dump_generic(&self, bool is_multiline, TokenType wrap_rule) @private
{
    NodeParserState tmpstate = NodeParserState {};
    TokenType brake_type = INVALID_TOKEN;

    // This filter is used for forcing raw writing (e.g. cast vs call ambiguity)
    usz skip_i_until = 0;

    self.@cache_statement_iter(; usz i, Token* t) {
        if (self._print_lex) io::eprintf("%s ", t.type);
        tmpstate.check(t);  // this is used only for current scope_depth

        // WTF: c3 doesn't support continue in macro @body!
        if (i >= skip_i_until) {

            switch TOP: (t.type) {
                case LPAREN:  // Function params and conditions splitting
                    if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                        skip_i_until = self._resolve__next_is_cast_and_dump(i);
                        if (skip_i_until == i) {
                            self.write("%s", t.value);
                            self.indent();
                            brake_type = RPAREN;
                        }
                        break;
                    } else {
                        nextcase default;
                    }
                case LBRACE:  // Array initializers splitting
                    if (tmpstate.scope_depth == 1 && brake_type == INVALID_TOKEN) {
                        self.write("%s", t.value);
                        self.indent();
                        brake_type = RBRACE;
                    } else {
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
                    self.write("  %s", t.value);
                case QUESTION:
                    if (self._resolve__next_question_is_error(i)) self.write(" ");
                    nextcase default;
                default:
                    if (is_multiline) {
                        if (self.cache_split_multiline(&tmpstate, wrap_rule)) {
                            if (tmpstate.current_token == SPACE) {
                                tmpstate.current_token = tmpstate.last_token;
                            } else {
                                self.newline();
                                self.write("%s", t.value);
                            }
                        } else {
                            if (tmpstate.current_token == SPACE) {
                                tmpstate.current_token = tmpstate.last_token;
                                if (self._resolve__next_token(i) == RBRACE) break;
                            }
                            self.write("%s", t.value);
                        }
                    } else {
                        switch (tmpstate.last_token) {
                            case LBRACE:
                                if (tmpstate.current_token == SPACE) {
                                    tmpstate.current_token = tmpstate.last_token;
                                    break;
                                } else if (brake_type == RBRACE && t.type != RBRACE) {
                                    if (tmpstate.scope_depth == 1) {
                                        self.newline();
                                    } else if (
                                        tmpstate.scope_depth == 2 &&
                                        (t.type == LBRACE || t.type == LBRACKET || t.type == LPAREN)
                                    ) {
                                        self.newline();
                                    }
                                }
                                nextcase default;
                            case LPAREN:
                                if (
                                    tmpstate.scope_depth == 1 &&
                                    brake_type == RPAREN &&
                                    t.type != RPAREN
                                ) {
                                    self.newline();
                                } else if (tmpstate.scope_depth == 2 && t.type == LPAREN) {
                                    self.newline();
                                }
                                nextcase default;
                            default:

                                if (tmpstate.current_token == SPACE) {
                                    tmpstate.current_token = tmpstate.last_token;
                                    if (self._resolve__next_token(i) == RBRACE) break;
                                }
                                self.write("%s", t.value);
                        }

                    }
            }
        }
    };
    if (self._print_lex) io::eprintf("\n");
    self.cache_statement_clear();
}

<*
 Adds a token to composite statement cache for further formatting.
*>
macro void CodeFmt.cache_statement_add(&self, NodeParserState* state, Token* t) @private
{
    if (self._lexer.is_whitespace_mode) return;
    assert(t.type != EMPTY_LINE);
    assert(t.type != SPACE);


    if (self.cache_statement_len() > 0){
        if(self._resolve_current_token(state, t)) {
            self.trace("ADD SPACE");
            self.__token_cache.push(TOKEN_SPACE);
        }
    }
    self.trace("ADD");
    self.__token_cache.push(*t);
}


<*
 Check if previous token triggers multi-line split
*>
macro bool CodeFmt.cache_split_multiline(&self, NodeParserState* state, TokenType wrap_rule) @local
{
    TokenType tt = state.last_token;
    switch (state.last_token) {
        case COMMENT_SINGLE_INLINE:
        case COMMENT_MULTI_INLINE:
        case COMMENT_MULTI:
        case COMMENT_SINGLE:
            return true;
        case LPAREN:
            if (state.scope_depth == 1 && state.current_token != RPAREN) return true;
            if (state.scope_depth == 2 && state.current_token == LPAREN) return true;
        case LBRACE:
            if (state.scope_depth == 1 && state.current_token != RBRACE) return true;
            if (state.scope_depth == 1 && state.current_token == SPACE) return true;
            if (state.scope_depth == 2 && state.current_token == LBRACKET) return true;
            if (state.scope_depth == 2 && state.current_token == LBRACE) return true;
            if (state.scope_depth == 2 && state.current_token == LPAREN) return true;
        default:
            break;
    }
    if (state.scope_depth == 2) {
        switch (state.current_token) {
            case LBRACE:  //aray initializers { [1..23] = 2}
            case LBRACKET:  // array of structs { {1, 2}, {2, 4}}
            case LPAREN:  // ( (some && cond) || (another || cond))
                break;
            default:
                return false;
        }
    } else if (state.scope_depth != 1) return false;

    switch (wrap_rule) {
        case INVALID_TOKEN:
            switch (state.last_token) {
                case COMMA:
                case OR:
                case AND:
                case CT_OR:
                case CT_AND:
                    return true;
                default:
                    return false;
            }
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
macro TokenType CodeFmt.cache_statement_wrap_rule(&self, TokenType initial_token) @private
{
    switch (initial_token) {
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
macro usz CodeFmt.cache_statement_len(&self) @private
{
    if (self.state_stack.len() == 0) return 0;

    usz start_len = self.state_stack[^1].token_cache_start;
    assert(self.__token_cache.len() >= start_len);

    return self.__token_cache.len() - start_len;
}

<*
 Iterate to each cached tokens available by only CURRENT stack
*>
macro CodeFmt.@cache_statement_iter(&self; @body(idx, token)) @private
{
    assert(self.state_stack.len() > 0);
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    for (usz i = start_len; i < self.__token_cache.len(); i++) {
        @body(i, &self.__token_cache[i]);
    }
}

<*
 Clear cache statements for current stack
*>
macro void CodeFmt.cache_statement_clear(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    while (self.__token_cache.len() > start_len) {
        self.__token_cache.remove_last()!!;
    }
}
