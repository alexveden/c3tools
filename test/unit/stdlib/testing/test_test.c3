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

fn void! setup_no_teardown(){
    test::setup(state.setup_fn);

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


fn void! test_gte(){
    test::gte(2, 1);
    test::gte(true, false);
    test::gte(1.32, 1.31);
    test::gte(2, 2);
    test::gte(true, true);
    test::gte(1.32, 1.32);
    //test::gt("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_gte_fails_when_less(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::gte(1, 2);
}

fn void! test_lt(){
    test::lt(1, 2);
    test::lt(false, true);
    test::lt(1.31, 1.32);
    //test::lt("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_lt_fails_when_equal(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::lt(2, 2);
}

fn void! test_lt_fails_when_greater(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::lt(2, 1);
}

fn void! test_lte(){
    test::lte(1, 2);
    test::lte(false, true);
    test::lte(1.31, 1.32);
    test::lte(2, 2);
    test::lte(true, true);
    test::lte(1.32, 1.32);
    //test::lte("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_lte_fails_when_greater(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::lte(2, 1);
}

fn void! test_check(){
    test::@check(1 == 1);
    test::@check(1.2 == 1.2, "1 == 1");
    test::@check(true == true, "1 == 1");
    test::@check("foo" == "foo", "2 == %d", 1 );
}

fn void! test_check_fails(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::@check(2 == 1, "2 == %d", 1 );
}

fn void! test_check_fails_no_info(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::@check(2 == 1);
}

def TestIntFn = fn int! (int a, int b);

fault MyFault {
    FOO,
}

fn void! test_error(){
    test::TestFn ffail_void = fn void!() {
        return IoError.FILE_NOT_FOUND?;
    };
    TestIntFn ffail_int = fn int! (int a, int b) {
        if (b == 0){
            return IoError.FILE_NOT_FOUND?;
        }
        return a / b;
    };
    test::setup(state.setup_fn, state.teardown_fn);

    test::@error(ffail_void(), IoError.FILE_NOT_FOUND);
    test::@error(ffail_int(1, 0), IoError.FILE_NOT_FOUND);
}

fn void! test_error_not_raised(){
    TestIntFn ffail_int = fn int! (int a, int b) {
        if (b == 0){
            return IoError.FILE_NOT_FOUND?;
        }
        return a / b;
    };
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;

    test::@error(ffail_int(1, 1), IoError.FILE_NOT_FOUND);
}

fn void! test_error_wrong_error_expected(){
    TestIntFn ffail_int = fn int! (int a, int b) {
        if (b == 0){
            return IoError.BUSY?;
        }
        return a / b;
    };
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;

    test::@error(ffail_int(1, 0), IoError.FILE_NOT_FOUND);
}

