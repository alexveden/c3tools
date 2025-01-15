module test::c3tools::ast @test;
import c3tools::ast @public;
import c3tools::lexer;
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
    test::equal(ast.@node_join(m.attributes, contents, ","), "@test,@if(env::NO_LIBC || $feature(C3_MATH))");
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
    test::equal(ast.@node_join(func.attributes, contents), "@test,@inline,@if(env::LIBC)");

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
    test::equal(ast.@node_join(imp.attributes, contents), "@test,@if(env::FOO)");

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

fn void test_func_default_params(){
   String code =  `module test::std::c3lang::ast;
fn void test_node(int a, int b = 2) @test @inline @if(env::LIBC) {
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
    test::equal(ast.@node_join(param.param_type, contents), "int,=,2");

    test::not_equal(func.attributes, null);
    test::equal(ast.@node_len(func.attributes), 3);
    test::equal(ast.@node_join(func.attributes, contents), "@test,@inline,@if(env::LIBC)");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_func_type_method(){
   String code =  `module test::std::c3lang::ast;
fn MyType* MyFoo.test_node(&self) {
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
    test::equal(ast.@node_join(func.name, contents), "MyFoo,test_node");
    test::equal(ast.@node_join(func.ret_type, contents), "MyType,*");

    test::equal(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "self");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}


fn void test_one_linefunc(){
   String code =  `module test::std::c3lang::ast;
fn char! String.to_uchar(s, int base = 10) @inline @test => s.@to_integer(char, base) @foo;
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
    test::equal(ast.@node_join(func.ret_type, contents), "char,!");
    test::equal(ast.@node_join(func.name, contents), "String,to_uchar");
    test::equal(ast.@node_join(func.attributes, contents), "@inline,@test");
    test::not_equal(func.params, null);

    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "s");
    test::equal(param.param_type.type, TokenType.TYPE_IDENT);
    test::equal(ast.@node_join(param.param_type, contents), "String");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "base");
    test::equal(ast.@node_join(param.param_type, contents), "int,=,10");


    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], ';');
}

fn void test_macro_type(){
   String code =  `module test::std::c3lang::ast;
macro MyFoo.@test_macro(self) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "MyFoo,@test_macro");

    test::equal(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "self");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_macro_type_with_ret_type(){
   String code =  `module test::std::c3lang::ast;
macro MyType(<$it>) MyFoo.@test_macro(self) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(ast.@node_join(func.ret_type, contents), "MyType,(<,$it,>)");
    test::equal(ast.@node_join(func.name, contents), "MyFoo,@test_macro");

    test::equal(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "self");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_macro_at_ident(){
   String code =  `module test::std::c3lang::ast;
macro @test_macro(self) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(func.ret_type, null);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "@test_macro");

    test::equal(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "self");
    test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "");

    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_macro_hash_argument(){
   String code =  `module test::std::c3lang::ast;
macro @test_macro(Type* #self, $bar) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(func.ret_type, null);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "@test_macro");

    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "#self");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "Type,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "$bar");
    test::equal(ast.@node_join(param.param_type, contents), "");


    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_ellipsis(){
   String code =  `module test::std::c3lang::ast;
macro @test_macro(double... a, ...args) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(func.ret_type, null);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "@test_macro");

    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "a");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "double,...");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "args");
    test::equal(ast.@node_join(param.param_type, contents), "...");


    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_macro_parameter_attributes(){
   String code =  `module test::std::c3lang::ast;
macro @test_macro(Type* #self @unused, $bar @export("foo") @ok) {
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

    test::equal(func.type, TokenType.MACRO);
    test::equal(func.ret_type, null);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "@test_macro");

    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "#self");
    // test::equal(param.param_type, null);
    test::equal(ast.@node_join(param.param_type, contents), "Type,*");
    test::equal(ast.@node_join(param.attributes, contents), "@unused");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "$bar");
    test::equal(ast.@node_join(param.param_type, contents), "");
    test::equal(ast.@node_join(param.attributes, contents), `@export("foo"),@ok`);


    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(func.iend, code.len-4);
    test::equal(code[func.iend], '}');
}

fn void test_macro_with_body_scope(){
   String code =  `module test::std::c3lang::ast;
macro @for_each(list; @body(it))
{
    for ($typeof(list) x = list; x; x = x.next)
    {
        @body(x);
    }
}//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.MACRO);
    test::equal(func.ret_type, null);
    test::equal(ast.@node_join(func.ret_type, contents), "");
    test::equal(ast.@node_join(func.name, contents), "@for_each");

    test::equal(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "list");
    test::equal(param.param_type, null);
    // test::equal(ast.@node_join(param.param_type, contents), "Type,*");
    // test::equal(ast.@node_join(param.attributes, contents), "@unused");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "@body");
    test::equal(ast.@node_join(param.param_type, contents), "(,it,)");
    test::equal(ast.@node_join(param.attributes, contents), "");


    io::printf("\n\n``%s``", code[func.istart..math::min((isz)func.iend, (isz)(code.len-1))]);
    test::equal(func.istart, 31);
    test::equal(code[func.iend], '}');
    test::equal(func.iend, code.len-3);
}

fn void test_enum_simple(){
   String code =  `module test::std::c3lang::ast;
enum Foo {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::not_equal(enum_type, null);

    test::equal(enum_type.type, TokenType.ENUM);
    test::equal(enum_type.value, "Foo");

    test::equal(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "FOO");

    io::printf("\n\n``%s``", code[enum_type.istart..math::min((isz)enum_type.iend, (isz)(code.len-1))]);
    test::equal(enum_type.istart, 31);
    test::equal(code[enum_type.iend], '}');
    test::equal(enum_type.iend, code.len-4);
}

fn void test_typed_enum_simple(){
   String code =  `module test::std::c3lang::ast;
enum Foo : int {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::not_equal(enum_type, null);

    test::equal(enum_type.type, TokenType.ENUM);
    test::equal(enum_type.value, "Foo");

    test::equal(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "FOO");

    io::printf("\n\n``%s``", code[enum_type.istart..math::min((isz)enum_type.iend, (isz)(code.len-1))]);
    test::equal(enum_type.istart, 31);
    test::equal(code[enum_type.iend], '}');
    test::equal(enum_type.iend, code.len-4);
}

fn void test_typed_enum_associated(){
   String code =  `module test::std::c3lang::ast;
enum Foo : int (String desc, bool active, Position pos) @test @if(env:FOO) {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::not_equal(enum_type, null);

    test::equal(enum_type.type, TokenType.ENUM);
    test::equal(enum_type.value, "Foo");
    test::equal(ast.@node_join(enum_type.attributes, contents), "@test,@if(env:FOO)");

    test::equal(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "FOO");

    io::printf("\n\n``%s``", code[enum_type.istart..math::min((isz)enum_type.iend, (isz)(code.len-1))]);
    test::equal(enum_type.istart, 31);
    test::equal(code[enum_type.iend], '}');
    test::equal(enum_type.iend, code.len-4);
}

fn void test_fault_type(){
   String code =  `module test::std::c3lang::ast;
fault SomeFault @local @if(env::FOO)
{
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::not_equal(enum_type, null);

    test::equal(enum_type.type, TokenType.FAULT);
    test::equal(enum_type.value, "SomeFault");

    test::equal(ast.@node_join(enum_type.attributes, contents), "@local,@if(env::FOO)");

    test::equal(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::equal(eval.type, TokenType.CONST_IDENT);
    test::equal(eval.value, "FOO");

    io::printf("\n\n``%s``", code[enum_type.istart..math::min((isz)enum_type.iend, (isz)(code.len-1))]);
    test::equal(enum_type.istart, 31);
    test::equal(code[enum_type.iend], '}');
    test::equal(enum_type.iend, code.len-4);
}

fn void test_interface_type(){
   String code =  `module test::std::c3lang::ast;
interface NodeI @local {
    fn bool foo(Ast* ast, AstNode* node, Token* t) @local;
    fn List(<int>) bar() @local;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefInterface* ifc_type = (AstTypeDefInterface*)ast.@node_at(m.decls, 0);
    test::not_equal(ifc_type, null);

    test::equal(ifc_type.type, TokenType.INTERFACE);
    test::equal(ifc_type.value, "NodeI");

    test::equal(ast.@node_join(ifc_type.attributes, contents), "@local");

    test::equal(ast.@node_len(ifc_type.functions), 2);

    AstCallable* func = (AstCallable*)ast.@node_at(ifc_type.functions, 0);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.ret_type, contents), "bool");
    test::equal(ast.@node_join(func.name, contents), "foo");
    test::equal(ast.@node_join(func.attributes, contents), "@local");

    test::equal(ast.@node_len(func.params), 3);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "ast");
    test::equal(ast.@node_join(param.param_type, contents), "Ast,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "node");
    test::equal(ast.@node_join(param.param_type, contents), "AstNode,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 2);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "t");
    test::equal(ast.@node_join(param.param_type, contents), "Token,*");



    func = (AstCallable*)ast.@node_at(ifc_type.functions, 1);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.ret_type, contents),`List,(<,int,>)` );
    test::equal(ast.@node_join(func.name, contents), "bar");
    test::equal(ast.@node_join(func.attributes, contents), "@local");

    test::equal(ast.@node_len(func.params), 0);

    io::printf("\n\n``%s``", code[ifc_type.istart..math::min((isz)ifc_type.iend, (isz)(code.len-1))]);
    test::equal(ifc_type.istart, 31);
    test::equal(code[ifc_type.iend], '}');
    test::equal(ifc_type.iend, code.len-4);
}

fn void test_interface_type_with_docs(){
   String code =  `module test::std::c3lang::ast;
interface NodeI @local {
    <* Doc string
    @param ast "some stuff"
    @requre {| return some; |}
    *>
    fn bool foo(Ast* ast, AstNode* node, Token* t) @local;
    <* another doc string *>
    fn List(<int>) bar() @local;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefInterface* ifc_type = (AstTypeDefInterface*)ast.@node_at(m.decls, 0);
    test::not_equal(ifc_type, null);

    test::equal(ifc_type.type, TokenType.INTERFACE);
    test::equal(ifc_type.value, "NodeI");

    test::equal(ast.@node_join(ifc_type.attributes, contents), "@local");

    test::equal(ast.@node_len(ifc_type.functions), 2);

    AstCallable* func = (AstCallable*)ast.@node_at(ifc_type.functions, 0);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.ret_type, contents), "bool");
    test::equal(ast.@node_join(func.name, contents), "foo");
    test::equal(ast.@node_join(func.attributes, contents), "@local");
    test::equal(ast.@node_join(func.docs, contents), "<* Doc string\n    ");

    test::equal(ast.@node_len(func.params), 3);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "ast");
    test::equal(ast.@node_join(param.param_type, contents), "Ast,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "node");
    test::equal(ast.@node_join(param.param_type, contents), "AstNode,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 2);
    test::equal(param.type, TokenType.VAR);
    test::equal(param.value, "t");
    test::equal(ast.@node_join(param.param_type, contents), "Token,*");



    func = (AstCallable*)ast.@node_at(ifc_type.functions, 1);
    test::not_equal(func, null);

    test::equal(func.type, TokenType.FN);
    test::equal(ast.@node_join(func.ret_type, contents),`List,(<,int,>)` );
    test::equal(ast.@node_join(func.name, contents), "bar");
    test::equal(ast.@node_join(func.attributes, contents), "@local");
    test::equal(ast.@node_join(func.docs, contents), "<* another doc string ");

    test::equal(ast.@node_len(func.params), 0);

    io::printf("\n\n``%s``", code[ifc_type.istart..math::min((isz)ifc_type.iend, (isz)(code.len-1))]);
    test::equal(ifc_type.istart, 31);
    test::equal(code[ifc_type.iend], '}');
    test::equal(ifc_type.iend, code.len-4);
}

fn void test_struct_typedef()
{
   String code =  `module test::std::c3lang::ast;
<* docs *>
struct MyStruct @local {
    int a;
    MyType b @test;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::not_equal(struct_type, null);

    test::equal(struct_type.type, TokenType.STRUCT);
    test::equal(struct_type.value, "MyStruct");

    test::equal(ast.@node_join(struct_type.attributes, contents), "@local");
    test::equal(ast.@node_join(struct_type.docs, contents), "<* docs ");

    test::equal(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "a");
    test::equal(ast.@node_join(member.field, contents), "int");
    test::equal(ast.@node_join(member.attributes, contents), "");
    test::equal(ast.@node_join(member.docs, contents), "");


    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "b");
    test::equal(ast.@node_join(member.field, contents), "MyType");
    test::equal(ast.@node_join(member.attributes, contents), "@test");
    test::equal(ast.@node_join(member.docs, contents), "");

    io::printf("\n\n``%s``", code[struct_type.istart..math::min((isz)struct_type.iend, (isz)(code.len-1))]);
    test::equal(struct_type.istart, 42);
    test::equal(code[struct_type.iend], '}');
    test::equal(struct_type.iend, code.len-4);
}


fn void test_struct_typedef_member_docs_ignored()
{
   String code =  `module test::std::c3lang::ast;
<* docs *>
struct MyStruct @local {
    <* some stuff *>
    int a;
    <* another doc *>
    List(<MyType>) b;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::not_equal(struct_type, null);

    test::equal(struct_type.type, TokenType.STRUCT);
    test::equal(struct_type.value, "MyStruct");

    test::equal(ast.@node_join(struct_type.attributes, contents), "@local");
    test::equal(ast.@node_join(struct_type.docs, contents), "<* docs ");

    test::equal(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "a");
    test::equal(ast.@node_join(member.field, contents), "int");
    test::equal(ast.@node_join(member.attributes, contents), "");
    test::equal(ast.@node_join(member.docs, contents), "");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "b");
    test::equal(ast.@node_join(member.field, contents), "List,(<,MyType,>)");
    test::equal(ast.@node_join(member.attributes, contents), "");
    test::equal(ast.@node_join(member.docs, contents), "");


    io::printf("\n\n``%s``", code[struct_type.istart..math::min((isz)struct_type.iend, (isz)(code.len-1))]);
    test::equal(struct_type.istart, 42);
    test::equal(code[struct_type.iend], '}');
    test::equal(struct_type.iend, code.len-4);
}

fn void test_struct_typedef_substructs()
{
   String code =  `module test::std::c3lang::ast;
struct MyStruct @local {
    struct my_sub @test {
        int x;
        int y;
        int z @test;
    }
    int b @test;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::not_equal(struct_type, null);

    test::equal(struct_type.type, TokenType.STRUCT);
    test::equal(struct_type.value, "MyStruct");

    test::equal(ast.@node_join(struct_type.attributes, contents), "@local");
    test::equal(ast.@node_join(struct_type.docs, contents), "");

    test::equal(ast.@node_len(struct_type.members), 2);
    // test::equal(ast.@node_join(struct_type.members, contents), ``);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.STRUCT);
    test::equal(member.value, "my_sub");
    test::equal(ast.@node_join(member.field, contents), ``);

    test::equal(ast.@node_join(member.attributes, contents), "@test");
    test::equal(ast.@node_join(member.docs, contents), ``);
    test::equal(ast.@node_len(member.members), 3);
    test::equal(ast.@node_join(member.members, contents), `x,y,z`);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "b");
    test::equal(ast.@node_join(member.field, contents), `int`);

    test::equal(ast.@node_join(member.attributes, contents), "@test");
    test::equal(ast.@node_join(member.docs, contents), ``);
    test::equal(ast.@node_len(member.members), 0);

    io::printf("\n\n``%s``", code[struct_type.istart..math::min((isz)struct_type.iend, (isz)(code.len-1))]);
    test::equal(struct_type.istart, 31);
    test::equal(code[struct_type.iend], '}');
    test::equal(struct_type.iend, code.len-4);
    
}

fn void test_struct_typedef_substructs_doc_strings_ignored()
{
   String code =  `module test::std::c3lang::ast;
<*doc1*>
struct MyStruct @local {
    <*doc2*>
    struct my_sub @test {
        <*doc3*>
        int x;
        int y;
        int z @test;
    }
    <*doc4*>
    int b @test;
}
//`; // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer ast.free();
    contents.clear();

    test::not_equal(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 1);
    test::not_equal(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::not_equal(struct_type, null);

    test::equal(struct_type.type, TokenType.STRUCT);
    test::equal(struct_type.value, "MyStruct");

    test::equal(ast.@node_join(struct_type.attributes, contents), "@local");
    test::equal(ast.@node_join(struct_type.docs, contents), "<*doc1");

    test::equal(ast.@node_len(struct_type.members), 2);
    // test::equal(ast.@node_join(struct_type.members, contents), ``);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.STRUCT);
    test::equal(member.value, "my_sub");
    test::equal(ast.@node_join(member.field, contents), ``);

    test::equal(ast.@node_join(member.attributes, contents), "@test");
    test::equal(ast.@node_join(member.docs, contents), ``);
    test::equal(ast.@node_len(member.members), 3);
    test::equal(ast.@node_join(member.members, contents), `x,y,z`);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::not_equal(member, null);
    test::equal(member.type, TokenType.TYPE_IDENT);
    test::equal(member.value, "b");
    test::equal(ast.@node_join(member.field, contents), `int`);

    test::equal(ast.@node_join(member.attributes, contents), "@test");
    test::equal(ast.@node_join(member.docs, contents), ``);
    test::equal(ast.@node_len(member.members), 0);

    io::printf("\n\n``%s``", code[struct_type.istart..math::min((isz)struct_type.iend, (isz)(code.len-1))]);
    test::equal(struct_type.istart, 40);
    test::equal(code[struct_type.iend], '}');
    test::equal(struct_type.iend, code.len-4);
}
