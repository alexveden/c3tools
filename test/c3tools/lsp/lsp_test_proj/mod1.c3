module test::c3tools::lsp_test_mod1;

// NOTE: this symbol will not be added to file scope symbol (only global one)
def MyInt = int;

// should be in file scope
int global_int @local = 2;

fn int add(int a, int b)
{
    return a + b;
}

fn int mul(int a, int b) @local
{
    return a + b;
}

macro int @sub(int a, int b) @private
{
    return a - b;
}

fn int logic(int a, int b) @local
{
    return add(a, b) + mul(a, b) - @sub(a, b);
}

