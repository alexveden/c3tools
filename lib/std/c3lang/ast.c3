module std::c3lang::ast;
import std::io;
import std::c3lang::lexer;
import std::collections::list;


struct Ast {
    String path;
    AstModule* modules;
    allocator::DynamicArenaAllocator _allocator;
    Lexer lexer;
    void* state;
}

struct AstNode {
    TokenType type;
    uint istart;
    uint iend;
    AstNode* next;
    String value;
}

struct AstModule {
    inline AstNode node;
    AstNode* name;
    AstNode* attributes;
    AstNode* imports;
    AstNode* decls;
    // AstCallable* callables;
    // List(<AstImport>) imports;
    // List(<AstType>) types;
    // AstDocString doc;
}
struct AstCallable {
    inline AstNode node;
    AstNode* name;
    AstNode* ret_type;
    AstCallableParam* params;
    AstNode* attributes;
}
struct AstCallableParam {
    inline AstNode node;
    AstNode* param_type;
    String param_name;
}

struct AstImport {
    inline AstNode node;
    AstNode* import_name;
    AstNode* attributes;
}

//
//                 PARSER STATE
//
def NodeParser = fn bool (Ast* ast, AstNode* node, Token* t);
struct NodeParserState @private {
    TokenType current_state;
    TokenType last_state;
    AstNode** sub_node;
    uint scope_depth;
    TokenType[32] scope_stack;
}
macro NodeParserState.check_scope(&self, TokenType t) {

    switch(t){
        //
        //  Entering new scope
        //  
        case LBRACE:           // {
        case LBRACKET:         // [
        case LPAREN:           // (
        case LBRAPIPE:         // {|
        case LGENPAR:          // (<
        case LVEC:             // [<
            if (self.scope_depth >= self.scope_stack.len) return;
            self.scope_stack[self.scope_depth] = t;
            self.scope_depth++;
        //
        //  Exiting scope
        //  
        case RBRACE:           // }
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRACE) nextcase EOF;
        case RBRACKET:         // ]
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRACKET) nextcase EOF;
        case RPAREN:           // )
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LPAREN) nextcase EOF;
        case RBRAPIPE:         // |}
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRAPIPE) nextcase EOF;
        case RGENPAR:          // >)
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LGENPAR) nextcase EOF;
        case RVEC:             // >)
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LVEC) nextcase EOF;
        case EOF:             
            // synthetic action to unscope stack
            if (self.scope_depth == 0) nextcase default;
            self.scope_stack[self.scope_depth-1] = INVALID_TOKEN;
            self.scope_depth--;
        default:
            break;
    }

}

macro TokenType NodeParserState.check(&self, Token* t) {
    assert(self.current_state != INVALID_TOKEN, "missing initialization?");
    self.last_state = self.current_state;
    self.check_scope(t.type);
    return self.current_state;
}
macro void NodeParserState.transition(&self, TokenType new_state) {
    self.current_state = new_state;
}
macro bool NodeParserState.next(&self) {
    if(self.current_state != self.last_state) {
        self.last_state = self.current_state;
        return true;
    } else {
        return false;
    }
}


fn bool parse_module(Ast* ast, AstNode* node, Token* t) 
{
    assert(node.type == MODULE);
    AstModule* m = (AstModule*)node;

    NodeParserState* state = ast.state;
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(MODULE);
    }

    switch (state.check(t)){
        case MODULE:
            state.transition(IDENT);  // expecting module identifiers
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &m.name, t);
                case SCOPE:
                    break; // skipping ::
                case AT_IDENT:
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.@allc_add(AstNode, &m.attributes, t);
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;

        case EOS:
            m.iend = t.offset + t.value.len;
            return true;
        default:
            break;
    }

    return false;
}

fn bool parse_function(Ast* ast, AstNode* node, Token* t) 
{
    assert(node.type == FN);
    AstCallable* node_func = (AstCallable*)node;

    NodeParserState* state = ast.state;
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(FN);
    }

    switch (state.check(t)){
        case FN:
            // function starts with return type definition
            state.transition(RETURN);
        case RETURN:
            // function return type
            // breakpoint();
            switch(t.type) {
                case IDENT:
                    // function name, make a transition if no scope and ret_type is set
                    if (state.scope_depth == 0 && node_func.ret_type) state.transition(IDENT);
                default:
                    ast.@allc_add(AstNode, &node_func.ret_type, t);
            }
            if(state.next()) nextcase state.current_state;
        case IDENT:
            // function name 
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &node_func.name, t);
                case TYPE_IDENT:
                    // struct based functions may contain TypeName.func_name
                    ast.@allc_add(AstNode, &node_func.name, t);
                case LPAREN:
                    if(state.scope_depth == 1) state.transition(VAR);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case VAR:
            // Defining function arguments
            AstCallableParam* current_param = state.sub_node ? (AstCallableParam*)*state.sub_node : null;
            
            switch(t.type) {
                case LPAREN:
                    // opening '(' or a part of type definition
                    if (state.scope_depth != 1) nextcase default;
                case COMMA:
                    // next parameter
                    if (state.scope_depth == 1) {
                        // Next parameter definition
                        current_param = (AstCallableParam*)ast.@allc_add(AstCallableParam, &node_func.params, &ast.lexer.token); 
                        current_param.param_name = "";
                        state.sub_node = &node;
                    } else {
                        nextcase default;
                    }
                case RPAREN:
                    // Done with parameters, looking for AT_IDENT or SCOPE
                    if (state.scope_depth == 0) {
                        state.transition(AT_IDENT);
                        state.sub_node = null;
                    } else {
                        nextcase default;
                    }
                case COMMENT_SINGLE_INLINE:
                case COMMENT_SINGLE:
                case COMMENT_MULTI:
                case EMPTY_LINE:
                case COMMENT_MULTI_INLINE:
                    break;
                default:
                    if (state.sub_node == null) {
                        current_param = (AstCallableParam*)ast.@allc_add(AstCallableParam, &node_func.params, &ast.lexer.token); 
                        current_param.param_name = "";
                        state.sub_node = &current_param;
                    }
                    if (state.scope_depth == 1 && t.type == IDENT) {
                        if (!current_param.param_name)
                        {
                            current_param.param_name = ast.@allc_str(t.value);
                        }
                    } else {
                        // all other goes to type
                        ast.@allc_add(AstNode, &current_param.param_type, t);
                    }
            }
            if(state.next()) nextcase state.current_state;

        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.@allc_add(AstNode, &node_func.attributes, t);
                case LBRACE:           // {
                    if (state.scope_depth == 1) state.transition(SCOPE);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case SCOPE:
            switch(t.type) {
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) state.transition(EOF);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case EOF:
            node_func.iend = t.offset;
            return true;
        default:
            unreachable();
    }

    return false;
}

//
//                 NODE MANAGEMENT
//

macro @node_last(self) @local 
{
    assert(self != null);
    $typeof(self) node = self;
    while(node.next) {
        node = ($typeof(self))node.next;            
    }
    return node;
}

macro AstNode* @node_add(AstNode** self, AstNode* new) @local 
{
    assert(self != null);

    if (*self == null) {
        ((AstNode*)*self) = new;
    } else {
        AstNode* node = @node_last(*self);
        node.next = new;
    }
    return new;
}

macro Ast.@allc_add(&self, $Type, AstNode** collection, lexer::Token* token) @local {
    $Type* result = self._allocator.acquire($Type.sizeof, NO_ZERO, $Type.alignof)!!;
    *result = {
        .type = token.type,
        .istart = token.offset,
        .iend = token.offset + token.value.len,
        .value = self.@allc_str(token.value),
    };
    return @node_add(collection,  result);
}

macro Ast.@node_join(self, node, DString out_str, String sep = ",")
{
    out_str.clear();
    $typeof(node) _node = node;
    while(_node) {
        out_str.append(_node.value);
        _node = ($typeof(node))_node.next;            
        if (_node) {
            out_str.append(sep);
        }
    }
    return out_str.str_view();
}
macro uint Ast.@node_len(self, node)
{
    uint len = 0;
    $typeof(node) _node = node;
    while(_node) {
        len++;
        _node = ($typeof(node))_node.next;            
    }
    return len;
}
macro Ast.@node_at(self, node, uint index)
{
    uint len = 0;
    $typeof(node) _node = node;
    while(_node) {
        if(len == index) return _node;
        len++;
        _node = ($typeof(node))_node.next;            
    }
    return _node;
}

macro String Ast.@allc_str(&self, String s) @local {
    String result = s.copy(&self._allocator);
    return result;
}

fn Ast parse(String contents, String file_path, bool print_lex = false) {
    Ast self;
    self._allocator.init(1024, allocator::heap());
    self.path = self.@allc_str(file_path);

	lexer::init(&self.lexer, contents);
	NodeParser node_fn = null;
	AstNode* node = null;
	AstModule* current_module = (AstModule*)self.@allc_add(AstModule, &self.modules, &self.lexer.token);

	const STATE_CAPACITY = 1024;
	self.state = mem::calloc(STATE_CAPACITY);
	assert(self.state);

	while LOOP: (self.lexer.next_token()) {
	    if (print_lex) self.lexer.token.print();

		if (!node_fn) {
		    switch(self.lexer.token.type) {
                case MODULE:
                    node_fn = &parse_module;
                    node = self.@allc_add(AstModule, &self.modules, &self.lexer.token); 
                    current_module = (AstModule*)node;
                case FN:
                    node_fn = &parse_function;
                    node = self.@allc_add(AstCallable, &current_module.decls, &self.lexer.token); 
                default:
                    continue LOOP;
		    }
		}

		if(node_fn(&self, node, &self.lexer.token)) {
		    // Node was finished, scan next;
		    node_fn = null;
		    node = null;
            mem::clear(self.state, STATE_CAPACITY);
		}
	}

    if (self.modules) {
        AstModule* last_mod = @node_last(self.modules); 
        last_mod.iend = self.lexer.token.offset - 1;
    }
	mem::free(self.state);
	self.state = null;
	return self;
}

fn void Ast.free(&self){
    self._allocator.free();
}
