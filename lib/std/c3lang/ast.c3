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
}
struct AstImport {
    inline AstNode node;
    AstNode* attributes;
}


def NodeParser = fn bool (Ast* ast, AstNode* node, Token* t);
struct NodeParserState @local {
    TokenType current_state;
    TokenType last_state;
    AstNode** sub_node;
}
macro TokenType NodeParserState.check(&self) {
    assert(self.current_state != INVALID_TOKEN, "missing initialization?");
    self.last_state = self.current_state;
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

    switch (state.check()){
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

    switch (state.check()){
        case FN:
            state.transition(TYPE_IDENT);  // expecting module identifiers
        case TYPE_IDENT:
            switch(t.type) {
                case TYPE_IDENT:
                    ast.@allc_add(AstNode, &node_func.ret_type, t);
                case IDENT:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &node_func.name, t);
                case LPAREN:
                    // TODO: state.add_scope()
                    state.transition(t.type);
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case LPAREN:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &node_func.name, t);
                case LPAREN:
                    state.transition(t.type);
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;

        case EOS:
            node_func.iend = t.offset + t.value.len + 1;
            return true;
        default:
            break;
    }

    return false;
}


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
