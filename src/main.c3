module c3test;
import std::io;
import std::os::argparse;


fn int main(String[] args)
{
	int val = 0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.epilog= "ArgParse epilog",
		.usage = `
option -sdf -[sdf]
foo bara [-]
		`,
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{.short_name = 'a', .long_name = "all", .value = &val, .help = "This is a sample option"},
		}
	};

	agp.parse(args)!!;
	agp.print_usage()!!;
	return 0;
}

