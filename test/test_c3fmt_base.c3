module test::c3tools::codefmt @test;
import std::collections::list;
import std::io;
import libc;
import c3tools::codecorpus @public;
import c3tools::codefmt;


fn void test_format_basic() {
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    
    test::equal(fmt.max_line_width, 80);

    String content = `
    fn 
    void
    main() {
    return 0;
    }
    `;
    String out = fmt.format(content, print_lex: true)!!;

    io::printfn("\n\nFormatted code");
    io::printfn("```\n%s```", out);

    test::equal(1, 0);
}
