fn int far(int a , int b) {
    return a + b;
}

module test::std::c3lang::ast @test;
import std::c3lang::ast;
import std::c3lang::lexer;
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

fn void test_func(){
   String code =  `module test::std::c3lang::ast;
fn void test_node() {
    return 1;
}
`;
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
    // io::printfn("```%s```", code[func.istart..func.iend+1]);
    test::equal(func.istart, 31);
    test::equal(code[func.iend], '}');
    test::equal(func.iend, code.len-2);
}
