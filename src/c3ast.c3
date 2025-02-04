module c3lexer;
import c3tools::lexer;
import c3tools::ast;
import std::io;
import std::os::argparse;
import std::collections::list;

fn void! process_file(String file_name)
{
    String contents = (String)file::load_new(file_name)!;
    defer contents.free();

    Ast ast = ast::parse(contents, file_name);
    // defer ast.free();

    for (AstModule* m = ast.modules; m != null; m = (AstModule*)m.next) {
        io::printfn("module %s", m.value);
        for (AstTypeDef* decl = m.decls; decl != null; decl = (AstTypeDef*)decl.next) {
            io::printfn("%s %s at %d offset", decl.type, decl.value, decl.istart);

        }
    }

    io::printfn("DONE");
}

fn int main(String[] args)
{
    int val = 0;
    bool flag = false;
    String s;
    float f = 0.0;
    argparse::ArgParse agp = {
        .description = "c3 lexer sample",
        .usage = "[args] source_file",
        .options = {
            argparse::help_opt(),
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
    if (catch err = process_file(agp.arguments[0])) {
        io::printfn("process_file error with: %s", err);
        return 1;
    }

    return 0;
}
