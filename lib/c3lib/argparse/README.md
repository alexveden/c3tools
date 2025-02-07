# Console arguments parsing module

 ## Features:
 - --long-names and -s short optional
 - --flags and negative flags via --no-flags to unset
 - Short flags stacking -s -f -v equals to -sfv
 - Support of `--long=value` and `--long value`
 - Support of `--` makes all following options as arguments
 - Generic option value to program value parsing
 - Sub-commands support
 - ZII initialization, with sensible defaults
 - Builtin argument validation for simple types
 - Custom argument parser via user-defined callbacks
 - Automatic help printout
 - Support of arrays of the arguments like -I ./foo -I ./bar (use callbacks!)
 - Support of accumulated values: -vvvv will increase int value by 1 four times
 - Low-level parser via `ArgParse.next()` if you want customized behavior
 - Automatically detects value of option your program expects, and does sanity checks
 - Doesn't require crating special types for arg parse tasks, just use ArgParse instance 
 - Does not allocate memory, it's just a static struct instance

## Example:

```c3

// Simple arguments
import std::os::argparse;
import std::io;

fn int main(String[] args)
{
    int val = 0;
    bool flag = false;
    String s;
    float f = 0.0;
    argparse::ArgParse agp = {
        .description = "My program",
        .usage = "[-a] [--string=<some>] arg1",
        .epilog= "Footer message",
        .options = { 
            argparse::help_opt(),
            argparse::group_opt("Basic options"),
            {.short_name = 'a', .long_name = "all", .value = &val, .help = "This is a sample option"},
            argparse::group_opt("Advanced options"),
            { .long_name = "string", .value = &s, .help = "Simple long_name string"},
            { .short_name = 'f', .value = &flag, .help = "short opt flag"},
        }, 
    };

    if(catch err = agp.parse(args)){
        agp.print_usage()!!;
        return 1;
    }

    io::printf("My arguments: val=%s, s=%s, flag=%s\n", val, s, f);
    return 0;
}
```


## Custom argument parsing via callbacks

```c3

fn void test_custom_type_callback_unknown_type()
{

    char val = '\0';
    ArgParseCallbackFn cbf = fn void! (ArgOpt* opt, String value) {
        io::printfn("flt--callback");
        test::eq(value, "bar");
        *anycast(opt.value, char)! = value[0];
    };
    // NOTE: pretends app struct
    ArgParse my_app_state = {};

    ArgParse agp = {
        .options = {
            {
                .short_name = 'f',
                .long_name = "flt",
                .value = &val,
                .callback = cbf
            },
            {
                .short_name = 'o',
                .long_name = "other",
                .value = &my_app_state,
                .callback = fn void! (ArgOpt* opt, String value) {
                    ArgParse* ctx = anycast(opt.value, ArgParse)!;
                    io::printfn("other--callback");
                    // NOTE: pretends to update important app struct
                    ctx.usage = value;
                }
            }
        }
    };

    String[] args = { "testprog", "--flt=bar", "--other=my_callback" };
    test::eq(val, '\0');
    test::eq(agp.options[0]._is_present, false);

    agp.parse(args)!!;

    test::eq(val, 'b');
    test::eq(my_app_state.usage, "my_callback");
    test::eq(agp.options[0]._is_present, true);
}

```

## Low-level API using `ArgParse.next()`

```c

fn void test_argparse_next_switch()
{

    List(<String>) args;
    args.new_init(); 
    defer args.free();

    ArgParse agp = {
        .description = "Test number sum program",
        .options = {
            {
                .short_name = 'a',
                .help = "a short name flag"
            },
            {
                .long_name = "flag",
                .help = "a long name flag"
            },
        }
    };
    String[] argv = { "testprog", "-n", "5", "--num", "2", "--num=3"};
    int n_sum = 0;  // expected to be 5+2+3
    while (String arg = agp.next(argv)!!) {
        switch (arg) {
            case "-n":
            case "--num":
                String value = agp.next(argv)!!;
                n_sum += value.to_integer(int)!!;
            default:
                // you may use ArgParse options only for usage display as well
                // OR make your own usage printout
                agp.print_usage()!!;
                test::eq(1, 0); // unexpected here
        }
        args.push(arg);
    }

    io::printfn("%s", args);
    test::eq(args.len(), 3);
    // NOTE: we skipped values in switch "--num" handler
    test::eq(args[0], "-n");
    test::eq(args[1], "--num");
    test::eq(args[2], "--num");
    test::eq(n_sum, 5+2+3);
}

```
