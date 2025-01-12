module std::c3lang::ast;
import std::io;
import std::c3lang::lexer;
import std::collections::list;
import std::c3lang::common;


struct Ast {
    String path;
    AstModule* modules;
    allocator::DynamicArenaAllocator _allocator;
    Lexer lexer;
    struct _state {
        char* scope_begin;
        uint scope_len;
        char* stmt_begin;
        uint stmt_len;
    }
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
    String module_name;
    AstNode* attributes;
    AstNode* conditions;
    // List(<AstImport>) imports;
    // List(<AstType>) types;
    // List(<AstCallable>) callables;
    // AstDocString doc;
}

struct AstImport {
    inline AstNode node;
    String name;
    List(<String>) attributes;
}

struct AstType {
    inline AstNode node;
    AstDocString doc;
    String name;
    List(<String>) attributes;
}

struct AstDocString {
    inline AstNode node;
    String text;
    List(<AstDocContracts>) contracts;
}

struct AstDocContracts {
    inline AstNode node;
    String name;
    String value;
}

struct AstCallable {
    inline AstNode node;
    String name;
    String returns;
    AstDocString doc;
    List(<String>) attributes;
    List(<AstCallableParam>) params;
}

struct AstCallableParam {
    inline AstNode node;
    String name;
    String type;
}

def NodeParser = fn bool (Ast* ast, AstNode* node, Token* t);
fn bool parse_module(Ast* ast, AstNode* node, Token* t) 
{
    assert(node.type == TOKEN_MODULE);
    AstModule* m = (AstModule*)node;

    t.print();

    switch (t.type){
        case TOKEN_MODULE:
            // initial statement
	        mem::clear(&ast._state, $sizeof(ast._state));
            ast._state.scope_begin = t.value.ptr;
            m.module_name = "";
        case TOKEN_IDENT:
            if(!ast._state.stmt_begin) ast._state.stmt_begin = t.value.ptr;
            nextcase;
        case TOKEN_SCOPE:
            ast._state.stmt_len += t.value.len;
        case TOKEN_AT_IDENT:
            AstNode* attr = ast.@allc_add(AstNode, &m.attributes, t);

        case TOKEN_EOS:
            if (ast._state.stmt_begin) {
                uint stmt_len = ast._state.stmt_len;
                assert(stmt_len > 0 && stmt_len < 100);
                m.module_name = ast.@allc_str((String)ast._state.stmt_begin[..stmt_len-1]);
            }
            m.iend = t.offset + t.value.len;
            // t.print(new_line: true);
            return true;
        default:
            // t.print();
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

macro String Ast.@allc_str(&self, String s) @local {
    String result = s.copy(&self._allocator);
    return result;
}

fn Ast parse(String contents, String file_path) {
    Ast self;
    self._allocator.init(1024, allocator::heap());
    self.path = self.@allc_str(file_path);

	lexer::init(&self.lexer, contents);
	NodeParser node_fn = null;
	AstNode* node = null;

	while LOOP: (self.lexer.next_token()) {
		// io::printf("%s\n", t);
		if (!node_fn) {
		    switch(self.lexer.token.type) {
                case TOKEN_MODULE:
                    assert(node == null);
                    node_fn = &parse_module;
                    node = self.@allc_add(AstModule, &self.modules, &self.lexer.token); 
                default:
                    continue LOOP;
		    }
		}

		if(node_fn(&self, node, &self.lexer.token)) {
		    // Node was finished, scan next;
		    node_fn = null;
		    node = null;
		}
	}

    if (self.modules) {
        AstModule* last_mod = @node_last(self.modules); 
        last_mod.iend = self.lexer.token.offset - 1;
    }
	mem::clear(&self._state, $sizeof(self._state));
	return self;
}

fn void Ast.free(&self){
    self._allocator.free();
}
