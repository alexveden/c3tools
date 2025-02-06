module test::c3tools::codefmt @test;
import std::collections::list;
import std::io;
import libc;
import c3tools::codefmt::codecorpus @public;
import c3tools::codefmt;


fn void test_two_spaces() 
{
    CodeFmt fmt = CodeFmt.new_init(indent_type: '2');
    defer fmt.free();
    String input = `
fn void main() 
{  
    if(foo) return 0;
    return 1;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\nformatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
  if (foo) return 0;
  return 1;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
}

fn void test_eight_spaces() 
{
    CodeFmt fmt = CodeFmt.new_init(indent_type: '8');
    defer fmt.free();
    String input = `
fn void main() 
{  
    if(foo) return 0;
    return 1;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\nformatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
        if (foo) return 0;
        return 1;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
}

fn void test_tabs() 
{
    CodeFmt fmt = CodeFmt.new_init(indent_type: 't');
    defer fmt.free();
    String input = `
fn void main() 
{  
    if(foo) return 0;
    return 1;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\nformatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = "\nfn void main()\n{\n\tif (foo) return 0;\n\treturn 1;\n}\n";
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
}
