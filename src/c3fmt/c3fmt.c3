module c3fmt;
module c3tools::codefmt;
import std::io;
import c3lib::argparse;

fn int main(String[] args)
{
    bool force_mode = false;
    bool dry_mode = false;
    int max_line_width = 100;
    String indent_type = "4";
    argparse::ArgParse agp = {
        .description = "c3 code formatting tool",
        .usage = "[options] file1 .. fileN",
        .options = {
            argparse::help_opt(),
            argparse::group_opt("Basic options"),
            {
                .short_name = 'f',
                .long_name = "force",
                .value = &force_mode,
                .help = "force formatting non .c3 files"
            },
            {
                .short_name = 'n',
                .long_name = "dry",
                .value = &dry_mode,
                .help = "dry mode (only print)"
            },
            argparse::group_opt("Code format options"),
            {
                .short_name = 'w',
                .long_name = "width",
                .value = &max_line_width,
                .help = "max line width"
            },
            {
                .short_name = 'i',
                .long_name = "indent",
                .value = &indent_type,
                .help = `indent type: 2,4,8 for spaces, t for tabs`
            },
        },
    };

    if (catch err = agp.parse(args)) {
        agp.print_usage()!!;
        return 1;
    }
    if (agp.arguments.len == 0) {
        agp.print_usage()!!;
        return 1;
    }

    foreach (String file_name : agp.arguments) {
        if (catch err = format_file(file_name, max_line_width, force_mode, dry_mode, indent_type)) {
            return 1;
        }
    }

    return 0;
}

fn void! format_file(
    String file_name, int max_line_width, bool force_mode, bool dry_mode, String indent_type
)
{
    path::Path p = path::temp_new(file_name)!;

    if (!path::exists(p)) {
        io::printfn("File not exists: %s", file_name);
        return IoError.FILE_NOT_FOUND?;
    }
    if (path::is_dir(p)) {
        io::printfn("Expected file, got directory: %s", file_name);
        return IoError.FILE_IS_DIR?;
    }
    if (!force_mode && !p.has_extension("c3")) {
        io::printfn("Expected only .c3 expension (or use --force flag) %s", file_name);
        return IoError.GENERAL_ERROR?;
    }
    if (indent_type.len != 1) {
        io::printfn("--indent= parameter must be a 2,4,8 or t, got '%s'", indent_type);
        return IoError.GENERAL_ERROR?;
    }

    io::printfn("Path: %s", p.str_view());

    String contents = (String)file::load_new(p.str_view())!;
    defer contents.free();

    CodeFmt fmt = CodeFmt.new_init(max_line_width: max_line_width, indent_type: indent_type[0]);
    defer fmt.free();

    String formatted = fmt.format(contents, print_lex: false)!!;
    if (dry_mode) {
        io::print(formatted);
    } else {
        file::save(file_name, formatted)!;
    }
}

