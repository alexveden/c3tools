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
}

struct ModuleDecl {
   AstModule* mod;
   AstNode* decl;
}

fn void! print_modules_list(FzfSettings* settings, AstProject* proj) @local {
    List(<AstModule*>) modules;
    modules.temp_init(proj.modules.capacity);
    foreach(idx: proj.mod_index.iter()) {
        if (settings.preview) {
            if (idx.key != settings.module_filter) continue;
        } else if (settings.module_filter != ".") {
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

fn void! print_preview(FzfSettings* settings, List(<AstModule*>) modules) @local {
    foreach(mod: modules){
        if (mod.value != settings.module_filter) continue;
        modules.push(mod);
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

fn int cmp_decl(ModuleDecl a, ModuleDecl b) @private
{
    if (a.mod != b.mod){
        // Check if it's a different files under the same module name
        int mcmp = ast::cmp_module(a.mod, b.mod);
        if (mcmp != 0) return mcmp;
    }
    if (a.decl.type == b.decl.type) return ast::cmp_str(a.decl.value, b.decl.value);

    return a.decl.type - b.decl.type;
}

fn void! find(FzfSettings *settings) @local {
    AstProject proj = AstProject.new_init(settings.project_path, settings.stdlib_path);
    defer proj.free();

    if (catch err = proj.load()) {
        io::printfn("c3 project load failed: %s", err);
        return err?;
    }

    if (!settings.type_filter && !settings.preview) {
        return print_modules_list(settings, &proj);
    }

    List(<ModuleDecl>) declarations;
    declarations.temp_init(proj.modules.capacity);
    foreach(m: proj.modules) {
        if (settings.module_filter != ".") {
            if (!m.value.contains(settings.module_filter)) continue;
        }

        for(AstNode* decl = m.decls; decl != null; decl = decl.next) {
            if (settings.type_filter != ".") {
                if (!decl.value.contains(settings.type_filter)) continue;
            }
            declarations.push(ModuleDecl{.mod = m, .decl = decl});
        }
        
    }
    if(!declarations.len()) {
        io::printfn("No declarations found with name: %s: %s", settings.module_filter, settings.type_filter);
        return FzfFault.MODULE_NOT_FOUND?;
    }

	sort::quicksort(declarations, &cmp_decl);
    foreach(mdecl: declarations) {
        io::printfn("%s %s:%s", mdecl.mod.value, mdecl.decl.type, mdecl.decl.value);
    }

    unreachable();
}

fn int main(String[] args)
{
	// Defaults
	FzfSettings settings = {
	    .stdlib_path = "/home/ubertrader/code/c3c/build/lib",
	    .project_path = ".",
	    .module_filter = ".",
	    .type_filter = "",
	    .item_filter = "",
	    .preview = false,
	};

	argparse::ArgParse agp = {
		.description = "c3 symbols fuzzy finder",
		.usage = "[options] [.|module_filter] [.|type_filter] [.|item_filter]",
		.options = { 
			argparse::help_opt(),
			argparse::group_opt("Basic options"),
			{.short_name = 's', .long_name = "stdlib", .value = &settings.stdlib_path, .help = "stdlib path"},
			{.short_name = 'p', .long_name = "preview", .value = &settings.preview, .help = "preview module symbols"},
		}, 
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	} 

	if(agp.arguments.len > 0)  settings.module_filter = agp.arguments[0];   
	if(agp.arguments.len > 1)  settings.type_filter = agp.arguments[1];   
	if(agp.arguments.len > 2)  settings.item_filter = agp.arguments[2];   
	
	// if(catch err = process_file(agp.arguments[0])) {
	// io::printfn("%s", stdlib_path);
	if(catch err = find(&settings)) {
	    return 1;
	}


	return 0;
}

