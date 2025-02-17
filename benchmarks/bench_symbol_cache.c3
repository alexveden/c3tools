module bench_symbol_cache;
import std::io;
import std::hash::fnv32a;
import c3tools::lsp;
import std::thread;
import std::math;

// NOTE: 10k iterations is a default

LspProject proj;
uint n_found = 0;
uint n_lookups = 0;

macro String sym_gen()
{
    assert(proj.sym_std.names_len > 1000);
    uint index = rand(proj.sym_std.names_len - 100);
    char* names = proj.sym_std.strings();
    String name = "sldaldjalsdsld";

    for (int i = index; i < proj.sym_std.names_len - 100; i++) {

        if (names[i] == '\0') {
            assert(names[i + 1] > 0);

            uint cnt = names[i + 1];
            name = (String)(&names[i + 2])[:cnt];
            // io::printfn("%s i=%s len=%s", name, i, cnt);
            break;
        }
    }

    return name;
}

fn void bench_binary_search() @benchmark
{
    String name = sym_gen();
    SymbolItem* it = proj.sym_std.find(name);
    if (it != null) {
        n_found++;
    }
    n_lookups++;
}

fn void bench_exhaustive_search() @benchmark
{
    String name = sym_gen();

    Fnv32a hash;
    hash.init();
    hash.update(name);

    SymbolItem* items = proj.sym_std.items();
    for (uint i = 0; i < proj.sym_std.items_len; i++) {
        if (items[i].hash == hash) {
            n_found++;
            break;
        }
    }

    n_lookups++;
}

fn void initialize() @init
{

    proj = LspProject.new_init(
        "/home/ubertrader/code/c3tools", "/home/ubertrader/code/c3c/lib/std"
    );

    proj.load()!!;
    proj.load_symbols()!!;

    io::printfn(
        "std_symbols: len[%s]/cap[%s], names len[%s]/cap[%s]",
        proj.sym_std.items_len,
        proj.sym_std.items_capacity,
        proj.sym_std.names_len,
        proj.sym_std.names_capacity,
    );

    // foreach (i, name : proj.sym_std.iter_symbols()) {
    //     io::printfn("%s, %s", i, name);
    // }
    // char* names = proj.sym_std.strings();
    // for (uint i = 0; i < proj.sym_std.names_len; i++) {
    //     if (names[i] == '\0') {
    //         // end of data
    //         break;
    //     }
    //
    //     uint cnt = names[i];
    //     String name = (String)(&names[i + 1])[:cnt];
    //     io::printfn("%s i=%s len=%s", name, i, cnt);
    //
    //     i += cnt + 1;
    //     assert(names[i] == '\0');  // expected to be at null term
    // }
}

fn void run_at_shutdown() @finalizer
{
    io::printfn("n_found: %s, n_lookups: %s", n_found, n_lookups);
}
