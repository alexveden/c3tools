module c3test;
import std::io;
import std::os::argparse;

fn void! hello_comand(argparse::ArgParse* args) {
	bool all = false;
	argparse::ArgParse agp = {
		.description = "Hello command",
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Command options"),
			{.short_name = 'a', .long_name = "all", .value = &all, .help = "This is a command option"},
		}, 
	};
	if(catch err = agp.parse(args.arguments)){
		agp.print_usage()!!;
		return err?;
	}

	if (all){
		io::printfn("Hello ALL world");
	} else {
		io::printfn("Hello world");
	}
}

fn void! command_handler(argparse::ArgParse* args){
	if(args.arguments.len == 0){
		args.print_usage()!!;
		return IoError.OVERFLOW?;
	}

	switch(args.arguments[0]) {
		case "hello":
			return hello_comand(args);
		case "add":
			io::printfn("add command");
			return;
		default:
			io::printfn("Unknown command");
			args.print_usage()!!;
			return IoError.OVERFLOW?;
	}

}

fn int main(String[] args)
{
	int val = 0;
	bool flag = false;
	String s;
	float f = 0.0;
	argparse::ArgParse agp = {
		.description = "test ArgParse program",
		.usage = "[c3test args] {hello,add} [cmd-args]",
		.epilog= "ArgParse epilog",
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{.short_name = 'a', .long_name = "all", .value = &val, .help = "This is a sample option"},
			{ .long_name = "string", .value = &s, .help = "Simple long_name string"},
			{ .short_name = 'f', .value = &flag, .help = "short opt flag"},
		}, 
		.flags = {
			.stop_at_non_option = true, // NOTE: this is crucial for sub commands 
		}
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	}

	if(catch err = command_handler(&agp)) {
		return 1;
	}

	io::printf("My arguments: val=%s, s=%s, f=%s\n", val, s, f);

	return 0;
}

