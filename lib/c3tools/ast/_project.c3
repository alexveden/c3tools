module c3tools::ast;
import c3tools::ast::lexer;
import std::hash::fnv64a;
import std::io;
import std::sort;
import std::collections::list;
import std::collections::map;

struct ModuleItem
{
    Fnv64a hash;
    AstModule* mod;
}

$assert(ModuleItem.sizeof == 16);

struct AstProject
{
    String proj_path;
    String stdlib_path;
    List(<ModuleItem>) modules;
    // HashMap(<String, uint>) mod_index;
    allocator::DynamicArenaAllocator _allocator;
}

fn AstProject AstProject.new_init(String proj_path, String stdlib_path) @operator(construct)
{
    AstProject self = {
        .proj_path = proj_path,
        .stdlib_path = stdlib_path,
    };

    //  Arena allocator for storing all AST metadata (DynamicArenaAllocator backed by heap)
    self._allocator.init(5 * 1024 * 1024, allocator::heap());

    uint initial_capacity = 1024;
    // All other allocations are done on heap to isolate AST data and make it sequential
    self.modules.new_init(initial_capacity, allocator: allocator::heap());

    // All other allocations are done on heap to isolate AST data and make it sequential
    // self.mod_index.new_init(initial_capacity, allocator: allocator::heap());

    return self;
}

fn void! AstProject.module_add(&self, AstModule* m) @private {
    assert(m.hash != 0, "module hash is zero");
    // TODO: implement insert + update
    self.modules.push(ModuleItem {.hash = m.hash, .mod = m});
}

macro AstModule* AstProject.module_find(&self, name_or_hash) {
    return null;

}

fn void! AstProject.load_source(&self, String full_source, String file_path)
{

    Ast ast = ast::parse(full_source, file_path, allc: &self._allocator);
    for (AstModule* m = ast.modules; m != null; m = (AstModule*)m.next) {
        // Skipping top level module without name
        if (ast.@node_len(m.name) == 0) continue;
        self.module_add(m)!;
    }
}

fn void! AstProject.load_path(&self, String path) @local
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
        AstProject* self = (AstProject*)ctx;
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

fn int cmp_module(ModuleItem* a, ModuleItem* b) @private
{
    assert(a.hash != 0);
    assert(b.hash != 0);
    if (a.hash < b.hash) return -1;
    if (a.hash > b.hash) return 1;
    return 0;
}

fn void! AstProject.load(&self)
{
    assert(self.modules.len() == 0, "double load?");

    if (self.proj_path) self.load_path(self.proj_path)!;
    if (self.stdlib_path) self.load_path(self.stdlib_path)!;

    sort::quicksort(self.modules, &cmp_module);
    assert(is_sorted(self.modules, &cmp_module), "modules must be sorted");

    // foreach (i, m : self.modules) {
    //     if (!self.mod_index.has_key(m.value)) {
    //         self.mod_index[m.value] = (uint)i;
    //     }
    // }
}

fn void AstProject.free(&self)
{
    // self.mod_index.free();
    self.modules.free();
    self._allocator.free();
}
