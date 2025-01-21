import std::io;

$echo("Exec me compiled!");

fn int main(String[] args)
{
	// io::printfn("exec_me running. Args: %s", args);
	// io::printfn(`$echo("Exec me compiled!");`);
	io::printfn(`fn int foo(int a, int b) { return a + b;}`);

	return 1;
}

