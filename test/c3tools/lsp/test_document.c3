module test::c3tools::lsp::document;
import c3tools::lsp;

fn Position resolve_src_pos(DString src) @private
{
    assert(src[0] == '\n', "ensure that test src code starts with new line");
    int lpos = -1;
    int cpos = -1;

    int line = -1;
    int col = -1;

    @pool() {
        DString tmp = dstring::temp_new();
        foreach (c : src) {
            if (c == '\n') {
                line++;
                col = -1;
            } else if (c == '|') {
                assert(lpos == -1 && cpos == -1, "duplicate | in source");
                lpos = line;
                cpos = col;
                continue;
            }
            tmp.append_char(c);
            col++;
        }
        src.clear();
        src.append(tmp);
    };
    assert(lpos >= 0 && cpos >= 0, "| cursor place was not found");
    return Position { .l = lpos, .c = cpos };
}

module test::c3tools::lsp::document @test;
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

        assert(state.lsp.proj.modules.len() > 0);
        assert(state.lsp.proj.sym_proj.len() > 0);
    },
    .teardown_fn = fn void () {
        state.lsp.free();
    },
};

fn void test_init_lsp_proj()
{
    test::@setup(state.setup_fn, state.teardown_fn);
    String uri = "file://" +++ BASE_PROJ_PATH +++ "mod1.c3";
    String src = (String)file::load_new(BASE_PROJ_PATH +++ "mod1.c3")!!;
    defer src.free();

    Document doc = Document.new_open(uri, src, &state.lsp.proj);
    defer doc.close();

    test::eq(uri, doc.uri);
    test::ne(uri.ptr, doc.uri.ptr);
    test::eq(src, doc.source.str_view());
    test::eq(&state.lsp.proj, doc.proj);
}

fn void test_document_cursor()
{
    test::@setup(state.setup_fn, state.teardown_fn);

    DString src = dstring::new(
        `
m|odule test::c3tools::lsp_test_mod1;
int global_int @local = 2;
fn int add(int a, int b) {
    return a + b;
}
    `
    );
    defer src.free();

    test::eq(true, src.str_view().contains("|"));
    Position cur = resolve_src_pos(src);
    test::eq(false, src.str_view().contains("|"));
    test::eq(cur.l, 0);
    test::eq(cur.c, 1);

    Document doc = Document.new_open("file://test.c3", src.str_view(), &state.lsp.proj);
    defer doc.close();

    test::eq(doc.ast.@node_len(doc.ast.modules), 1);
    test::eq(doc.ast.@node_len(doc.ast.modules.decls), 2);
}

fn void test_document_cursor_next_line()
{
    test::@setup(state.setup_fn, state.teardown_fn);

    DString src = dstring::new(
        `
module test::c3tools::lsp_test_mod1;
int g|lobal_int @local = 2;
fn int add(int a, int b) {
    return a + b;
}
    `
    );
    defer src.free();

    test::eq(true, src.str_view().contains("|"));
    Position cur = resolve_src_pos(src);
    test::eq(false, src.str_view().contains("|"));
    test::eq(cur.l, 1);
    test::eq(cur.c, 5);
}

fn void test_document_context()
{
    test::@setup(state.setup_fn, state.teardown_fn);

    DString src = dstring::new(
        `
m|odule test::c3tools::lsp_test_mod1;
int global_int @local = 2;
fn int add(int a, int b) {
    return a + b;
}
    `
    );
    defer src.free();

    Position cur = resolve_src_pos(src);
    Document doc = Document.new_open("file://test.c3", src.str_view(), &state.lsp.proj);
    defer doc.close();

}
