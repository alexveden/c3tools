module test::c3tools::c3fmt_corpus @test;
import c3tools::codefmt;
import c3tools::codefmt::codecorpus @public;
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__generic_statements formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__generic_statements DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__multiple_decl() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
int a,b,c;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__multiple_decl formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int a, b, c;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__multiple_decl DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__call_statement_single_line() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    io::printf("soo", a, sooo::  foo::bar  (    "adskjalsda", looooong, var1));
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
return;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__call_statement_single_line formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    io::printf("soo", a, sooo::foo::bar("adskjalsda", looooong, var1));
    io::printf(
        "soo", a, sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__call_statement_single_line DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__double_long_call() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    return io::printf("soo", a, sooo::  foo::bar  (    "adskjalsda", looooong, var1)) + 
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__double_long_call formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return io::printf(
        "soo",
        a,
        sooo::foo::bar("adskjalsda", looooong, var1)
    ) + io::printf(
        "soo",
        a,
        sooo::foo::bar("adskjalsda", looooong, var1),
        another_var1
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__double_long_call DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__arith_and_long_call() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    return 2 + foo_log_long + 
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskja", looong, var1), another_var1
    ) + bar;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__arith_and_long_call formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return 2 + foo_log_long + io::printf(
        "soo", a, sooo::foo::bar("adskja", looong, var1), another_var1
    ) + bar;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__arith_and_long_call DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__logical_with_calls_in_parens() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    return (foo_log_long || bar && 
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    ) || bar);
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__logical_with_calls_in_parens formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return (
        foo_log_long ||
        bar &&
        io::printf("soo", a, sooo::foo::bar("adskjalsda", looooong, var1), another_var1) ||
        bar
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__logical_with_calls_in_parens DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__logical_with_calls_no_parens() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    return foo_log_long || bar && 
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    ) || bar;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__logical_with_calls_no_parens formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return foo_log_long || bar && io::printf(
        "soo",
        a,
        sooo::foo::bar("adskjalsda", looooong, var1),
        another_var1
    ) || bar;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__logical_with_calls_no_parens DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__chained_call() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    return 
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    ).foo(a).bar(b).baz(c);
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__chained_call formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return io::printf(
        "soo",
        a,
        sooo::foo::bar("adskjalsda", looooong, var1),
        another_var1
    ).foo(
        a
    ).bar(
        b
    ).baz(
        c
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__chained_call DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__assignment_with_call() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    foo[call(some,1,4, very_long_parametesr, anothe_one)] =
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__assignment_with_call formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foo[call(some, 1, 4, very_long_parametesr, anothe_one)] = io::printf(
        "soo", a, sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__assignment_with_call DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__assignment_left_too_long() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    foo[call(some,1,4, very_long_parametesr, anothe_one, "some stuff is going on it's too wide")] =
    io::printf(
        "soo", a, 
        sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__assignment_left_too_long formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foo[call(some, 1, 4, very_long_parametesr, anothe_one, "some stuff is going on it's too wide")] = io::printf(
        "soo", a, sooo::foo::bar("adskjalsda", looooong, var1), another_var1
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__assignment_left_too_long DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_struct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1,.world =2};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_struct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = { .hello = 1, .world = 2 };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_struct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_struct_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1,.world =2, .anothe_call = io::prinf("hi there it's c3fmt")   };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_struct_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1, .world = 2, .anothe_call = io::prinf("hi there it's c3fmt")
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_struct_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_struct_wrap_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.question = "how long it could be", .hello=1,.world =2, .anothe_call = io::prinf("hi there it's c3fmt")  , .this_is_a_lloong_field = (x & 12) };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_struct_wrap_multiline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .question = "how long it could be",
        .hello = 1,
        .world = 2,
        .anothe_call = io::prinf("hi there it's c3fmt"),
        .this_is_a_lloong_field = (x & 12)
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_struct_wrap_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_with_sub_structs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.question = "how long it could be",
        .sub = {.hello=1,.world =2, .sub_sub = {.foo = bar, .zoo= bas}, 
            .anothe_call = io::prinf(Foo{.nowrap=true}, "hi there it's c3fmt")  ,

            .a_call_unwrappe = io::prinf_wrapped_if_struct(long_argument_name, "another",  "hi there it's c3fmt") ,


            .this_is_a_lloong_field = (x & 12) },        
            };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_with_sub_structs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .question = "how long it could be",
        .sub = {
            .hello = 1,
            .world = 2,
            .sub_sub = {
                .foo = bar,
                .zoo = bas
            },
            .anothe_call = io::prinf(Foo {
                .nowrap = true
            },"hi there it's c3fmt"),
            .a_call_unwrappe = io::prinf_wrapped_if_struct(long_argument_name,"another","hi there it's c3fmt"),
            .this_is_a_lloong_field = (x & 12)
        },
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_with_sub_structs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_statement_simple() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if(   
    doo)
    {
    return
    0;}
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_statement_simple formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (doo) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_statement_simple DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_statement_simple_inside_if() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if(   
    doo)
    {
        if(foo){ return 1;}
    return
    0;}
return 200;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_statement_simple_inside_if formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (doo) {
        if (foo) {
            return 1;
        }
        return 0;
    }
    return 200;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_statement_simple_inside_if DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_statement_simple_sub_with_looong_condition() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if(   
    doo)
    {
        if(foo_bar(soo, okr) || fffff || zzz.another.foo(1, 2, 3) && a_little_bit ){ return 1;}
    return
    0;}
return 200;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_statement_simple_sub_with_looong_condition formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (doo) {
        if (
            foo_bar(soo, okr) ||
            fffff ||
            zzz.another.foo(1, 2, 3) &&
            a_little_bit
        ) {
            return 1;
        }
        return 0;
    }
    return 200;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_statement_simple_sub_with_looong_condition DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_statement_with_label() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if LABEL : (   
    doo)
    {
        if ANOTHER: (foo_bar(soo, okr) || fffff || zzz.another.foo(1, 2, 3) && a_little_bit ){ return 1;}
    return
    0;}
return 200;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_statement_with_label formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if LABEL: (doo) {
        if ANOTHER: (
            foo_bar(soo, okr) ||
            fffff ||
            zzz.another.foo(1, 2, 3) &&
            a_little_bit
        ) {
            return 1;
        }
        return 0;
    }
    return 200;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_statement_with_label DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_single_line() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if LABEL : (   
    doo)
        zzz.another.foo(1, 2, 3);
return 200;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_single_line formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if LABEL: (doo) zzz.another.foo(1, 2, 3);
    return 200;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_single_line DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_single_line_never_wraps() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if LABEL : (   
    doo)
        zzz.another.foo(whit_is_too_long, and_maybe(another, call, ther), 3);
return 200;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_single_line_never_wraps formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if LABEL: (doo) zzz.another.foo(whit_is_too_long, and_maybe(another, call, ther), 3);
    return 200;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_single_line_never_wraps DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_else_simple() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if(   
    doo)
    {
    return
    0;} else   
    {
    return 3;
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_else_simple formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (doo) {
        return 0;
    } else {
        return 3;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_else_simple DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_elseif_simple() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
if(   
    doo)
    {
    return
    0;} else  if  (
    bar
    )
    {
    return 3;
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_elseif_simple formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (doo) {
        return 0;
    } else if (bar) {
        return 3;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_elseif_simple DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__for_loop() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
for TOP  : (   
    int i=0;i< foo(call, some);i++)
    {
        break TOP  ;
        break;
        continue;
        continue TOP;
        continue TOP  :;
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__for_loop formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    for TOP: (int i = 0; i < foo(call, some); i++) {
        break TOP;
        break;
        continue;
        continue TOP;
        continue TOP:;
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__for_loop DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__for_loop_long_wrap_axis_semicol() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
for(   
    int i=foo.launch(some, stuff, kwarg: in_loong);i< foo(call, some) && another_long_condition;i++)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__for_loop_long_wrap_axis_semicol formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    for (
        int i = foo.launch(some, stuff, kwarg: in_loong);
        i < foo(call, some) && another_long_condition;
        i++
    ) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__for_loop_long_wrap_axis_semicol DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__for_loop_infinite() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
for(   
    ; ; ;)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__for_loop_infinite formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    for (;;;) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__for_loop_infinite DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__while_loop() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
while(   
    foo.launch(some, stuff, kwarg: in_loong) || i< foo(call, some) && another_long_condition)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__while_loop formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    while (
        foo.launch(some, stuff, kwarg: in_loong) ||
        i < foo(call, some) &&
        another_long_condition
    ) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__while_loop DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__foreach_loop_single() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
foreach(i   ,    z :   
    foo)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__foreach_loop_single formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foreach (i, z : foo) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__foreach_loop_single DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__foreach_r_loop_single() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
foreach_r(i:
    foo)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__foreach_r_loop_single formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foreach_r (i : foo) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__foreach_r_loop_single DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__foreach_loop() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
foreach(i   ,    z :   
    foo.launch(some, stuff, kwarg: in_loong) || i< foo(call, some) && another_long_condition)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__foreach_loop formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foreach (
        i, z :
        foo.launch(some, stuff, kwarg: in_loong) || i < foo(call, some) && another_long_condition
    ) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__foreach_loop DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__foreach_r_loop() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
  foreach_r   (i   ,    z :   
    foo.launch(some, stuff, kwarg: in_loong) || i< foo(call, some) && another_long_condition)
    {
    return
    0;}} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__foreach_r_loop formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foreach_r (
        i, z :
        foo.launch(some, stuff, kwarg: in_loong) || i < foo(call, some) && another_long_condition
    ) {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__foreach_r_loop DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_inline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    defer foo.launch(some, stuff, kwarg: in_loong);
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_inline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    defer foo.launch(some, stuff, kwarg: in_loong);
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_inline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_braces() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    defer { foo.launch(some, stuff, kwarg: in_loong);  if(too) {return 0;}}
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_braces formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    defer {
        foo.launch(some, stuff, kwarg: in_loong);
        if (too) {
            return 0;
        }
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_braces DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_empty() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    switch {}
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_empty formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch {
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_empty DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_empty_condition_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    switch LABEL: (    foo.launch(
        some, stuff, 
        kwarg: in_loong, this_is_another_looong_looong_field) ) {  }  
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_empty_condition_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch LABEL: (
        foo.launch(some, stuff, kwarg: in_loong, this_is_another_looong_looong_field)
    ) {
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_empty_condition_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_struct_magic_comma() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1,.world =2,};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_struct_magic_comma formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1,
        .world = 2,
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_struct_magic_comma DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_with_cases_and_default() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    switch LABEL: (    foo.launch(
        some, stuff, 
        kwarg: in_loong) ) {  
            case FOO:
            bar();
            case BAR:
            case BAZ:
            case "another":
            case 922:
                    if(foo) nextcase STATE: state.transition(SCOPE);
            case 1..0xffff:
            foo();
            default:  nextcase LABEL : FOO;
        }  
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_with_cases_and_default formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch LABEL: (foo.launch(some, stuff, kwarg: in_loong)) {
        case FOO:
            bar();
        case BAR:
        case BAZ:
        case "another":
        case 922:
            if (foo) nextcase STATE: state.transition(SCOPE);
        case 1..0xffff:
            foo();
        default:
            nextcase LABEL: FOO;
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_with_cases_and_default DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_with_cases_in_braces() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    switch LABEL: (    foo.launch(
        some, stuff, 
        kwarg: in_loong) ) {  
            case FOO: {
            bar() ; }
            case BAR:
            case BAZ:
            case "another"   :

            case 922:
            case 1..0xffff:
            foo();
            default   : {  nextcase LABEL : FOO;  }
                
        }  
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_with_cases_in_braces formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch LABEL: (foo.launch(some, stuff, kwarg: in_loong)) {
        case FOO: {
            bar();
        }
        case BAR:
        case BAZ:
        case "another":

        case 922:
        case 1..0xffff:
            foo();
        default: {
            nextcase LABEL: FOO;
        }

    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_with_cases_in_braces DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__scope_in_scope() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
{  foo = 0;}

    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__scope_in_scope formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    {
        foo = 0;
    }

    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__scope_in_scope DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_catch() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
defer (   catch 
err)
io::printfn("fault found: %s", err);

    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_catch formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    defer (catch err) io::printfn("fault found: %s", err);

    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_catch DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_catch_full_example() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    defer (catch 
    err)
    {
        io::printfn("Excuse found: %s", 
        err);
        (void)   
        free(data);
            (t.type=
            EMPTY_LINE);
    }
    // Returns Excuse, memory gets freed
    return IoError.FILE_NOT_FOUND?;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_catch_full_example formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    defer (catch err) {
        io::printfn("Excuse found: %s", err);
        (void)free(data);
        (t.type = EMPTY_LINE);
    }
    // Returns Excuse, memory gets freed
    return IoError.FILE_NOT_FOUND?;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_catch_full_example DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_catch_no_paren() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    defer catch
        io::printfn("Excuse found: %s", 
        err);
    return IoError.FILE_NOT_FOUND?;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_catch_no_paren formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    defer catch io::printfn("Excuse found: %s", err);
    return IoError.FILE_NOT_FOUND?;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_catch_no_paren DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__defer_catch_braces() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    defer catch 
        {io::printfn("Excuse found: %s", 
        err);}
    return IoError.FILE_NOT_FOUND?;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__defer_catch_braces formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    defer catch {
        io::printfn("Excuse found: %s", err);
    }
    return IoError.FILE_NOT_FOUND?;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__defer_catch_braces DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_catch_return_excuse() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
if (catch excuse = foo(call, dab))
                {
            // Return the excuse with ? operator
    return excuse?;
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_catch_return_excuse formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    if (catch excuse = foo(call, dab)) {
        // Return the excuse with ? operator
        return excuse?;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_catch_return_excuse DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__if_catch_switch() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void! test()
{
if (catch excuse = optional_value)
            {
    case NoHomework.DOG_ATE_MY_HOMEWORK:
                io::printn("Dog ate your file");
case IoError.FILE_NOT_FOUND:
            io::printn("File not found");
            default: {
            io::printfn("Unexpected Excuse: %s", excuse);
            return excuse?;}
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__if_catch_switch formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void! test()
{
    if (catch excuse = optional_value) {
        case NoHomework.DOG_ATE_MY_HOMEWORK:
            io::printn("Dog ate your file");
        case IoError.FILE_NOT_FOUND:
            io::printn("File not found");
        default: {
            io::printfn("Unexpected Excuse: %s", excuse);
            return excuse?;
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__if_catch_switch DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__body_macro() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
        c.@foo( a, b ; xyz , abcj ) 
        { xyz[1] =    4;};
    return 0;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__body_macro formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    c.@foo(a, b; xyz, abcj) {
        xyz[1] = 4;
    };
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__body_macro DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__expr_block() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    int foo = {| int a = 0; return a+1; |}  ! ;  
    return 0;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__expr_block formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    int foo = {|
        int a = 0;
        return a + 1;
    |}!;
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__expr_block DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__expr_block_bangbang() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    int foo = {| int a = 0; return a+1; |}  !! ;  
    return 0;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__expr_block_bangbang formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    int foo = {|
        int a = 0;
        return a + 1;
    |}!!;
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__expr_block_bangbang DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_jump_atts() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    switch LABEL: (    foo.launch(
        some, stuff, 
        kwarg: in_loong) ) @jump   {  }  
    return
    0;} 

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_jump_atts formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch LABEL: (foo.launch(some, stuff, kwarg: in_loong)) @jump {
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_jump_atts DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__switch_conditional() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
switch
{
    case 
    foo() > 0:   bar();
    case test() == 
    1:   baz();
    case 
    (foo_too_long(a, tb, sz) > 0 && another_too_loong(maybe) && just_one_more_condition > 0):   bar();
}
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__switch_conditional formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    switch {
        case foo() > 0:
            bar();
        case test() == 1:
            baz();
        case (
            foo_too_long(a, tb, sz) > 0 &&
            another_too_loong(maybe) &&
            just_one_more_condition > 0
        ):
            bar();
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__switch_conditional DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__asm_block() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int aa = 3;
int g;
int* gp = &g;
int* xa = &a;
usz asf = 1;
asm("nop");
asm 
    {
            movl x, 4;                  // Move 4 into the variable x
            movl [gp], {x};             // Move the value of x into the address in gp
            movl x, 1;                  // Move 1 into x
            movl [xa + asf * 4 + 4], x; // Move x into the address at xa[asf + 1]
            movl $eax, (23 + x);        // Move 23 + x into EAX
            movl x, $eax;               // Move EAX into x
            movq [&z], 33;              // Move 33 into the memory address of z
    }
if( foo) { return 1;}
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__asm_block formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int aa = 3;
    int g;
    int* gp = &g;
    int* xa = &a;
    usz asf = 1;
    asm("nop");
    asm {
            movl x, 4;                  // Move 4 into the variable x
            movl [gp], {x};             // Move the value of x into the address in gp
            movl x, 1;                  // Move 1 into x
            movl [xa + asf * 4 + 4], x; // Move x into the address at xa[asf + 1]
            movl $eax, (23 + x);        // Move 23 + x into EAX
            movl x, $eax;               // Move EAX into x
            movq [&z], 33;              // Move 33 into the memory address of z
    }
    if (foo) {
        return 1;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__asm_block DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_array() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[3] a = { 1, 2, 3 };
int[*] b = { 4, 5, 6 }; // Type inferred to be int[3]
int[] b2 = a[0 : 5]; // { 1, 20, 50, 100, 200 } start-index 0, slice-length 5
    int[] c2 = a[2 :];
    int[] c2 = a[2 .. ];
    int[] c2 = a[.. 2];
    int[] c2 = a[..  ];
    int[] c2 = a[ : ];
    int[] c2 = a[ : ^77];
    int[<?>] c2 = {1, 2, 3};
    int[] c2 = a[ ^ 77];
int[][4] unwrapped_array = { {1},{2, 3},{7, 8, 9, 10}};
    int[][4] array_magic_comma = {
    { 1 },
    { 2, 3 },
};
int[][4] wrapped_1line_array = { {1},{2, 3},{4, 5, 6},{7, 8, 9, 10},{7, 8, 9, 10}};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_array formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[3] a = { 1, 2, 3 };
    int[*] b = { 4, 5, 6 };  // Type inferred to be int[3]
    int[] b2 = a[0:5];  // { 1, 20, 50, 100, 200 } start-index 0, slice-length 5
    int[] c2 = a[2:];
    int[] c2 = a[2..];
    int[] c2 = a[..2];
    int[] c2 = a[..];
    int[] c2 = a[:];
    int[] c2 = a[:^77];
    int[<?>] c2 = { 1, 2, 3 };
    int[] c2 = a[^77];
    int[][4] unwrapped_array = { {1}, {2, 3}, {7, 8, 9, 10} };
    int[][4] array_magic_comma = {
        {1},
        {2, 3},
    };
    int[][4] wrapped_1line_array = {
        {1}, {2, 3}, {4, 5, 6}, {7, 8, 9, 10}, {7, 8, 9, 10}
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_array DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__vectors_arrays_generic() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
    int[<2>] a = { 23, 11 };
    int[<2>] b = { 2, 1 };
    int[<3>] a = { 11, 22, 33 };
    List(<int >) l = List.new(doo, 1);
    int[<4>] b = a.xxzx;                         // b = { 11, 11, 33, 11 }
    int c = b.w;                                 // c = 11;
    char[<4>] color = { 0x11, 0x22, 0x33, 0xFF };
    char red = color.r;                          // red = 0x11
    test_float(1.0, &f);
    foo_test::test(<int, double>) ( 1.0, &g );
    int[<2>] c = { a[0] * b[0], a[1] * b[1] };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__vectors_arrays_generic formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[<2>] a = { 23, 11 };
    int[<2>] b = { 2, 1 };
    int[<3>] a = { 11, 22, 33 };
    List(<int>) l = List.new(doo, 1);
    int[<4>] b = a.xxzx;  // b = { 11, 11, 33, 11 }
    int c = b.w;  // c = 11;
    char[<4>] color = { 0x11, 0x22, 0x33, 0xFF };
    char red = color.r;  // red = 0x11
    test_float(1.0, &f);
    foo_test::test(<int, double>)(1.0, &g);
    int[<2>] c = { a[0] * b[0], a[1] * b[1] };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__vectors_arrays_generic DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_initializers() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[256] x = { [0..128] = 1, [0] = {.a = b, .c = 1} };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_initializers formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[256] x = { [0..128] = 1, [0] = {.a = b, .c = 1} };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_initializers DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_initializers_wide() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[256] x = { [0..128] = 1, [0] = {.a = b, .c = 1}, [77] = {.soo = 0, .a = 1} };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_initializers_wide formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[256] x = {
        [0..128] = 1, [0] = {.a = b, .c = 1}, [77] = {.soo = 0, .a = 1}
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_initializers_wide DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_initializers_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[256] x = { [0..128] = 1, [0] = {.a = b, .c = 1},
[77] = {.soo = looong, .another = 1}, 
[888] = one_moar(call, should, be, one, line ) };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_initializers_multiline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[256] x = {
        [0..128] = 1,
        [0] = {.a = b, .c = 1},
        [77] = {.soo = looong, .another = 1},
        [888] = one_moar(call, should, be, one, line)
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_initializers_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__pointers() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
VoidFunc a = &test;
int b = (int)null;
int c = (int)a; // Invalid, not constant
int d = (int)((int*)1); // Invalid, not constant
byte a = 1;
int* b = (int*)a; // Invalid, pointer type is > 8 bits.
int* c = (int*)1; // Valid, but runtime value.
int* d = (int*)0; // Valid and constant value.
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__pointers formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    VoidFunc a = &test;
    int b = (int)null;
    int c = (int)a;  // Invalid, not constant
    int d = (int)((int*)1);  // Invalid, not constant
    byte a = 1;
    int* b = (int*)a;  // Invalid, pointer type is > 8 bits.
    int* c = (int*)1;  // Valid, but runtime value.
    int* d = (int*)0;  // Valid and constant value.
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__pointers DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__module_import() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module test::std::core::test @test @if(FOO || BAR);
import std::core::test    @public;
import std::core:: builtin;
import 
std::io;
module math_tests::complex   (< ElementType >) @test;
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__module_import formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module test::std::core::test @test @if(FOO || BAR);
import std::core::test @public;
import std::core::builtin;
import std::io;
module math_tests::complex(<ElementType>) @test;
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__module_import DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__const() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
const Time FAR_FUTURE = long.max;
const ulong WIN_TO_UNIX_EPOCH_US @local = 116444736000000000u64 / WINDOWS_TICK_US;
const CONTEXT_AMD64_ALL = CONTEXT_AMD64_CONTROL | CONTEXT_AMD64_INTEGER | CONTEXT_AMD64_SEGMENTS | CONTEXT_AMD64_FLOATING_POINT | CONTEXT_AMD64_DEBUG_REGISTERS;
const char[?] HEXALPHABET @private = "0123456789abcdef";
const Base64Alphabet URL = {
.encoding = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
.reverse = 2
};
const bool KEY_BY_VALUE @private = NO_KEY_FN ||| $assignable(Type{}[0], $typefrom(KeyFn.paramsof[0].type));
const bool KEY_BY_VALUE @private = $assignable(Type{}[0], $typefrom(KeyFn.paramsof[0].type)) ||| $assignable(Type{}[0], $typefrom(KeyFn.paramsof[0].type));
const Foo F4 = (F1 | ~F2) ^ F3;
const Foo F5 = Foo { true, false } | Foo { false, true };
const char[?] TEST_QOI_DATA = b64"cW9pZgAAAVQAAACpBABV/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39";

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__const formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
const Time FAR_FUTURE = long.max;
const ulong WIN_TO_UNIX_EPOCH_US @local = 116444736000000000u64 / WINDOWS_TICK_US;
const CONTEXT_AMD64_ALL = CONTEXT_AMD64_CONTROL | CONTEXT_AMD64_INTEGER | CONTEXT_AMD64_SEGMENTS | CONTEXT_AMD64_FLOATING_POINT | CONTEXT_AMD64_DEBUG_REGISTERS;
const char[?] HEXALPHABET @private = "0123456789abcdef";
const Base64Alphabet URL = {
    .encoding = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
    .reverse = 2
};
const bool KEY_BY_VALUE @private = NO_KEY_FN ||| $assignable(
    Type {}[0], $typefrom(KeyFn.paramsof[0].type)
);
const bool KEY_BY_VALUE @private = $assignable(
    Type {}[0],
    $typefrom(KeyFn.paramsof[0].type)
) ||| $assignable(
    Type {}[0],
    $typefrom(KeyFn.paramsof[0].type)
);
const Foo F4 = (F1 | ~F2) ^ F3;
const Foo F5 = Foo { true, false } | Foo { false, true };
const char[?] TEST_QOI_DATA = b64"cW9pZgAAAVQAAACpBABV/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39";
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__const DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__extern_func() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
extern fn Test func_returning_struct();
extern fn int printf(char *str, ...);
extern fn void* __asan_region_is_poisoned(void* beg, usz size);
extern fn void __sanitizer_weak_hook_strcmp(void* called_pc, ZString s1, ZString s2, CInt result);
extern fn Char16** _win_command_line_to_argv_w(ushort* cmd_line, int* argc_ptr) @extern("CommandLineToArgvW");
extern fn int! maybe();
extern fn Win32_BOOL win32_QueryPerformanceFrequency(Win32_LARGE_INTEGER* lpFrequency) @extern("QueryPerformanceFrequency");
extern Char16* _win_command_line_to_argv_w;
extern const int FOO @extern("foo1");
extern void *__stdoutp;
extern const char *manifest_default_keys[][2];

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__extern_func formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
extern fn Test func_returning_struct();
extern fn int printf(char* str, ...);
extern fn void* __asan_region_is_poisoned(void* beg, usz size);
extern fn void __sanitizer_weak_hook_strcmp(
    void* called_pc, ZString s1, ZString s2, CInt result
);
extern fn Char16** _win_command_line_to_argv_w(ushort* cmd_line, int* argc_ptr) @extern("CommandLineToArgvW");
extern fn int! maybe();
extern fn Win32_BOOL win32_QueryPerformanceFrequency(
    Win32_LARGE_INTEGER* lpFrequency
) @extern("QueryPerformanceFrequency");
extern Char16* _win_command_line_to_argv_w;
extern const int FOO @extern("foo1");
extern void* __stdoutp;
extern const char* manifest_default_keys[][2];
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__extern_func DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__do_while() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main()
{
do
{   io::printn("FOO");
} while (0);
do
{
    io::printn("FOO");
};
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__do_while formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    do {
        io::printn("FOO");
    } while(0);
    do {
        io::printn("FOO");
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__do_while DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_array_of_structs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { run_stuff_of_someth(),{.foo = 2, .bar = 3},{.sub = 1}, {1,2,3}};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_array_of_structs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = {
        run_stuff_of_someth(), {.foo = 2, .bar = 3}, {.sub = 1}, {1, 2, 3}
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_array_of_structs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_array_of_structs_magic_comma() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { run_stuff_of_someth(),{.foo = 2, .bar = 3},{.sub = 1}, {1,2,3},};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_array_of_structs_magic_comma formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = {
        run_stuff_of_someth(),
        {.foo = 2, .bar = 3},
        {.sub = 1},
        {1, 2, 3},
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_array_of_structs_magic_comma DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_with_arrays() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
    argparse::ArgParse agp = {
        .description = "c3 code formatting tool",
        .usage = "[options] file1 .. fileN",
        .options = { 
            argparse::help_opt(),
            {1, 3, 4, 5, 6},
            argparse::group_opt("Basic options"),
            { .short_name = 'f', .long_name = "force",  .value = &force_mode, .help = "force formatting non .c3 files"},
            { .short_name = 'n', .long_name = "dry",  .value = &dry_mode, .help = "dry mode (only print)"},
            argparse::group_opt("Code format options"),
            { .short_name = 'w', .long_name = "line-width",  .value = &max_line_width, .help = "max line width"},
        }, 
    };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_with_arrays formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    argparse::ArgParse agp = {
        .description = "c3 code formatting tool",
        .usage = "[options] file1 .. fileN",
        .options = {
            argparse::help_opt(),
            {
                1,
                3,
                4,
                5,
                6
            },
            argparse::group_opt("Basic options"),
            {
                .short_name = 'f',
                .long_name = "force",
                .value = &force_mode,
                .help = "force formatting non .c3 files"
            },
            {
                .short_name = 'n',
                .long_name = "dry",
                .value = &dry_mode,
                .help = "dry mode (only print)"
            },
            argparse::group_opt("Code format options"),
            {
                .short_name = 'w',
                .long_name = "line-width",
                .value = &max_line_width,
                .help = "max line width"
            },
        },
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_with_arrays DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__struct_designated_init_in_different_ctx() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {};
    MyStruct foo = {1, 2,3};
    MyStruct foo = {.bax = 2};
    MyStruct foo_magic = {.bax = 2,};
    call(MyStruct{}, Bar   {.soo = 1, });
    call(MyStruct{1, 2, 3});
    MyStruct foo = (MyStruct)call(MyStruct{1, 2, 3});
    MyStruct foo = (MyStruct)call(MyStruct{1, 2, 3, });
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__struct_designated_init_in_different_ctx formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {};
    MyStruct foo = { 1, 2, 3 };
    MyStruct foo = { .bax = 2 };
    MyStruct foo_magic = {
        .bax = 2,
    };
    call(MyStruct {}, Bar {.soo = 1,});
    call(MyStruct {1, 2, 3});
    MyStruct foo = (MyStruct)call(MyStruct {1, 2, 3});
    MyStruct foo = (MyStruct)call(MyStruct {1, 2, 3,});
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__struct_designated_init_in_different_ctx DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__body_macro_with_arg() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String Token.to_string(&self, Allocator allocator) @dynamic {
    @pool(allocator)
    {
        DString builder = dstring::temp_new();
        if (foo) {return 0;
        }
        return builder.copy_str(allocator);
    };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__body_macro_with_arg formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String Token.to_string(&self, Allocator allocator) @dynamic
{
    @pool(allocator) {
        DString builder = dstring::temp_new();
        if (foo) {
            return 0;
        }
        return builder.copy_str(allocator);
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__body_macro_with_arg DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__body_macro_no_arg() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String Token.to_string(&self, Allocator allocator) @dynamic {
    @pool
    {
        DString builder = dstring::temp_new();
        if (foo) {return 0;
        }
        return builder.copy_str(allocator);
    };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__body_macro_no_arg formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String Token.to_string(&self, Allocator allocator) @dynamic
{
    @pool {
        DString builder = dstring::temp_new();
        if (foo) {
            return 0;
        }
        return builder.copy_str(allocator);
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__body_macro_no_arg DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__expr_block_standalone() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn  char[   ]   ! test   ()
{
    {| int a = 0; return a+1; |}  ! ;  
    return 0;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__expr_block_standalone formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn char[]! test()
{
    {|
        int a = 0;
        return a + 1;
    |}!;
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__expr_block_standalone DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__expr_block_standalone_body_macro() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String Token.to_string(&self, Allocator allocator) @dynamic {
    @pool()
    {
        DString builder = dstring::temp_new();
        {| int a = 2; return a;
        |}!!;
        return builder.copy_str(allocator);
    };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__expr_block_standalone_body_macro formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String Token.to_string(&self, Allocator allocator) @dynamic
{
    @pool() {
        DString builder = dstring::temp_new();
        {|
            int a = 2;
            return a;
        |}!!;
        return builder.copy_str(allocator);
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__expr_block_standalone_body_macro DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_with_parens() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { (a + 1 + 3), (b + 1 & 2), (1 ||2&&3)};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_with_parens formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = { (a + 1 + 3), (b + 1 & 2), (1 || 2 && 3) };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_with_parens DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_with_parens_single_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { (a + 1 + 3), (b + 1 & 2), (1 ||2&&3), (boar + foo + aso)};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_with_parens_single_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = {
        (a + 1 + 3), (b + 1 & 2), (1 || 2 && 3), (boar + foo + aso)
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_with_parens_single_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__array_with_parens_multi_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { (a + 1 + 3), (b + 1 & 2), (1 ||2&&3), (boar + foo + aso),};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__array_with_parens_multi_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = {
        (a + 1 + 3),
        (b + 1 & 2),
        (1 || 2 && 3),
        (boar + foo + aso),
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__array_with_parens_multi_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__designated_initializers_with_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
    argparse::ArgParse agp = {  //  inline2
        // stuff
        .description = "c3 code formatting tool",
        // another
        .usage = "[options] file1 .. fileN", // maybe inline
        .options = { 
            // one moar
            .foo = {1, 2, 3, // another inline
            },
        }, 
    };
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__designated_initializers_with_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    argparse::ArgParse agp = {  //  inline2
        // stuff
        .description = "c3 code formatting tool",
        // another
        .usage = "[options] file1 .. fileN",  // maybe inline
        .options = {
            // one moar
            .foo = {
                1,
                2,
                3,  // another inline
            },
        },
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__designated_initializers_with_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__struct_init_with_fn_pointers() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

TestContext state @local  = {
.foo = 1, 
    .setup_fn = fn void!() {
        io::printn("new test setup");
        // initialize something heavy (maybe a DB)
        state.n_runs = 777;
    }, 
    .teardown_fn = fn void!() { // inline
        state.n_runs = 0;
        io::printn("test teardown"); // inline
    },
.bar = 1, 
};

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__struct_init_with_fn_pointers formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
TestContext state @local = {
    .foo = 1,
    .setup_fn = fn void! () {
        io::printn("new test setup");
        // initialize something heavy (maybe a DB)
        state.n_runs = 777;
    },
    .teardown_fn = fn void! () {  // inline
        state.n_runs = 0;
        io::printn("test teardown");  // inline
    },
    .bar = 1,
};
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__struct_init_with_fn_pointers DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__struct_init_with_sub_fn() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

TestContext state @local = {
    .foo = 1, 
    .sub_struct ={
        .another = {1, 2, 3},
        .setup_fn = fn void! (int a, int b, $typeof(c) c) {
            io::printn("new test setup");
            // initialize something heavy (maybe a DB)
            state.n_runs = 777;
        }, 
        .sub_field = 1
    }, 
    .teardown_fn = fn void!() { // inline
        state.n_runs = 0;
        io::printn("test teardown"); // inline
    },
    .bar = 1, 
};

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__struct_init_with_sub_fn formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
TestContext state @local = {
    .foo = 1,
    .sub_struct = {
        .another = {
            1,
            2,
            3
        },
        .setup_fn = fn void! (int a, int b, $typeof(c) c) {
            io::printn("new test setup");
            // initialize something heavy (maybe a DB)
            state.n_runs = 777;
        },
        .sub_field = 1
    },
    .teardown_fn = fn void! () {  // inline
        state.n_runs = 0;
        io::printn("test teardown");  // inline
    },
    .bar = 1,
};
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__struct_init_with_sub_fn DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__struct_init_with_sub_previous_sub_struct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

TestContext state @local = {
    .foo = 1, 
    .sub_struct ={
        .sub_field = 1,
        .sub_field = 2
    }, 
    .teardown_fn = fn void!() { // inline
        state.n_runs = 0;
        io::printn("test teardown"); // inline
    },
    .bar = 1, 
};

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__struct_init_with_sub_previous_sub_struct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
TestContext state @local = {
    .foo = 1,
    .sub_struct = {
        .sub_field = 1,
        .sub_field = 2
    },
    .teardown_fn = fn void! () {  // inline
        state.n_runs = 0;
        io::printn("test teardown");  // inline
    },
    .bar = 1,
};
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__struct_init_with_sub_previous_sub_struct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__statements__inline_code_flow() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main()
{
    foreach (&c : s) if (c.is_upper() @pure) *c += 'a' - 'A';
    foreach (&c : s) if (c.is_upper() @pure) &c = null;
    foreach (&c : s) if (c.is_upper() @pure) return 0;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__statements__inline_code_flow formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    foreach (&c : s) if (c.is_upper() @pure) *c += 'a' - 'A';
    foreach (&c : s) if (c.is_upper() @pure) &c = null;
    foreach (&c : s) if (c.is_upper() @pure) return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__statements__inline_code_flow DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__expressions() 
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__expressions formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__expressions DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__simple_expressions() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() { 
bool a =(a||b)&&c; 
int* bin = (int*)&a;
b = *(int*)&a;
b = (*a = 2);
b = { .work = 1, .work=2 };
 (  void) free(data);
    (void * * )free(data);
    int* bin = &&1;
return;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__simple_expressions formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    bool a = (a || b) && c;
    int* bin = (int*)&a;
    b = *(int*)&a;
    b = (*a = 2);
    b = { .work = 1, .work = 2 };
    (void)free(data);
    (void**)free(data);
    int* bin = &&1;
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__simple_expressions DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__ternary() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() { 
bool a = foo    ? bar   : 1;
return file ?: file_open_errno()?;
return i ?: Foo.X?;
return x ?: (y ?: x);
assert((root.get_int("yyy") ?? -1) == -1);
double x = ((double)testError() + testError()) ?? 100;
io::printfn("6:%s", @catch((3 > 2 ? Foo.ABC? : 4) ?? Foo.DEF?));
bool a = foo    ? * other   : * self;
return * i ?: *self;
return FOO ? X : Z;
    return foo ? socket_error()? : bar;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__ternary formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    bool a = foo ? bar : 1;
    return file ?: file_open_errno()?;
    return i ?: Foo.X?;
    return x ?: (y ?: x);
    assert((root.get_int("yyy") ?? - 1) == -1);
    double x = ((double)testError() + testError()) ?? 100;
    io::printfn("6:%s", @catch((3 > 2 ? Foo.ABC? : 4) ?? Foo.DEF?));
    bool a = foo ? *other : *self;
    return *i ?: *self;
    return FOO ? X : Z;
    return foo ? socket_error()? : bar;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__ternary DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__numbers() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() { 
int a = -1;
int a = -float.inf;
int a = 3 -float.inf;
int a = 3+1;
return +1;
return 1;
int a = (usz)-1;
int a = -add(-2, -3);
return (usz)+1.234f;
return a == -1;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__numbers formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int a = -1;
    int a = -float.inf;
    int a = 3 - float.inf;
    int a = 3 + 1;
    return +1;
    return 1;
    int a = (usz)-1;
    int a = -add(-2, -3);
    return (usz)+1.234f;
    return a == -1;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__numbers DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__generic_vec_expr() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() { 
List(<Foo*>) lfoo;
List(<Foo*>)* lfoo = List(<Foo*>){}.init(bar: 1);
int[<2>]* lfoo = int[<2 >]{}.init(bar: 1);
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__generic_vec_expr formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    List(<Foo*>) lfoo;
    List(<Foo*>)* lfoo = List(<Foo*>){}.init(bar: 1);
    int[<2>]* lfoo = int[<2>]{}.init(bar: 1);
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__generic_vec_expr DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__conditional_expr_multi_parens_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro bool char_is_base64(char c)
{
    return ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
                || c == '+' || c == '/');
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__conditional_expr_multi_parens_multiline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro bool char_is_base64(char c)
{
    return (
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9') ||
        c == '+' ||
        c == '/'
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__conditional_expr_multi_parens_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__conditional_expr_multi_parens_single_line() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro bool char_is_base64(char c)
{
    return ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'));
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__conditional_expr_multi_parens_single_line formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro bool char_is_base64(char c)
{
    return (
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9')
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__conditional_expr_multi_parens_single_line DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__call_with_parens_single_line_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro bool char_is_base64(char c)
{
    return its_along_call((arg_long_ags+1), (foo ?(bar) : baz), (a && b && coooooooooool) );
    return its_along_call((arg_long_ags+1), (foo ?bar : baz), (a && b && coooooooooool) );
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__call_with_parens_single_line_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro bool char_is_base64(char c)
{
    return its_along_call(
        (arg_long_ags + 1), (foo ? (bar) : baz), (a && b && coooooooooool)
    );
    return its_along_call(
        (arg_long_ags + 1), (foo ? bar : baz), (a && b && coooooooooool)
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__call_with_parens_single_line_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__call_with_parens_multi_line_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro bool char_is_base64(char c)
{
    return its_along_call((arg_long_ags+1), (foo ?(bar) : baz), (a && b && coooooooooool), (a | super + too_long ) );
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__call_with_parens_multi_line_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro bool char_is_base64(char c)
{
    return its_along_call(
        (arg_long_ags + 1),
        (foo ? (bar) : baz),
        (a && b && coooooooooool),
        (a | super + too_long)
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__call_with_parens_multi_line_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__bang_expressions() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn List(<int>)! foo() => 0;
fn int[<2>]! foo() => 0;

def TFoo = fn List(<int>)! foo();
def TFoo = fn int[<3>]! foo();
def TFoo = fn int! foo();
def TFoo = fn int*! foo();

fn void! main() { 
    char! c = call();
    char*! c = call();
    char c = call()!;
    char c = !call();
    int[<2>]! c = call();
    List<[2]>! c = call();
    List(<2>)! c = call();
    if(!foo()) return 0;
    if(!foo() && (!(foo | bar) && !foo)) return 0;
    return !(!foo());
    if(!*self) return 0;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__bang_expressions formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn List(<int>)! foo() => 0;
fn int[<2>]! foo() => 0;

def TFoo = fn List(<int>)! foo();
def TFoo = fn int[<3>]! foo();
def TFoo = fn int! foo();
def TFoo = fn int*! foo();

fn void! main()
{
    char! c = call();
    char*! c = call();
    char c = call()!;
    char c = !call();
    int[<2>]! c = call();
    List <[2] >! c = call();
    List(<2>)! c = call();
    if (!foo()) return 0;
    if (!foo() && (!(foo | bar) && !foo)) return 0;
    return !(!foo());
    if (!*self) return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__bang_expressions DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__brackets() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() { 
    char[] foo = arr[];
    int[?] arr = { 1 };
    ar[:] = 1;
    foo = arr[:a];
    arr[..a];
    arr[b..];
    arr[b..a];
    arr[b:];
    arr[:a];
    arr[b:a];
    arr[^1:];
    arr[:^2];
    arr[^2..^1];
    arr[i..^1];
    arr[i + 1 .. i * 1];
    arr[i + 1 .. i];
    arr[foo(1, 2, kwarg: 3) + 1 : bar()];
    arr[(i & a) * 0xff];
    arr[(i | a) & 0xff];
    return a[ : decode()!];
    arr[(0.2f | DASK) & MASK];
    arr[(0.2f >> DASK) & MASK];
    arr[(0.2f << foo()) & MASK];
    arr[((uint)0.2f << (char)foo()) & (int)MASK];
    arr[src[i + 1 :]];
    arr[src[i + 1 : i]];
    arr[src[i : i + 1]];
    arr[(char)((result ^ x) & x)];
    arr[(in[i + 1] & 3) >> 2 * foo];
    arr[i++];
    arr[--i];
    arr[a - 1];
    int a = (int)arr[i + 1];
    int a = (int)arr[i - 1];
    int a = (int)arr[i * 1];
    int a = (int)arr[i & 1];
    int a = (int)arr[i ^ 1];
    int a = (void*)arr + foo;
    int a = (void*)arr - foo;
    int a = (void*)arr * foo;
    int a = (void*)arr & foo;
}

fn void b(int[2]* p, int* p2)
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__brackets formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    char[] foo = arr[];
    int[?] arr = { 1 };
    ar[:] = 1;
    foo = arr[:a];
    arr[..a];
    arr[b..];
    arr[b..a];
    arr[b:];
    arr[:a];
    arr[b:a];
    arr[^1:];
    arr[:^2];
    arr[^2..^1];
    arr[i..^1];
    arr[i + 1 .. i * 1];
    arr[i + 1 .. i];
    arr[foo(1, 2, kwarg: 3) + 1 : bar()];
    arr[(i & a) * 0xff];
    arr[(i | a) & 0xff];
    return a[:decode()!];
    arr[(0.2f | DASK) & MASK];
    arr[(0.2f >> DASK) & MASK];
    arr[(0.2f << foo()) & MASK];
    arr[((uint)0.2f << (char)foo()) & (int)MASK];
    arr[src[i + 1 :]];
    arr[src[i + 1 : i]];
    arr[src[i:i + 1]];
    arr[(char)((result ^ x) & x)];
    arr[(in[i + 1] & 3) >> 2 * foo];
    arr[i++];
    arr[--i];
    arr[a - 1];
    int a = (int)arr[i + 1];
    int a = (int)arr[i - 1];
    int a = (int)arr[i * 1];
    int a = (int)arr[i & 1];
    int a = (int)arr[i ^ 1];
    int a = (void*)arr + foo;
    int a = (void*)arr - foo;
    int a = (void*)arr * foo;
    int a = (void*)arr & foo;
}

fn void b(int[2]* p, int* p2)
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__brackets DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__double_plus_minus() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main()
{
    usz len =++(*index_ptr);
    for(; ++(*a); ++i);
    return ++a;
    return --a;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__double_plus_minus formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    usz len = ++(*index_ptr);
    for (; ++(*a); ++i) ;
    return ++a;
    return --a;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__double_plus_minus DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__expressions__double_quest_errors() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void main()
{
    String text = io::readline() ?? InputResult.FAILED_TO_READ?!;
    io::fprintf(out, "%s", s.title.get() ?? "missing", s.ok)!;
    return Summary {
        .title = new_string_val(doc.head.get().title.get()) ?? MaybeString {},
        .ok = true,
    };
    long e10 = String.to_long() ?? NumberConversion.MALFORMED_FLOAT ? !;
    url.path = decode(allocator) ?? UrlParsingResult.INVALID_PATH ? !;
    int! b = foo((a + 3) ?? 2);
    char* data4 = $embed("fiek") ?? null;
    bool r = foo ? !bar : !vrr;
    bool r = foo ? (!bar) : !vrr;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__expressions__double_quest_errors formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    String text = io::readline() ?? InputResult.FAILED_TO_READ?!;
    io::fprintf(out, "%s", s.title.get() ?? "missing", s.ok)!;
    return Summary {
        .title = new_string_val(doc.head.get().title.get()) ?? MaybeString {},
        .ok = true,
    };
    long e10 = String.to_long() ?? NumberConversion.MALFORMED_FLOAT?!;
    url.path = decode(allocator) ?? UrlParsingResult.INVALID_PATH?!;
    int! b = foo((a + 3) ?? 2);
    char* data4 = $embed("fiek") ?? null;
    bool r = foo ?!bar : !vrr;
    bool r = foo ? (!bar) : !vrr;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__expressions__double_quest_errors DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__simple_one_line_comment() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() {
              //this simple comment
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__simple_one_line_comment formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    //this simple comment
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__simple_one_line_comment DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__simple_inline_comment() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

/// single one
fn void 
main() {  //this is a comment
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__simple_inline_comment formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
/// single one
fn void main()
{  //this is a comment
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__simple_inline_comment DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__simple_inline_after_eos_comment() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() {  
return;//this is inline comment       
// single line comment               
        if(fgoo) { return bar; // another inline coment
    } 
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__simple_inline_after_eos_comment formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return;  //this is inline comment
    // single line comment
    if (fgoo) {
        return bar;  // another inline coment
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__simple_inline_after_eos_comment DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__multiline_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
/***
** Hi this is
a comment */
fn void 
main() {  
return/* inline comment before ; */;
    /* multi
    line comment {
    */
        if(fgoo) { return bar;         /* another inline comment */  } 
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__multiline_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
/***
** Hi this is
a comment */
fn void main()
{
    return   /* inline comment before ; */
    ;
    /* multi
    line comment {
    */
    if (fgoo) {
        return bar;  /* another inline comment */
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__multiline_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__comments_inside_func_args() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String[]! 
Foo.main(
String[] args, int* foo, List(<float>) /* some */     
bar, na   ,    varg...
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__comments_inside_func_args formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(
    String[] args,
    int* foo,
    List(<float>)   /* some */
    bar,
    na,
    varg...
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
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__comments_inside_func_args DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__comments_single_line_forces_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String[]! 
Foo.main(
// coment
List(<float>)
bar, int a
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__comments_single_line_forces_multiline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(
    // coment
    List(<float>) bar,
    int a
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
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__comments_single_line_forces_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__comments_in_statements_inline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() {
if(this_a_condition && // do we have to comment next?
another_condition && /* maybe the followed by another */
      /* this another multiline */
foo
) { return 1;}
return   0   
;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__comments_in_statements_inline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (
        this_a_condition &&  // do we have to comment next?
        another_condition &&  /* maybe the followed by another */
        /* this another multiline */
        foo
    ) {
        return 1;
    }
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__comments_in_statements_inline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__in_call_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
/***
** Hi this is
a comment */
fn void 
main() {  
    return foo(bar,  // a stuff,
            foofoo,  //another
            var,  // super var
    );
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__in_call_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
/***
** Hi this is
a comment */
fn void main()
{
    return foo(
        bar,  // a stuff,
        foofoo,  //another
        var,  // super var
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__in_call_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__comment_before_next_fn() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void foo()
{

}

// comment TODO: maybe fix it?

fn bool bar()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__comment_before_next_fn formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void foo()
{

}

// comment TODO: maybe fix it?

fn bool bar()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__comment_before_next_fn DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__in_code_scope_mixed_with_empty_lines() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() {  
return;//this is inline comment

// single line comment

        if(fgoo) { return bar; // another inline coment
    } 
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__in_code_scope_mixed_with_empty_lines formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    return;  //this is inline comment

    // single line comment

    if (fgoo) {
        return bar;  // another inline coment
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__in_code_scope_mixed_with_empty_lines DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__if_inline_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() {  
        if(fgoo) // comment
        {
            return 0;
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__if_inline_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    if (fgoo)  // comment
    {
        return 0;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__if_inline_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__comment_before_fn() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void m() {}


// a comment
fn void main() {  
    return; //this is inline comment
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__comment_before_fn formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void m()
{
}

// a comment
fn void main()
{
    return;  //this is inline comment
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__comment_before_fn DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__array_with_multi_inline_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main()
{
int[][4] wrapped_array = { 
(a + 1 + 3), /* 1 */ 
(b + 1 & 2), /* 2 */
(1 ||2&&3), /* 3 */ 
(boar + foo + aso), /* 4 */
};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__array_with_multi_inline_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    int[][4] wrapped_array = {
        (a + 1 + 3),  /* 1 */
        (b + 1 & 2),  /* 2 */
        (1 || 2 && 3),  /* 3 */
        (boar + foo + aso),  /* 4 */
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__array_with_multi_inline_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__designated_initializers_struct_single_comments_inside() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1,
    // comment
    .world =2};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__designated_initializers_struct_single_comments_inside formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1,
        // comment
        .world = 2
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__designated_initializers_struct_single_comments_inside DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__designated_initializers_struct_inline_comments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1, // world
    .world =2};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__designated_initializers_struct_inline_comments formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1,  // world
        .world = 2
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__designated_initializers_struct_inline_comments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__designated_initializers_struct_multi_comments_inside() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1,
    /* comment */
    .world =2};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__designated_initializers_struct_multi_comments_inside formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1,
        /* comment */
        .world = 2
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__designated_initializers_struct_multi_comments_inside DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__comments__designated_initializers_struct_multi_inline_comments_inside() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void main() 
{ 
    MyStruct foo = {.hello=1, /* comment */
    .world =2};
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__comments__designated_initializers_struct_multi_inline_comments_inside formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    MyStruct foo = {
        .hello = 1,  /* comment */
        .world = 2
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__comments__designated_initializers_struct_multi_inline_comments_inside DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__simple_struct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

struct 
Person {
    char age;   string::String name; }
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__simple_struct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
struct Person
{
    char age;
    string::String name;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__simple_struct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__simple_sub_struct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

struct 
Person @extern(  "foo") {
    struct foo // its a kinda struct
    { int bar; struct zoo @if(asd || dda) {

            <* doc c *>
    int c;

    int d;
    }}
    }
    struct Friend {
        bool or_foe;
    }
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__simple_sub_struct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
struct Person @extern(  "foo")
{
    struct foo   // its a kinda struct
    {
        int bar;
        struct zoo @if(asd || dda)
        {

            <* doc c *>
            int c;

            int d;
        }
    }
}

struct Friend
{
    bool or_foe;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__simple_sub_struct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__struct_union_inline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

union
Person @extern(  "foo") {
inline    Pet    cat  ;
    struct foo // its a kinda struct
    { int bar; union zoo @if(asd || dda) { int  [34 ] c;}}
    }
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__struct_union_inline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
union Person @extern(  "foo")
{
    inline Pet cat;
    struct foo   // its a kinda struct
    {
        int bar;
        union zoo @if(asd || dda)
        {
            int[34] c;
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__struct_union_inline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__bitstruct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
bitstruct Foo: 
char 
@bigendian
{
    int a : 0..2;   int b : 4..6;   bool c : 7;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__bitstruct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
bitstruct Foo : char @bigendian
{
    int a : 0..2;
    int b : 4..6;
    bool c : 7;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__bitstruct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__bitstruct_char_array() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
bitstruct Test2 : char[4] @bigendian
{
    ushort a : 0..15;
    ushort b : 16..31;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__bitstruct_char_array formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
bitstruct Test2 : char[4] @bigendian
{
    ushort a : 0..15;
    ushort b : 16..31;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__bitstruct_char_array DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__simple_enum() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
enum State
{
    WAITING,    RUNNING,    TERMINATED
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__simple_enum formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
enum State
{
    WAITING,
    RUNNING,
    TERMINATED
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__simple_enum DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__simple_enum_multi_comma() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
enum State:
int @test @if( asd || bar)
{
    WAITING,    RUNNING,    TERMINATED,
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__simple_enum_multi_comma formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
enum State : int @test @if( asd || bar)
{
    WAITING,
    RUNNING,
    TERMINATED,
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__simple_enum_multi_comma DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__enum_associated() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
enum State : int @if("foo") (
String desc, bool active, Position pos
) @test
{
    WAITING    = { "waiting", false, { 1, 2} }, // this is a comment
    RUNNING    = { "running", true,  {12,22} },
    TERMINATED = { "ended",   false, {0, 0} },
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__enum_associated formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
enum State : int @if("foo") (String desc, bool active, Position pos) @test
{
    WAITING = { "waiting", false, {1, 2} },  // this is a comment
    RUNNING = { "running", true, {12, 22} },
    TERMINATED = { "ended", false, {0, 0} },
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__enum_associated DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__enum_associated_definition_wrapping() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
enum State : int @if("foo") (
String desc, bool active, Position pos, FooooLong type, AnotherLoong Type, maybe_one_more
) @test
{
    WAITING    = { "waiting", false, {1, 2} }, // this is a comment
    RUNNING    = { "running", true,  {12,22} },
    TERMINATED = { "ended",   false, { 0, 0} },
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__enum_associated_definition_wrapping formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
enum State : int @if("foo") (
    String desc,
    bool active,
    Position pos,
    FooooLong type,
    AnotherLoong Type,
    maybe_one_more
) @test
{
    WAITING = { "waiting", false, {1, 2} },  // this is a comment
    RUNNING = { "running", true, {12, 22} },
    TERMINATED = { "ended", false, {0, 0} },
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__enum_associated_definition_wrapping DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__enum_associated_magic_comma() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
enum State : int @if("foo") (
String desc, bool active, Position pos
) @test
{
    WAITING    = { "waiting", false, {1, 2}, }, // this is a comment
    RUNNING    = { "running", true,  {12,22,} },
    TERMINATED = { "ended",   false, {0, 0} },
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__enum_associated_magic_comma formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
enum State : int @if("foo") (String desc, bool active, Position pos) @test
{
    WAITING = {
        "waiting",
        false,
        {1, 2},
    },  // this is a comment
    RUNNING = { "running", true, {12, 22,} },
    TERMINATED = { "ended", false, {0, 0} },
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__enum_associated_magic_comma DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__fault_simple() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fault Err
{
    OOPS, OOPS_WITH_COMMENT,   // this is an oops
    LOTS_OF_OOPS
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__fault_simple formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fault Err
{
    OOPS,
    OOPS_WITH_COMMENT,  // this is an oops
    LOTS_OF_OOPS
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__fault_simple DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__def_statement_global() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
def EnumSetType = $typefrom(private::type_for_enum_elements(Enum.elements)) @private;
def ElementTest = fn bool(Type *type, any context);
def TestFailFn = fn void! (bool to_fail);
def FormatTzTestSpec = Triple(<TzDateTime, DateTimeFormat, String>);
def IntList = ElasticArray(<int, 10>);
def BenchmarkFn = fn void!(int) @if($$OLD_TEST);
def @Align(y) = { @Align16(y / 2) };
def @Test = { @noinline };
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__def_statement_global formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
def EnumSetType = $typefrom(
    private::type_for_enum_elements(Enum.elements)
) @private;
def ElementTest = fn bool (Type* type, any context);
def TestFailFn = fn void! (bool to_fail);
def FormatTzTestSpec = Triple(<TzDateTime, DateTimeFormat, String>);
def IntList = ElasticArray(<int, 10>);
def BenchmarkFn = fn void! (int) @if($$OLD_TEST);
def @Align(y) = { @Align16(y / 2) };
def @Test = { @noinline };
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__def_statement_global DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__def_interface() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
interface Printable @if("sasda")
{
    fn String* to_string(Allocator allocator) @optional;
    fn String to_new_string(Allocator allocator) @optional @deprecated("Use to_string");
    fn usz! to_format(Formatter* formatter) @optional;
    fn usz* to_format(Formatter* formatter, Alooong Type, Maybe can, bool wrap, please) @optional;
    fn usz* to_format(Formatter* formatter, Alooong Type, Maybe can, bool wrap, please, or_maybe multiline) @optional;
    fn usz* to_format(Formatter* magic_comma, ) @optional;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__def_interface formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
interface Printable @if("sasda")
{
    fn String* to_string(Allocator allocator) @optional;
    fn String to_new_string(Allocator allocator) @optional @deprecated("Use to_string");
    fn usz! to_format(Formatter* formatter) @optional;
    fn usz* to_format(
        Formatter* formatter, Alooong Type, Maybe can, bool wrap, please
    ) @optional;
    fn usz* to_format(
        Formatter* formatter,
        Alooong Type,
        Maybe can,
        bool wrap,
        please,
        or_maybe multiline
    ) @optional;
    fn usz* to_format(
        Formatter* magic_comma,
    ) @optional;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__def_interface DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__distinct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
distinct Color = float[<4>];
distinct TypeA = char[];
distinct Bob = inline Abc;
distinct Foo = fn void(Foo** x); // #error: cannot define a new function type
distinct Foo = inline PrivateFoo(<int>); // #error: could not be found
distinct PriorityQueue = inline PrivatePriorityQueue <[Type,false] >;
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__distinct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
distinct Color = float[<4>];
distinct TypeA = char[];
distinct Bob = inline Abc;
distinct Foo = fn void (Foo** x);  // #error: cannot define a new function type
distinct Foo = inline PrivateFoo(<int>);  // #error: could not be found
distinct PriorityQueue = inline PrivatePriorityQueue <[Type, false] >;
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__distinct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__union_with_struct() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
union SourceSpan
{
    struct
    {
        char length;
        uint col;
        uint row;
    }
    ulong a;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__union_with_struct formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
union SourceSpan
{
    struct
    {
        char length;
        uint col;
        uint row;
    }
    ulong a;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__union_with_struct DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__typeid_cases() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

extern typeid foo;

struct ReflectedParam (Printable) @if(!$defined(ReflectedParam))
{
    String name;
    typeid type;
}
def Time_t = $typefrom(env::WIN32 ? long.typeid : CLong.typeid);

macro bool @typeis(#value, $Type) @const @builtin => $typeof(#value).typeid == $Type.typeid;

fn typeid 
main( typeid t) { 
        $switch
        $case @is_vector(y) &&& $typeof(y).inner == float.typeid:
            return (float)x;
        $case $typeof(y).typeid == float.typeid:
            return (float)x;
        $default:
            return (double)x;
        $endswitch
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__typeid_cases formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
extern typeid foo;

struct ReflectedParam (Printable) @if(!$defined(ReflectedParam))
{
    String name;
    typeid type;
}

def Time_t = $typefrom(env::WIN32 ? long.typeid : CLong.typeid);

macro bool @typeis(#value, $Type) @const @builtin => $typeof(#value).typeid == $Type.typeid;

fn typeid main(typeid t)
{
    $switch
        $case @is_vector(y) &&& $typeof(y).inner == float.typeid:
            return (float)x;
        $case $typeof(y).typeid == float.typeid:
            return (float)x;
        $default:
            return (double)x;
    $endswitch
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__typeid_cases DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__any_anyfault() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro any
main(any foo) { return;}

macro anyfault
main(anyfault foo) { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__any_anyfault formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro any main(any foo)
{
    return;
}

macro anyfault main(anyfault foo)
{
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__any_anyfault DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__static_and_global_vars() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

int foo;
tlocal bar;

fn void
main(any foo) { 
static Win32_LARGE_INTEGER freq;
static ulong div = 0;
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__static_and_global_vars formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
int foo;
tlocal bar;

fn void main(any foo)
{
    static Win32_LARGE_INTEGER freq;
    static ulong div = 0;
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__static_and_global_vars DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__simple_struct_with_multiple_interfaces() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

struct Person (Printable, Foo, Bar)
{
    char age;
    string::String name;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__simple_struct_with_multiple_interfaces formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
struct Person (Printable, Foo, Bar)
{
    char age;
    string::String name;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__simple_struct_with_multiple_interfaces DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__struct_with_bitstruct_member() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

struct Person (Printable, Foo, Bar)
{
    bitstruct foo : char @bigendian
    {
        int a : 0..2;
    }
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__struct_with_bitstruct_member formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
struct Person (Printable, Foo, Bar)
{
    bitstruct foo : char @bigendian
    {
        int a : 0..2;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__struct_with_bitstruct_member DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__typedef__struct_with_bitstruct_anonymous() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

struct Person (Printable, Foo, Bar)
{
    bitstruct : char @bigendian
    {
        int a : 0..2;
    }
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__typedef__struct_with_bitstruct_anonymous formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
struct Person (Printable, Foo, Bar)
{
    bitstruct : char @bigendian
    {
        int a : 0..2;
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__typedef__struct_with_bitstruct_anonymous DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__fmtoff__full_off_full() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
// fmt: off
fn void
main() {
              //this simple comment
    if(   foo (far)) { zooo;        ;
    }
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__fmtoff__full_off_full formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
// fmt: off
fn void
main() {
              //this simple comment
    if(   foo (far)) { zooo;        ;
    }
return;}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__fmtoff__full_off_full DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__fmtoff__full_off_inside_code_scope() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void 
main() {
              //this simple comment
          // fmt: off
    if(   foo (far)) { zooo;
    }
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__fmtoff__full_off_inside_code_scope formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    //this simple comment
    // fmt: off
    if(   foo (far)) { zooo;
    }
return;}

`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__fmtoff__full_off_inside_code_scope DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__fmtoff__full_off_inside_code_scope_restoring_formatting() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void 
main() {
              //this simple comment
    // fmt: off
    if(   foo (far)) {
          s = {.abs = 2, .zozo = 3,};
    // fmt: on
                if (   abs(mode.to)) {
    return 0; }
    }
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__fmtoff__full_off_inside_code_scope_restoring_formatting formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    //this simple comment
    // fmt: off
    if(   foo (far)) {
          s = {.abs = 2, .zozo = 3,};
    // fmt: on
        if (abs(mode.to)) {
            return 0;
        }
    }
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__fmtoff__full_off_inside_code_scope_restoring_formatting DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__fmtoff__off_inside_cache_statement_ugly() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void 
main() {
              //this simple comment
    if(   foo (far) &&
            // fmt: off
            abs(saldj) || (soze) && afk
        // fmt: on
    ) {
          s = {.abs = 2, .zozo = 3,};
    // fmt: on
                if (   abs(mode.to)) {
    return 0; }
    }
return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__fmtoff__off_inside_cache_statement_ugly formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void main()
{
    //this simple comment
    if (foo(far) &&
    // fmt: off
            abs(saldj) || (soze) && afk
        // fmt: on
    ) {
        s = {
            .abs = 2,
            .zozo = 3,
        };
        // fmt: on
        if (abs(mode.to)) {
            return 0;
        }
    }
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__fmtoff__off_inside_cache_statement_ugly DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_main() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_main formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_main DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_main_int formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_main_int DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__ret_generic_list formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__ret_generic_list DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__ret_generic_list_pointer_opt formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__ret_generic_list_pointer_opt DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__ret_generic_method formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__ret_generic_method DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__ret_generic_method_attrs formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__ret_generic_method_attrs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__returns_array_type formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__returns_array_type DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__returns_multiple_arguments formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__returns_multiple_arguments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__typed_vargs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String[]! 
Foo.main(String[] args, int ...varg
) { 
call(i, j, ...varg);
return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__typed_vargs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn String[]! Foo.main(String[] args, int ...varg)
{
    call(i, j, ...varg);
    return 0;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__typed_vargs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__long_arguments() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String[]! Foo.main(String[] args, int* foo, List(<float>) bar, MySuperClass[] last
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__long_arguments formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__long_arguments DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__long_arguments_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn String[]! Foo.main(SoTypeIsHuuuuuuge ok, String[] args, int* foo, List(<float>) bar, MySuperClass[] last, List(<ThisIsTooBig>) too_be_true
) { return   0   ;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__long_arguments_multiline formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__long_arguments_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
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
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__arguments_magic_comma formatted code\n```");
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__arguments_magic_comma DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_main_docstring() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* My doc *>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_main_docstring formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<* My doc *>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_main_docstring DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_main_docstring_multiline() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<*
   My doc asdlkjad aiis is not formatted at                                all an used as is
*>


fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_main_docstring_multiline formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 My doc asdlkjad aiis is not formatted at                                all an used as is
*>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_main_docstring_multiline DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_main_docstring_only_contract() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* @require foo > 1 *>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_main_docstring_only_contract formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<* @require foo > 1 *>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_main_docstring_only_contract DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_lambda() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro CFile stderr() => __acrt_iob_func(STDERR_FD);
fn bool in_range(char c, 
char start, char len) => in_range_m(c, 
start, len);

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_lambda formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro CFile stderr() => __acrt_iob_func(STDERR_FD);
fn bool in_range(char c, char start, char len) => in_range_m(c, start, len);
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_lambda DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_lambda_with_attrs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro CFile stderr() @if(FOO||Bar||   "non form") => __acrt_iob_func(STDERR_FD);
fn bool in_range(char c, 
char start, char len) => in_range_m(c, 
start, len, args_are_too, long, and_many, of_them_getting_new_line);

fn bool in_range(char c, 
char start, char len) => in_range_m(c, 
start, len, args_are_too, long, and_many, of_them_getting_new_line, but_sometimes_even, multiline);
fn bool in_range(char c, char start, char len) => with_magic_comma(c, 
start, len, magic_comma,);
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_lambda_with_attrs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro CFile stderr() @if(FOO||Bar||   "non form") => __acrt_iob_func(STDERR_FD);
fn bool in_range(char c, char start, char len) => in_range_m(c, start, len, args_are_too, long, and_many, of_them_getting_new_line);

fn bool in_range(char c, char start, char len) => in_range_m(c, start, len, args_are_too, long, and_many, of_them_getting_new_line, but_sometimes_even, multiline);
fn bool in_range(char c, char start, char len) => with_magic_comma(c, start, len, magic_comma,);
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_lambda_with_attrs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_lambda_arg() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void remove_using_test()
{
        IntList test;
        usz removed;

        removed = test.remove_using_test(fn bool_long(i, ctx) => *i >= *(int*)ctx, &&10);
        assert(removed == 3);
    thread.create(fn int(void* arg)
    {
        UnbufferedChannel(<int>) c = (UnbufferedChannel(<int>))arg;
        c.push(123)!!;
        if (foo) {
        c.push(321)!!; }
        return 0;
    }, (void*)c)!!;

}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_lambda_arg formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void remove_using_test()
{
    IntList test;
    usz removed;

    removed = test.remove_using_test(
        fn bool_long(i, ctx) => *i >= *(int*)ctx, &&10
    );
    assert(removed == 3);
    thread.create(fn int (void* arg) {
        UnbufferedChannel(<int>) c = (UnbufferedChannel(<int>))arg;
        c.push(123)!!;
        if (foo) {
            c.push(321)!!;
        }
        return 0;
    }, (void*)c)!!;

}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_lambda_arg DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__simple_lambda_with_docs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

<* A doc *>

macro CFile stderr() => __acrt_iob_func(STDERR_FD);

<* Another doc
@param c "with contracts" 
*>

fn bool in_range(char c, 
char start, char len) => in_range_m(c, 
start, len);

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__simple_lambda_with_docs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<* A doc *>
macro CFile stderr() => __acrt_iob_func(STDERR_FD);

<*
 Another doc

 @param c "with contracts"
*>
fn bool in_range(char c, char start, char len) => in_range_m(c, start, len);
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__simple_lambda_with_docs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_amp_self() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro NodeParserState.check_scope( &self, TokenType t)
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_amp_self formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro NodeParserState.check_scope(&self, TokenType t)
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_amp_self DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_long_cast_in_ternary() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params(
    Ast* ast, Token* t, AstCallable* node_func, NodeParserState* state
) @local
{
    AstCallableParam* current_param = state.sub_node ?(
        AstCallableParam*
    )state.sub_node : null;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_long_cast_in_ternary formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params(
    Ast* ast, Token* t, AstCallable* node_func, NodeParserState* state
) @local
{
    AstCallableParam* current_param = state.sub_node ? (AstCallableParam*)state.sub_node : null;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_long_cast_in_ternary DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_long_call_wrap_when_cast() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params()
{
    if(foo) { if(bar){
    current_param = (
        AstCallableParam*
    )ast.@allc_add(
        AstCallableParam,
        &node_func.params,
        &ast.lexer.token
    );
    }}
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_long_call_wrap_when_cast formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params()
{
    if (foo) {
        if (bar) {
            current_param = (AstCallableParam*)ast.@allc_add(
                AstCallableParam,
                &node_func.params,
                &ast.lexer.token
            );
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_long_call_wrap_when_cast DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_long_call_wrap_no_args_assert() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params()
{
    if(foo) { if(bar){
        assert(self.cache_statement_len() == 0, "cache_statement_dump must be called befor fmt: off");
    }}
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_long_call_wrap_no_args_assert formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params()
{
    if (foo) {
        if (bar) {
            assert(
                self.cache_statement_len() == 0,
                "cache_statement_dump must be called befor fmt: off"
            );
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_long_call_wrap_no_args_assert DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_long_call_with_last_params_no_wrap() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params()
{
    if(foo) { if(bar){
    current_param = ast.@allc_add(
        AstCallableParam,
        &node_func.params,
        &ast.lexer.token()
    );
    }}
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_long_call_with_last_params_no_wrap formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params()
{
    if (foo) {
        if (bar) {
            current_param = ast.@allc_add(
                AstCallableParam, &node_func.params, &ast.lexer.token()
            );
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_long_call_with_last_params_no_wrap DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__func_forward_decl() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
FopenFn native_fopen_fn @weak @if(!$defined(native_fopen_fn));
FcloseFn native_fclose_fn @weak @if(!$defined(native_fclose_fn));
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__func_forward_decl formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
FopenFn native_fopen_fn @weak @if(!$defined(native_fopen_fn));
FcloseFn native_fclose_fn @weak @if(!$defined(native_fclose_fn));
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__func_forward_decl DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_with_long_call_null() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params()
{
            !win32::createProcessW(null, convert_command_line_win32(command_line), null,   // process security attributes
            null,   // primary thread security attributes
            1,   // handles are inherited
            flags,   // creation flags
            used_environment,   // environment
            null,   // use parent dir
            & start_info,   // startup info ptr
            & process_info);
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_with_long_call_null formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params()
{
    !win32::createProcessW(
        null,
        convert_command_line_win32(command_line),
        null,  // process security attributes
        null,  // primary thread security attributes
        1,  // handles are inherited
        flags,  // creation flags
        used_environment,  // environment
        null,  // use parent dir
        &start_info,  // startup info ptr
        &process_info
    );
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_with_long_call_null DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__functions__fn_variable_invalid_arg_list() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro parse_callable_params()
{
    var check_sort = fn bool ($Type list, usz start, usz end, $typeof(cmp) cmp) {
        return true;
    };
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__functions__fn_variable_invalid_arg_list formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro parse_callable_params()
{
    var check_sort = fn bool ($Type list, usz start, usz end, $typeof(cmp) cmp) {
        return true;
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__functions__fn_variable_invalid_arg_list DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__simple_macro() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro    

main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__simple_macro formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro main()
{
    return;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__simple_macro DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__simple_ct_macro() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro @m(
#x 

, y
)
{  #x = 2 * y;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__simple_ct_macro formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @m(#x, y)
{
    #x = 2 * y;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__simple_ct_macro DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__simple_macro_ct_type() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro size($Type)
{
    return $Type.sizeof + 

    int.sizeof;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__simple_macro_ct_type formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro size($Type)
{
    return $Type.sizeof + int.sizeof;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__simple_macro_ct_type DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__simple_macro_body_definition() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro SomeType   * !
   @for_each(   list   ; @body(   it  ))
{
    for ($typeof(list)
    x = list; x;
    x = x.next)
    {
    @body(x);
    }
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__simple_macro_body_definition formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro SomeType*! @for_each(list; @body(it))
{
    for ($typeof(list) x = list; x; x = x.next) {
        @body(x);
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__simple_macro_body_definition DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__name_fields() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro usz @offset($Type, #field)
{
        $Type* t = null;
    return (usz)

    (uptr)  &    t   .   #field;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__name_fields formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro usz @offset($Type, #field)
{
    $Type* t = null;
    return (usz)(uptr)&t.#field;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__name_fields DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__hash_macro() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

macro Foo.@check(#expr, $Type t, args...)
{
    if ( !  
    #expr)
    abort(
    $stringify(#expr
    ));
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__hash_macro formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro Foo.@check(#expr, $Type t, args...)
{
    if (!#expr) abort($stringify(#expr));
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__hash_macro DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__hash_macro_with_contracts() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<*
@require $defined(#a=#b,#b= #a)
*>
macro void @swap(#a,     #b)
{
        var temp = #a;
    #a = #b;
        #b = temp;
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__hash_macro_with_contracts formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 @require $defined(#a = #b, #b = #a)
*>
macro void @swap(#a, #b)
{
    var temp = #a;
    #a = #b;
    #b = temp;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__hash_macro_with_contracts DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_if_else() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $if $x > 3:
    #y += $x * $x;
    $endif

    $if $x > 3:  #y += $x * $x; $else  #y += $x; $endif
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_if_else formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $if $x > 3:
        #y += $x * $x;
    $endif

    $if $x > 3:
        #y += $x * $x;
    $else
        #y += $x;
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_if_else DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_for_in_ct_scope() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro foo($a)
{
    $if $x > 3:
    $for (var $x = 0; $x < $a; $x++)
io::printfn("%d", $x);
    $endfor
    $endif
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_for_in_ct_scope formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro foo($a)
{
    $if $x > 3:
        $for (var $x = 0; $x < $a; $x++)
            io::printfn("%d", $x);
        $endfor
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_for_in_ct_scope DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_foreach() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro foo_enum($SomeEnum)
{
    $if $x > 3:
    $foreach ($x : $SomeEnum.values)
    io::printfn("%d", (int)$x);
    $endforeach
    $endif
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_foreach formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro foo_enum($SomeEnum)
{
    $if $x > 3:
        $foreach ($x : $SomeEnum.values)
            io::printfn("%d", (int)$x);
        $endforeach
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_foreach DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_switch() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $if $x > 3:
    $switch ($x)
        $case 0:
        $case 1:
            #y += $x * $x;
        $case 2:
            #y += $x;
        $case 3:
        $case $x > 10&&!$x:
            $if $x > 3:
            #y *= $x;
            $endif
        $default:
            #y -= $x;
    $endswitch
    $endif
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_switch formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $if $x > 3:
        $switch ($x)
            $case 0:
            $case 1:
                #y += $x * $x;
            $case 2:
                #y += $x;
            $case 3:
            $case $x > 10 && !$x:
                $if $x > 3:
                    #y *= $x;
                $endif
            $default:
                #y -= $x;
        $endswitch
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_switch DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_switch_no_top_cond() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $if $x > 3:
    $switch
        $case 0:
        $case 1:
            #y += $x * $x;
            if(#y) { return 0;}
        $case 2:
            #y += $x;
        $case 3:
        $case $x > 10&&!$x:
            $if $x > 3:
            #y *= $x;
            $endif
        $default:
            #y -= $x;
    $endswitch
    $endif
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_switch_no_top_cond formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $if $x > 3:
        $switch
            $case 0:
            $case 1:
                #y += $x * $x;
                if (#y) {
                    return 0;
                }
            $case 2:
                #y += $x;
            $case 3:
            $case $x > 10 && !$x:
                $if $x > 3:
                    #y *= $x;
                $endif
            $default:
                #y -= $x;
        $endswitch
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_switch_no_top_cond DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_if_call_colon_position() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $if type_is_overaligned(foo,bar: soo):
    #y += $x * $x;
    $endif
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_if_call_colon_position formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $if type_is_overaligned(foo, bar: soo):
        #y += $x * $x;
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_if_call_colon_position DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__body_macro_with_vector_init() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro void Slice2d.@each(&self; @body(usz[<2>], Type))
{
    foreach (y, line : *self)
    {
        foreach (x, val : line)
        {
            @body({ x, y }, val);
        }
    }
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__body_macro_with_vector_init formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro void Slice2d.@each(&self; @body(usz[<2>], Type))
{
    foreach (y, line : *self) {
        foreach (x, val : line) {
            @body({x, y}, val);
        }
    }
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__body_macro_with_vector_init DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__mem_scoped_stack_pool() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro void @stack_pool(usz $size; @body) @builtin
{
    mem::@scoped(&allocator){ @body(); };
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__mem_scoped_stack_pool formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro void @stack_pool(usz $size; @body) @builtin
{
    mem::@scoped(&allocator) {
        @body();
    };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__mem_scoped_stack_pool DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_if_else_inside_other() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $if $x > 3:
    #y += $x * $x;
        $if $x > 3:  #y += $x * $x; $else  #y += $x; $endif
    $endif

}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_if_else_inside_other formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $if $x > 3:
        #y += $x * $x;
        $if $x > 3:
            #y += $x * $x;
        $else
            #y += $x;
        $endif
    $endif

}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_if_else_inside_other DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_foreach_in_other() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro foo_enum($SomeEnum)
{
    $if $x > 3:
    $foreach ($x : $SomeEnum.values)
    $foreach ($x : $SomeEnum.values)
    io::printfn("%d", (int)$x);
    $endforeach
    $endforeach
    $endif
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_foreach_in_other formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro foo_enum($SomeEnum)
{
    $if $x > 3:
        $foreach ($x : $SomeEnum.values)
            $foreach ($x : $SomeEnum.values)
                io::printfn("%d", (int)$x);
            $endforeach
        $endforeach
    $endif
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_foreach_in_other DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__ct_switch_in_other() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro @foo($x, #y)
{
    $switch ($x)
        $case 1:
            $switch ($x)
                $case 1:
                $default:
                    #y -= $x;
            $endswitch
        $default:
            #y -= $x;
            $switch ($x)
                $case 2:
                $default:
                    #y -= $x;
            $endswitch
    $endswitch
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__ct_switch_in_other formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro @foo($x, #y)
{
    $switch ($x)
        $case 1:
            $switch ($x)
                $case 1:
                $default:
                    #y -= $x;
            $endswitch
        $default:
            #y -= $x;
            $switch ($x)
                $case 2:
                $default:
                    #y -= $x;
            $endswitch
    $endswitch
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__ct_switch_in_other DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__macros__matrix_component_mul() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
macro matrix_component_mul(mat, val) @private
{
    var $Type = Real[<$typeof(mat.m).len>];
    return $typeof(*mat) { .m = val * ($Type)mat.m };
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__macros__matrix_component_mul formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
macro matrix_component_mul(mat, val) @private
{
    var $Type = Real[<$typeof(mat.m).len>];
    return $typeof(*mat){ .m = val * ($Type)mat.m };
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__macros__matrix_component_mul DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__empty_lines__module_spacing() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module foo;
import bar;

fn void main()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__empty_lines__module_spacing formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module foo;
import bar;

fn void main()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__empty_lines__module_spacing DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__empty_lines__module_spacing_double_empty() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module foo;
import bar;


fn void main()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__empty_lines__module_spacing_double_empty formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module foo;
import bar;

fn void main()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__empty_lines__module_spacing_double_empty DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__empty_lines__module_spacing_tripple_empty() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module foo;
import bar;



fn void main()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__empty_lines__module_spacing_tripple_empty formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module foo;
import bar;

fn void main()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__empty_lines__module_spacing_tripple_empty DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__empty_lines__module_spacing_docstr() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module foo;
import bar;


<* Doc *>
fn void main()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__empty_lines__module_spacing_docstr formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module foo;
import bar;

<* Doc *>
fn void main()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__empty_lines__module_spacing_docstr DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__empty_lines__module_spacing_docstr_with_comment() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
module foo;
import bar;

// My module


<* Doc *>
fn void main()
{
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__empty_lines__module_spacing_docstr_with_comment formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
module foo;
import bar;

// My module

<* Doc *>
fn void main()
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__empty_lines__module_spacing_docstr_with_comment DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__casting__fn_with_lambda_arg() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void remove_using_test()
{
    removed = test.remove_using_test(fn bool(i, c) => *i >= *(int*)ctx, &&10);
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__casting__fn_with_lambda_arg formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void remove_using_test()
{
    removed = test.remove_using_test(fn bool (i, c) => *i >= *(int*)ctx, &&10);
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__casting__fn_with_lambda_arg DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__casting__casting_pointers() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

fn void * 
main(int* arg) { 
bool a =(a||b)&&c; 
int bin = (1&2)&3;
int bin = &a + (1&2)*&a;
int bin = &a + (1&2)+&a;
int bin = &a + (1&2)-&a;
int* bin = (int*)&a;
*bin = 1;
*bin = *foo;
b = *(int*)&a;
*(int*)&a = 2;
b = (*a = 2);
b = { .work = 1, .work=2};
int** ptr = &(*(int*)&a);
 (  void) free(data);
    (void * * )free(data);
    int* bin = &&1;

call(&StrucType.fn_ptr);
    node = ($typeof(self))node.next;            
    node = ($typeof(#self))node.next;            
    node = ($typeof(#self[0]))node.next;            
    node = ($Type*)node.next;            
    defer (void)f.close();
    return (*(char[8]*))foo;
    return (char[8])foo;
    return &StrucType.func;
    node = some_fn(&&node.next);            
    node = a + *b;
    node = ( (w | x) & y) + &(w & y);
    node = (void*.alignof) * 2;
    node = size & PAGE;
    node = (*h ^ ($typeof(*h))x) * FOO;
    node = a + *(int*)b;
    return (char[?])foo;
    return { q.v[0] * -foo};
    node = ((int*)*self & (int)bar);
    node = ((int*)*self & ~(int)bar);
    node = (*h * ($typeof(*h))x) & FOO;
    bitcast( (float)x, uint) & 0xff;
    match = (mem::@volatile_load(((char*)data1)[i]) ^ mem::@volatile_load());
    * @extract(op, run);
    roo = * @extract(op, run);
    r = &((*foo).prev);
    (double)x[0] * P10ST;
    foo(&(char[16])uuid);
    for(int i; *a > 0; i++);
    f = (*(char[$Type.sizeof]*)bar);
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__casting__casting_pointers formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void* main(int* arg)
{
    bool a = (a || b) && c;
    int bin = (1 & 2) & 3;
    int bin = &a + (1 & 2) * &a;
    int bin = &a + (1 & 2) + &a;
    int bin = &a + (1 & 2) - &a;
    int* bin = (int*)&a;
    *bin = 1;
    *bin = *foo;
    b = *(int*)&a;
    *(int*)&a = 2;
    b = (*a = 2);
    b = { .work = 1, .work = 2 };
    int** ptr = &(*(int*)&a);
    (void)free(data);
    (void**)free(data);
    int* bin = &&1;

    call(&StrucType.fn_ptr);
    node = ($typeof(self))node.next;
    node = ($typeof(#self))node.next;
    node = ($typeof(#self[0])) node.next;
    node = ($Type*)node.next;
    defer (void)f.close();
    return (*(char[8]*))foo;
    return (char[8])foo;
    return &StrucType.func;
    node = some_fn(&&node.next);
    node = a + *b;
    node = ((w | x) & y) + &(w & y);
    node = (void*.alignof) * 2;
    node = size & PAGE;
    node = (*h ^ ($typeof(*h))x) * FOO;
    node = a + *(int*)b;
    return (char[?])foo;
    return { q.v[0] * -foo };
    node = ((int*)*self & (int)bar);
    node = ((int*)*self & ~(int)bar);
    node = (*h * ($typeof(*h))x) & FOO;
    bitcast((float)x, uint) & 0xff;
    match = (mem::@volatile_load(((char*)data1)[i]) ^ mem::@volatile_load());
    *@extract(op, run);
    roo = *@extract(op, run);
    r = &((*foo).prev);
    (double)x[0] * P10ST;
    foo(&(char[16])uuid);
    for (int i; *a > 0; i++) ;
    f = (*(char[$Type.sizeof] *) bar);
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__casting__casting_pointers DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__casting__fn_array_args_casting_ambiguity() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
fn void remove_using_test(char* a, char[16]* boo)
{
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__casting__fn_array_args_casting_ambiguity formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
fn void remove_using_test(char* a, char[16]* boo)
{
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__casting__fn_array_args_casting_ambiguity DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__simple_enum_docs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* Some State *>
enum State
{
    WAITING,  <* Running state*>  RUNNING,

    <* Another with empty line *>
    TERMINATED
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__simple_enum_docs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<* Some State *>
enum State
{
    WAITING,
    <* Running state*>
    RUNNING,

    <* Another with empty line *>
    TERMINATED
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__simple_enum_docs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__def_interface_with_docs() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
interface Printable @if("sasda")
{
    <*
     Doc
     @param foo "bar"
     @param boo "baz"
    *>
    fn String* to_string(Allocator allocator) @optional;
    <* Doc 2 *>
    fn String* to_string(Allocator allocator) @optional;

    <* Doc 3 empty line *>
    fn String* to_string(Allocator allocator) @optional;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__def_interface_with_docs formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
interface Printable @if("sasda")
{
    <*
     Doc

     @param foo "bar"
     @param boo "baz"
    *>
    fn String* to_string(Allocator allocator) @optional;
    <* Doc 2 *>
    fn String* to_string(Allocator allocator) @optional;

    <* Doc 3 empty line *>
    fn String* to_string(Allocator allocator) @optional;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__def_interface_with_docs DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__simple_struct_doc_str() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `

<* Docstr *>
struct 
Person {
    char age; 
<* Docstr *>
    string::String name; }
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__simple_struct_doc_str formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<* Docstr *>
struct Person
{
    char age;
    <* Docstr *>
    string::String name;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__simple_struct_doc_str DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__param_space_in_contract() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* 
 Doc
 @require foo > 1 
 *>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__param_space_in_contract formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 Doc

 @require foo > 1
*>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__param_space_in_contract DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__simple_main_docstring_multi_contract() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<*              
Descr @param @ensure ignored
   another line

        maybe one more
  last one


@param [&in] i
@param num_foo "The number of foos."
@require foo==0, bar > 0 : "This is a stuff"
@require !foo : "This is a stuff"
@ensure foo==null, bar > 0 ``This is raw stuff``
@require $kindof() "This is a stuff"

@require foo > 1 
@return IoError.FOO, EioError.BAR
@return! IoError.FOO, EioError.BAR
@require $defined(resource.open, resource.open()),  ``Expected resource to have an "open" function``
@require resource != nil
@require $assignable(resource.open(), void*)
@require test::@foo(), $assign(&&pass[0], this_is_very_long, call, with, multiple, arguments), !bar() "some stuff"
@require test::@foo(), $assign(&&pass[0]), !bar(): "some stuff"
@require {| return resource != nil; |} "Shit!" 
@mycustom "aoo" , "foo"
*>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__simple_main_docstring_multi_contract formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 Descr @param @ensure ignored
 another line

 maybe one more
 last one

 @param [&in] i
 @param num_foo "The number of foos."
 @require foo == 0, bar > 0 : "This is a stuff"
 @require !foo : "This is a stuff"
 @ensure foo == null, bar > 0 ``This is raw stuff``
 @require $kindof() "This is a stuff"

 @require foo > 1
 @return IoError.FOO, EioError.BAR
 @return! IoError.FOO, EioError.BAR
 @require $defined(resource.open, resource.open()), ``Expected resource to have an "open" function``
 @require resource != nil
 @require $assignable(resource.open(), void*)
 @require test::@foo(), $assign(&&pass[0], this_is_very_long, call, with, multiple, arguments), !bar() "some stuff"
 @require test::@foo(), $assign(&&pass[0]), !bar() : "some stuff"
 @require {|return resource != nil; |} "Shit!"
 @mycustom "aoo" , "foo"
*>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__simple_main_docstring_multi_contract DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__docstr_double_spaces() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* 
 Doc
 line2


 line3
 @require foo > 1 
 *>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__docstr_double_spaces formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 Doc
 line2

 line3

 @require foo > 1
*>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__docstr_double_spaces DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__docstr_code_block() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* 
 Doc string for c3fmt
 
     Here is an example of code with ident:
``````c3
int f = 0;
if (foo) {
    // code indent maintained
    return;
}
``````
    This line is indented by 1 space.

 @require foo > 1 
 *>
fn void 
main() { return;}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__docstr_code_block formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 Doc string for c3fmt

 Here is an example of code with ident:

``````c3
int f = 0;
if (foo) {
    // code indent maintained
    return;
}
``````
 This line is indented by 1 space.

 @require foo > 1
*>
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
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__docstr_code_block DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__def_interface_indented_code() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
interface Printable @if("sasda")
{
    <*
     Doc

     This is an example:
    ``````c3
     if (foo) {
        return 0;
     }
    ``````

     @param foo "bar"
     @param boo "baz"
    *>
    fn String* to_string(Allocator allocator) @optional;
    <* Doc 2 *>
    fn String* to_string(Allocator allocator) @optional;

    <* Doc 3 empty line *>
    fn String* to_string(Allocator allocator) @optional;
}
`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__def_interface_indented_code formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
interface Printable @if("sasda")
{
    <*
     Doc

     This is an example:

    ``````c3
     if (foo) {
        return 0;
     }
    ``````

     @param foo "bar"
     @param boo "baz"
    *>
    fn String* to_string(Allocator allocator) @optional;
    <* Doc 2 *>
    fn String* to_string(Allocator allocator) @optional;

    <* Doc 3 empty line *>
    fn String* to_string(Allocator allocator) @optional;
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__def_interface_indented_code DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}

fn void test_corpus__docstrings__docstr_unicode() 
{
    CodeFmt fmt = CodeFmt.new_init();
    defer fmt.free();
    String input = `
<* 
 Doc привет мир!
 Hello, 世界! 
 Print any value to stderr, appending an '\n’ after.

 @require foo > 1 
 *>
fn void main() 
{
    String uni = "привет мир";
}

`;
    String formatted = fmt.format(input[1..], print_lex: false)!!;
    io::printfn("\n__docstrings__docstr_unicode formatted code\n```");
    io::print(formatted);
    io::printfn("```");
    String expected = `
<*
 Doc привет мир!
 Hello, 世界! 
 Print any value to stderr, appending an '\n’ after.

 @require foo > 1
*>
fn void main()
{
    String uni = "привет мир";
}
`;
    test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`);
    String fmt_out = formatted.copy();
    defer fmt_out.free();
    formatted = fmt.format(fmt_out, print_lex: false)!!;
    assert(fmt_out.ptr != formatted.ptr);
    if(expected[1..] != formatted) {
        io::printfn("\n__docstrings__docstr_unicode DOUBLE formatted code\n```");
        io::print(formatted);
        io::printfn("```");
    }
    test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`);
}
