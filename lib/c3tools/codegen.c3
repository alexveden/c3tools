module c3tools::codegen;

struct CodeGen {
    int indent;
    DString buf;
}

fn void CodeGen.free(&self) {
    self.buf.free();
}

fn CodeGen* CodeGen.new_init(&self) {
    self.buf.new_init();
    return self;
}

fn void CodeGen.reset(&self) {
    self.buf.clear();
}

macro CodeGen.wn(&self, String format, args...) {
    self.ws(format, ...args);
    self.buf.appendf(";\n");
}
macro CodeGen.ws(&self, String format, args...) {
    for(int i = 0; i < self.indent; i++) {
        self.buf.append(" ");
    }
    self.buf.appendf(format, ...args);
}

<* Gen c3 module statement *>
macro CodeGen.@module(&self, #format, args...) {
    self.buf.appendf("module " +++ #format +++ ";\n", ...args);
}

<* Gen c3 import statement *>
macro CodeGen.@import(&self, #format, args...) {
    self.buf.appendf("import " +++ #format +++ ";\n", ...args);
}

<* Gen c3 return statement *>
macro CodeGen.@return(&self, #format, args...) {
    self.ws("return " +++ #format +++ ";\n", ...args);
}

<* Gen c3 if statement *>
macro CodeGen.@if(&self, #format, args...; @body())
{
    self.ws("if(" +++ #format +++ ") {\n", ...args);
    self.indent += 4;
    @body();
    self.indent -= 4;
    self.ws("}\n");
}


<* Gen c3 function body and scope *>
macro CodeGen.@fn(&self, #format, args...; @body())
{
    if (self.indent == 0) self.ws("\n");

    self.ws("fn " +++ #format +++ " \n{\n", ...args);
    self.indent += 4;
    @body();
    self.indent -= 4;
    self.ws("}\n");
}

macro CodeGen.@struct(&self, #format, args...; @body())
{
    if (self.indent == 0) self.ws("\n");

    self.ws("struct " +++ #format +++ " \n", ...args);
    self.ws("{\n");
    self.indent += 4;
    @body();
    self.indent -= 4;
    self.ws("}\n");
}

