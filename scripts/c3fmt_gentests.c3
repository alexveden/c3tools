import std::io;
import std::io::path;
import std::collections::list;
import c3lib::codegen;
import c3tools::codefmt::codecorpus @public;


fn void! load_corpus(CodeGen* code, String path) @local {
    assert(path);

    path::Path p = path::temp_new(path)!;
    io::printfn("Processing path: %s", p.str_view());

    if (!path::exists(p)) {
        return IoError.FILE_NOT_FOUND?;
    }
    if (!path::is_dir(p)) {
        return IoError.FILE_NOT_DIR?;
    }

    path::PathWalker fnwalk = fn bool!(Path p, bool is_dir, void* ctx) {
        CodeGen* code = ctx;

        if (is_dir) return false;
        if (!p.has_extension("txt")) return false;

		io::printfn("Parsing corpus: %s", p.str_view());
	    List(<CodeCorpus>)! corpus = codecorpus::new_parse(p.str_view());
    	defer (void)corpus.free();

	    if (catch err = corpus) {
			io::printfn("Error parsing corpus (%s): %s", err, p.str_view());
			return err?;
	    }

	    String file_part = p.basename();
	    assert(file_part.contains(".txt"));
	    file_part = file_part[:file_part.rindex_of(".txt")!!];

		foreach(c: corpus){
			code.@fn("void test_corpus__%s__%s()", file_part, c.case_name) {
				code.wn("CodeFmt fmt = CodeFmt.new_init()");
				code.wn("defer fmt.free()");
				// NOTE: adding \n to input + input[1..] when check for visual formatting reasons
				code.wn("String input = `\n%s`", c.case_input);
				code.wn("String formatted = fmt.format(input[1..], print_lex: false)!!");
				code.wn("io::printfn(\"\\n__%s__%s formatted code\\n```\")", file_part, c.case_name);
				code.wn("io::print(formatted)");
				code.wn("io::printfn(\"```\")");
				code.wn("String expected = `\n%s`", c.case_output);
				code.wn("test::@check(codecorpus::compare_output(expected[1..], formatted), `format mismatch`)");
				code.wn("String fmt_out = formatted.copy()");
				code.wn("defer fmt_out.free()");
				code.wn("formatted = fmt.format(fmt_out, print_lex: false)!!");
				code.wn("assert(fmt_out.ptr != formatted.ptr)");
				code.@if("expected[1..] != formatted"){
					code.wn("io::printfn(\"\\n__%s__%s DOUBLE formatted code\\n```\")", file_part, c.case_name);
					code.wn("io::print(formatted)");
					code.wn("io::printfn(\"```\")");
				}; 
				code.wn("test::@check(codecorpus::compare_output(expected[1..], formatted), `DOUBLE!! format mismatch`)");
			};
		}

        return false;
    };
    p.walk(fnwalk, code)!;
}

fn int main(String[] args)
{
	CodeGen* code = CodeGen{}.new_init();
	defer code.free();

	code.@module("test::c3tools::c3fmt_corpus @test");
	code.@import("c3tools::codefmt");
	code.@import("c3tools::codefmt::codecorpus");
	code.@import("std::io");

	Path p = path::temp_cwd()!!;
	io::printfn("cwd: %s", p.str_view());

	String cwd = "../test/c3tools/codefmt/c3fmt_corpus";
	String out_file = "../test/c3tools/codefmt/test_c3fmt_corpus.c3";

	if(catch err = load_corpus(code, cwd)) {
		return 1;
	}

	io::printfn("Generated test: %s", out_file);

	file::save(out_file, code.buf.str_view())!!;

	return 0;
}

