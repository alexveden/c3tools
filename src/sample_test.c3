module sample::m;
import std::io;


fault MathError
{
    DIVISION_BY_ZERO
}

fn double! divide(int a, int b)
{
    if (b == 0) return MathError.DIVISION_BY_ZERO?;
    return (double)(a) / (double)(b);
}

fn void! test_div() @test {
    test::eq(2, divide(6, 3)!);
    test::ne(1, 2);
    test::almost_equal(m::divide(1, 3)!, 0.333, places: 3);
    test::gt_equal(3, 3);
    test::gt(2, divide(3, 3)!);
    test::less(2, 3);
    test::less_equal(2, 3);
    test::@check(2 == 2, "divide: %d", divide(6, 3)!);
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
    test::eq(0, state.n_runs);
    test::setup(state.setup_fn, state.teardown_fn);
    test::eq(777, state.n_runs);

    test::eq(2, m::divide(6, 3)!);

    // NOTE: next line will fail, but teardown_fn is triggered
    // test::eq(1, 0); 
}
