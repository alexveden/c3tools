module c3symbols;
import c3tools::ast;
import c3tools::lexer;
import std::io;
import std::os::argparse;
import std::collections::list;

fn void! process_dir(String dir_name) {
    AstProject proj = AstProject.new_init(dir_name, "");
    proj.load()!!;
    io::printfn("Project [%s]: #%d modules", dir_name, proj.modules.len());
}
fn void! process_file(String file_name) {
	String contents = (String)file::load_new(file_name)!;
	defer contents.free();

    DString tstr = dstring::temp_new(contents);
    defer tstr.free();

	// io::printfn("File source:\n%s", file_name);

    Ast ast = ast::parse(contents, file_name, print_lex: false);
    // defer ast.free();
    io::printfn("{");
    io::printfn(`  "modules": [`);
    ast::@node_foreach(ast.modules; AstModule* m){
        io::printfn("    {");
        io::printfn(`      "file": "%s",`, file_name);
        io::printfn(`      "name": "%s",`, ast.@node_join(m.name, tstr, "::"));
        io::printf(`      "attr": [`, ast.@node_join(m.attributes, tstr, ","));

        bool is_first = true;
        ast::@node_foreach(m.attributes; AstNode* att){
            if (!att.value.starts_with("@link")){
                if (!is_first) io::printf(`, `);
                io::printf(`"%s"`, att.value);
                is_first = false;
            }
        };
        io::printfn(`],`, ast.@node_join(m.attributes, tstr, ","));

        io::printf(`      "imports": [`, ast.@node_join(m.attributes, tstr, ","));
        ast::@node_foreach(m.imports; AstImport* imp){
            io::printf(`"%s"`, ast.@node_join(imp.name, tstr, "::"));
            if (imp.next) io::printf(`, `);
        };
        io::printfn(`],`, ast.@node_join(m.attributes, tstr, ","));

        io::printf(`      "callable": [`, ast.@node_join(m.attributes, tstr, ","));
        is_first = true;
        ast::@node_foreach(m.decls; AstNode* decl){
            if (decl.type == FN || decl.type == MACRO) {
                AstCallable* func = (AstCallable*)decl;
                if (!is_first) io::printf(`, `);
                io::printf(`"%s"`, ast.@node_join(func.name, tstr, "."));
                is_first = false;
            } 
        };
        io::printfn(`]`);
        io::printf("    }");

        if (m.next) io::printf(`,`);
        io::printfn("");
    };
    io::printfn("  ]");
    io::printfn("}, ");
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
	
	// if(catch err = process_file(agp.arguments[0])) {
	if(catch err = process_dir(agp.arguments[0])) {
	    io::printfn("process_file error with: %s", err);
	    return 1;
	}


	return 0;
}

