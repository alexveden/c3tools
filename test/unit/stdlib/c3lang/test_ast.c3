module test::std::c3lang::ast @test;
import std::c3lang::ast;
import std::c3lang::lexer;
import std::c3lang::common;
import std::collections::list;
import std::io;


fn void test_node(){
   String contents = `module test::std::c3lang::ast  @test;
import std::c3lang::ast;

fn void test_node() {
    return 1;
}
`;
    
    
    String path = "foo.c3";
    Ast ast = ast::parse(contents, path);
    defer ast.free();


    test::equal(ast.path, "foo.c3");
    test::@check(path.ptr != ast.path.ptr, "should be copied");

    test::not_equal(ast.modules, null);
    test::equal(ast.modules.value, "module");
    test::equal(ast.modules.type, TokenType.TOKEN_MODULE);
    test::equal(ast.modules.module_name, "test::std::c3lang::ast");
    test::equal(ast.modules.istart, 0);
    test::equal(ast.modules.iend, contents.len-1);

    test::not_equal(ast.modules.attributes, null);
    test::equal(ast.modules.attributes.value, "@test");
    test::equal(ast.modules.attributes.type, TokenType.TOKEN_AT_IDENT);
    test::equal(ast.modules.attributes.istart, 31);
    test::equal(ast.modules.attributes.iend, 31+5);

    // test::equal(0, 1);
}
