module c3tools::lsp;

<*
 Kind of symbol of a project or document
*>
enum SymbolKind
{
    NA,  // ZII unknown kind
    MODULE,  // os::
    METHOD,  // struct fn Foo.bar() or self.bar() or Foo.@macro_callable
    FIELD,  // struct self.field
    CALLABLE,  // standalone some_fn() / @some_macro
    LOCAL_VAR,  // local_i
    GLOBAL_VAR,  // global scope variable
    ARGUMENT,  // function argument
    CONSTANT,  // FOO_BAR (may be owned by enum or fault)
    ENUM,  // MyEnum.BAR / MyFault.ANOTHER
    STRUCT,  // struct Name
    TYPE, // custom TypeName
    GENERIC, // generic type List(<int>)
    ARRAY,  // array or List or other collection of items
    BUILTIN, // represents builtin type/func/const/keyword
}

struct Position
{
    uint l;
    uint c;
}

struct Range
{
    struct start
    {
        uint l;
        uint c;
    }

    struct end
    {
        uint l;
        uint c;
    }
}

struct DocChange
{
    String value;
    Range range;
}
