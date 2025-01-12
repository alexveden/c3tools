module std::c3lang::ast;
import std::io;
import std::c3lang::lexer;
import std::collections::list;
import std::c3lang::common;


struct Ast {
    String path;
    List(<AstModule>) modules;
    Allocator allc;
}

struct AstNode {
    TokenType type;
    uint offset;
    uint len;
}


struct AstModule {
    inline AstNode node;
    String module_name;
    List(<String>) attributes;
    List(<String>) conditions;
    List(<AstImport>) imports;
    List(<AstType>) types;
    List(<AstCallable>) callables;
    AstDocString doc;
}

struct AstImport {
    inline AstNode node;
    TokenType type;
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
fn bool parse_module(Ast* ast, AstNode* node, Token* t) {
    
    if (t.type == TOKEN_EOS){
        t.print(new_line: true);
        return true;
    }
    t.print();
    return false;
}

fn Ast* parse(String contents, String file_path, Allocator allc = allocator::heap()) {
    @pool(allc) {
        Ast* self = mem::calloc(Ast.sizeof);
        assert(self);
        self.allc = allc;
        self.path = file_path;

	    Lexer lexer = lexer::new_init(contents);
	    NodeParser node_fn = null;
	    AstNode* node = null;

	    while LOOP: (lexer.next_token()) {
		    Token t = Token {
		    	.type = lexer.token_type, 
		    	.value = lexer.data.string, 
		    	.row = lexer.tok_span.row,
		    	.col = lexer.tok_span.col,
		    	.offset = (usz)(lexer.lexing_start - lexer.file_begin), 
		    };

		    // io::printf("%s\n", t);
		    if (!node_fn) {
		        switch(t.type) {
                    case TOKEN_MODULE:
                        assert(node == null);
                        node_fn = &parse_module;
                        node = mem::calloc(AstModule.sizeof);
                    default:
                        continue LOOP;
		        }
		    }

		    if(node_fn(self, node, &t)) {
		        // Node was finished, scan next;
		        node_fn = null;
		        node = null;
		    }


	    }
	    return self;
	};
}
