module test::c3tools::c3fmt_corpus @test;
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
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    test::@check(codecorpus::compare_output(expected[1..], formatted), `double format mismatch`);
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
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    test::@check(codecorpus::compare_output(expected[1..], formatted), `double format mismatch`);
}

fn void test_corpus__functions__ret_generic_list() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn List(<int>) 
main(
String[] args
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn List(<int>) main(String[] args)
{
    return 0;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    test::@check(codecorpus::compare_output(expected[1..], formatted), `double format mismatch`);
}

fn void test_corpus__functions__ret_generic_list_pointer_opt() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn List(<int>)*! 
main(
String[] args
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn List(<int>)*! main(String[] args)
{
    return 0;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    test::@check(codecorpus::compare_output(expected[1..], formatted), `double format mismatch`);
}

fn void test_corpus__functions__ret_generic_method() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn List(<int>)*! 
Foo.main(
String[] args
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn List(<int>)*! Foo.main(String[] args)
{
    return 0;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    test::@check(codecorpus::compare_output(expected[1..], formatted), `double format mismatch`);
}
