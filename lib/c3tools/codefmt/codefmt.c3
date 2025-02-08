module c3tools::codefmt;
import c3tools::ast::lexer;
import c3tools::ast;
import std::io;
import std::collections::list;

<*
 Code Formatter Object
*>
struct CodeFmt
{
    Lexer _lexer;
    DString buf;
    List(<CodeFmtState>) state_stack;
    List(<Token>) __token_cache;
    char indent_type;
    usz max_line_width;
    usz _indent_level;
    usz _line_used;
    bool _print_lex;
    bool _is_paused;
    bool _is_empty_line;
    bool _is_inline_comment;
    bool _is_cascade_call;
    bool _skip_next_new_line;
}

<*
 CodeFmt processing function signature
*>
def CodeFmtFn = fn bool! (CodeFmt* self, Token* t, NodeParserState* state) @private;

<*
 Item for code formatting state stack
*>
struct CodeFmtState @private
{
    CodeFmtFn state_fn;
    NodeParserState state;
    usz token_cache_start;
}

<* Simple white space synthetic token *>
const Token TOKEN_SPACE @private = Token { .type = SPACE, .value = " " };

/*
*                  CODE FORMATTER OBJECT
*/

<*
 Code formatter constructor

 @require max_line_width >= 80 : "too short"
 @require max_line_width <= 120 : "too long"
*>
fn CodeFmt CodeFmt.new_init(int max_line_width = 80, char indent_type = '4') @operator(construct)
{
    CodeFmt self = {
        .max_line_width = max_line_width,
        .indent_type = indent_type,
    };
    self.buf.new_init();
    self.state_stack.new_init();
    self.__token_cache.new_init();
    return self;
}

<*
 Code formatter destructor
*>
fn void CodeFmt.free(&self)
{
    self.buf.free();
    self.state_stack.free();
    self.__token_cache.free();
    *self = {};
}

<*
 Formats code chunk and return str view of internal buffer. 

 NOTE: result will live until next CodeFmt.format() or CodeFmt.free() call 
*>
fn String! CodeFmt.format(&self, String contents, bool print_lex = false)
{
    switch (self.indent_type) {
        case '2':
        case '4':
        case '8':
        case 't':
            break;
        default:
            io::eprintfn("Invalid separator value: expected 2,4,8 or t");
            return IoError.GENERAL_ERROR?;
    }

    self._print_lex = print_lex;
    self.buf.clear();
    self.state_stack.clear();

    lexer::init(&self._lexer, contents);
    self._lexer.set_whitespace_mode(false);

    // Default scope formatter
    self.push_run_state(&CodeFmt.format_global_file_scope, null)!;
    self._is_empty_line = true;

    NodeParserState globalstate;
    while LOOP: (self._lexer.next_token()) {
        Token* t = &self._lexer.token;
        globalstate.check(t);
        if (print_lex) t.print(new_line: true);

        switch (t.type) {
            case COMMENT_SINGLE:
            case COMMENT_MULTI:
            case COMMENT_SINGLE_INLINE:
            case COMMENT_MULTI_INLINE:
            case EMPTY_LINE:  // disallow EMPTY_LINE inside existing statements!
            case EOF:
                if (self.format_comment_or_empty(&globalstate, t)!) continue LOOP;
            case SPACE:
            default:
                break;
        }

        self._is_cascade_call = false;
        if (t.type != SPACE && self.run_state(t)!) {
            self.pop_state()!;

            // Ending one state, may trigger cascade parent exit
            self._is_cascade_call = true;
            if (self.run_state(t)!) {
                self.pop_state()!;
            }
        }
        self._is_empty_line = false;

        if (self._lexer.is_whitespace_mode && t.type != EOF) {
            // NOTE: Printing raw when // fmt: off
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

<*
 Pushes new state handler function to stack. Allows parsing sub-structs, etc...
*>
fn bool! CodeFmt.push_run_state(
    &self, CodeFmtFn new_state, Token* t, TokenType initial_token = INVALID_TOKEN
) @private
{
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
fn void! CodeFmt.pop_state(&self) @private
{
    assert(self.cache_statement_len() == 0, "cache_statement is not empty, forgot dump?");

    self.state_stack.remove_last();
}

<*
 Runs last state in the state_stack with current token
*>
fn bool! CodeFmt.run_state(&self, Token* t) @private
{
    if (self.state_stack.len() == 0) return false;
    CodeFmtFn state_fn = self.state_stack[^1].state_fn;
    bool result = state_fn(self, t, &self.state_stack[^1].state)!;
    return result;
}

<*
 Emits formatting procedure error with debug message
*>
macro bool! CodeFmt.@fail(&self, Token* t, String msg) @private
{
    if (t != null) {
        io::eprintfn("Patially formatted code:\n```\n%s```", self.buf.str_view());
        io::eprintfn("Error at line:%s - %s", self._lexer.current_row, msg);
        io::eprintfn(
            "    (%s:%d) at [Token: %s] line:col %d:%d",
            $$FILE,
            $$LINE,
            t.type,
            t.row,
            t.col,
        );
    } else {
        io::eprintfn("Error at line %s - %s", self._lexer.current_row, msg);
    }
    return IoError.GENERAL_ERROR?;
}

<*
 Debug logging (only when self._print_lex = true)
*>
macro CodeFmt.trace(&self, $msg, args...) @private
{
    if (!self._print_lex) return;

    io::eprintf("\t\t%s[#%s] (%s:%d): ", $$FUNC, self.state_stack.len(), $$FILE, $$LINE);
    io::eprintfn($msg, ...args);
}

<*
 Writes code chunk into internal buffer
*>
macro void CodeFmt.write(&self, String format, args...) @private
{
    if (self._lexer.is_whitespace_mode) return;
    if (self._is_inline_comment) {
        // Forcing a new line when previous write was a single line comment
        // if(foo) // comment  { <<<< oops this must be new line
        self.newline();
        format = format.trim_left();
    }

    usz len = self.buf.appendf(format, ...args)!!;
    self._line_used += (int)len;
}

<*
 Writes a new line into internal buffer with proper indentation
*>
macro void CodeFmt.newline(&self, bool is_empty = false, bool indent_only = false) @private
{
    if (self._skip_next_new_line) {
        self._skip_next_new_line = false;
        return;
    } else {
        self._skip_next_new_line = false;
    }

    self._is_inline_comment = false;

    if (self._lexer.is_whitespace_mode) return;

    if (!indent_only) self.buf.append("\n");

    if (!is_empty) {
        self._line_used = 0;
        for (int i = 0; i < self._indent_level; i++) {
            switch (self.indent_type) {
                case '2':
                    self.buf.append("  ");
                    self._line_used += 2;
                case '4':
                    self.buf.append("    ");
                    self._line_used += 4;
                case '8':
                    self.buf.append("        ");
                    self._line_used += 8;
                case 't':
                    self.buf.append("\t");
                    self._line_used += 4;
                default:
                    unreachable();
            }

        }
    }
}

<*
 Increase code indent
*>
macro void CodeFmt.indent(&self) @private
{
    self.trace("indent");
    self._indent_level++;
}

<*
 Decreases code indent
*>
macro void! CodeFmt.dedent(&self) @private
{
    self.trace("dedent");
    if (self._indent_level == 0) {
        self.@fail(&self._lexer.token, "indentation error")!;
    }
    self._indent_level--;
}
