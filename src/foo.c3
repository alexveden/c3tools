module foo;
import std::io;

<*
@param a
*>
struct TypeFoo {
    int bar;
}

interface Too {
    
}

<*
add test @paramdlkjt
asnother
@param num_foo `The number of foos.`
@mycustom 2
@deprecated "tell me why?"
@require a == 0, "zzero"
@ensure b > 0, "not so zero"
*>
fn int add(int a, int b) {
    io::print("");
    io::print("Hello!");
    io::print(`Hello raw!`);
    $echo("привет!");
    TypeFoo t;
    t.bar = a;
    return a + b + (char)18 + 0.31 + 8u8 + 0o231 + 0x12FEED + 0b01010110 + 0.31e-12 + double.nan; 
}
