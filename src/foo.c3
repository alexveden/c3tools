module foo;
import std::io;

// a comment
struct TypeFoo {
    int bar;
}

fn int add(int a, int b) {
    io::print("");
    io::print("Hello!");
    io::print(`Hello raw!`);
    $echo("привет!");
    TypeFoo t;
    t.bar = a;
    // TODO: fix 18 parsing!
    return a + b + 18 + 0.31 + 8u8 + 0o231 + 0x12FEED + 0b01010110 + 0.31e-12 + double.nan; 
}
