module test::c3tools::lsp @test;
import c3tools::lsp @public;
import c3tools::ast;
import std::io;

const BASE_PROJ_PATH = "test/c3tools/lsp/lsp_test_proj/";

struct TestState @local
{
    Lsp lsp;
    TestFn setup_fn;
    TestFn teardown_fn;
}

TestState state = {
    .setup_fn = fn void () {
        state.lsp.new_init(BASE_PROJ_PATH, "")!!;
    },
    .teardown_fn = fn void () {
        state.lsp.free();
    },
};

// fn String src_load(String file_name){
//     String contents = (String)file::load_new(p.str_view())!;
// }

fn void test_init_lsp_proj()
{
    test::@setup(state.setup_fn, state.teardown_fn);
    String uri = "file://"+++ BASE_PROJ_PATH +++ "mod1.c3";
    String src = (String)file::load_new(BASE_PROJ_PATH +++ "mod1.c3" )!!;
    defer src.free();

    Document doc = Document.new_open(uri, src, &state.lsp.proj);
    defer doc.close();

    test::eq(uri, doc.uri);
    test::ne(uri.ptr, doc.uri.ptr);
    test::eq(src, doc.source.str_view());

    // check reserved capacity
    test::eq(doc.file_symbols.table.len, 32);
    test::eq(doc.global_symbols.table.len, 256);
}

fn void test_load_file_symbols()
{
    test::@setup(state.setup_fn, state.teardown_fn);
    String uri = "file://"+++ BASE_PROJ_PATH +++ "mod1.c3";
    String src = (String)file::load_new(BASE_PROJ_PATH +++ "mod1.c3" )!!;
    defer src.free();

    Document doc = Document.new_open(uri, src, &state.lsp.proj);
    defer doc.close();

    // There have to be 3 file scope symbols in mod1.c3
    // global_int
    // mul()
    // logic()
    // Other symbols will be accessible via import scope of self module
    doc._load_file_symbols()!!;

    test::eq(doc.file_symbols.len(),3);
}

