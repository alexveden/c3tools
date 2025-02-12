module test::c3tools::ast @test;
import c3tools::ast @public;
import c3tools::ast::lexer;
import std::math;
import std::collections::list;
import std::io;

fn void test_module()
{
    String code = `module test::std::c3lang::ast  @test @if(env::NO_LIBC || $feature(C3_MATH));
import std::c3lang::ast;

fn void test_node() {
    return 1;
}
`;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::eq(ast.path, "foo.c3");
    test::@check(path.ptr != ast.path.ptr, "should be copied");

    test::ne(ast.modules, null);
    test::eq(ast.@node_len(ast.modules), 1);
    test::eq(ast.@node_join(ast.modules, contents, ","), "test::std::c3lang::ast");

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    test::eq(m.value, "test::std::c3lang::ast");
    test::eq(m.type, TokenType.MODULE);

    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.istart, 0);
    test::eq(m.iend, code.len - 1);

    test::ne(m.attributes, null);
    test::eq(m.attributes.value, "@test");
    test::eq(m.attributes.type, TokenType.AT_IDENT);
    test::eq(
        ast.@node_join(m.attributes, contents, ","), "@test,@if(env::NO_LIBC || $feature(C3_MATH))"
    );
    test::eq(m.attributes.istart, 31);
    test::eq(m.attributes.iend, 31 + 5);

    // test::eq(0, 1);
}

fn void test_module_no_attr()
{
    String code = `module test::std::c3lang::ast;`;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path);
    defer mem::free(ast._allocator);
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    // test::eq(0, 1);
}

fn void test_module_imports()
{
    String code = `
   import std::io; // imports to emty module

   module test::std::c3lang::ast; // new module
   `;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path);
    defer mem::free(ast._allocator);
    contents.clear();

    test::eq(ast.@node_len(ast.modules), 2);
    test::eq(ast.@node_join(ast.modules, contents, ","), ",test::std::c3lang::ast");

    AstModule* m = ast.@node_at(ast.modules, 1);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);
    test::eq(m.file_path, ast.path);

    m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "");
    test::eq(m.attributes, null);
    test::eq(m.file_path, ast.path);
    test::eq(m.file_path.ptr, ast.path.ptr);
    // test::eq(0, 1);
}

fn void test_scope()
{
    NodeParserState state;
    TokenType t;

    t = TokenType.LBRACE;
    state.check_scope(t);
    test::eq(state.scope_depth, 1);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    t = TokenType.LBRACKET;
    state.check_scope(t);
    test::eq(state.scope_depth, 2);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    t = TokenType.LPAREN;
    state.check_scope(t);
    test::eq(state.scope_depth, 3);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    t = TokenType.LBRAPIPE;
    state.check_scope(t);
    test::eq(state.scope_depth, 4);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    t = TokenType.LGENPAR;
    state.check_scope(t);
    test::eq(state.scope_depth, 5);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    t = TokenType.LVEC;
    state.check_scope(t);
    test::eq(state.scope_depth, 6);
    test::eq(state.scope_stack[state.scope_depth - 1], t);

    // EXIT SCOPE in reverse order

    t = TokenType.RVEC;
    state.check_scope(t);
    test::eq(state.scope_depth, 5);

    t = TokenType.RGENPAR;
    state.check_scope(t);
    test::eq(state.scope_depth, 4);

    t = TokenType.RBRAPIPE;
    state.check_scope(t);
    test::eq(state.scope_depth, 3);

    t = TokenType.RPAREN;
    state.check_scope(t);
    test::eq(state.scope_depth, 2);

    t = TokenType.RBRACKET;
    state.check_scope(t);
    test::eq(state.scope_depth, 1);

    t = TokenType.RBRACE;
    state.check_scope(t);
    test::eq(state.scope_depth, 0);

    // This should be ignored
    t = TokenType.RBRACE;
    state.check_scope(t);
    test::eq(state.scope_depth, 0);

    foreach (tok : state.scope_stack) {
        // all old tokens set to zero
        test::eq(tok, TokenType.INVALID_TOKEN);
    }
}

fn void test_scope_oveflow_protection()
{
    NodeParserState state;

    TokenType t = TokenType.LBRACE;

    for (uint i = 0; i < state.scope_stack.len * 2; i++) {
        state.check_scope(t);
    }

    test::eq(state.scope_depth, state.scope_stack.len);
    test::eq(state.scope_stack[state.scope_depth - 1], t);
}

fn void test_func()
{
    String code = `module test::std::c3lang::ast;
fn void test_node() {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(m, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "void");
    test::eq(func.params, null);

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');

    test::gt(func.iscope_start, func.istart);
    test::eq(code[func.iscope_start], '{');
}

fn void test_func_generic_ret_type()
{
    String code = `module test::std::c3lang::ast;
fn List(<int>) test_node() {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(m, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "List,(<,int,>)");
    test::eq(func.params, null);

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_func_vector_ret_type()
{
    String code = `module test::std::c3lang::ast;
fn int[<2>] test_node() {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(m, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "int,[<,2,>]");
    test::eq(func.params, null);

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_func_struct_pointer_type()
{
    String code = `module test::std::c3lang::ast;
fn MyType* test_node() {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "MyType,*");
    test::eq(func.params, null);

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_func_params()
{
    String code = `module test::std::c3lang::ast;
fn void test_node(int a, List(<int>) b) @test @inline @if(env::LIBC) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(m, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "void");

    test::ne(func.params, null);
    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "a");
    test::eq(ast.@node_join(param.param_type, contents), "int");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "b");
    test::eq(ast.@node_join(param.param_type, contents), "List,(<,int,>)");

    test::ne(func.attributes, null);
    test::eq(ast.@node_len(func.attributes), 3);
    test::eq(ast.@node_join(func.attributes, contents), "@test,@inline,@if(env::LIBC)");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_import()
{
    String code = `
   module test::std::c3lang::ast;
   import test::std::c3lang::ast::foo @test @if(env::FOO) ;
   import single_mod;
   `;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path);
    defer mem::free(ast._allocator);
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    test::ne(m.imports, null);
    test::eq(ast.@node_len(m.imports), 2);
    AstImport* imp;

    imp = ast.@node_at(m.imports, 0);
    test::eq(imp.type, TokenType.IMPORT);
    test::eq(imp.value, "import");
    test::eq(ast.@node_join(imp.name, contents, "::"), "test::std::c3lang::ast::foo");
    test::eq(ast.@node_join(imp.attributes, contents), "@test,@if(env::FOO)");

    imp = ast.@node_at(m.imports, 1);
    test::eq(imp.type, TokenType.IMPORT);
    test::eq(imp.value, "import");
    test::eq(ast.@node_join(imp.name, contents, "::"), "single_mod");
    test::eq(ast.@node_join(imp.attributes, contents), "");

}

fn void test_docstring_module()
{
    String code = `
<* My module *>
module test::std::c3lang::ast;
   `;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, true);
    defer mem::free(ast._allocator);
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    test::ne(m.docs, null);
    test::eq(m.docs.value, "<* My module ");
    test::eq(m.docs.istart, 1);
    test::eq(code[m.docs.istart], '<');
    test::eq(code[m.docs.iend], '>');

    // test::eq(1, 0);
}

fn void test_docstring_module_func()
{
    String code = `
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
    defer mem::free(ast._allocator);
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    test::ne(m.docs, null);
    test::@check(m.docs.value.contains("My module"));

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);
    test::ne(func.docs, null);

    test::@check(func.docs.value.contains("My func"));
}

fn void test_docstring_contracts()
{
    String code = `
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
    defer mem::free(ast._allocator);
    contents.clear();

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    test::ne(m.docs, null);
    test::@check(m.docs.value.contains("My module"));

    test::ne(m.docs.contracts, null);
    test::eq(ast.@node_len(m.docs.contracts), 6);

    AstDocContract* contract;

    contract = ast.@node_at(m.docs.contracts, 0);
    test::eq(contract.value, "@param");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), `foo,"some info"`);

    contract = ast.@node_at(m.docs.contracts, 1);
    test::eq(contract.value, "@test");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), ``);

    contract = ast.@node_at(m.docs.contracts, 2);
    test::eq(contract.value, "@param");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), `foo,"some info"`);

    contract = ast.@node_at(m.docs.contracts, 3);
    test::eq(contract.value, "@return");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), `"some stuff"`);

    contract = ast.@node_at(m.docs.contracts, 4);
    test::eq(contract.value, "@return");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), `!,Fault,.,SOME,,,IoError,.,ANOTHER`);

    contract = ast.@node_at(m.docs.contracts, 5);
    test::eq(contract.value, "@requre");
    test::eq(contract.type, TokenType.AT_IDENT);
    test::eq(ast.@node_join(contract.items, contents), `a,>,0,,,a,<,d`);

}

fn void test_func_default_params()
{
    String code = `module test::std::c3lang::ast;
fn void test_node(int a, int b = 2) @test @inline @if(env::LIBC) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(m, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.name, contents), "test_node");
    test::eq(ast.@node_join(func.ftype, contents), "void");

    test::ne(func.params, null);
    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "a");
    test::eq(ast.@node_join(param.param_type, contents), "int");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "b");
    test::eq(ast.@node_join(param.param_type, contents), "int,=,2");

    test::ne(func.attributes, null);
    test::eq(ast.@node_len(func.attributes), 3);
    test::eq(ast.@node_join(func.attributes, contents), "@test,@inline,@if(env::LIBC)");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_func_type_method()
{
    String code = `module test::std::c3lang::ast;
fn MyType* MyFoo.test_node(&self) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(func.value, "MyFoo.test_node");
    test::eq(ast.@node_join(func.name, contents), "MyFoo,test_node");
    test::eq(ast.@node_join(func.ftype, contents), "MyType,*");

    test::eq(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_one_linefunc()
{
    String code = `module test::std::c3lang::ast;
fn char! String.to_uchar(s, int base = 10) @inline @test => s.@to_integer(char, base) @foo;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.ftype, contents), "char,!");
    test::eq(ast.@node_join(func.name, contents), "String,to_uchar");
    test::eq(ast.@node_join(func.attributes, contents), "@inline,@test");
    test::ne(func.params, null);

    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "s");
    test::eq(param.param_type.type, TokenType.TYPE_IDENT);
    test::eq(ast.@node_join(param.param_type, contents), "String");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "base");
    test::eq(ast.@node_join(param.param_type, contents), "int,=,10");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], ';');
}

fn void test_macro_type()
{
    String code = `module test::std::c3lang::ast;
macro MyFoo.@test_macro(self) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "MyFoo,@test_macro");

    test::eq(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_type_with_ret_type()
{
    String code = `module test::std::c3lang::ast;
macro MyType(<$it>) MyFoo.@test_macro(self) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(ast.@node_join(func.ftype, contents), "MyType,(<,$it,>)");
    test::eq(ast.@node_join(func.name, contents), "MyFoo,@test_macro");

    test::eq(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_at_ident()
{
    String code = `module test::std::c3lang::ast;
macro @test_macro(self) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "@test_macro");

    test::eq(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "self");
    test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_hash_argument()
{
    String code = `module test::std::c3lang::ast;
macro @test_macro(Type* #self, $bar) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "@test_macro");

    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "#self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "Type,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "$bar");
    test::eq(ast.@node_join(param.param_type, contents), "");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_ellipsis()
{
    String code = `module test::std::c3lang::ast;
macro @test_macro(double... a, ...args) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "@test_macro");

    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "a");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "double,...");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "args");
    test::eq(ast.@node_join(param.param_type, contents), "...");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_parameter_attributes()
{
    String code = `module test::std::c3lang::ast;
macro @test_macro(Type* #self @unused, $bar @export("foo") @ok) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "@test_macro");

    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "#self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "Type,*");
    test::eq(ast.@node_join(param.attributes, contents), "@unused");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "$bar");
    test::eq(ast.@node_join(param.param_type, contents), "");
    test::eq(ast.@node_join(param.attributes, contents), `@export("foo"),@ok`);

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_with_body_scope()
{
    String code = `module test::std::c3lang::ast;
macro @for_each(list; @body(it))
{
    for ($typeof(list) x = list; x; x = x.next)
    {
        @body(x);
    }
}//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "@for_each");

    test::eq(ast.@node_len(func.params), 2);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "list");
    test::eq(param.param_type, null);
    // test::eq(ast.@node_join(param.param_type, contents), "Type,*");
    // test::eq(ast.@node_join(param.attributes, contents), "@unused");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "@body");
    test::eq(ast.@node_join(param.param_type, contents), "(,it,)");
    test::eq(ast.@node_join(param.attributes, contents), "");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 31);
    test::eq(code[func.iend], '}');
    test::eq(func.iend, code.len - 3);
}

fn void test_enum_simple()
{
    String code = `module test::std::c3lang::ast;
enum Foo {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::ne(enum_type, null);

    test::eq(enum_type.type, TokenType.ENUM);
    test::eq(enum_type.value, "Foo");

    test::eq(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "FOO");

    io::printf(
        "\n\n``%s``", code[enum_type.istart .. math::min((isz)enum_type.iend, (isz)(code.len - 1))]
    );
    test::eq(enum_type.istart, 31);
    test::eq(code[enum_type.iend], '}');
    test::eq(enum_type.iend, code.len - 4);
}

fn void test_typed_enum_simple()
{
    String code = `module test::std::c3lang::ast;
enum Foo : int {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::ne(enum_type, null);

    test::eq(enum_type.type, TokenType.ENUM);
    test::eq(enum_type.value, "Foo");

    test::eq(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "FOO");

    io::printf(
        "\n\n``%s``", code[enum_type.istart .. math::min((isz)enum_type.iend, (isz)(code.len - 1))]
    );
    test::eq(enum_type.istart, 31);
    test::eq(code[enum_type.iend], '}');
    test::eq(enum_type.iend, code.len - 4);
}

fn void test_typed_enum_associated()
{
    String code = `module test::std::c3lang::ast;
enum Foo : int (String desc, bool active, Position pos) @test @if(env:FOO) {
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::ne(enum_type, null);

    test::eq(enum_type.type, TokenType.ENUM);
    test::eq(enum_type.value, "Foo");
    test::eq(ast.@node_join(enum_type.attributes, contents), "@test,@if(env:FOO)");

    test::eq(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "FOO");

    io::printf(
        "\n\n``%s``", code[enum_type.istart .. math::min((isz)enum_type.iend, (isz)(code.len - 1))]
    );
    test::eq(enum_type.istart, 31);
    test::eq(code[enum_type.iend], '}');
    test::eq(enum_type.iend, code.len - 4);
}

fn void test_fault_type()
{
    String code = `module test::std::c3lang::ast;
fault SomeFault @local @if(env::FOO)
{
    A,
    RUNNING    = { OtherEnum.FAILING, true,  {12,22} },
    FOO = SOME_OTHER_CONST,
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefEnumerable* enum_type = (AstTypeDefEnumerable*)ast.@node_at(m.decls, 0);
    test::ne(enum_type, null);

    test::eq(enum_type.type, TokenType.FAULT);
    test::eq(enum_type.value, "SomeFault");

    test::eq(ast.@node_join(enum_type.attributes, contents), "@local,@if(env::FOO)");

    test::eq(ast.@node_len(enum_type.values), 3);
    AstNode* eval;

    eval = ast.@node_at(enum_type.values, 0);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "A");

    eval = ast.@node_at(enum_type.values, 1);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "RUNNING");

    eval = ast.@node_at(enum_type.values, 2);
    test::eq(eval.type, TokenType.CONST_IDENT);
    test::eq(eval.value, "FOO");

    io::printf(
        "\n\n``%s``", code[enum_type.istart .. math::min((isz)enum_type.iend, (isz)(code.len - 1))]
    );
    test::eq(enum_type.istart, 31);
    test::eq(code[enum_type.iend], '}');
    test::eq(enum_type.iend, code.len - 4);
}

fn void test_interface_type()
{
    String code = `module test::std::c3lang::ast;
interface NodeI @local {
    fn bool foo(Ast* ast, AstNode* node, Token* t) @local;
    fn List(<int>) bar() @local;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefInterface* ifc_type = (AstTypeDefInterface*)ast.@node_at(m.decls, 0);
    test::ne(ifc_type, null);

    test::eq(ifc_type.type, TokenType.INTERFACE);
    test::eq(ifc_type.value, "NodeI");

    test::eq(ast.@node_join(ifc_type.attributes, contents), "@local");

    test::eq(ast.@node_len(ifc_type.functions), 2);

    AstCallable* func = (AstCallable*)ast.@node_at(ifc_type.functions, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.ftype, contents), "bool");
    test::eq(ast.@node_join(func.name, contents), "foo");
    test::eq(ast.@node_join(func.attributes, contents), "@local");

    test::eq(ast.@node_len(func.params), 3);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "ast");
    test::eq(ast.@node_join(param.param_type, contents), "Ast,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "node");
    test::eq(ast.@node_join(param.param_type, contents), "AstNode,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 2);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "t");
    test::eq(ast.@node_join(param.param_type, contents), "Token,*");

    func = (AstCallable*)ast.@node_at(ifc_type.functions, 1);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.ftype, contents), `List,(<,int,>)`);
    test::eq(ast.@node_join(func.name, contents), "bar");
    test::eq(ast.@node_join(func.attributes, contents), "@local");

    test::eq(ast.@node_len(func.params), 0);

    io::printf(
        "\n\n``%s``", code[ifc_type.istart .. math::min((isz)ifc_type.iend, (isz)(code.len - 1))]
    );
    test::eq(ifc_type.istart, 31);
    test::eq(code[ifc_type.iend], '}');
    test::eq(ifc_type.iend, code.len - 4);
}

fn void test_interface_type_with_docs()
{
    String code = `module test::std::c3lang::ast;
interface NodeI @local {
    <* Doc string
    @param ast "some stuff"
    @requre {| return some; |}
    *>
    fn bool foo(Ast* ast, AstNode* node, Token* t) @local;
    <* another doc string *>
    fn List(<int>) bar() @local;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefInterface* ifc_type = (AstTypeDefInterface*)ast.@node_at(m.decls, 0);
    test::ne(ifc_type, null);

    test::eq(ifc_type.type, TokenType.INTERFACE);
    test::eq(ifc_type.value, "NodeI");

    test::eq(ast.@node_join(ifc_type.attributes, contents), "@local");

    test::eq(ast.@node_len(ifc_type.functions), 2);

    AstCallable* func = (AstCallable*)ast.@node_at(ifc_type.functions, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.ftype, contents), "bool");
    test::eq(ast.@node_join(func.name, contents), "foo");
    test::eq(ast.@node_join(func.attributes, contents), "@local");
    test::eq(ast.@node_join(func.docs, contents), "<* Doc string\n");

    test::eq(ast.@node_len(func.params), 3);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "ast");
    test::eq(ast.@node_join(param.param_type, contents), "Ast,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 1);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "node");
    test::eq(ast.@node_join(param.param_type, contents), "AstNode,*");

    param = (AstCallableParam*)ast.@node_at(func.params, 2);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "t");
    test::eq(ast.@node_join(param.param_type, contents), "Token,*");

    func = (AstCallable*)ast.@node_at(ifc_type.functions, 1);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(ast.@node_join(func.ftype, contents), `List,(<,int,>)`);
    test::eq(ast.@node_join(func.name, contents), "bar");
    test::eq(ast.@node_join(func.attributes, contents), "@local");
    test::eq(ast.@node_join(func.docs, contents), "<* another doc string ");

    test::eq(ast.@node_len(func.params), 0);

    io::printf(
        "\n\n``%s``", code[ifc_type.istart .. math::min((isz)ifc_type.iend, (isz)(code.len - 1))]
    );
    test::eq(ifc_type.istart, 31);
    test::eq(code[ifc_type.iend], '}');
    test::eq(ifc_type.iend, code.len - 4);
}

fn void test_struct_typedef()
{
    String code = `module test::std::c3lang::ast;
<* docs *>
struct MyStruct @local {
    int a;
    MyType b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "<* docs ");

    test::eq(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "a");
    test::eq(ast.@node_join(member.ftype, contents), "int");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), "MyType");
    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), "");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 42);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_struct_typedef_member_docs()
{
    String code = `module test::std::c3lang::ast;
<* docs *>
struct MyStruct @local {
    <* some stuff *>
    int a;
    <* another doc *>
    List(<MyType>) b;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "<* docs ");

    test::eq(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "a");
    test::eq(ast.@node_join(member.ftype, contents), "int");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "<* some stuff ");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), "List,(<,MyType,>)");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "<* another doc ");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 42);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_struct_typedef_substructs()
{
    String code = `module test::std::c3lang::ast;
struct MyStruct @local {
    struct my_sub @test {
        int x;
        int y;
        int z @test;
    }
    int b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);
    // test::eq(ast.@node_join(struct_type.members, contents), ``);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.STRUCT);
    test::eq(member.value, "my_sub");
    test::eq(ast.@node_join(member.ftype, contents), ``);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), ``);
    test::eq(ast.@node_len(member.members), 3);
    test::eq(ast.@node_join(member.members, contents), `x,y,z`);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), `int`);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), ``);
    test::eq(ast.@node_len(member.members), 0);

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);

}

fn void test_struct_typedef_substructs_doc_strings()
{
    String code = `module test::std::c3lang::ast;
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
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*doc1");

    test::eq(ast.@node_len(struct_type.members), 2);
    // test::eq(ast.@node_join(struct_type.members, contents), ``);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.STRUCT);
    test::eq(member.value, "my_sub");
    test::eq(ast.@node_join(member.ftype, contents), ``);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), `<*doc2`);
    test::eq(ast.@node_len(member.members), 3);
    test::eq(ast.@node_join(member.members, contents), `x,y,z`);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), `int`);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), `<*doc4`);
    test::eq(ast.@node_len(member.members), 0);

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 40);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_struct_sub_sub()
{
    String code = `module test::std::c3lang::ast;
struct MyStruct @local {
    struct my_sub @test {
        int x;
        struct my_sub_2 @foo {
            int y;
            int z;
        }
        int f;
    }
    int b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);
    test::eq(ast.@node_join(struct_type.members, contents), `my_sub,b`);

    AstTypeDefStructural* field1, field2;

    field1 = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(field1, null);
    test::eq(field1.type, TokenType.STRUCT);
    test::eq(field1.value, "my_sub");
    test::eq(ast.@node_join(field1.ftype, contents), ``);
    test::eq(ast.@node_join(field1.members, contents), `x,my_sub_2,f`);
    test::eq(ast.@node_len(field1.members), 3);

    test::eq(ast.@node_join(field1.attributes, contents), "@test");
    test::eq(ast.@node_join(field1.docs, contents), ``);

    // my_sub field x
    field2 = (AstTypeDefStructural*)ast.@node_at(field1.members, 0);
    test::ne(field2, null);
    test::eq(field2.type, TokenType.TYPE_IDENT);
    test::eq(field2.value, "x");
    test::eq(ast.@node_join(field2.ftype, contents), `int`);
    test::eq(ast.@node_join(field2.members, contents), ``);
    test::eq(ast.@node_len(field2.members), 0);
    test::eq(ast.@node_join(field2.attributes, contents), "");
    test::eq(ast.@node_join(field2.docs, contents), ``);

    // my_sub field my_sub_2
    field2 = (AstTypeDefStructural*)ast.@node_at(field1.members, 1);
    test::ne(field2, null);
    test::eq(field2.type, TokenType.STRUCT);
    test::eq(field2.value, "my_sub_2");
    test::eq(ast.@node_join(field2.ftype, contents), ``);
    test::eq(ast.@node_join(field2.members, contents), `y,z`);
    test::eq(ast.@node_len(field2.members), 2);
    test::eq(ast.@node_join(field2.attributes, contents), "@foo");
    test::eq(ast.@node_join(field2.docs, contents), ``);

    // my_sub field x
    field2 = (AstTypeDefStructural*)ast.@node_at(field1.members, 2);
    test::ne(field2, null);
    test::eq(field2.type, TokenType.TYPE_IDENT);
    test::eq(field2.value, "f");
    test::eq(ast.@node_join(field2.ftype, contents), `int`);
    test::eq(ast.@node_join(field2.members, contents), ``);
    test::eq(ast.@node_len(field2.members), 0);
    test::eq(ast.@node_join(field2.attributes, contents), "");
    test::eq(ast.@node_join(field2.docs, contents), ``);

    // Main struct second field
    field2 = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(field2, null);
    test::eq(field2.type, TokenType.TYPE_IDENT);
    test::eq(field2.value, "b");
    test::eq(ast.@node_join(field2.ftype, contents), `int`);

    test::eq(ast.@node_join(field2.attributes, contents), "@test");
    test::eq(ast.@node_join(field2.docs, contents), ``);
    test::eq(ast.@node_len(field2.members), 0);

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);

}

fn void test_struct_anonymous()
{
    String code = `module test::std::c3lang::ast;
struct MyStruct @local {
    struct @test {
        int x;
        int y;
        int z @test;
    }
    int b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);
    test::eq(ast.@node_join(struct_type.members, contents), `,b`);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.STRUCT);
    test::eq(member.value, "");
    test::eq(ast.@node_join(member.ftype, contents), ``);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), ``);
    test::eq(ast.@node_len(member.members), 3);
    test::eq(ast.@node_join(member.members, contents), `x,y,z`);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), `int`);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), ``);
    test::eq(ast.@node_len(member.members), 0);

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);

}

fn void test_struct_inline()
{
    String code = `module test::std::c3lang::ast;
struct MyStruct @local {
    <*inline doc*>
    inline List(<int>) base @test;
    int b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyStruct");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);
    test::eq(ast.@node_join(struct_type.members, contents), `base,b`);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.INLINE);
    test::eq(member.value, "base");
    test::eq(ast.@node_join(member.ftype, contents), `List,(<,int,>)`);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), `<*inline doc`);
    test::eq(ast.@node_len(member.members), 0);
    test::eq(ast.@node_join(member.members, contents), ``);

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), `int`);

    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), ``);
    test::eq(ast.@node_len(member.members), 0);

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);

}

fn void test_union()
{
    String code = `module test::std::c3lang::ast;
union MyUnion @local {
    int a;
    int b @test;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.UNION);
    test::eq(struct_type.value, "MyUnion");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "a");
    test::eq(ast.@node_join(member.ftype, contents), "int");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), "int");
    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), "");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_struct_with_unions()
{
    String code = `module test::std::c3lang::ast;
struct MyUnion @local {
    union {
        int a;
        int b;
    }
    union foo @test {
        int x;
        int z;
    }
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyUnion");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 2);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.UNION);
    test::eq(member.value, "");
    test::eq(ast.@node_join(member.ftype, contents), "");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.UNION);
    test::eq(member.value, "foo");
    test::eq(ast.@node_join(member.ftype, contents), "");
    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), "");
    test::eq(ast.@node_join(member.members, contents), "x,z");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_bitstruct()
{
    String code = `module test::std::c3lang::ast;
bitstruct MyBit @local : char
{
    int a : 0..2;
    int b @test : 4..6;
    bool c : 7;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.BITSTRUCT);
    test::eq(struct_type.value, "MyBit");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@local");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 3);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "a");
    test::eq(ast.@node_join(member.ftype, contents), "int,:,0,..,2");
    test::eq(ast.@node_join(member.attributes, contents), "");
    test::eq(ast.@node_join(member.docs, contents), "");

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 1);
    test::ne(member, null);
    test::eq(member.type, TokenType.TYPE_IDENT);
    test::eq(member.value, "b");
    test::eq(ast.@node_join(member.ftype, contents), "int,:,4,..,6");
    test::eq(ast.@node_join(member.attributes, contents), "@test");
    test::eq(ast.@node_join(member.docs, contents), "");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_sub_bitstruct()
{
    String code = `module test::std::c3lang::ast;
struct MyBit {
    bitstruct my_bit @local : char
    {
        int a : 0..2;
        int b @test : 4..6;
        bool c : 7;
    }
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.STRUCT);
    test::eq(struct_type.value, "MyBit");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "");

    test::eq(ast.@node_len(struct_type.members), 1);

    AstTypeDefStructural* member;

    member = (AstTypeDefStructural*)ast.@node_at(struct_type.members, 0);
    test::ne(member, null);
    test::eq(member.type, TokenType.BITSTRUCT);
    test::eq(member.value, "my_bit");
    test::eq(ast.@node_join(member.ftype, contents), "");
    test::eq(ast.@node_join(member.attributes, contents), "@local");
    test::eq(ast.@node_join(member.docs, contents), "");
    test::eq(ast.@node_join(member.members, contents), "a,b,c");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 31);
    test::eq(code[struct_type.iend], '}');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_def()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
def Int32 = int;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.DEF);
    test::eq(struct_type.value, "Int32");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(struct_type.ftype, contents), "int");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_def_attr_type()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
def @Int32 = { @foo @bar };
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.DEF);
    test::eq(struct_type.value, "@Int32");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(struct_type.ftype, contents), "{,@foo,@bar,}");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_def_inline_list()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
def IntList32 @test @foo = inline List(<int>);
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.DEF);
    test::eq(struct_type.value, "IntList32");

    test::eq(ast.@node_join(struct_type.attributes, contents), "@test,@foo");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    // NOTE: inline expected to be excluded from type fields
    test::eq(ast.@node_join(struct_type.ftype, contents), "List,(<,int,>)");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_distinct()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
distinct Int32 = int;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.DISTINCT);
    test::eq(struct_type.value, "Int32");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(struct_type.ftype, contents), "int");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_constant()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
const Int32 A_FOO_BAR = 123;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.CONST);
    test::eq(struct_type.value, "A_FOO_BAR");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(struct_type.ftype, contents), "Int32");

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_def_fn_pointer()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
def NodeParser = fn bool (Ast* ast, AstNode* node, Token* t, NodeParserState* state);
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDefStructural* struct_type = (AstTypeDefStructural*)ast.@node_at(m.decls, 0);
    test::ne(struct_type, null);

    test::eq(struct_type.type, TokenType.DEF);
    test::eq(struct_type.value, "NodeParser");

    test::eq(ast.@node_join(struct_type.attributes, contents), "");
    test::eq(ast.@node_join(struct_type.docs, contents), "<*def doc");
    test::eq(
        ast.@node_join(struct_type.ftype, contents),
        "fn,bool,(,Ast,*,ast,,,AstNode,*,node,,,Token,*,t,,,NodeParserState,*,state,)"
    );

    io::printf(
        "\n\n``%s``",
        code[struct_type.istart .. math::min((isz)struct_type.iend, (isz)(code.len - 1))]
    );
    test::eq(struct_type.istart, 43);
    test::eq(code[struct_type.iend], ';');
    test::eq(struct_type.iend, code.len - 4);
}

fn void test_module_imports_comma_sep()
{
    String code = `
   module test::std::c3lang::ast; 
   import std::io @test, test::math @foo;

   `;
    DString contents = dstring::temp_new(code);

    String path = "foo.c3";
    Ast ast = ast::parse(contents.str_view(), path, true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::eq(ast.@node_len(ast.modules), 1);
    test::eq(ast.@node_join(ast.modules, contents, ","), "test::std::c3lang::ast");

    AstModule* m = ast.@node_at(ast.modules, 0);
    test::eq(ast.@node_join(m.name, contents, "::"), "test::std::c3lang::ast");
    test::eq(m.attributes, null);

    test::ne(m.imports, null);
    test::eq(ast.@node_len(m.imports), 2);
    AstImport* imp;

    imp = ast.@node_at(m.imports, 0);
    test::eq(imp.type, TokenType.IMPORT);
    test::eq(imp.value, "import");
    test::eq(ast.@node_join(imp.name, contents, "::"), "std::io");
    test::eq(ast.@node_join(imp.attributes, contents), "@test");

    imp = ast.@node_at(m.imports, 1);
    test::eq(imp.type, TokenType.IMPORT);
    test::eq(imp.value, "import");
    test::eq(ast.@node_join(imp.name, contents, "::"), "test::math");
    test::eq(ast.@node_join(imp.attributes, contents), "@foo");
}

/*

*/
fn void test_macro_atomic_regression1()
{
    String code = `module test::std::c3lang::ast;

macro fetch_add(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT, bool $volatile = false, usz $alignment = 0)
{
	$if $alignment == 0:
		$alignment = $typeof(*ptr).sizeof;
	$endif
	return $$atomic_fetch_add(ptr, y, $volatile, $ordering.ordinal, $alignment);
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "fetch_add");

    test::eq(ast.@node_join(func.params, contents), "ptr,y,$ordering,$volatile,$alignment");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 32);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_macro_type_based()
{
    String code = `module test::std::c3lang::ast;

macro MyType.fetch_add(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT, bool $volatile = false, usz $alignment = 0)
{
	$if $alignment == 0:
		$alignment = $typeof(*ptr).sizeof;
	$endif
	return $$atomic_fetch_add(ptr, y, $volatile, $ordering.ordinal, $alignment);
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.MACRO);
    test::eq(func.ftype, null);
    test::eq(ast.@node_join(func.ftype, contents), "");
    test::eq(ast.@node_join(func.name, contents), "MyType,fetch_add");

    test::eq(ast.@node_join(func.params, contents), "ptr,y,$ordering,$volatile,$alignment");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 32);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_func_with_c_docstring()
{
    String code = `module test::std::c3lang::ast;
/**
 * Allocate data for a token, including source location.
 * This call is doing the basic allocation, with other functions
 * filling out additional information.
**/
fn MyType* MyFoo.test_node(&self) {
    return 1;
}
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstCallable* func = (AstCallable*)ast.@node_at(m.decls, 0);
    test::ne(func, null);

    test::eq(func.type, TokenType.FN);
    test::eq(func.value, "MyFoo.test_node");
    test::eq(ast.@node_join(func.name, contents), "MyFoo,test_node");
    test::eq(ast.@node_join(func.ftype, contents), "MyType,*");

    test::eq(ast.@node_len(func.params), 1);
    AstCallableParam* param;

    param = (AstCallableParam*)ast.@node_at(func.params, 0);
    test::eq(param.type, TokenType.VAR);
    test::eq(param.value, "self");
    // test::eq(param.param_type, null);
    test::eq(ast.@node_join(param.param_type, contents), "MyFoo");

    io::printf("\n\n``%s``", code[func.istart .. math::min((isz)func.iend, (isz)(code.len - 1))]);
    test::eq(func.istart, 200);
    test::eq(func.iend, code.len - 4);
    test::eq(code[func.iend], '}');
}

fn void test_module_variable()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
int global_int @local @bar("foo") = 2;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDef* var_type = (AstTypeDef*)ast.@node_at(m.decls, 0);
    test::ne(var_type, null);

    test::eq(var_type.type, TokenType.TYPE_IDENT);
    test::eq(var_type.value, "global_int");

    test::eq(ast.@node_join(var_type.attributes, contents), `@local,@bar("foo")`);
    test::eq(ast.@node_join(var_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(var_type.ftype, contents), "int");

    io::printf(
        "\n\n``%s``",
        code[var_type.istart .. math::min((isz)var_type.iend, (isz)(code.len - 1))]
    );
    test::eq(var_type.istart, 43);
    test::eq(code[var_type.iend], ';');
    test::eq(var_type.iend, code.len - 4);
}

fn void test_module_variable_tlocal()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
tlocal int global_int @local @bar("foo") = 2;
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDef* var_type = (AstTypeDef*)ast.@node_at(m.decls, 0);
    test::ne(var_type, null);

    test::eq(var_type.type, TokenType.TYPE_IDENT);
    test::eq(var_type.value, "global_int");

    test::eq(ast.@node_join(var_type.attributes, contents), `@local,@bar("foo")`);
    test::eq(ast.@node_join(var_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(var_type.ftype, contents), "int");

    io::printf(
        "\n\n``%s``",
        code[var_type.istart .. math::min((isz)var_type.iend, (isz)(code.len - 1))]
    );
    test::eq(var_type.istart, 43);
    test::eq(code[var_type.iend], ';');
    test::eq(var_type.iend, code.len - 4);
}

fn void test_module_variable_custom_type()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
MyType global_int @local @bar("foo");
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDef* var_type = (AstTypeDef*)ast.@node_at(m.decls, 0);
    test::ne(var_type, null);

    test::eq(var_type.type, TokenType.TYPE_IDENT);
    test::eq(var_type.value, "global_int");

    test::eq(ast.@node_join(var_type.attributes, contents), `@local,@bar("foo")`);
    test::eq(ast.@node_join(var_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(var_type.ftype, contents), "MyType");

    io::printf(
        "\n\n``%s``",
        code[var_type.istart .. math::min((isz)var_type.iend, (isz)(code.len - 1))]
    );
    test::eq(var_type.istart, 43);
    test::eq(code[var_type.iend], ';');
    test::eq(var_type.iend, code.len - 4);
}

fn void test_module_variable_array()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
char[10] global_int @local @bar("foo");
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDef* var_type = (AstTypeDef*)ast.@node_at(m.decls, 0);
    test::ne(var_type, null);

    test::eq(var_type.type, TokenType.TYPE_IDENT);
    test::eq(var_type.value, "global_int");

    test::eq(ast.@node_join(var_type.attributes, contents), `@local,@bar("foo")`);
    test::eq(ast.@node_join(var_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(var_type.ftype, contents), "char,[,10,]");

    io::printf(
        "\n\n``%s``",
        code[var_type.istart .. math::min((isz)var_type.iend, (isz)(code.len - 1))]
    );
    test::eq(var_type.istart, 43);
    test::eq(code[var_type.iend], ';');
    test::eq(var_type.iend, code.len - 4);
}

fn void test_module_variable_generic()
{
    String code = `module test::std::c3lang::ast;
<*def doc*>
List(<MyType>) global_int @local @bar("foo");
//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: true);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    AstModule* m = ast.@node_at(ast.modules, 0);
    test::ne(m, null);

    AstTypeDef* var_type = (AstTypeDef*)ast.@node_at(m.decls, 0);
    test::ne(var_type, null);

    test::eq(var_type.type, TokenType.TYPE_IDENT);
    test::eq(var_type.value, "global_int");

    test::eq(ast.@node_join(var_type.attributes, contents), `@local,@bar("foo")`);
    test::eq(ast.@node_join(var_type.docs, contents), "<*def doc");
    test::eq(ast.@node_join(var_type.ftype, contents), "List,(<,MyType,>)");

    io::printf(
        "\n\n``%s``",
        code[var_type.istart .. math::min((isz)var_type.iend, (isz)(code.len - 1))]
    );
    test::eq(var_type.istart, 43);
    test::eq(code[var_type.iend], ';');
    test::eq(var_type.iend, code.len - 4);
}
