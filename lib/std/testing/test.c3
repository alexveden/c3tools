module std::testing::test;
import std::core::builtin;
import libc, std::time, std::io, std::sort;

def TestFn = fn void!();

struct TestUnit @private
{
	String name;
	TestFn func;
}

fn TestUnit[] test_collection_create(Allocator allocator = allocator::heap()) 
{
	TestFn[] fns = $$TEST_FNS;
	String[] names = $$TEST_NAMES;
	TestUnit[] tests = allocator::alloc_array(allocator, TestUnit, names.len);
	foreach (i, test : fns)
	{
		tests[i] = { names[i], fns[i] };
	}
	return tests;
}

struct TestContext @private
{
	JmpBuf buf;
	// Allows filtering test cased or modules by substring, e.g. 'foo::', 'foo::test_add'  
	String test_filter;
	// Triggers debugger breakpoint when assert or test:: checks failed
	bool breakpoint_on_assert;

	// internal state
	bool assert_print_backtrace;
	bool has_ansi;
	bool is_in_panic;
	String current_test_name;
	TestFn setup_fn;
	TestFn teardown_fn;
}

// Sort the tests by their name in ascending order.
fn int cmp_test_unit(TestUnit a, TestUnit b) @private
{
	usz an = a.name.len;
	usz bn = b.name.len;
	if (an > bn) @swap(a, b);
	foreach (i, ac : a.name)
	{
		char bc = b.name[i];
		if (ac != bc) return an > bn ? bc - ac : ac - bc;
	}
	return (int)(an - bn);
}

TestContext* test_context;

fn void test_panic(String message, String file, String function, uint line) @private
{
	if(test_context.is_in_panic){
		return;
	}

	test_context.is_in_panic = true;
	(void)io::stdout().flush();
	if (test_context.assert_print_backtrace){
    	builtin::print_backtrace(message, 3);
	}
	io::printfn("[%sFAIL%s] %s ( %s:%s ) %s", 
		test_context.has_ansi ? "\e[0;31m" : "",
		test_context.has_ansi ? "\e[0m" : "",
		test_context.current_test_name, 
		file, 
		line,
		message);
	test_context.assert_print_backtrace = true;

	if (test_context.breakpoint_on_assert) {
		breakpoint();
	}

	if (test_context.teardown_fn){
		if(catch err = test_context.teardown_fn()) {
			io::printfn("teardown_fn failed with %s (ignored)", err);
		}
	}

	test_context.is_in_panic = false;
	libc::longjmp(&test_context.buf, 1);
}
fn bool terminal_has_ansi() @private {
	// TODO: implement this 
	return true;
}

fn bool run_tests(TestUnit[] tests) @private
{
	usz max_name;
	foreach (&unit : tests)
	{
		if (max_name < unit.name.len) max_name = unit.name.len;
	}
	// TODO: add argument to sort or not
	//quicksort(tests, &cmp_test_unit);

	TestContext context = {
		.assert_print_backtrace = true,
		//.breakpoint_on_assert = true,
		//.test_filter = "test_bar::",
		.has_ansi = terminal_has_ansi(),
	};
	test_context = &context;

	PanicFn old_panic = builtin::panic;
	defer builtin::panic = old_panic;
	builtin::panic = &test_panic;
	int tests_passed = 0;
	int tests_skipped = 0;
	int test_count = tests.len;
	DString name = dstring::temp_with_capacity(64);
	usz len = max_name + 9;
	name.append_repeat('-', len / 2);
	name.append(" TESTS ");
	name.append_repeat('-', len - len / 2);
	io::printn(name);
	name.clear();
	foreach(unit : tests)
	{
		if (test_context.test_filter && !unit.name.contains(test_context.test_filter)){
			tests_skipped++;
			continue;
		}
		test_context.setup_fn = null;
		test_context.teardown_fn = null;

		test_context.current_test_name = unit.name;
		(void)io::stdout().flush();
		if (libc::setjmp(&context.buf) == 0)
		{
			if (catch err = unit.func())
			{
				io::printfn("[%sFAIL%s] Failed due to: %s",
							test_context.has_ansi ? "\e[0;31m" : "",
							test_context.has_ansi ? "\e[0m" : "",
							err);
			} else {
				io::printfn("[%sPASS%s] %s", 
							test_context.has_ansi ? "\e[0;32m" : "",
							test_context.has_ansi ? "\e[0m" : "",
							unit.name);
				tests_passed++;
			}

			if (test_context.teardown_fn){
				if(catch err = test_context.teardown_fn()) {
					io::printfn("teardown_fn failed with %s (ignored)", err);
				}
			}
		}
	}
	io::printfn("\n%d test%s run.\n", test_count-tests_skipped, test_count > 1 ? "s" : "");
	io::printfn("Test Result: %s. %d passed, %d failed, %d skipped.",
				tests_passed < test_count - tests_skipped ? "FAILED" : "ok", 
				tests_passed,
				test_count - tests_passed - tests_skipped, 
				tests_skipped);
	return test_count-tests_skipped == tests_passed;
}

fn bool default_test_runner()
{
	@pool()
	{
		assert(test_context == null, "test suite is already running");
		return run_tests(test_collection_create(allocator::temp()));
	};
}

macro setup(TestFn setup_fn, TestFn teardown_fn = null){
	assert(setup_fn != null);

	test_context.setup_fn = setup_fn;
	test_context.teardown_fn = teardown_fn;

	if(catch err = test_context.setup_fn()) {
    	test_context.assert_print_backtrace = false;
	    builtin::panicf("test::setup() failed with %s", $$FILE, $$FUNC, $$LINE, err);
	}
}


macro eq(left, right) { 
	assert(test_context != null, "this macro is allowed only in @test functions");
    if(!equals(left, right)) {
    	test_context.assert_print_backtrace = false;
	    builtin::panicf("`%s` != `%s`", $$FILE, $$FUNC, $$LINE, left, right);
    }
}

macro neq(left, right) { 
	assert(test_context != null, "this macro is allowed only in @test functions");
    if(equals(left, right)) {
    	test_context.assert_print_backtrace = false;
	    builtin::panicf("`%s` == `%s`", $$FILE, $$FUNC, $$LINE, left, right);
    }
}

macro gt(left, right) { 
	assert(test_context != null, "this macro is allowed only in @test functions");
    if(!greater(left, right)) {
    	test_context.assert_print_backtrace = false;
	    builtin::panicf("`%s` <= `%s`", $$FILE, $$FUNC, $$LINE, left, right);
    }
}

macro gte(left, right) { 
	assert(test_context != null, "this macro is allowed only in @test functions");
    if(!greater_eq(left, right)) {
    	test_context.assert_print_backtrace = false;
	    builtin::panicf("`%s` <= `%s`", $$FILE, $$FUNC, $$LINE, left, right);
    }
}
