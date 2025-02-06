module test::c3lib::codegen @test;
import c3lib::codegen;
import std::io;

fn void test_codegen_module()
{
    CodeGen* c = CodeGen {}.new_init();
    defer c.free();

    c.@module("myfoo @if(%d)", c.indent);
    c.@import("std::io");

    c.@struct("MyType @local") {
        c.wn("float a");
        c.wn("int b");
        c.@struct("substruct") {
            c.wn("float c");
        };
    };

    c.@fn("void my_foo() @test") {
        c.@if("x == 1") {
            c.wn("int b = %s", c.indent);
        };
        c.@return("0");
    };

    io::printfn("%s", c.buf.str_view());
    // test::eq(1, 0);
}
