module test::c3tools::lsp::project @test;
import c3tools::ast @public;
import c3tools::lsp @public;
import std::math;
import std::hash::fnv32a;
import std::collections::list;
import std::io;

fn void test_multi_module_addition()
{
    String code = `

// this has to be excluded from proj.modules 
fn void test_blank_module_skipped(int a) => a * 2;

module test::std::c3lang::ast;
fn void test1(int a) => a * 2;
fn void test2(int a) => a * 2;

module test::std::c3lang::best;
fn void test3(int a) => a * 2;
fn void test4(int a) => a * 2;

module test::std::c3lang::cest;
fn void test5(int a) => a * 2;
fn void test6(int a) => a * 2;

//`;  // NOTE: // - is sanity guard comment, don't delete it!
    DString contents = dstring::temp_new(code);
    Ast ast = ast::parse(contents.str_view(), "foo.c3", print_lex: false);
    defer mem::free(ast._allocator);
    contents.clear();

    test::ne(ast.modules, null);
    test::eq(4, ast.@node_len(ast.modules));

    AstModule* m = ast.@node_at(ast.modules, 0);
    io::printfn("'%s' hash: %s", m.node.value, m.hash);
    test::eq(m.hash, (Fnv32a)0);

    m = ast.@node_at(ast.modules, 1);
    io::printfn("'%s' hash: %s", m.node.value, m.hash);
    test::ne(m.hash, (Fnv32a)0);

    m = ast.@node_at(ast.modules, 2);
    io::printfn("'%s' hash: %s", m.node.value, m.hash);
    test::ne(m.hash, (Fnv32a)0);

    m = ast.@node_at(ast.modules, 3);
    io::printfn("'%s' hash: %s", m.node.value, m.hash);
    test::ne(m.hash, (Fnv32a)0);

    LspProject proj = LspProject.new_init("", "");
    defer proj.free();

    proj.load_source(code, "foo.c3")!!;
    test::eq(proj.modules.len(), 3);

}

fn void test_module_index()
{
    String code = `

// this has to be excluded from proj.modules 
fn void test_blank_module_skipped(int a) => a * 2;

module test::std::c3lang::ast;
fn void test1(int a) => a * 2;
fn void test2(int a) => a * 2;

module test::std::c3lang::best;
fn void test3(int a) => a * 2;
fn void test4(int a) => a * 2;

module test::std::c3lang::cest;
fn void test5(int a) => a * 2;
fn void test6(int a) => a * 2;

//`;  // NOTE: // - is sanity guard comment, don't delete it!

    LspProject proj = LspProject.new_init("", "");
    defer proj.free();

    proj.load_source(code, "foo.c3")!!;
    test::eq(proj.modules.len(), 3);

    test::ne(null, proj.modules.first("test::std::c3lang::ast"));
    test::ne(null, proj.modules.first("test::std::c3lang::best"));
    test::ne(null, proj.modules.first("test::std::c3lang::cest"));

    SymbolItem* m = proj.modules.first("test::std::c3lang::ast");
    test::eq(proj.modules.get_name(m), "test::std::c3lang::ast");
    test::eq(m.kind, SymbolKind.MODULE);
    test::eq(m.module_hash, (Fnv32a)fnv32a::encode("test::std::c3lang::ast"));
    test::eq(m.hash, (Fnv32a)fnv32a::encode("test::std::c3lang::ast"));

    m = proj.modules.first("test::std::c3lang::best");
    test::eq(proj.modules.get_name(m), "test::std::c3lang::best");
    test::eq(m.kind, SymbolKind.MODULE);
    test::eq(m.module_hash, (Fnv32a)fnv32a::encode("test::std::c3lang::best"));
    test::eq(m.hash, (Fnv32a)fnv32a::encode("test::std::c3lang::best"));

    m = proj.modules.first("test::std::c3lang::cest");
    test::eq(proj.modules.get_name(m), "test::std::c3lang::cest");
    test::eq(m.kind, SymbolKind.MODULE);
    test::eq(m.module_hash, (Fnv32a)fnv32a::encode("test::std::c3lang::cest"));
    test::eq(m.hash, (Fnv32a)fnv32a::encode("test::std::c3lang::cest"));
}

fn void test_module_index_duplicates()
{
    String code = `

// this has to be excluded from proj.modules 
fn void test_blank_module_skipped(int a) => a * 2;

module test::std::c3lang::ast;
fn void test1(int a) => a * 2;
fn void test2(int a) => a * 2;

module test::std::c3lang::ast;
fn void test3(int a) => a * 2;
fn void test4(int a) => a * 2;

module test::std::c3lang::cest;
fn void test5(int a) => a * 2;
fn void test6(int a) => a * 2;

//`;  // NOTE: // - is sanity guard comment, don't delete it!

    LspProject proj = LspProject.new_init("", "");
    defer proj.free();

    proj.load_source(code, "foo.c3")!!;
    test::eq(proj.modules.len(), 3);

    test::ne(null, proj.modules.first("test::std::c3lang::ast"));
    test::eq(null, proj.modules.first("test::std::c3lang::best"));
    test::ne(null, proj.modules.first("test::std::c3lang::cest"));


    int n_collision = 0;
    for (
        SymbolItem* m = proj.modules.first("test::std::c3lang::ast");
        m != null;
        m = proj.modules.next(m)
    ) {
        test::eq(proj.modules.get_name(m), "test::std::c3lang::ast");
        test::eq(m.kind, SymbolKind.MODULE);
        test::eq(m.module_hash, (Fnv32a)fnv32a::encode("test::std::c3lang::ast"));
        test::eq(m.hash, (Fnv32a)fnv32a::encode("test::std::c3lang::ast"));

        n_collision++;
    }
    test::eq(n_collision, 2);
}
