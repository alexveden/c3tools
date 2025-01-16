module c3symbols;
import c3tools::ast;
import std::io;
import std::os::argparse;
import std::collections::list;

fn void! process_file(String file_name) {
	String contents = (String)file::load_new(file_name)!;
	defer contents.free();

    DString tstr = dstring::temp_new(contents);
    defer tstr.free();

	io::printfn("File source:\n%s", file_name);

    Ast ast = ast::parse(contents, file_name, print_lex: false);
    defer ast.free();

    ast::@node_foreach(ast.modules; AstModule* m){
        io::printfn("%s %s;", m.value, ast.@node_join(m.name, tstr, "::"));

        io::printfn("imports:");
        ast::@node_foreach(m.imports; AstImport* imp){
            io::printfn("\t%s %s;", imp.value, ast.@node_join(imp.name, tstr, "::"));
        };

        io::printfn("decls:");
        ast::@node_foreach(m.decls; AstNode* decl){
            io::printfn("\t%s %s;", decl.type, decl.value);
        };
    };

	io::printfn("DONE");
}

fn int main(String[] args)
{
	int val = 0;
	bool flag = false;
	String s;
	float f = 0.0;
	argparse::ArgParse agp = {
		.description = "prints all c3 file symbols",
		.usage = "[args] source_file",
		.options = { 
			argparse::help_opt(),
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
	
	if(catch err = process_file(agp.arguments[0])) {
	    io::printfn("process_file error with: %s", err);
	    return 1;
	}


	return 0;
}

