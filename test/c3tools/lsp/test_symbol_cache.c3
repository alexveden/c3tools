module test::c3tools::lsp::symbols @test;
import c3tools::ast @public;
import c3tools::lsp::symbols @public;
import std::math;
import std::hash::fnv32a;
import std::collections::list;
import std::io;

fn void test_add_symbols()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    test::eq(cache.items_len, 0);
    test::eq(cache.items_capacity, 10);
    test::eq(cache.names_len, 0);
    test::eq(cache.names_capacity, 10 * symbols::CHARS_PER_SYMBOL);

    SymbolItem* items = cache.items();
    char* strings = cache.strings();
    test::eq((void*)items - (void*)cache, SymbolCache.sizeof);
    test::eq(
        (void*)strings - (void*)cache,
        SymbolCache.sizeof + SymbolItem.sizeof * (usz)(cache.items_capacity + 1)
    );

    test::eq(cache.items()[cache.items_capacity].hash, (Fnv32a)ulong.max);
}

fn void test_find_insert_position()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    SymbolItem* items = cache.items();

    test::eq(0, cache._find_insert_position((Fnv32a)1));

    cache.items_len = 1;
    items[0].hash = (Fnv32a)2;
    test::eq(0, cache._find_insert_position((Fnv32a)1));
    test::eq(1, cache._find_insert_position((Fnv32a)3));
    test::eq(0, cache._find_insert_position((Fnv32a)2));

    cache.items_len = 2;
    items[0].hash = (Fnv32a)2;
    items[1].hash = (Fnv32a)5;
    test::eq(0, cache._find_insert_position((Fnv32a)1));
    test::eq(0, cache._find_insert_position((Fnv32a)2));
    test::eq(1, cache._find_insert_position((Fnv32a)5));
    test::eq(2, cache._find_insert_position((Fnv32a)6));

    // inserting into a middle, and border case
    test::eq(1, cache._find_insert_position((Fnv32a)3));
    test::eq(1, cache._find_insert_position((Fnv32a)4));
}

fn void test_find_insert_at()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    SymbolItem* items = cache.items();

    test::eq(0, cache._find_insert_position((Fnv32a)1));

    test::eq(&items[0], cache._insert_item((Fnv32a)2, 0));
    test::eq(cache.items_len, 1);
    test::eq(items[0].hash, (Fnv32a)2);

    test::eq(&items[1], cache._insert_item((Fnv32a)5, 1));
    test::eq(cache.items_len, 2);
    test::eq(items[0].hash, (Fnv32a)2);
    test::eq(items[1].hash, (Fnv32a)5);

    test::eq(&items[1], cache._insert_item((Fnv32a)3, 1));
    test::eq(cache.items_len, 3);
    test::eq(items[0].hash, (Fnv32a)2);
    test::eq(items[1].hash, (Fnv32a)3);
    test::eq(items[2].hash, (Fnv32a)5);

    test::eq(&items[0], cache._insert_item((Fnv32a)1, 0));
    test::eq(cache.items_len, 4);
    test::eq(items[0].hash, (Fnv32a)1);
    test::eq(items[1].hash, (Fnv32a)2);
    test::eq(items[2].hash, (Fnv32a)3);
    test::eq(items[3].hash, (Fnv32a)5);

    test::eq(&items[4], cache._insert_item((Fnv32a)6, cache.items_len));
    test::eq(cache.items_len, 5);
    test::eq(items[0].hash, (Fnv32a)1);
    test::eq(items[1].hash, (Fnv32a)2);
    test::eq(items[2].hash, (Fnv32a)3);
    test::eq(items[3].hash, (Fnv32a)5);
    test::eq(items[4].hash, (Fnv32a)6);
}

fn void test_find_insert_at_random()
{
    Lcg128Random random;
    random::seed_entropy(&random);

    for (int i = 0; i < 100; i++) {
        SymbolCache* cache = SymbolCache.new_init(100);
        defer cache.free();
        SymbolItem* items = cache.items();

        Fnv32a hash = (Fnv32a)random.next_long();
        for (uint j = 0; j < cache.items_capacity; j++) {
            // every 10th is a duplicate hash
            if (j % 10 != 0) hash = (Fnv32a)random.next_long();
            if (!cache.has_capacity("foo")) {
                cache = cache.grow(cache.items_capacity + 100);
                test::eq(cache.items()[cache.items_capacity].hash, (Fnv32a)ulong.max);
            }
            uint pos = cache._find_insert_position(hash);
            SymbolItem* it = cache._insert_item(hash, pos);
            if (pos > 0) {
                // we must be at the start of hash cluster
                test::gt(hash, items[pos - 1].hash);
            }
            test::eq(it, &items[pos]);
            test::eq(it.hash, hash);
            test::eq(it.name_offset, 0);
            test::eq(it.kind, SymbolKind.NA);
            test::eq(it.module_hash, (Fnv32a)0);
            test::eq(it.ptr.mod, null);
            test::eq(it.ptr.type, null);

            // always return first item of a hash bucket
            test::eq(it, cache.first(hash));
            test::eq(cache.items()[cache.items_capacity].hash, (Fnv32a)ulong.max);
        }
        // Check if sorted in ascending order
        for (uint j = 1; j < cache.items_capacity; j++) {
            test::@check(items[j].hash >= items[j - 1].hash, "unsorted!");
        }
    }
}

fn void test_insert_name()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    char* names = cache.strings();

    test::eq(cache.names_len, 0);
    test::eq(1, cache._insert_name("foo"));
    test::eq(cache.names_len, 5);
    test::eq(names[0], 3);
    test::eq((String)names[1..3], "foo");
    test::eq(names[4], '\0');  // null term

    test::eq(6, cache._insert_name("bar"));
    test::eq(cache.names_len, 10);
    test::eq(names[5], 3);
    test::eq((String)names[6..8], "bar");
    test::eq(names[9], '\0');  // null term
}

fn void test_item_add()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    char* names = cache.strings();
    SymbolItem* items = cache.items();

    SymbolItem* it_bar = cache.add("bar");
    test::eq(cache.get_name(it_bar), "bar");
    test::ne(it_bar.hash, (Fnv32a)0);

    SymbolItem* it_foo = cache.add("foo");
    test::eq(cache.get_name(it_foo), "foo");
    test::ne(it_foo.hash, (Fnv32a)0);

    test::@check(it_bar.hash < it_foo.hash, "check if it sorted bar->foo");

    test::eq(cache.names_len, 10);
    test::eq(names[0], 3);
    test::eq((String)names[1..3], "bar");
    test::eq(names[4], '\0');  // null term

    test::eq(names[5], 3);
    test::eq((String)names[6..8], "foo");
    test::eq(names[9], '\0');  // null term

    // Adding duplicate index
    SymbolItem* it_foo2 = cache.add("foo");
    test::eq(cache.get_name(it_foo2), "foo");
    test::eq(it_foo2.hash, it_foo.hash);

    test::eq(cache.items_len, 3);
    test::eq(cache.get_name(&items[0]), "bar");
    test::eq(cache.get_name(&items[1]), "foo");
    test::eq(cache.get_name(&items[2]), "foo");

    // name of foo should be reused
    test::eq(cache.names_len, 10);
    test::eq(items[1].name_offset, items[2].name_offset);

}

fn void test_item_find()
{
    SymbolCache* cache = SymbolCache.new_init(10);
    defer cache.free();

    SymbolItem* items = cache.items();
    test::eq(null, cache.first("fooa"));

    cache.add("foo");
    test::eq(null, cache.first("fooa"));
    test::ne(null, cache.first("foo"));
    cache.add("foo");
    test::eq(null, cache.first("fooa"));
    test::ne(null, cache.first("foo"));
    cache.add("bar");
    test::ne(null, cache.first("bar"));
    cache.add("baz");
    test::ne(null, cache.first("baz"));
    cache.add("foo");
    cache.add("baz");
    cache.add("baz");
    cache.add("bar");
    test::eq(null, cache.first("fooa"));
    test::eq(cache.items_len, 8);

    // test::eq(items[0].hash, (Fnv32a)1);
    // test::eq(items[1].hash, (Fnv32a)2);
    // test::eq(items[2].hash, (Fnv32a)3);
    // test::eq(items[3].hash, (Fnv32a)5);
    // test::eq(items[4].hash, (Fnv32a)6);

    // test::eq(&items[1], cache.item_find((Fnv32a)2));
}

fn void test_grow()
{
    SymbolCache* cache = SymbolCache.new_init(4);
    defer cache.free();

    SymbolItem* items = cache.items();
    test::eq(cache.items_len, 0);
    test::eq(cache.items_capacity, 4);
    test::eq(cache.names_len, 0);
    test::eq(cache.names_capacity, 4 * symbols::CHARS_PER_SYMBOL);

    cache.add("foo");
    cache.add("foo");
    cache.add("bar");
    cache.add("baz");
    test::eq(cache.items_len, 4);
    test::eq(cache.items_capacity, 4);
    test::eq(false, cache.has_capacity("bar"));

    char* names = cache.strings();
    test::eq(cache.names_len, 15);

    test::eq(names[0], 3);
    test::eq((String)names[1..3], "foo");
    test::eq(names[4], '\0');  // null term

    test::eq(names[5], 3);
    test::eq((String)names[6..8], "bar");
    test::eq(names[9], '\0');  // null term

    test::eq(names[10], 3);
    test::eq((String)names[11..13], "baz");
    test::eq(names[14], '\0');  // null term

    cache = cache.grow(5);
    names = cache.strings();
    items = cache.items();

    test::eq(cache.items_len, 4);
    test::eq(cache.items_capacity, 5);
    test::eq(cache.names_len, (3 + 2) * 3);
    test::eq(cache.names_capacity, 5 * symbols::CHARS_PER_SYMBOL);

    test::eq(names[0], 3);
    test::eq((String)names[1..3], "foo");
    test::eq(names[4], '\0');  // null term

    test::eq(names[5], 3);
    test::eq((String)names[6..8], "bar");
    test::eq(names[9], '\0');  // null term

    test::eq(names[10], 3);
    test::eq((String)names[11..13], "baz");
    test::eq(names[14], '\0');  // null term

    cache.add("fzz");
    test::eq(cache.items_len, 5);
    test::eq(cache.names_len, (3 + 2) * 4);

    test::eq(names[15], 3);
    test::eq((String)names[16..18], "fzz");
    test::eq(names[19], '\0');  // null term

    test::eq(items[cache.items_capacity].hash, (Fnv32a)uint.max);

}

fn void test_add_with_resize_and_validate()
{
    Lcg128Random random;
    random::seed_entropy(&random);

    SymbolCache* cache = SymbolCache.new_init(100);
    DString buf;
    defer buf.free();
    defer cache.free();
    for (int i = 0; i < 1000; i++) {
        SymbolItem* items = cache.items();

        if (!cache.has_capacity("my_symbol_name0000")) {
            // Validate all records before resize
            for (int k = 0; k < i; k++) {
                items = cache.items();
                buf.clear();
                buf.appendf("my_symbol_name%04d", k);

                Fnv32a hash;
                hash.init();
                hash.update(buf.str_view());

                SymbolItem* it = cache.first(buf.str_view());
                test::ne(it, null);
                test::eq(it.hash, hash);
                test::eq(cache.get_name(it), buf.str_view());
            }
            cache = cache.grow(cache.items_capacity + 100);
            items = cache.items();
            test::eq(cache.items()[cache.items_capacity].hash, (Fnv32a)ulong.max);
            io::printfn("resize");
            // Validate all records after resize
            for (int k = 0; k < cache.items_capacity; k++) {
                if (k < i) {
                    // ensure old data is in place
                    buf.clear();
                    buf.appendf("my_symbol_name%04d", k);

                    Fnv32a hash;
                    hash.init();
                    hash.update(buf.str_view());

                    SymbolItem* it = cache.first(buf.str_view());
                    test::ne(it, null);
                    test::eq(it.hash, hash);
                    test::eq(cache.get_name(it), buf.str_view());
                } else {
                    // ensure everything is clean after resize
                    test::eq(cache.items()[k].hash, (Fnv32a)0);
                    test::eq(cache.items()[k].ptr.mod, null);
                    test::eq(cache.items()[k].name_offset, 0);
                    test::eq(cache.items()[k].kind, SymbolKind.NA);
                }
            }
        } else {

            // Validate all records
            for (int k = 0; k < i; k++) {
                items = cache.items();
                buf.clear();
                buf.appendf("my_symbol_name%04d", k);

                Fnv32a hash;
                hash.init();
                hash.update(buf.str_view());

                SymbolItem* it = cache.first(buf.str_view());
                test::ne(it, null);
                test::eq(it.hash, hash);
                test::eq(cache.get_name(it), buf.str_view());
            }
        }

        buf.clear();
        buf.appendf("my_symbol_name%04d", i);

        items = cache.items();

        Fnv32a hash;
        hash.init();
        hash.update(buf.str_view());

        uint pos = cache._find_insert_position(hash);
        SymbolItem* it = cache.add(buf.str_view());

        test::eq(it, &items[pos]);
        test::eq(cache.get_name(it), buf.str_view());

        // always return first item of a hash bucket
        test::eq(it, cache.first(it.hash));
        test::eq(cache.items()[cache.items_capacity].hash, (Fnv32a)ulong.max);
    }
    // Validate all records
    for (int i = 0; i < 1000; i++) {
        SymbolItem* items = cache.items();
        buf.clear();
        buf.appendf("my_symbol_name%04d", i);

        Fnv32a hash;
        hash.init();
        hash.update(buf.str_view());

        SymbolItem* it = cache.first(buf.str_view());
        test::ne(it, null);
        test::eq(it.hash, hash);
        test::eq(cache.get_name(it), buf.str_view());
    }

}
