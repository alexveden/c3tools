module test::std::os::argparse @test;
import std::os::argparse;
import std::testing::test;


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

	test::eq(agp.usage, "option -sdf -[sdf]");
	test::eq(agp.description, "test ArgParse program");
	test::eq(agp.epilog, "ArgParse epilog");
	test::eq(agp.options.len, 5);
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

