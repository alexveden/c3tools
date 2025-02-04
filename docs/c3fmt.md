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


## Code style

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

## Wrapping logic

All wrapping logic is based on 1st level of parentheses(calls/logic) or braces (arrays/structs).

**HINT**: if your wrapped expression looks weird, try to add extra parentheses around it.

### Simple calls
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
### Logic

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

### Arrays 
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

### Structs
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

### chained calls
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

## Wrapping exceptions

Some parts of the language intentionally don't wrap:
1. Inline flow (if/for/while/etc), for example `if (foo) this_never(wraps)!;`
2. Lambda functions: `fn foo(this, can, wrap) => this_never(wraps)!;`
3. Comments and doc strings.
4. Left part of assignment expression: `foo[this_never_wrap] = can(wrap);`
5. Contents of `asm{}` block never wrap.


## Disabling c3fmt
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
