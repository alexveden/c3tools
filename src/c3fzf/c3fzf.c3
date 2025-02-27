module c3symbols;
import c3tools::ast @public;
import c3tools::lsp @public;
import c3tools::ast::lexer;
import std::io;
import c3lib::argparse;
import std::sort;
import std::collections::list;

struct FzfSettings
{
    String project_path;
    String stdlib_path;
    String module_filter;
    String type_filter;
    String item_filter;
    bool preview;
    int verbosity;
}

fault FzfFault
{
    MODULE_NOT_FOUND,
    BAD_ARGUMENT,
}

struct ModuleDecl
{
    AstModule* mod;
    AstNode* decl;
}

fn int main(String[] args)
{
    // Defaults
    FzfSettings settings = {
        .stdlib_path = "",
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
            {
                .long_name = "stdlib",
                .value = &settings.stdlib_path,
                .help = "stdlib path for std symbols"
            },
            {
                .long_name = "preview",
                .value = &settings.preview,
                .help = "preview symbols (requires full module name)"
            },
            {
                .long_name = "project",
                .value = &settings.project_path,
                .help = "project path"
            },
        },
    };

    if (catch err = agp.parse(args)) {
        agp.print_usage()!!;
        return 1;
    }

    if (agp.arguments.len > 0) settings.module_filter = agp.arguments[0];
    if (agp.arguments.len > 1) settings.type_filter = agp.arguments[1];

    if (catch err = find(&settings)) {
        return 1;
    }

    return 0;
}

fn void! find(FzfSettings* settings) @local
{
    if (settings.preview && settings.module_filter == ".") {
        io::printfn("You must pass full module name in a module filter argument, got .");
        return FzfFault.BAD_ARGUMENT?;
    }
    if (!settings.project_path) {
        io::printfn("project_path is not set");
        return FzfFault.BAD_ARGUMENT?;
    }

    Path proj_abs = path::temp_new(settings.project_path).new_absolute()!;
    settings.project_path = proj_abs.str_view();
    defer proj_abs.free();
    
    Path! std_abs = path::temp_new(settings.stdlib_path).new_absolute();
    defer {
        if(try std_abs) std_abs.free();
    }
    
    if (try std_abs){
        settings.stdlib_path = std_abs.str_view();
    }
    
    LspProject proj = LspProject.new_init(settings.project_path, settings.stdlib_path);
    defer proj.free();

    if (catch err = proj.load()) {
        io::printfn("c3 project load failed: %s", err);
        return err?;
    }

    proj.load_symbols()!;

    if (!settings.type_filter && !settings.preview) {
        return print_modules_list(settings, &proj);
    }

    List(<ModuleDecl>) declarations;
    declarations.temp_init(proj.modules.items_len);

    foreach (&sym : proj.modules.iter_items()) {
        AstModule* m = sym.ptr.mod;

        if (settings.module_filter != ".") {
            if (settings.preview) {
                if (m.value != settings.module_filter) continue;
            } else {
                if (!m.value.contains(settings.module_filter)) continue;
            }
        }

        if (settings.type_filter == ".") {
            declarations.push(ModuleDecl {.mod = m, .decl = null});
        }

        for LOOP: (AstTypeDef* decl = m.decls; decl != null; decl = (AstTypeDef*)decl.next) {
            if (settings.type_filter && settings.type_filter != ".") {
                if (!decl.value.contains(settings.type_filter)) continue;
            }

            for (AstNode* attr = decl.attributes; attr != null; attr = attr.next) {
                if (attr.value.starts_with("@local")) continue LOOP;
                if (attr.value.starts_with("@test")) continue LOOP;
            }

            declarations.push(ModuleDecl {.mod = m, .decl = decl});
        }

    }
    if (!declarations.len()) {
        io::printfn(
            "No declarations found with name: %s: %s", settings.module_filter, settings.type_filter
        );
        return FzfFault.MODULE_NOT_FOUND?;
    }

    sort::quicksort(declarations, &cmp_decl);
    if (settings.preview) {
        return print_preview(
            settings, &proj, declarations, is_full_preview: settings.type_filter != ""
        );
    } else {
        foreach (mdecl : declarations) {
            io::printfn(
                "%s %s %s",
                mdecl.mod.value,
                mdecl.decl == null ? "." : mdecl.decl.value,
                mdecl.decl == null ? "" : lexer::token_type_to_string(mdecl.decl.type)
            );
        }
    }
}

// Sort the tests by their name in ascending order.
fn int cmp_str(String a, String b)
{
    usz an = a.len;
    usz bn = b.len;
    if (an > bn) @swap(a, b);
    foreach (i, ac : a) {
        char bc = b[i];
        if (ac != bc) return an > bn ? bc - ac : ac - bc;
    }
    return (int)(an - bn);
}

fn void! print_modules_list(FzfSettings* settings, LspProject* proj) @local
{
    List(<String>) modules;
    modules.new_init(proj.modules.len());
    defer modules.free();

    foreach (mod : proj.modules.iter_names()) {
        if (settings.module_filter != ".") {
            if (!mod.contains(settings.module_filter)) continue;
        }

        modules.push(mod);
    }
    if (!modules.len()) {
        io::printfn("No modules found with name: %s", settings.module_filter);
        return FzfFault.MODULE_NOT_FOUND?;
    }

    sort::quicksort(modules, &cmp_str);

    foreach (i, m : modules) {
        io::printf("%s", m);
        io::print("\n");
    }
}

macro print_nodes(format, ast_nodes, String sep = "")
{
    for (AstNode* node = ast_nodes; node != null; node = node.next) {
        io::printf(format, node.value);
        if (node.next) {
            io::print(sep);
        }
    }
}

fn void print_decl_def(AstTypeDef* d, bool is_full_preview)
{
    assert(d.type == TokenType.DEF);

    io::printf("def %s = ", d.value);
    print_nodes("%s", d.ftype, sep: " ");
    io::printfn(";");
}

fn void print_decl_distinct(AstTypeDef* d, bool is_full_preview)
{
    assert(d.type == TokenType.DISTINCT);

    io::printf("distinct %s = ", d.value);
    print_nodes("%s", d.ftype);
    io::printfn(";");
}

fn void print_decl_const(AstTypeDef* d, bool is_full_preview)
{
    assert(d.type == TokenType.CONST);

    io::printf("const ");
    print_nodes("%s", d.ftype);
    io::printfn(" %s;", d.value);
}

fn void print_decl_enum(AstTypeDefEnumerable* d, bool is_full_preview)
{
    assert(d.type == TokenType.ENUM || d.type == TokenType.FAULT);

    if (is_full_preview) {
        io::print("\n");
        print_docs(d.docs);
    }

    io::printf("%s %s ", lexer::token_type_to_string(d.type), d.value);
    if (is_full_preview) {
        io::printfn("{");
        print_nodes("    %s,\n", d.values);
        io::printfn("}");
    } else {
        io::printfn("{ ... }");
    }
}

fn void print_decl_struct(AstTypeDefStructural* d, bool is_full_preview, uint indent = 0)
{

    if (is_full_preview && indent == 0) {
        io::print("\n");
        print_docs(d.docs);
    }

    DString idt = dstring::temp_new();
    for (uint i = 0; i < indent; i++) {
        idt.append(" ");
    }
    io::printf("%s%s %s ", idt, lexer::token_type_to_string(d.type), d.value);

    if (is_full_preview) {
        print_nodes("%s ", d.attributes, sep: " ");
        io::printfn("{");
        for (AstTypeDef* node = d.members; node != null; node = (AstTypeDef*)node.next) {
            switch (node.type) {
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

fn void print_docs(AstDoc* docs)
{
    if (!docs) return;

    io::printf(docs.value);
    for (AstDocContract* node = docs.contracts; node != null; node = (AstDocContract*)node.next) {
        io::printf("\n%s ", node.value);

        for (AstNode* contr = node.items; contr != null; contr = contr.next) {
            if (contr.type == STRING || contr.type == RAW_STRING) io::print(" ");
            io::printf("%s", contr.value);
        }
    }
    if (docs.contracts) io::print("\n");
    io::printfn("*>");
}

fn void print_decl_callable(AstCallable* d, bool is_full_preview)
{
    assert(d != null);
    if (is_full_preview) {
        io::printf("\n");
        print_docs(d.docs);
    }
    switch (d.type) {
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
    for (AstCallableParam* node = d.params; node != null; node = (AstCallableParam*)node.next) {
        if (is_full_preview) {
            if (node.param_type) {
                io::printf("%s", node.param_type.value);
                if (node.param_type.next && node.param_type.next.value != "=") {
                    print_nodes("%s", node.param_type.next);
                }
                io::print(" ");
            }
        }

        io::printf("%s", node.value);

        if (is_full_preview && node.param_type) {
            if (node.param_type.next && node.param_type.next.value == "=") {
                print_nodes("%s", node.param_type.next);
            }
        }
        if (node.next) {
            io::printf(", ");
        }
    }
    io::printf(")");

    if (is_full_preview) 
    {
        if (d.attributes) {
            print_nodes(" %s", d.attributes, sep: " ");
        }
        io::printfn(" {} ");
    } else {
        io::printf("\n");
    }
}

fn String strip_path(FzfSettings* settings, String path) {
    String result = path;
    if (settings.project_path && path.starts_with(settings.project_path)) {
        result = path[settings.project_path.len..];
    }

    if (settings.stdlib_path && path.starts_with(settings.stdlib_path)) {
        result = path[settings.stdlib_path.len..];
    }

    if (result && result[0] == '/') result = result[1..];

    return result;
}

fn void! print_preview(
    FzfSettings* settings, LspProject* proj, List(<ModuleDecl>) declarations, bool is_full_preview
) @local
{

    SymbolItem* sym = proj.modules.first(settings.module_filter);
    if (sym == null) {
        io::printfn("module not found: %s", settings.module_filter);
        return;
    }

    io::printfn("module %s;\n", sym.ptr.mod.value);
    if (sym.ptr.mod.docs) {
        io::printf(sym.ptr.mod.docs.value);
        io::printfn("*>");
    }
    io::printfn("/*             FILES           */");

    for(sym = proj.modules.first(settings.module_filter); sym; sym = proj.modules.next(sym)) {
        AstModule* mod = sym.ptr.mod;

        io::printf("// %s", mod.value);
        for (AstNode* node = mod.attributes; node != null; node = node.next) {
            io::printf(" %s", node.value);
        }

        io::printf(" at: %s:%d\n", strip_path(settings, mod.file_path), mod.src_line);
    }

    io::printfn("\n\n/*             TYPES           */");
    foreach (d : declarations) {
        if (d.decl == null) continue;

        switch (d.decl.type) {
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
    foreach (d : declarations) {
        if (d.decl == null) continue;

        switch (d.decl.type) {
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
    if (a.decl == null || b.decl == null) {
        // synth module-wide decl filter
        if (a.decl == null && b.decl != null) return -1;
        if (a.decl != null && b.decl == null) return 1;
        return 0;
    }
    if (a.decl.type == b.decl.type) {
        return cmp_str(a.decl.value, b.decl.value);
    }
    bool is_comparable_type = false;
    switch (a.decl.type) {
        case FN:
        case MACRO:
            switch (b.decl.type) {
                case FN:
                case MACRO:
                    is_comparable_type = true;
                default:
                    break;
            }
        case STRUCT:
        case DEF:
        case DISTINCT:
            switch (b.decl.type) {
                case STRUCT:
                case DEF:
                case DISTINCT:
                    is_comparable_type = true;
                default:
                    break;
            }
        default:
            break;
    }

    if (is_comparable_type) {
        return cmp_str(a.decl.value, b.decl.value);
    } else {
        return a.decl.type - b.decl.type;
    }

}
