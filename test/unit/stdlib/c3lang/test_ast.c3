fn int far(int a , int b) {
    return a + b;
}

module test::std::c3lang::ast @test;
import std::c3lang::ast @public;
import std::c3lang::lexer;
import std::math;
import std::collections::list;
import std::io;


fn void test_module(){
   String code =  `module test::std::c3lang::ast  @test @if(env::NO_LIBC || $feature(C3_MATH));
import std::c3lang::ast;

fn void test_node() {
    return 1;
}
`;
    DString contents = dstring::temp_new(code);
    
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, print_lex: true);
    defer ast.free();
    contents.clear();


    test::equal(ast.path, "foo.c3");
    test::@check(path.ptr != ast.path.ptr, "should be copied");

    test::not_equal(ast.modules, null);
    test::equal(ast.@node_len(ast.modules), 2);
    test::equal(ast.@node_join(ast.modules, contents, ","), ",module");

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);
    
    test::equal(m.value, "module");
    test::equal(m.type, TokenType.MODULE);
    
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.istart, 0);
    test::equal(m.iend, code.len-1);

    test::not_equal(m.attributes, null);
    test::equal(m.attributes.value, "@test");
    test::equal(m.attributes.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(m.attributes, contents, ","), "@test,@if");
    test::equal(m.attributes.istart, 31);
    test::equal(m.attributes.iend, 31+5);

    // test::equal(0, 1);
}

fn void test_module_no_attr(){
   String code =  `module test::std::c3lang::ast;`;
    DString contents = dstring::temp_new(code);
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path);
    defer ast.free();
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.attributes, null);

    // test::equal(0, 1);
}



fn void test_scope(){
    NodeParserState state;
    TokenType t;

    t = TokenType.LBRACE;
    state.check_scope(t);
    test::equal(state.scope_depth, 1);
    test::equal(state.scope_stack[state.scope_depth-1], t);

    t = TokenType.LBRACKET;
    state.check_scope(t);
    test::equal(state.scope_depth, 2);
    test::equal(state.scope_stack[state.scope_depth-1], t);

    t = TokenType.LPAREN;
    state.check_scope(t);
    test::equal(state.scope_depth, 3);
    test::equal(state.scope_stack[state.scope_depth-1], t);

    t = TokenType.LBRAPIPE;
    state.check_scope(t);
    test::equal(state.scope_depth, 4);
    test::equal(state.scope_stack[state.scope_depth-1], t);

    t = TokenType.LGENPAR;
    state.check_scope(t);
    test::equal(state.scope_depth, 5);
    test::equal(state.scope_stack[state.scope_depth-1], t);

    t = TokenType.LVEC;
    state.check_scope(t);
    test::equal(state.scope_depth, 6);
    test::equal(state.scope_stack[state.scope_depth-1], t);
    
    // EXIT SCOPE in reverse order
    
    t = TokenType.RVEC;
    state.check_scope(t);
    test::equal(state.scope_depth, 5);

    t = TokenType.RGENPAR;
    state.check_scope(t);
    test::equal(state.scope_depth, 4);

    t = TokenType.RBRAPIPE;
    state.check_scope(t);
    test::equal(state.scope_depth, 3);

    t = TokenType.RPAREN;
    state.check_scope(t);
    test::equal(state.scope_depth, 2);

    t = TokenType.RBRACKET;
    state.check_scope(t);
    test::equal(state.scope_depth, 1);

    t = TokenType.RBRACE;
    state.check_scope(t);
    test::equal(state.scope_depth, 0);

    // This should be ignored
    t = TokenType.RBRACE;
    state.check_scope(t);
    test::equal(state.scope_depth, 0);

    foreach(tok: state.scope_stack) {
        // all old tokens set to zero
        test::equal(tok, TokenType.INVALID_TOKEN);
    }
}

fn void test_scope_oveflow_protection(){
    NodeParserState state;

    TokenType t = TokenType.LBRACE;

    for(uint i = 0; i < state.scope_stack.len * 2; i++){
        state.check_scope(t);
    }

    test::equal(state.scope_depth, state.scope_stack.len);
    test::equal(state.scope_stack[state.scope_depth-1], t);
}

fn void test_func(){
   String code =  `module test::std::c3lang::ast;
fn void test_node() {
    return 1;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(m, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.name, contents), "test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "void");
    test::equal(func.params, null);

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');

    test::greater(func.iscope_start, func.istart);
    test::equal(code[func.iscope_start], '{');
}

fn void test_func_generic_ret_type(){
   String code =  `module test::std::c3lang::ast;
fn List(<int>) test_node() {
    return 1;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(m, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.name, contents), "test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "List,(<,int,>)");
    test::equal(func.params, null);

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_func_vector_ret_type(){
   String code =  `module test::std::c3lang::ast;
fn int[<2>] test_node() {
    return 1;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(m, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.name, contents), "test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "int,[<,2,>]");
    test::equal(func.params, null);

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_func_struct_pointer_type(){
   String code =  `module test::std::c3lang::ast;
fn MyType* test_node() {
    return 1;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.name, contents), "test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "MyType,*");
    test::equal(func.params, null);

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_func_params(){
   String code =  `module test::std::c3lang::ast;
fn void test_node(int a, List(<int>) b) @test @inline @if(env::LIBC) {
    return 1;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(m, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.name, contents), "test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "void");

    test::not_equal(func.params, null);
    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "a");
    test::equal(ast.@node_join(param.param_type, contents), "int");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "b");
    test::equal(ast.@node_join(param.param_type, contents), "List,(<,int,>)");

    test::not_equal(func.attributes, null);
    test::equal(ast.@node_len(func.attributes), 3);
    test::equal(ast.@node_join(func.attributes, contents), "@test,@inline,@if");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_import(){
   String code =  `
   module test::std::c3lang::ast;
   import test::std::c3lang::ast::foo @test @if(env::FOO) ;
   import single_mod;
   `;
    DString contents = dstring::temp_new(code);
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path);
    defer ast.free();
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.attributes, null);

    test::not_equal(m.imports, null);
    test::equal(ast.@node_len(m.imports), 2);
    AstImport* imp;

    imp = ast.@node_at(m.imports, 0);
    test::equal(imp.type, TokenType.IMPORT);
    test::equal(imp.value, "import");
    test::equal(ast.@node_join(imp.name, contents, "::"), "test::std::c3lang::ast::foo");
    test::equal(ast.@node_join(imp.attributes, contents), "@test,@if");

    imp = ast.@node_at(m.imports, 1);
    test::equal(imp.type, TokenType.IMPORT);
    test::equal(imp.value, "import");
    test::equal(ast.@node_join(imp.name, contents, "::"), "single_mod");
    test::equal(ast.@node_join(imp.attributes, contents), "");

}


fn void test_docstring_module(){
   String code =  `
<* My module *>
module test::std::c3lang::ast;
   `;
    DString contents = dstring::temp_new(code);
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, true);
    defer ast.free();
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.attributes, null);

    test::not_equal(m.docs, null);
    test::equal(m.docs.value, "<* My module ");
    test::equal(m.docs.istart, 1);
    test::equal(code[m.docs.istart], '<');
    test::equal(code[m.docs.iend], '>');

    // test::equal(1, 0);
}

fn void test_docstring_module_func(){
   String code =  `
<* My module *>
module test::std::c3lang::ast;

<* My func *>
fn void test_node() {
    return 1;
}
   `;
    DString contents = dstring::temp_new(code);
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, true);
    defer ast.free();
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.attributes, null);

    test::not_equal(m.docs, null);
    test::@check(m.docs.value.contains("My module"));

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(func, null);
    test::not_equal(func.docs, null);

    test::@check(func.docs.value.contains("My func"));
}

fn void test_docstring_contracts(){
   String code =  `
<* 
My module 
@param foo "some info"
@test
@param [&inout] foo "some info"
@return "some stuff"
@return! Fault.SOME,IoError.ANOTHER 
@requre a > 0, a < d
*>
module test::std::c3lang::ast;
   `;
    DString contents = dstring::temp_new(code);
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, true);
    defer ast.free();
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::equal(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::equal(m.attributes, null);

    test::not_equal(m.docs, null);
    test::@check(m.docs.value.contains("My module"));

    test::not_equal(m.docs.contracts, null);
    test::equal(ast.@node_len(m.docs.contracts), 6);

    AstDocContract* contract;

    contract = ast.@node_at(m.docs.contracts, 0);
    test::equal(contract.value, "@param");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), `foo,"some info"`);

    contract = ast.@node_at(m.docs.contracts, 1);
    test::equal(contract.value, "@test");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), ``);

    contract = ast.@node_at(m.docs.contracts, 2);
    test::equal(contract.value, "@param");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), `foo,"some info"`);

    contract = ast.@node_at(m.docs.contracts, 3);
    test::equal(contract.value, "@return");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), `"some stuff"`);

    contract = ast.@node_at(m.docs.contracts, 4);
    test::equal(contract.value, "@return");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), `!,Fault,.,SOME,,,IoError,.,ANOTHER`);

    contract = ast.@node_at(m.docs.contracts, 5);
    test::equal(contract.value, "@requre");
    test::equal(contract.type, TokenType.AT_IDENT);
    test::equal(ast.@node_join(contract.items, contents), `a,>,0,,,a,<,d`);

}
