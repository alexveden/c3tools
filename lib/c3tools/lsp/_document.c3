module c3tools::lsp;
import c3tools::ast;
import std::collections::list;
import std::collections::map;

<*
 Open .c3 source file LSP representation
*>
struct Document
{
    // document URI for LSP (acts as a hashmap key)
    String uri;

    // source code of a file (will be dynamically changing)
    DString source;

    // document version according to LSP protocol
    uint version;

    // Current document AST
    Ast ast;

    // builtin and std::core symbols (pre-calculated and common for all c3 code)
    HashMap(<String, Symbol*>)* core_symbols;

    // Symbols available for file via imports
    HashMap(<String, Symbol*>) global_symbols;

    // Local file symbols (@local funcs, module variables, etc.)
    HashMap(<String, Symbol*>) file_symbols;

    DynamicArenaAllocator _allocator;
}

struct DocChange
{
    String value;
    Range range;
}

<*
 LSP Symbol item which is used for completion or global/local scope resolving for a document

 Symbol is a dual purpose data-structure
 - Allows storing core type information about module, struct fields, etc
 - Allows local processing of local code scope (for code suggestions, reference search, etc)
*>
struct Symbol
{
    // Symbol kind - for determining LSP logic based on it
    SymbolKind kind;

    // Unique symbol name (used as a key in hashmap, may use path: foo::my_func)
    String name;

    // hierarchical parent (typically it's a type of identifier or array info)
    // when it's used
    //  - symbol is struct field????
    //  - symbol is array
    //  - symbol is generic?
    //  - WTF? generic multi element? IDEA: resolve via typedef.mod item
    Symbol* parent;

    // Full type information of the symbol (params, fields, docs, fn signature, etc)
    AstTypeDef* typedef;

    // A module where symbol is defined
    AstModule* mod;

    // Symbol position in the module
    Position position;

    // item type (struct, variable, call, type, etc)
    // item parent type (module, or instance, or something)
    // local scope (what else is available at current scope)

    // Optional: if unique symbol name collide between each other (linked list next pointer)
    Symbol* collision;
}

fn Document Document.new_open(String uri, String full_source, LspProject* proj) @operator(construct)
{
    Document self = {};

    // TODO: estimate average source size
    self._allocator.init(1024, allocator::heap());

    // Allocate AST first, it will fill the arena with local metadata
    self.ast = ast::parse(full_source, file_path: uri, allc: &self._allocator);

    // append uri, because uri arg might be a short-lived object from json request
    self.uri = uri.copy(&self._allocator);

    // file cache goes last
    // TODO: estimate capacity from real amount of symbols maybe?
    self.file_symbols.new_init(capacity: 32, allocator: &self._allocator);
    self.global_symbols.new_init(capacity: 256, allocator: &self._allocator);

    // NOTE: source is allocated in heap, not in arena + add extra space for editing
    self.source.new_init(capacity: full_source.len * 2, allocator: allocator::heap());
    self.source.append(full_source);

    return self;
}

fn void! Document._load_file_symbols(&self) @private
{
    log::debug("Loading file_symbols: %s", self.uri);
    DString buf;
    defer buf.free();

    for (AstModule* mod = self.ast.modules; mod != null; mod = (AstModule*)mod.next) {
        log::debug("    module: %s", self.ast.@node_join(mod.name, buf, "::"));
        for (AstTypeDef* type = mod.decls; type != null; type = (AstTypeDef*)type.next) {
            log::debug(
                "        type: %s %s (%s)",
                type.type,
                type.value,
                self.ast.@node_join(type.attributes, buf, " "),
            );

        }
    }

}

fn void! Document.save(&self, String full_sourse)
{
    // update full document structure?
    // trigger LspProject* document decls updates?

}

fn void! Document.change(&self, List(<DocChange>) changes)
{
    // update document scope structure

}

fn void Document.close(&self)
{
    // self.source has a separate allocator::heap()
    self.source.free();

    self._allocator.free();
}
