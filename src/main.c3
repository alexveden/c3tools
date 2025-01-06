module c3test;
import std::io;
import std::os::argparse;


fn int main(String[] args)
{
	int val = 0;
	any aval = &val;

	int* pval = anycast(aval, int)!!;
	
	String s;
	float f = 0.0;
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
			{.short_name = 'a', .long_name = "all", .value = &val, .default_value=&&3, .help = "This is a sample option"},
			{.short_name = 's', .long_name = "string", .value = &s, .default_value=&&"foo", .help = "Simple string"},
			{.short_name = 'f', .long_name = "flt", .value = &f, .required=true, .help = "float arg"},
		}
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	}
	return 0;
}

