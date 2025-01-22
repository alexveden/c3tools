module test::c3tools::c3fmt_autogen @test;
import c3tools::codefmt;
import c3tools::codecorpus;

fn void test_c3fmt__functions__simple_main() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..])!!;
    String expected = `
fn void main() 
{
    return;
}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted));
}

fn void test_c3fmt__functions__simple_main_int() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn int 
main(
String[] args
) { return;}

`;
    String formatted = fmt.format(input[1..])!!;
    String expected = `
fn int main(String[] args)
{
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted));
}
