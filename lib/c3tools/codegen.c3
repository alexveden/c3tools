<*
Code generation tool for C3, mimics original code structure

Example: ```c3

CodeGen* c = CodeGen{}.new_init(); 
defer c.free();

c.@module("myfoo @if(%d)", c.indent);
c.@import("std::io");

c.@struct("MyType @local") {
    c.wn("float a");
    c.wn("int b");
    c.@struct("substruct") {
        c.wn("float c");
    };
};

c.@fn("void my_foo() @test"){
    c.@if("x == 1") {
        c.wn("int b = %s", c.indent);
    };
    c.@return("0");
};

io::printfn("%s", c.buf.str_view());
```
*>
module c3tools::codegen;

struct CodeGen {
    int indent;
    DString buf;
}

<*
CodeGen constructor 
*>
fn CodeGen* CodeGen.new_init(&self) {
    self.buf.new_init();
    return self;
}

<*
CodeGen destructor 
*>
fn void CodeGen.free(&self) {
    self.buf.free();
}


<* Reset CodeGen buffer and state *>
fn void CodeGen.reset(&self) {
    self.buf.clear();
}

<* Writes new code statement indent + code + ;\n *> 
macro CodeGen.wn(&self, String format, args...) {
    self.ws(format, ...args);
    self.buf.appendf(";\n");
}

<* Writes new code (with indentation) *> 
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

<* Gen c3 struct (support sub-structs as well) *>
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

