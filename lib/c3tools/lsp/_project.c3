module c3tools::lsp::project;
import c3tools::ast::lexer;
import c3tools::lsp::symbols;
import std::hash::fnv32a;
import std::io;
import std::sort;
import std::collections::list;
import std::collections::map;

struct LspProject
{
    String proj_path;
    String stdlib_path;
    SymbolCache* modules;
    SymbolCache* sym_core;
    SymbolCache* sym_std;
    SymbolCache* sym_proj;
    allocator::DynamicArenaAllocator _allocator;
}

fn LspProject LspProject.new_init(String proj_path, String stdlib_path) @operator(construct)
{
    LspProject self = {
        .proj_path = proj_path,
        .stdlib_path = stdlib_path,
    };

    //  Arena allocator for storing all AST metadata (DynamicArenaAllocator backed by heap)
    self._allocator.init(5 * 1024 * 1024, allocator::heap());

    // All other allocations are done on heap to isolate AST data and make it sequential
    self.modules = SymbolCache.new_init(capacity: 512);

    // We will store symbols for core/std/project separately because they might have different
    // access or update patterns within LSP lifetime

    // builtin + std::core
    self.sym_core = SymbolCache.new_init(capacity: 128);
    // all other stdlib symbols
    self.sym_std = SymbolCache.new_init(capacity: 1024);
    // project symbols
    self.sym_proj = SymbolCache.new_init(capacity: 1024);

    return self;
}

fn void LspProject.free(&self)
{
    // self.mod_index.free();
    self.modules.free();
    self.sym_proj.free();
    self.sym_core.free();
    self.sym_std.free();
    self._allocator.free();
}

fn void! LspProject.module_add(&self, AstModule* m) @private
{
    assert(m.hash != 0, "module hash is zero");
    SymbolItem* it = self.modules.add(m.value);
    it.kind = SymbolKind.MODULE;
    it.ptr.mod = m;
}

fn void! LspProject.load_symbols(&self)
{
    assert(self.modules.len() > 0, "load modules first");
    SymbolItem* items = self.modules.items();

    for (uint i = 0; i < self.modules.len(); i++) {
        SymbolItem* it = &items[i];
        assert(it.kind == SymbolKind.MODULE);

        if (self.modules.get_name(it).starts_with("std::")) {
            self._load_module_symbols(&self.sym_std, it.ptr.mod)!;
        }
    }
    io::printfn(
        "Modules: #%s,Symbols stdlib: #%s, proj: #%s, core #%s",
        self.modules.len(),
        self.sym_std.len(),
        self.sym_proj.len(),
        self.sym_core.len(),
    );
}

fn void! LspProject._load_module_symbols(&self, SymbolCache** dest, AstModule* src) @private
{
    assert(src.hash, "no module hash");
    io::printfn("adding module symbols: %s", src.value);

    for LOOP: (AstTypeDef* decl = src.decls; decl != null; decl = (AstTypeDef*)decl.next) {
        if (!decl.value) {
            io::printfn("    %s -> %s: zero length symbol!", src.value, decl.type);
            continue LOOP;
        }
        io::printfn("    %s: %s", decl.type, decl.value);

        if (!(*dest).has_capacity(decl.value)) {
            *dest = (*dest).grow((*dest).items_capacity + 512);
            io::printfn("    %s -> grow!", decl.value);
        }

        self._add_symbol(*dest, src, decl)!;
    }
}

fn void! LspProject._add_symbol(&self, SymbolCache* dest, AstModule* src, AstTypeDef* decl) @private
{
    bool is_private = false;
    bool is_conditional = false;
    for (AstNode* attr = decl.attributes; attr != null; attr = attr.next) {
        if (attr.value.starts_with("@local")) return;
        if (attr.value.starts_with("@test")) return;
        if (attr.value.starts_with("@benchmark")) return;
        if (attr.value.starts_with("@private")) is_private = true;
        if (attr.value.starts_with("@if")) is_conditional = true;
    }
    SymbolItem* it = dest.add(decl.value);
    it.kind = SymbolKind.NA;
    it.module_hash = src.hash;
    // declarations.push(ModuleDecl {.mod = m, .decl = decl});
}

fn void! LspProject.load_source(&self, String full_source, String file_path)
{

    Ast ast = ast::parse(full_source, file_path, allc: &self._allocator);
    for (AstModule* m = ast.modules; m != null; m = (AstModule*)m.next) {
        // Skipping top level module without name
        if (ast.@node_len(m.name) == 0) continue;
        self.module_add(m)!;
    }
}

fn void! LspProject.load_path(&self, String path) @local
{
    assert(path);

    path::Path p = path::temp_new(path)!;
    if (!path::exists(p)) {
        return IoError.FILE_NOT_FOUND?;
    }
    if (!path::is_dir(p)) {
        return IoError.FILE_NOT_DIR?;
    }

    path::PathWalker fnwalk = fn bool! (Path p, bool is_dir, void* ctx) {
        LspProject* self = (LspProject*)ctx;
        if (is_dir) return false;
        if (!p.has_extension("c3")) {
            return false;
        }

        String contents = (String)file::load_new(p.str_view())!;
        defer contents.free();

        self.load_source(contents, p.str_view())!;

        return false;
    };
    p.walk(fnwalk, self)!!;
}

fn void! LspProject.load(&self)
{
    assert(self.modules.len() == 0, "double load?");

    if (self.proj_path) self.load_path(self.proj_path)!;
    if (self.stdlib_path) self.load_path(self.stdlib_path)!;

    // sort::quicksort(self.modules, &cmp_module);
    // assert(is_sorted(self.modules, &cmp_module), "modules must be sorted");

    // foreach (i, m : self.modules) {
    //     if (!self.mod_index.has_key(m.value)) {
    //         self.mod_index[m.value] = (uint)i;
    //     }
    // }
}
