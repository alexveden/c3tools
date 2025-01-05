module test::std::testing::test @test;
import std::testing::test;
import std::core::builtin;
import std::io;

struct TestState {
    int n_runs;
    int n_fails;
    bool expected_fail;
    bool setup_fail;
    bool teardown_fail;

    // NOTE: we must wrap setup/teardown functions to hide them from module @test runner
    test::TestFn setup_fn;
    test::TestFn teardown_fn;
    builtin::PanicFn old_panic;  // original test panic, use it when it's really fails
    builtin::PanicFn panic_mock_fn; // mock panic, for testing the test:: failed
}

TestState state = {
    .setup_fn = fn void!() {
        //io::printn("new test setup");
        state.n_runs++;
        state.n_fails = 0;
	    state.old_panic = builtin::panic;
	    builtin::panic = state.panic_mock_fn;
	    if (state.setup_fail) {
	        return IoError.FILE_NOT_FOUND?;
	    }
    },
    .teardown_fn = fn void!() {
        //io::printn("test teardown");
	    builtin::panic = state.old_panic;

	    assert(state.n_runs > 0);

	    if (state.expected_fail){
	        assert(state.n_fails > 0, "test case expected to fail, but it's not");
	    }
        state.n_fails = 0;
        state.expected_fail = false;
        state.n_runs = 0;
        state.setup_fail = false;

	    if (state.teardown_fail) {
            state.teardown_fail = false;
            io::printn("teardown_fail: must be ignored");
	        return IoError.FILE_NOT_FOUND?;
	    }
        state.teardown_fail = false;

    },
    .panic_mock_fn = fn void (String message, String file, String function, uint line) {
        if (state.expected_fail) {
	        io::printfn("[OOPS] (expected fail) ( %s:%s ) %s", file, line, message);
            state.n_fails++;
        } else {
            state.old_panic(message, file, function, line);
        }
    }
};


fn void! test_eq(){
    test::eq(1, 1);
    test::eq(true, true);
    test::eq(1.31, 1.31);
    test::eq("foo", "foo");
}

fn void! setup_teardown(){
    test::setup(state.setup_fn, state.teardown_fn);

    test::eq(state.n_runs, 1);
    test::eq(state.n_fails, 0);
    test::eq(state.expected_fail, false);
}

fn void! expected_fail(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::eq(state.n_fails, 0);
    test::eq(2, 1); // this fails, and we test it
    test::eq(state.n_fails, 1);
}

fn void! setup_failed_when_setup_fn_failed(){
    test::eq(state.n_fails, 0);
    test::eq(state.n_runs, 0);
    state.setup_fail = true;
    state.expected_fail = true;
    test::setup(state.setup_fn, state.teardown_fn);
    test::eq(state.n_runs, 1);
    test::eq(state.n_fails, 1);
}

fn void! setup_no_effect_when_teardown_fn_failed(){
    test::eq(state.n_fails, 0);
    test::eq(state.n_runs, 0);
    state.teardown_fail = true;
    test::setup(state.setup_fn, state.teardown_fn);
    test::eq(state.n_runs, 1);
    test::eq(state.n_fails, 0);
}

fn void! test_neq(){
    test::neq(2, 1);
    test::neq(false, true);
    test::neq(1.32, 1.31);
    test::neq("foo", "bar");
}

fn void! test_neq_fails(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::neq(1, 1);
}

fn void! test_gt(){
    test::gt(2, 1);
    test::gt(true, false);
    test::gt(1.32, 1.31);
    //test::gt("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_gt_fails_when_equal(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::gt(2, 2);
}

fn void! test_gt_fails_when_less(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::gt(1, 2);
}
