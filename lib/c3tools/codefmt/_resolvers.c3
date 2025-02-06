module c3tools::codefmt;
import c3tools::ast::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;

/*
*                  CODE WRAP CONFLICT RESOLVERS
*/

<*
 Decides if we need insert space before current token
*>
macro bool CodeFmt._resolve_current_token(&self, NodeParserState* state, Token* t) @private
{
    usz cache_len = self.cache_statement_len();
    TokenType prev_t = cache_len > 0 ? self.__token_cache[^1].type : TokenType.INVALID_TOKEN;

    bool pre_space = false;

    switch TOP: (t.type) {
        case MINUSMINUS:
        case PLUSPLUS:
            switch (prev_t) {
                case IDENT:
                case HASH_IDENT:
                case RBRACKET:
                case CT_IDENT:
                    break;
                default:
                    nextcase TOP: default;
            }
        case COMMA:
        case SCOPE:
            break;
        case EQ:
        case DIV:
        case GREATER:
        case LESS:
        case MOD:
        case CT_AND:
        case CT_OR:
        case CT_CONCAT:
        case DIV_ASSIGN:
        case ELVIS:
        case QUESTQUEST:
        case EQEQ:
        case GREATER_EQ:
        case IMPLIES:
        case LESS_EQ:
        case NOT_EQUAL:
        case SHL:
        case SHR:
        case OR:
        case BIT_OR:
        case BIT_AND_ASSIGN:
        case BIT_OR_ASSIGN:
        case BIT_XOR_ASSIGN:
        case MINUS_ASSIGN:
        case MULT_ASSIGN:
        case MOD_ASSIGN:
        case PLUS_ASSIGN:
        case SHL_ASSIGN:
        case SHR_ASSIGN:
        case WHILE:  // as part of do{} while();
            pre_space = true;
        case BIT_NOT:
            switch (prev_t) {
                case BIT_XOR:
                case BIT_OR:
                case AMP:
                    pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case DOT:
            switch (prev_t) {
                case COMMA:
                    pre_space = true;
                case LBRACE:
                    pre_space = state.scope_depth == 1;
                default:
                    break;
            }
        case AT_IDENT:
            switch (prev_t) {
                case AT_IDENT:  // attributes @foo @bar("")
                case RPAREN:  // fn sig(int) @foo
                    pre_space = true;
                default:
                    nextcase TOP: IDENT;
            }
        case CT_IDENT:
        case CONST_IDENT:
        case IDENT:
            switch (prev_t) {
                case TYPE_IDENT:
                case RBRACKET:
                case CONST_IDENT:
                case CT_TYPE_IDENT:
                case AT_IDENT:
                case IDENT:
                    pre_space = true;
                case STAR:
                case RPAREN:
                case AMP:  // likely &var
                    // if (t.type == AT_IDENT) pre_space = true;
                    if (self._resolve__prev_is_binexp()) pre_space = true;
                    break;
                default:
                    nextcase TOP: default;
            }
        case TYPE_IDENT:
            switch (prev_t) {
                case AMP:  // likely &Type.foo
                    if (self._resolve__prev_is_binexp()) pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case ELLIPSIS:
            switch (prev_t) {
                case TYPE_IDENT:
                case CT_TYPE_IDENT:
                case COMMA:
                    pre_space = true;
                default:
                    break;
            }
        case AMP:  // &
        case MINUS:
        case PLUS:
        case AND:
            switch (prev_t) {
                case LPAREN:
                case LBRACKET:
                    break;
                case RPAREN:
                    // distinguish casting and regular expression
                    if (self._resolve__prev_is_binexp()) pre_space = true;
                    break;
                default:
                    pre_space = true;
            }
        case STAR:  // *
            switch (prev_t) {
                case LPAREN:
                case TYPE_IDENT:
                case CT_TYPE_IDENT:
                case STAR:
                case LBRACKET:
                case RGENPAR:
                case RVEC:
                case BANG:
                    break;
                case RPAREN:
                case RBRACKET:
                    if (self._resolve__prev_is_binexp()) pre_space = true;
                default:
                    pre_space = cache_len > 0;
            }
        case LVEC:
        case RVEC:
        case LGENPAR:
        case RGENPAR:
            // No space for vectors and generic type
            break;
        case LBRACKET:
            switch (prev_t) {
                case LBRACE:
                case COMMA:
                    pre_space = true;
                default:
                    break;
            }
        case RBRACKET:
            switch (prev_t) {
                // pre_space = true;
                case QUESTION:
                default:
                    break;
            }
        case BIT_XOR:
            switch (prev_t) {
                case LBRACKET:
                case COLON:
                case DOTDOT:
                    break;
                default:
                    pre_space = true;

            }
        case LPAREN:
            switch (prev_t) {
                case AMP:
                case STAR:
                    if (self._resolve__prev_is_binexp()) pre_space = true;
                case IDENT:
                case AT_IDENT:
                case CT_IDENT:
                case CT_TYPE_IDENT:
                case RPAREN:
                case RGENPAR:
                case RVEC:
                case LPAREN:
                    break;
                case LBRACE:
                    pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case RPAREN:
            break;
        case RBRACE:
            // array related brace
            switch (prev_t) {
                case LBRACE:
                    // empty {}
                    break;
                default:
                    pre_space = state.scope_depth == 0;
            }
            break;
        case LBRACE:
            switch (prev_t) {
                case RGENPAR:
                case RVEC:
                    // List(<Foo>){}.init(...)
                    break;
                case COMMA:
                    pre_space = true;
                default:
                    nextcase TOP: default;
            }
        case EOS:
            switch (prev_t) {
                case LPAREN:
                case EOS:
                    break;
                default:
                    break;
            }
        case DOTDOT:
            switch (prev_t) {
                case LBRACKET:
                    break;
                default:
                    if (state.prev_scope(1) == LBRACKET) {
                        pre_space = self._resolve__bracket_is_complex_expr();
                    } else {
                        pre_space = false;
                    }
            }
        case COLON:
            if (state.prev_scope(1) == LBRACKET) {
                pre_space = self._resolve__bracket_is_complex_expr();
                break;  // break switch
            }
            switch (prev_t) {
                case CONST_IDENT:
                    pre_space = !self._resolve__const_label();
                case BITSTRUCT:
                case ENUM:
                case STRUCT:
                case UNION:
                    nextcase TOP: default;
                case LBRACKET:
                    break;
                case IDENT:
                    if (state.initial_token == FOREACH && state.scope_depth == 1) {
                        pre_space = true;
                    } else if (!self._resolve__keyword_call_colon(state)) {
                        pre_space = true;
                    } else if (state.initial_token == BITSTRUCT) {
                        pre_space = true;
                    }
                default:
                    if (state.prev_scope(1) == LBRACKET) {

                    } else {
                        pre_space = true;
                    }
            }
        case QUESTION:
            // HACK: it's impossible to distinguish err?; and err ? foo : bar;
            // we'll try to resolve it by forward looking hack in dump func()
            break;
        case BANG:
            switch (prev_t) {
                case TYPE_IDENT:
                case CT_TYPE_IDENT:
                case RVEC:
                case RGENPAR:
                case STAR:
                case GREATER:  // new generic syntax Foo<[bar]>
                case QUESTION:
                    break;  // no space
                default:
                    nextcase TOP: default;
            }
        default:
            if (self._resolve_default_space(state, t)) pre_space = true;
    }

    return pre_space;
}

<*
 Check if previous token type requires a space after it (in general case)
*>
macro bool CodeFmt._resolve_default_space(&self, NodeParserState* state, Token* t) @private
{
    switch (state.last_token) {
        case QUESTION:
            switch (state.current_token) {
                case EOS:
                case RPAREN:
                    return false;  // no space
                default:
                    return true;
            }
            break;
            // resolving ambiguity between &, *, &&, -, +
        case BIT_XOR:
        case AND:
        case AMP:
        case STAR:
        case MINUS:
        case PLUS:
            return self._resolve__prev_is_binexp();
        case LBRACE:
            return state.scope_depth <= 1 || t.type == LBRACE;
        case BANG:
            return self._resolve__prev_bang_type();
        case LBRACKET:
            // no space after bracket
            return false;
        case DOTDOT:
            if (state.prev_scope(1) == LBRACKET) {
                return self._resolve__bracket_is_complex_expr();
            } else {
                return false;
            }
        case COLON:
            if (state.prev_scope(1) == LBRACKET) {
                return self._resolve__bracket_is_complex_expr();
            } else {
                return true;
            }
        case DIV:
        case GREATER:
        case LESS:
        case MOD:
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
        case OR:
        case BIT_OR:
        case RETURN:
        case EOS:
        case IDENT:
        case TYPE_IDENT:
        case CT_IDENT:
        case CT_TYPE_IDENT:
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
        case TYPEID:
        case DISTINCT:
        case BREAK:
        case CONTINUE:
        case RVEC:
        case RGENPAR:
        case TRY:
        case FN:
        case IF:
        case FOR:
        case FOREACH:
        case DEFER:
        case DEF:
        case CONST:
        case TLOCAL:
        case STATIC:
        case EXTERN:
        case MODULE:
        case DO:
        case IMPORT:
        case COMMENT_MULTI_INLINE:
        case STRUCT:
        case ENUM:
        case UNION:
        case BITSTRUCT:
        case INTERFACE:
            return true;
        default:
            break;
    }
    return false;
}

<*
 Resolves if colon belongs to call(kwarg: 0) or foreach(f : some) 
*>
fn bool CodeFmt._resolve__keyword_call_colon(&self, NodeParserState* state) @private
{
    assert(state.current_token == COLON);
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    // only 1 token, it's not a binary exp
    if (self.__token_cache.len() - start_len == 1) return false;

    bool is_call_kwarg = true;

    for LOOP: (usz i = self.__token_cache.len(); i-- > start_len;) {
        Token* t = &self.__token_cache[i];
        switch (t.type) {
            case IDENT:
            case SPACE:
                break;
            case COMMA:
            case LPAREN:
                break LOOP;
            default:
                is_call_kwarg = false;
                break LOOP;
        }
    }
    return is_call_kwarg;
}

<*
 Resolves if array access bracket contain expression [a:b] vs [a + 1 : b - 1]
*>
fn bool CodeFmt._resolve__bracket_is_complex_expr(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    // only 1 token, it's not a binary exp
    if (self.__token_cache.len() - start_len == 1) return false;

    int exp_count = 0;

    for LOOP: (usz i = self.__token_cache.len(); i-- > start_len;) {
        Token* t = &self.__token_cache[i];
        switch (t.type) {
            case BIT_XOR:  // [^1]
            case SPACE:
            case COLON:
            case DOTDOT:
                break;
            case LBRACKET:
                break LOOP;
            default:
                exp_count++;
        }

        if (exp_count > 1) break LOOP;
    }
    return exp_count > 1;
}

<*
 resolve  bool! c vs if(!foo)
*>
fn bool CodeFmt._resolve__prev_bang_type(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;

    if (self.__token_cache.len() - start_len < 2) return false;

    assert(self.__token_cache[^1].type == BANG);

    Token* t = &self.__token_cache[^2];

    switch (t.type) {
        case CT_TYPE_IDENT:
        case TYPE_IDENT:
        case RVEC:
        case RGENPAR:
        case STAR:
        case GREATER:  // new generic notation ]>
            return true;
        default:
            return false;
    }
}

<*
 nextcase CONST: label vs ? test.CONST : ternary
*>
fn bool CodeFmt._resolve__const_label(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    if (self.__token_cache.len() - start_len < 3) return false;

    for LOOP: (usz i = self.__token_cache.len(); i-- > start_len;) {
        Token* t = &self.__token_cache[i];

        switch (t.type) {
            case SPACE:
            case CONST_IDENT:
            case COLON:
                break;
            case IF:
            case BREAK:
            case CONTINUE:
            case SWITCH:
            case FOR:
            case WHILE:
            case NEXTCASE:
                return true;
            default:
                return false;
        }
    }
    return false;
}

<*
 Resolves ambiguity conflict for casting (void)&some and expression (1 | 2) & some
*>
fn bool CodeFmt._resolve__prev_is_binexp(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;
    // only 1 token, it's not a binary exp
    if (self.__token_cache.len() - start_len == 1) return false;

    int scope = 0;
    int exp_count = 0;
    bool has_parens = false;
    bool has_brackets = false;
    bool has_type = false;
    bool has_idents = false;
    bool has_expr = false;

    TokenType rhs_token = INVALID_TOKEN;

    // NOTE: looping backwards
    for LOOP: (usz i = self.__token_cache.len(); i-- > start_len;) {
        Token* t = &self.__token_cache[i];
        switch (t.type) {
            case LBRACKET:
                scope--;
                if (scope < 0) {
                    // breaks when we are inside array access expression
                    // arr[
                    // arr[1:|
                    break LOOP;
                }
            case RBRACKET:
                scope++;
                has_brackets = true;
            case RPAREN:
                has_parens = true;
                scope++;
                switch (rhs_token) {
                    case BIT_XOR:
                        return true;
                    default:
                        break;
                }
            case LPAREN:
                scope--;
                if (scope <= 0) {
                    break LOOP;
                }
            case STAR:
                if (rhs_token == STAR) break;  // double pointer
                nextcase;
            case BIT_XOR:
            case PLUS:
            case MINUS:
            case AMP:
            case AND:  // logical && or &&1
                has_expr = true;
                switch (rhs_token) {
                    case PLUS:
                    case MINUS:
                    case AMP:
                    case STAR:
                        return false;
                    default:
                        break;
                }
                break;
            case SPACE:
            case BANG:  // if(!*
                break;
            case QUESTION:  // for ternary
                if (scope == 0) break LOOP;
                has_expr = true;
            case INTEGER:
            case IDENT:
            case HASH_IDENT:
                // is a binary expression sign
                // ident &
                // ident *
                // ident ^
                // ident + foo
                // ident - foo
                // indent[i]
                switch (rhs_token) {
                    case PLUS:
                    case MINUS:
                    case AMP:
                    case STAR:
                    case BIT_XOR:
                    case LBRACKET:
                        return true;
                    default:
                        break;
                }
                has_idents = true;
            case TYPE_IDENT:
            case CT_TYPE_IDENT:
            case CT_TYPEOF:
                has_type = true;
            case LVEC:
            case RVEC:
            case LGENPAR:
            case RGENPAR:
                has_brackets = true;
            case BIT_AND_ASSIGN:
            case BIT_OR_ASSIGN:
            case BIT_XOR_ASSIGN:
            case MINUS_ASSIGN:
            case MULT_ASSIGN:
            case MOD_ASSIGN:
            case PLUS_ASSIGN:
            case SHL_ASSIGN:
            case SHR_ASSIGN:
            case IMPLIES:
            case EQ:
            case RETURN:
            case DEFER:
            case TRY:
            case CATCH:
            case COLON:  // for ternary / foreach / array slice
            case ELVIS:  // for ternary
            case DOTDOT:  // for array slice
            case COMMENT_MULTI:
            case COMMENT_MULTI_INLINE:
            case COMMENT_SINGLE:
            case COMMENT_SINGLE_INLINE:
            case EOS:
                // assignment operator reached
                break LOOP;
            case COMMA:
                if (scope == 0) break LOOP;
                return true;  // call(a, b, <-) |
            case EQEQ:
            case GREATER_EQ:
            case LESS_EQ:
            case NOT_EQUAL:
            case GREATER:
            case LESS:
                break LOOP;
            default:
                return true;
        }

        if (t.type != SPACE) rhs_token = t.type;
    }

    bool is_cast = {|
        if (has_parens) {
            // simple cast (void*)
            // generic cast (Foo(<void>)*) / array cast (char[8]*)
            if (has_type) {
                // return !has_idents || has_brackets;
                return true;
            } else {
                return false;
            }
        } else if (scope <= 0) {
            // maybe incomplete cast or fn argument
            // (char[8]   | ?
            // (char[8]   |* ?
            // (char[8]*  |) ?
            // (char[8]*  |param ?
            if (has_type && has_brackets) {
                if (has_idents && !has_expr) return true;
            }
        }

        if (!has_parens && !has_type && !has_brackets && !has_idents) return true;
        // not a cast
        return false;
    |};
    return !is_cast;
}

<*
 Distinguish if next (.code.) block is a function call with more than 1 argument
*>
fn usz CodeFmt._resolve__next_is_cast_and_dump(&self, usz current_idx) @private
{
    NodeParserState tmpstate = NodeParserState {};

    bool is_cast = true;
    bool has_type = false;
    usz cast_end = current_idx;
    for (usz i = current_idx; i < self.__token_cache.len(); i++) {
        Token* t = &self.__token_cache[i];
        tmpstate.check(t);
        if (i == current_idx) {
            assert(t.type == LPAREN);
            assert(tmpstate.scope_depth == 1);
        }

        switch (t.type) {
            // These are allowed in casts
            case TYPE_IDENT:
            case CT_TYPE_IDENT:
            case CT_TYPEOF:
                has_type = true;
            case IDENT:
            case STAR:
            case AMP:
            case LPAREN:
            case RPAREN:
            case LVEC:
            case RVEC:
            case LGENPAR:
            case RGENPAR:
                break;
            default:
                is_cast = false;
        }

        // Looping until next closing paren
        if (tmpstate.scope_depth == 0) {
            cast_end = i;
            break;
        }

    }
    if (is_cast && has_type) {
        // cast must have at least one type
        for (usz i = current_idx; i <= cast_end; i++) {
            Token* t = &self.__token_cache[i];
            self.write("%s", t.value);
        }
        return cast_end + 1;
    } else {
        // Not a cast, wrap as usual
        return current_idx;
    }
}

<*
 Distinguish if previous (.code.) block is a function call or type cast
*>
fn bool CodeFmt._resolve__prev_is_cast(&self) @private
{
    assert(self.state_stack.len() > 0);

    usz start_len = self.state_stack[^1].token_cache_start;

    int scope = 0;
    bool is_cast = true;
    bool has_type = false;

    for LOOP: (usz i = self.__token_cache.len(); i-- > start_len;) {
        Token* t = &self.__token_cache[i];
        switch (t.type) {
            case RPAREN:
                scope++;
            case LPAREN:
                scope--;
                if (scope == 0) {
                    if (i > 0) {
                        if (self.__token_cache[i - 1].type == CT_TYPEOF) has_type = true;
                    }
                    break LOOP;
                }
                // These are allowed in casts
            case TYPE_IDENT:
            case CT_TYPE_IDENT:
            case CT_TYPEOF:
                has_type = true;
            case IDENT:
            case STAR:
            case AMP:
            case LVEC:
            case RVEC:
            case LGENPAR:
            case RGENPAR:
            case LBRACKET:
            case RBRACKET:
            case QUESTION:
            case INTEGER:
                break;
            default:
                is_cast = false;
        }
    }
    return is_cast && has_type;
}

<*
 Checks next token type in token cache
*>
fn TokenType CodeFmt._resolve__next_token(&self, usz current_idx) @private
{
    TokenType result = INVALID_TOKEN;
    while (++current_idx < self.__token_cache.len()) {
        result = self.__token_cache[current_idx].type;
        if (result != SPACE) break;
    }
    return result;
}

<*
 Checks if we need a white space before ?
*>
fn bool CodeFmt._resolve__next_question_is_error(&self, usz current_idx) @private
{
    // Resolves ambiguity
    // foo ? bar : baz;
    // return foo?;
    // foo ?? ERR?!;
    // a = foo ? !bar : baz;
    switch (self._resolve__next_token(current_idx)) {
        case EOS:
        case RPAREN:
        case COLON:
        case QUESTQUEST:
        case RBRACKET:
        case RVEC:
        case RGENPAR:
        case INVALID_TOKEN:
            return false;
        case BANG:
            // ?!;
            // return false;
            // self.write("%s", self._resolve__next_token(current_idx + 2));
            if (self._resolve__next_token(current_idx + 2) == EOS) return false;
            if (self._resolve__next_token(current_idx + 1) == EOS) return false;
        default:
            break;
    }
    return true;
}
