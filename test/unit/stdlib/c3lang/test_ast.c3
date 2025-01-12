module test::std::c3lang::ast @test;
import std::c3lang::ast;
import std::c3lang::lexer;
import std::collections::list;
import std::io;


fn void test_node(){
   String contents = `
module test::std::c3lang::ast @test;
import std::c3lang::ast;
fn void test_node() {
    return 1;
}
`;
    
    Ast* ast = ast::parse(contents, "foo.c3");
    defer mem::free(ast);

    test::equal(ast.path, "foo.c3");
    test::equal(0, 1);
}
