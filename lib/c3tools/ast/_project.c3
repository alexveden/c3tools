module c3tools::ast;
import c3tools::ast::lexer;
import std::io;
import std::sort;
import std::collections::list;
import std::collections::map;

struct AstProject
{
    String proj_path;
    String stdlib_path;
    List(<AstModule*>) modules;
    HashMap(<String, uint>) mod_index;
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
    self.mod_index.new_init(initial_capacity, allocator: allocator::heap());

    return self;
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

        Ast ast = ast::parse(contents, file_path: p.str_view(), allc: &self._allocator);
        for (AstModule* m = ast.modules; m != null; m = (AstModule*)m.next) {
            self.modules.push(m);
        }

        return false;
    };
    p.walk(fnwalk, self)!!;
}

fn int cmp_str(String a, String b) @private
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

fn int cmp_module(AstModule* a, AstModule* b) @private
{
    return cmp_str(a.value, b.value);

}

fn void! AstProject.load(&self)
{
    assert(self.modules.len() == 0, "double load?");

    if (self.proj_path) self.load_path(self.proj_path)!;
    if (self.stdlib_path) self.load_path(self.stdlib_path)!;

    sort::quicksort(self.modules, &cmp_module);

    foreach (i, m : self.modules) {
        if (!self.mod_index.has_key(m.value)) {
            self.mod_index[m.value] = (uint)i;
        }
    }
}

fn void AstProject.free(&self)
{
    self.mod_index.free();
    self.modules.free();
    self._allocator.free();
}
