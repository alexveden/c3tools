module test::std::os::argparse @test;
import std::os::argparse;


fn void! test_simple_arg_init() {

	int val = 0;
	String s;
	float f = 7.0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.epilog= "ArgParse epilog",
		.usage = `option -sdf -[sdf]`,
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{.short_name = 'a', .long_name = "all", .value = &val, .default_value=&&3, .help = "This is a sample option"},
			{.short_name = 's', .long_name = "string", .value = &s, .default_value=&&"foo", .help = "Simple string"},
			{.short_name = 'f', .long_name = "flt", .value = &f, .help = "float arg"},
		}
	};

    String[] args = {"testprog"}; 
	agp.parse(args)!;

	test::equal(agp.usage, "option -sdf -[sdf]");
	test::equal(agp.description, "test ArgParse program");
	test::equal(agp.epilog, "ArgParse epilog");
	test::equal(agp.options.len, 5);
	test::equal(agp.program_name, "testprog");
}

fn void! test_help_show() {

	int val = 0;
	String s;
	float f = 7.0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			argparse::help_opt(),
		}
	};

    String[] args = {"testprog", "-h"}; 
	test::@error(agp.parse(args), ArgError.HELP_SHOW);
}

fn void! test_help_show_long() {

	int val = 0;
	String s;
	float f = 7.0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			argparse::help_opt(),
		}
	};

    String[] args = {"testprog", "--help"}; 
	test::@error(agp.parse(args), ArgError.HELP_SHOW);
}

fn void! test_bool_flag() {

	bool val = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "-f"}; 
    test::equal(val, false);
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, true);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_bool_flag_default() {

	bool val = true;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog"}; 
    test::equal(val, true);
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, true);
    test::equal(agp.options[0].is_present, false);
}

fn void! test_bool_flag_unset() {

	bool val = true;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--no-flt"}; 
    test::equal(val, true);
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, false);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_str_default() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog"}; 
    test::equal(val, "foo");
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, "foo");
    test::equal(agp.options[0].is_present, false);
}

fn void! test_str_set_equal() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--flt=bar"}; 
    test::equal(val, "foo");
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, "bar");
    test::equal(agp.options[0].is_present, true);
}

fn void! test_str_set_next_arg() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--flt", "bar"}; 
    test::equal(val, "foo");
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, "bar");
    test::equal(agp.options[0].is_present, true);
}


fn void! test_str_set_short_arg() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "-f", "bar"}; 
    test::equal(val, "foo");
    test::equal(agp.options[0].is_present, false);

	agp.parse(args)!;

    test::equal(val, "bar");
    test::equal(agp.options[0].is_present, true);
}

fn void! test_invalid_arg_short() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "-z"}; 
	test::@error(agp.parse(args), ArgError.INVALID_ARGUMENT);
}

fn void! test_invalid_arg_long() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--zooo"}; 
	test::@error(agp.parse(args), ArgError.INVALID_ARGUMENT);
}

fn void! test_missing_require_argument() {

	bool val = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val, .required = true},
		}
	};

    String[] args = {"testprog"}; 
	test::@error(agp.parse(args), ArgError.MISSING_ARGUMENT);
}


fn void! test_missing_require_arguments_many() {

	bool val = false;
	bool val2 = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val, .required = true},
			{.short_name = 'z', .long_name = "zzz", .value = &val, .required = true},
		}
	};

    String[] args = {"testprog"}; 
	test::@error(agp.parse(args), ArgError.MISSING_ARGUMENT);
}

fn void! test_passing_short_option_after_argument() {

	bool val = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "foo", "-f"}; 
	test::@error(agp.parse(args), ArgError.INVALID_ARGUMENT);
}

fn void! test_passing_long_option_after_argument() {

	bool val = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "foo", "--flt"}; 
	test::@error(agp.parse(args), ArgError.INVALID_ARGUMENT);
}

fn void! test_multiple_short_args() {

	bool val = false;
	bool val2 = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
			{.short_name = 'z', .long_name = "zzz", .value = &val2},
		}
	};

    String[] args = {"testprog", "-f", "-z"}; 
    agp.parse(args)!;

    test::equal(val, true);
    test::equal(val2, true);
    test::equal(agp.options[0].is_present, true);
    test::equal(agp.options[1].is_present, true);
}

fn void! test_str_set_next_arg_missing_value_with_eqchar() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--flt="}; 
	test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_str_set_next_arg_missing_value() {

	String val = "foo";
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
		}
	};

    String[] args = {"testprog", "--flt"}; 
	test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_str_set_next_arg_is_another_option() {

	String val = "foo";
	bool val2 = true;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
			{.short_name = 'a',  .value = &val},
		}
	};

    String[] args = {"testprog", "--flt", "-a" }; 
	test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_str_set_next_arg_is_another_option_long() {

	String val = "foo";
	bool val2 = true;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'f', .long_name = "flt", .value = &val},
			{.long_name = "all",  .value = &val},
		}
	};

    String[] args = {"testprog", "--flt", "--all" }; 
	test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_duplicated_flag(){

	bool val2 = true;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "all",  .value = &val2},
		}
	};

    String[] args = {"testprog", "--all", "--all" }; 
	test::@error(agp.parse(args), ArgError.INVALID_ARGUMENT);
}

fn void! test_integer_option_i32(){

	int val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "--int=3"}; 
    agp.parse(args)!;

    test::equal(val, 3);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_integer_option_parsing_error(){

	int val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'i', .long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "--int=a"}; 
    test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_integer_option_parsing_error_short(){

	int val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'i', .long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "-i", "a"}; 
    test::@error(agp.parse(args), ArgError.ARGUMENT_VALUE);
}

fn void! test_integer_option_u32(){

	uint val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "--int=3"}; 
    agp.parse(args)!;

    test::equal(val, 3);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_integer_option_i64(){

	long val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "--int=3"}; 
    agp.parse(args)!;

    test::equal(val, 3);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_integer_option_u64(){

	ulong val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "int",  .value = &val},
		}
	};

    String[] args = {"testprog", "--int=3"}; 
    agp.parse(args)!;

    test::equal(val, 3);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_float_option_f32(){

	float val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "float",  .value = &val},
		}
	};

    String[] args = {"testprog", "--float=3.23"}; 
    agp.parse(args)!;

    test::almost_equal(val, 3.23);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_float_option_f64(){

	double val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "float",  .value = &val},
		}
	};

    String[] args = {"testprog", "--float=3.23"}; 
    agp.parse(args)!;

    test::almost_equal(val, 3.23);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_float_option_f64_nan(){

	double val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.long_name = "float",  .value = &val},
		}
	};

    String[] args = {"testprog", "--float=nan"}; 
    agp.parse(args)!;

    test::almost_equal(val, double.nan);
    test::equal(agp.options[0].is_present, true);
}

fn void! test_multi_short_flags(){

	bool val = false;
	bool val2 = false;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.options = { 
			{.short_name = 'a',  .value = &val},
			{.short_name = 'b',  .value = &val2},
		}
	};

    String[] args = {"testprog", "-ab"}; 
	agp.parse(args)!!;

	test::equal(val, true);
	test::equal(val2, true);
}
