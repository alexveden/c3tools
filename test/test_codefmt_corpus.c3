module test::c3tools::codefmt @test;
import std::collections::list;
import std::io;
import c3tools::codecorpus @public;
import c3tools::codefmt;

fn void test_corpus() {
    List(<CodeCorpus>) corp = codecorpus::new_parse("test/c3fmt_corpus/functions.txt")!!;
    
    test::greater_equal(2, corp.len());
    // test::@checks(1, 0);
    test::equal(corp[0].case_name, "Main func");
    // foreach(i, c: corp[0].case_output) {
    //     io::printfn("%d: %d -> '%c'", i, c, c);
    // }
    test::equal(corp[0].case_input, "fn void \nmain() { return;}\n\n");
    test::equal(corp[0].case_output, "fn void main() \n{\n    return;\n}\n\n");

    test::equal(corp[1].case_name, "Main func int");
    test::equal(corp[1].case_input, `fn int 
main(
String[] args
) { return;}

`);
    test::equal(corp[1].case_output, `fn int main(String[] args)
{
    return 0;
}
`);
}
