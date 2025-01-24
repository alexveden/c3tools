module test::c3tools::c3fmt_corpus @test;
import c3tools::codefmt;
import c3tools::codecorpus;
import std::io;

fn void test_corpus__statements__generic_statements() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main() 
{ 
int a = b;
b|= 10+a;
 io :: printf(   "soo"   , a   );
v  .  
    @call(a, b);
return;
}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int a = b;
    b |= 10 + a;
    io::printf("soo", a);
    v.@call(a, b);
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

fn void test_corpus__statements__expressions() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main() 
{ 
int a = b*2/1-1+3%1;
b%= 10+a;
b&=a;
b|=a;
b^=a;
b&&&a;
b|||a;
b+++a;
b/=a;
a==s;
a>=s;
a<=s;
a>=s;
a-=s;
a+=s;
a*=s;
a%=s;
a!=s;
a  ++  s;
--  a;
a<<1;
a>>1;
return;
}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int a = b * 2 / 1 - 1 + 3 % 1;
    b %= 10 + a;
    b &= a;
    b |= a;
    b ^= a;
    b &&& a;
    b ||| a;
    b +++ a;
    b /= a;
    a == s;
    a >= s;
    a <= s;
    a >= s;
    a -= s;
    a += s;
    a *= s;
    a %= s;
    a != s;
    a++s;
    --a;
    a << 1;
    a >> 1;
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

fn void test_corpus__statements__call_statement_single_line() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main() 
{ 
    io::printf("soo", a, sooo::  foo::bar  (    "adskjalsda", looooong, var));
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var), another_var
    );
return;
}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    io::printf("soo", a, sooo::foo::bar("adskjalsda", looooong, var));
    io::printf(
        "soo", a, sooo::foo::bar("adskjalsda", looooong, var), another_var
    );
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

fn void test_corpus__functions__ret_generic_method_attrs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn List(<int>) * ! 
Foo.main(
String[] args
) @test @if("dio" || too) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn List(<int>)*! Foo.main(String[] args) @test @if("dio" || too)
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

fn void test_corpus__functions__returns_array_type() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn String[]! 
Foo.main(
String[] args
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(String[] args)
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

fn void test_corpus__functions__returns_multiple_arguments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn String[]! 
Foo.main(
String[] args, int* foo, List(<float>)     
bar, na   ,    varg...
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(String[] args, int* foo, List(<float>) bar, na, varg...)
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

fn void test_corpus__functions__long_arguments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn String[]! Foo.main(String[] args, int* foo, List(<float>) bar, MySuperClass[] last
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(
    String[] args, int* foo, List(<float>) bar, MySuperClass[] last
)
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

fn void test_corpus__functions__long_arguments_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn String[]! Foo.main(SoTypeIsHuuuuuuge ok, String[] args, int* foo, List(<float>) bar, MySuperClass[] last, List(<ThisIsTooBig>) too_be_true
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(
    SoTypeIsHuuuuuuge ok,
    String[] args,
    int* foo,
    List(<float>) bar,
    MySuperClass[] last,
    List(<ThisIsTooBig>) too_be_true
)
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

fn void test_corpus__functions__arguments_magic_comma() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn String[]! 
Foo.main(
String[] args, int* foo, List(<float>)     
bar, na   ,
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: true)!!;
    io::printfn("formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(
    String[] args,
    int* foo,
    List(<float>) bar,
    na,
)
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
