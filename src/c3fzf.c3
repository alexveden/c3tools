module c3symbols;
import c3tools::ast @public;
import c3tools::lexer; 
import std::io;
import std::os::argparse;
import std::sort;
import std::collections::list;

struct FzfSettings {
    String project_path;
    String stdlib_path;
    String module_filter;
    String type_filter;
    String item_filter;
    bool preview;
}

fault FzfFault {
    MODULE_NOT_FOUND,
    BAD_ARGUMENT,
}

struct ModuleDecl {
   AstModule* mod;
   AstNode* decl;
}

fn void! print_modules_list(FzfSettings* settings, AstProject* proj) @local {
    List(<AstModule*>) modules;
    modules.temp_init(proj.modules.capacity);
    foreach(idx: proj.mod_index.iter()) {
        if (settings.module_filter != ".") {
            if (!idx.key.contains(settings.module_filter)) continue;
        }
        
        modules.push(proj.modules[idx.value]);
    }
    if(!modules.len()) {
        io::printfn("No modules found with name: %s", settings.module_filter);
        return FzfFault.MODULE_NOT_FOUND?;
    }

	sort::quicksort(modules, &ast::cmp_module);
    foreach(i, m: modules) {
        io::printf("%s", m.value);
        // for(AstNode* node = m.attributes; node != null; node = node.next){
        //     io::printf(" %s", node.value);
        // } 
        io::print("\n");
    }
}

macro print_nodes(format, ast_nodes, String sep = "") {
    for(AstNode* node = ast_nodes; node != null; node = node.next){ 
        io::printf(format, node.value);
        if (node.next) {
            io::print(sep);
        }
    }
}

fn void print_decl_def(AstTypeDef* d, bool is_full_preview) {
    assert(d.type == TokenType.DEF);

    io::printf("def %s = ", d.value);
    print_nodes("%s", d.ftype, sep: " ");
    io::printfn(";");
}
fn void print_decl_distinct(AstTypeDef* d, bool is_full_preview) {
    assert(d.type == TokenType.DISTINCT);

    io::printf("distinct %s = ", d.value);
    print_nodes("%s", d.ftype);
    io::printfn(";");
}
fn void print_decl_const(AstTypeDef* d, bool is_full_preview) {
    assert(d.type == TokenType.CONST);

    io::printf("const ");
    print_nodes("%s", d.ftype);
    io::printfn(" %s;", d.value);
}
fn void print_decl_enum(AstTypeDefEnumerable* d, bool is_full_preview) {
    assert(d.type == TokenType.ENUM || d.type == TokenType.FAULT);

    if (is_full_preview){
        io::print("\n");
        print_docs(d.docs);
    } 

    io::printf("%s %s ", lexer::token_type_to_string(d.type), d.value);
    if (is_full_preview){
        io::printfn("{");
        print_nodes("    %s,\n", d.values);
        io::printfn("}");
    } else {
        io::printfn("{ ... }");
    }
}

fn void print_decl_struct(AstTypeDefStructural* d, bool is_full_preview, uint indent = 0) {

    if (is_full_preview && indent == 0){
        io::print("\n");
        print_docs(d.docs);
    } 

	DString idt = dstring::temp_new();
	for(uint i = 0; i < indent; i++){
	    idt.append(" ");
	}
    io::printf("%s%s %s ", idt, lexer::token_type_to_string(d.type), d.value);

    if (is_full_preview){
        print_nodes("%s ", d.attributes, sep: " ");
        io::printfn("{");
        for(AstTypeDef* node = d.members; node != null; node = (AstTypeDef*)node.next){ 
            switch(node.type) {
                case STRUCT:
                case BITSTRUCT:
                case UNION:
                    print_decl_struct((AstTypeDefStructural*)node, true, indent + 4);
                default:
                    io::printf("%s    ", idt);
                    print_nodes("%s", node.ftype);
                    io::printf(" %s;\n", node.value);
            }
        }
        io::printfn("%s}", idt);
    } else {
        io::printfn("{ ... }");
    }
}

fn void print_docs(AstDoc* docs) {
    if(!docs) return;

    io::printf(docs.value);
    for(AstDocContract* node = docs.contracts; node != null; node = (AstDocContract*)node.next){
        io::printf("\n%s ", node.value);
        print_nodes(" %s", node.items, sep: " ");
    }
    if(docs.contracts) io::print("\n");
    io::printfn("*>");
} 

fn void print_decl_callable(AstCallable* d, bool is_full_preview) {
    assert(d != null);
    if(is_full_preview){
        io::printf("\n");
        print_docs(d.docs);
    }
    switch(d.type){
        case FN:
            io::printf("fn    ");
        case MACRO:
            io::printf("macro ");
        default:
            unreachable();
    }
    if (is_full_preview && d.ftype) {

        print_nodes("%s", d.ftype);
        if (d.ftype.value) io::printf(" ");
    }

    print_nodes("%s", d.name, sep: ".");

    io::printf("(");
    for(AstCallableParam* node = d.params; node != null; node = (AstCallableParam*)node.next){ 
        if (is_full_preview) {
            if (node.param_type) {
                io::printf("%s", node.param_type.value);
                if(node.param_type.next && node.param_type.next.value != "="){
                    print_nodes("%s", node.param_type.next);
                }
                io::print(" ");
            }
        }
        
        io::printf("%s", node.value);

        if (is_full_preview && node.param_type) {
            if(node.param_type.next && node.param_type.next.value == "="){
                print_nodes("%s", node.param_type.next);
            }
        }
        if(node.next) {
            io::printf(", ");
        }
    }
    io::printf(")");

    if (is_full_preview) print_nodes(" %s", d.attributes, sep: "");

    io::printfn(" {} ");
}
fn void! print_preview(FzfSettings* settings, AstProject* proj, List(<ModuleDecl>) declarations, bool is_full_preview) @local {

    uint mod_idx = proj.mod_index[settings.module_filter]!!;
    AstModule* mod = proj.modules[mod_idx];
    io::printfn("module %s;\n", mod.value);
    if(mod.docs) {
        io::printf(mod.docs.value);
        io::printfn("*>");
    }
    io::printfn("/*             FILES           */");
    for(mod_idx; mod_idx < proj.modules.len(); mod_idx++) {
        if (mod.value != proj.modules[mod_idx].value) break; // got another module
        mod = proj.modules[mod_idx];

        io::printf("// %s", mod.value);
        for(AstNode* node = mod.attributes; node != null; node = node.next){
            io::printf(" %s", node.value);
        } 

        io::printf(" at: %s:%d\n", mod.file_path, mod.src_line);
    }

    io::printfn("\n\n/*             TYPES           */");
    foreach(d: declarations) {
        if(d.decl == null) continue;

        switch(d.decl.type) {
            case DEF:
                print_decl_def((AstTypeDef*)d.decl, is_full_preview);
            case DISTINCT:
                print_decl_distinct((AstTypeDef*)d.decl, is_full_preview);
            case ENUM:
            case FAULT:
                print_decl_enum((AstTypeDefEnumerable*)d.decl, is_full_preview);
            case CONST:
                print_decl_const((AstTypeDef*)d.decl, is_full_preview);
            case STRUCT:
            case BITSTRUCT:
            case UNION:
                print_decl_struct((AstTypeDefStructural*)d.decl, is_full_preview);
            default:
                // io::printfn("UNKN %s:%s",d.decl.type, d.decl.value);
                continue;
        }

    }

    io::printfn("\n\n/*             CALLABLE           */");
    foreach(d: declarations) {
        if(d.decl == null) continue;

        switch(d.decl.type) {
            case FN:
            case MACRO:
                print_decl_callable((AstCallable*)d.decl, is_full_preview);
            default:
                continue;
        }

    }
}

fn int cmp_decl(ModuleDecl a, ModuleDecl b) @private
{
    // if (a.mod != b.mod){
    //     // Check if it's a different files under the same module name
    //     int mcmp = ast::cmp_module(a.mod, b.mod);
    //     if (mcmp != 0) return mcmp;
    // }
    if (a.decl == null || b.decl == null) {
        // synth module-wide decl filter
        if (a.decl == null && b.decl != null) return -1;
        if (a.decl != null && b.decl == null) return 1;
        return 0;
    }
    if (a.decl.type == b.decl.type) {
        return ast::cmp_str(a.decl.value, b.decl.value);
    }
    bool is_comparable_type = {|
        switch(a.decl.type) {
            case FN:
            case MACRO:
                switch(b.decl.type){
                    case FN:
                    case MACRO:
                        return true;
                    default:
                        return false;
                }
            case STRUCT:
            case DEF:
            case DISTINCT:
                switch(b.decl.type){
                    case STRUCT:
                    case DEF:
                    case DISTINCT:
                        return true;
                    default:
                        return false;
                }
            default:
                return false;
        }
    |};

    if(is_comparable_type) {
        return ast::cmp_str(a.decl.value, b.decl.value);
    } else {
        return a.decl.type - b.decl.type;
    }

}

fn void! find(FzfSettings *settings) @local {
    if (settings.preview && settings.module_filter == ".") {
        io::printfn("You must pass full module name in a module filter argument, got .");
        return FzfFault.BAD_ARGUMENT?;
    }
    AstProject proj = AstProject.new_init(settings.project_path, settings.stdlib_path);
    defer proj.free();

    if (catch err = proj.load()) {
        io::printfn("c3 project load failed: %s", err);
        return err?;
    }

    if (!settings.type_filter && !settings.preview){
        return print_modules_list(settings, &proj);
    }

    List(<ModuleDecl>) declarations;
    declarations.temp_init(proj.modules.capacity);
    foreach(m: proj.modules) {
        if (settings.module_filter != ".") {
            if (settings.preview) {
                if (m.value != settings.module_filter) continue;
            } else {
                if (!m.value.contains(settings.module_filter)) continue;
            }
        }

        if(settings.type_filter == "."){
            declarations.push(ModuleDecl{.mod = m, .decl = null});
        }

        for LOOP: (AstTypeDef* decl = m.decls; decl != null; decl = (AstTypeDef*)decl.next) {
            if (settings.type_filter && settings.type_filter != ".") {
                if (!decl.value.contains(settings.type_filter)) continue;
            }

            for(AstNode* attr = decl.attributes; attr != null; attr = attr.next) {
                if (attr.value.starts_with("@local")) continue LOOP;
                if (attr.value.starts_with("@test")) continue LOOP;
            }

            declarations.push(ModuleDecl{.mod = m, .decl = decl});
        }
        
    }
    if(!declarations.len()) {
        io::printfn("No declarations found with name: %s: %s", settings.module_filter, settings.type_filter);
        return FzfFault.MODULE_NOT_FOUND?;
    }

	sort::quicksort(declarations, &cmp_decl);
	if (settings.preview) {
	    return print_preview(settings, &proj, declarations, is_full_preview: settings.type_filter != "");
	} else {
        foreach(mdecl: declarations) {
            io::printfn("%s %s %s",
                        mdecl.mod.value,
                        mdecl.decl == null ? "." : mdecl.decl.value,
                        mdecl.decl == null ? "" : lexer::token_type_to_string(mdecl.decl.type)
                        );
        }
	}
}

fn int main(String[] args)
{
	// Defaults
	FzfSettings settings = {
	    .stdlib_path = "/home/ubertrader/code/c3c/lib",
	    // .stdlib_path = "",
	    .project_path = ".",
	    .module_filter = ".",
	    .type_filter = "",
	    .item_filter = "",
	    .preview = false,
	};

	argparse::ArgParse agp = {
		.description = "c3 symbols fuzzy finder",
		.usage = "[options] [.|module_filter] [.|type_filter]",
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{.short_name = 's', .long_name = "stdlib", .value = &settings.stdlib_path, .help = "includes stdlib symbols"},
			{.short_name = 'p', .long_name = "preview", .value = &settings.preview, .help = "preview symbols (require full module name)"},
		}, 
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	} 

	if(agp.arguments.len > 0)  settings.module_filter = agp.arguments[0];   
	if(agp.arguments.len > 1)  settings.type_filter = agp.arguments[1];   
	
	// if(catch err = process_file(agp.arguments[0])) {
	// io::printfn("%s", stdlib_path);
	if(catch err = find(&settings)) {
	    return 1;
	}


	return 0;
}

