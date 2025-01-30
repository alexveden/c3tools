module c3fmt;
module c3tools::codefmt;
import std::io;
import std::os::argparse;


fn void! format_file(String file_name, int max_line_width, bool force_mode) {
    path::Path p = path::temp_new(file_name)!;
    defer p.free();

	io::printfn("Path: %s", p);
    if (!path::exists(p)) {
        io::printfn("File not exists: %s", file_name);
        return IoError.FILE_NOT_FOUND?;
    }
    if (!path::is_dir(p)) {
        io::printfn("Expected file, got directory: %s", file_name);
        return IoError.FILE_IS_DIR?;
    }
    if (force_mode && !p.has_extension("c3")) {
        io::printfn("Expected only .c3 expension (or use --force flag) %s", file_name);
        return IoError.GENERAL_ERROR?;
    }

	String contents = (String)file::load_new(p.str_view())!;
	defer contents.free();
}

fn int main(String[] args)
{
	bool force_mode = false;
	int max_line_width = 88;
	argparse::ArgParse agp = {
		.description = "c3 code formatting tool",
		.usage = "[options] file1 .. fileN",
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{ .short_name = 'f', .long_name = "force",  .value = &force_mode, .help = "force formatting non .c3 files"},
			argparse::group_opt("Code format options"),
			{ .short_name = 'w', .long_name = "line-width",  .value = &max_line_width, .help = "max line width"},
		}, 
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	}
	if(agp.arguments.len == 0){
		agp.print_usage()!!;
		return 1;
	}

	foreach(String file_name : agp.arguments) {
	    if(catch err = format_file(file_name, max_line_width, force_mode))
	    {
	        return 1;
	    }
	}

	return 0;
}

