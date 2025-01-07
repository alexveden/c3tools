module sample::m;

fault MathError
{
    DIVISION_BY_ZERO
}

fn int foo() { return 123; }
fn int bar() { return 0; }

fn double! divide(int a, int b)
{
    if (b == 0) return MathError.DIVISION_BY_ZERO?;

    return (double)(a) / (double)(b);
}


module test::sample::m @test;
import std::io;
import sample::m;

fn void! test_div() {
    test::equal(2, m::divide(6, 3)!);
    test::not_equal(1, 2);
    test::greater_equal(3, 3);
    test::greater(2, m::divide(3, 3)!);
    test::less(2, 3);
    test::less_equal(2, 3);
    test::@check(m::foo() == 123, "foo is %d", m::foo());
    test::@error(m::divide(3, 0), MathError.DIVISION_BY_ZERO);
}

struct TestContext {
    int n_runs;
    int n_fails;
    // NOTE: we must wrap setup/teardown functions to hide them from module @test runner
    test::TestFn setup_fn;
    test::TestFn teardown_fn;
}

TestContext state @local  = {
    .setup_fn = fn void!() {
        io::printn("new test setup");
        // initialize something heavy (maybe a DB)
        state.n_runs = 777;
    },
    .teardown_fn = fn void!() {
        state.n_runs = 0;
        io::printn("test teardown");
    }
};

fn void! test_with_setup_teardown() {
    test::equal(0, state.n_runs);
    test::setup(state.setup_fn, state.teardown_fn);
    test::equal(777, state.n_runs);

    test::equal(2, m::divide(6, 3)!);

    // NOTE: next line will fail, but teardown_fn is triggered
    // test::equal(1, 0); 
}
