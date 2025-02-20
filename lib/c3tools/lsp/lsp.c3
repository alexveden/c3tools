module c3tools::lsp;
import c3tools::ast;
import std::collections::map;

struct Lsp
{
    LspProject proj;
    HashMap(<String, Document>) documents;
}

fn void! Lsp.new_init(&self, String project_root, String stdlib_path)
{
    self.proj = LspProject.new_init(project_root, stdlib_path);

    if (catch err = self.proj.load()) {
        log::error("c3 project load failed: %s", err);
        return err?;
    }

    self.proj.load_symbols()!;
}

fn void Lsp.free(&self){
    self.proj.free();
    self.documents.free();
    
}

fn void! Lsp.document_did_open(&self, String uri, String full_source)
{
    assert(uri.starts_with("file://"));
    Document d = Document.new_open(uri, full_source, &self.proj);

    assert(!self.documents.has_key(uri), "document is already open");
    self.documents[uri] = d;
}
