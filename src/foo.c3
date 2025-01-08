module foo;
import std::io;

struct TypeFoo {
    int bar;
}

fn int add(int a, int b) {
    io::print("Hello!");
    $echo("compile time");
    TypeFoo t;
    t.bar = a;
    return a + b;
}
