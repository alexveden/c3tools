# c3fmt Automatic code formatter tool

## Installation and build

Currently c3fmt only supports build from source with latest c3c compiler.

It requires `--trust=full` in order to generate test code corpus by running a `scripts/c3fmt_gentests.c3`

```
git clone https://github.com/alexveden/c3tools.git
cd c3tools
c3c --trust=full build c3fmt

# Running with default settings (4 spaces indents, 88 line width)
./buil/c3fmt src/file.c3 lib/file2.c3

# Running with stdlib settings (tabs indents, 120 line width)
./buil/c3fmt --width=120 --indent=t src/file.c3 lib/file2.c3
```

## Configuration

`c3fmt` is designed to have a standard formatting style, with only two options:
1. `-w, --width=<int>` - max line width (default: 88)
2. `-i, --indent=<str>` - indent type: 2,4,8 for spaces, t for tabs (default: 4 spaces)


## c3fmt

### Principles
1. c3fmt tries to preserve original structure as much as possible
2. Line width is a soft constraint, but not an ultimate goal.
3. Wrapping can only occur inside 1st level of parentheses or braces `(wrap, (no_wrap))`, or `{wrap, {no_wrap}}`
4. Comments and doc-strings are untouched
5. Dotted array initializers will wrap recursively.

### Code wrapping

There are only 2 ways of wrapping in c3fmt:

1. Single line wrap occurs when wrapped text into line-width
2. Multi-line wrap occurs when wrapped text doesn't fit, or there is a `magic comma` at the end or in-line comment in the expression.
```c
// initial
fn void foo(int a, int b, int c) {}

// single wrap
fn void foo(
    int a, int b, int c
) 
{
}

// multi-wrap
fn void foo(
    int a,
    int b, 
    int c
) 
{
}

// ... simple call wrap when magic comma added
return foo(a, b, c,);

// wraps to
return foo(
    a, 
    b,
    c,
);

```

### Wrapping logic

All wrapping logic is based on 1st level of parentheses(calls/logic) or braces (arrays/structs).

**HINT**: if your wrapped expression looks weird, try to add extra parentheses around it.

A list of what can be wrapped:
1. `fn/macro` arguments in definition
2. `fn lambda(these, can, wrap) => never_wrap;`;
3. `if / switch / for / while` conditions in `()`
4. any function calls
5. any expression in `{}` scopes
6. Struct initializers
7. Array initializers
8. Global const initializers


#### Simple calls
```c

// calls
return foo(a, b, c,);

// wraps to
return foo(
    a, 
    b,
    c,
);
```
#### Logic

```c

// initial
if (foo || bar || baz) {
}

// single wrap
if (
    foo || bar || baz
) {
}

// multi wrap
if (
    foo ||
    bar ||
    baz
) {
}

```

#### Arrays 
```c
// initial
int[][] arr = {{1}, {1, 2}, {3, 4}};

// single wrap
int[][] arr = {
    {1}, {1, 2}, {3, 4} 
};

// multi wrap
int[][] arr = {
    {1}, 
    {1, 2}, 
    {3, 4} 
};
```

#### Structs
```c
// initial
Foo s = {.foo = 1, .bar = 2, .sub = {.baz = 3}};

// single wrap
Foo s = {
    .foo = 1, .bar = 2, {.baz = 3}
};

// multi wrap
Foo s = {
    .foo = 1,
    .bar = 2,
    .sub = {
        .baz = 3
    }
};
```

#### Chained calls
```c
// initial
return foo(a).bar(b, z).baz(c, magic_comma,);

// wraps
return foo(
    a
).bar(
    b, a
).baz(
    c,
    magic_comma,
);

```

### Wrapping exceptions

Some parts of the language intentionally don't wrap:
1. Inline flow (if/for/while/etc), for example `if (foo) this_never(wraps)!;`
2. Lambda functions: `fn foo(this, can, wrap) => this_never(wraps)!;`
3. Comments and doc strings.
4. Left part of assignment expression: `foo[this_never_wrap] = can(wrap);`
5. Contents of `asm{}` block never wrap.

### Wrapping quirks
Sometimes you will find weird chunks of code, which could be weirdly formatted, and before you fill an issue for this try to wrap it with `()`.

Example:
```c

// initial
macro bool char_is_base64(char c)
{
    return (c >= 'A' && c <= 'Z')
           || (c >= 'a' && c <= 'z')
           || (c >= '0' && c <= '9')
           || c == '+' || c == '/';
}

// first try 
// NOTE: actually there's no issue with logic, it wraps at 1st level of ()
macro bool char_is_base64(char c)
{
    return (
        c >= 'A' &&
        c <= 'Z'
    ) || (
        c >= 'a' &&
        c <= 'z'
    ) || (
        c >= '0' &&
        c <= '9'
    ) || c == '+' || c == '/';
}

// Adding extra (), much better!
macro bool char_is_base64(char c)
{
    return (
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9') ||
        c == '+' ||
        c == '/'
    );
}
```


### Disabling c3fmt
You can add a single line comment `// fmt: off` (must be exact match!) to temporarily disable formatting for code block of function. Use `// fmt: on` to re-enable it.

```c

fn void main()
{
    // fmt: off
    if(   foo (far)) {
          s = {.abs = 2, .bar = 3,};
    // fmt: on
        
        if (abs(mode)) {
            return 0;
        }
    }
    return;
}
```

### Magic comma 
You can force multi-line wrap any expression if you add `,` after the last item.

## c3fmt code style

```c
<*
 Doc string
*>
module foo;

// Empty lines are preserved, but no more than 1 consequently

struct Foo 
{
    
}

<* 
 Doc
 Multiline doc

 @param arg "argument"
 @require arg > 0
*>
fn void main(
    int arg, bool arg2
) 
{
    defer {
        io::printfn("defer");
    }

    return a_call_with_magic_comma(
        arg1,
        arg + 1,
        &arg,
    )

    if (arg) {
        return;
    }

    if (
        long ||
        condition &&
        (another || one)
    ) {
        return;
    }

    switch (arg) {
        case 1:
            return;
        default:
            break;
    }

    foreach(i,v : array) {
        for (
            int long_for_loop = 0;
            long_for_loop < 100;
            long_for_loop++            
        ) {
            arg++;
        }
    }

    int[][] array = { {1}, {2, 3} };
    int[] array = { 1, 2, 3 };

    argparse::ArgParse agp = {
        .description = "c3 code formatting tool",
        .usage = "[options] file1 .. fileN",
        .options = {
            argparse::help_opt(),
            {
                1,
                3,
                4,
                5,
                6
            },
            argparse::group_opt("Basic options"),
            {
                .short_name = 'f',
                .long_name = "force",
                .value = &force_mode,
                .help = "force formatting non .c3 files"
            },
            {
                .short_name = 'n',
                .long_name = "dry",
                .value = &dry_mode,
                .help = "dry mode (only print)"
            },
            argparse::group_opt("Code format options"),
            {
                .short_name = 'w',
                .long_name = "line-width",
                .value = &max_line_width,
                .help = "max line width"
            },
        },
    };
}
```
