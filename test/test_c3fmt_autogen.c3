module test::c3tools::c3fmt_autogen @test;
import c3tools::codefmt;
import c3tools::codecorpus;
import std::io;

fn void test_corpus__functions__simple_main() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted));
}

fn void test_corpus__functions__simple_main_int() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn int 
main(
String[] args
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn int main(String[] args)
{
    return 0;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted));
}
