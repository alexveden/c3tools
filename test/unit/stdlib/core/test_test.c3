module test::std::core::test @test;
import std::core::test @public;
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

        assert (test::test_context.assert_print_backtrace);
	    assert (builtin::panic != state.panic_mock_fn, "missing finalization of panic");

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
	    if (test::test_context.assert_print_backtrace){
    	    builtin::print_backtrace(message, 3);
	    }
	    test::test_context.assert_print_backtrace = true;
        if (state.expected_fail) {
	        io::printfn("[OOPS] (expected fail) ( %s:%s ) %s", file, line, message);
            state.n_fails++;
        } else {
	        builtin::panic = state.old_panic;
            state.old_panic(message, file, function, line);
;        }
    }
};


fn void! test_eq(){
    test::equal(1, 1);
    test::equal(true, true);
    test::equal(1.31, 1.31);
    test::equal("foo", "foo");
}

fn void! setup_teardown(){
    test::setup(state.setup_fn, state.teardown_fn);

    test::equal(state.n_runs, 1);
    test::equal(state.n_fails, 0);
    test::equal(state.expected_fail, false);
}

fn void! setup_no_teardown(){
    test::setup(state.setup_fn);

    test::equal(state.n_runs, 1);
    test::equal(state.n_fails, 0);
    test::equal(state.expected_fail, false);

    // WARNING: reverting back original panic func
	builtin::panic = state.old_panic;
}

fn void! expected_fail(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::equal(state.n_fails, 0);
    test::equal(2, 1); // this fails, and we test it
    test::equal(state.n_fails, 1);
}

fn void! setup_failed_when_setup_fn_failed(){
    test::equal(state.n_fails, 0);
    test::equal(state.n_runs, 0);
    state.setup_fail = true;
    state.expected_fail = true;
    test::setup(state.setup_fn, state.teardown_fn);
    test::equal(state.n_runs, 1);
    test::equal(state.n_fails, 1);
}

fn void! setup_no_effect_when_teardown_fn_failed(){
    test::equal(state.n_fails, 0);
    test::equal(state.n_runs, 0);
    state.teardown_fail = true;
    test::setup(state.setup_fn, state.teardown_fn);
    test::equal(state.n_runs, 1);
    test::equal(state.n_fails, 0);
}

fn void! test_neq(){
    test::not_equal(2, 1);
    test::not_equal(false, true);
    test::not_equal(1.32, 1.31);
    test::not_equal("foo", "bar");
}

fn void! test_neq_fails(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::not_equal(1, 1);
}

fn void! test_gt(){
    test::greater(2, 1);
    test::greater(true, false);
    test::greater(1.32, 1.31);
    //test::greater("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_gt_fails_when_equal(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::greater(2, 2);
}

fn void! test_gt_fails_when_less(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::greater(1, 2);
}


fn void! test_gte(){
    test::greater_equal(2, 1);
    test::greater_equal(true, false);
    test::greater_equal(1.32, 1.31);
    test::greater_equal(2, 2);
    test::greater_equal(true, true);
    test::greater_equal(1.32, 1.32);
    //test::greater("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_gte_fails_when_less(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::greater_equal(1, 2);
}

fn void! test_lt(){
    test::less(1, 2);
    test::less(false, true);
    test::less(1.31, 1.32);
    //test::less("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_lt_fails_when_equal(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::less(2, 2);
}

fn void! test_lt_fails_when_greater(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::less(2, 1);
}

fn void! test_lte(){
    test::less_equal(1, 2);
    test::less_equal(false, true);
    test::less_equal(1.31, 1.32);
    test::less_equal(2, 2);
    test::less_equal(true, true);
    test::less_equal(1.32, 1.32);
    //test::less_equal("fooooooo", "bar"); // NOTE: Error: @require "types::@comparable_value(a) && types::@comparable_value(b)" violated
}

fn void! test_lte_fails_when_greater(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    test::less_equal(2, 1);
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
    // int result = test::@ok(ffail_int(6, 2));
    // test::equal(result, 3);

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

fn void! test_vanilla_assert_fail(){
    test::setup(state.setup_fn, state.teardown_fn);
    state.expected_fail = true;
    assert(false, "this assert expected to fail with backtrace");
}
