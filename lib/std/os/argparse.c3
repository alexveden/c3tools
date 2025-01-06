module std::os::argparse;
import std::io;
import std::io::path;

fault ArgError {
    MISSING_ARGUMENT,
    INVALID_ARGUMENT,
    CONFIGURATION,
    HELP_SHOW,
}

enum ArgType : int
{
    USER,
    GROUP,
    HELP,
}
$assert(ArgType.USER.ordinal == 0); // USER must be first to support ZII behavior

struct ArgOpt {
    char short_name;
    String long_name;
    any value;
    any default_value;
    bool required;
    String help;
    bool is_present;
    ArgType _arg_type;
    // argparse_callback_f* callback;
    // intptr_t data;
    // int flags;
}

struct ArgParse {
    String usage;        // usage text (can be multiline), each line prepended by program_name
    String description;  // a description after usage
    String epilog;       // a description at the end
    String program_name; // program name in usage (by default: argv[0])
    ArgOpt[] options;
    String[] arguments;

    struct flags {
        bool ignore_unknown_args;
        bool stop_at_non_option;
    }

    struct _ctx {
        // Internal ArgParse state after calling argparse::parse()

        int argc;
        String[] argv;
        String[] out;
        int cpidx;
        String optvalue; 
        bool has_argument;
    }
}


macro help_opt(String help_prompt = "show this help message and exit") {
    return ArgOpt {
        ._arg_type = ArgType.HELP,
        .short_name = 'h',
        .long_name = "help",
        .help = help_prompt,
        .value = any_make(null, bool.typeid),
    };
}

macro group_opt(String group_name) {
    return ArgOpt {
        ._arg_type = ArgType.GROUP,
        .help = group_name,
    };
}

fn void! ArgParse.options_ensure_required(&self) @local
{
    bool has_errors = false;
    foreach(i, opt: self.options){
        if (opt._arg_type == ArgType.GROUP || opt._arg_type == ArgType.HELP) {
            continue;
        }

        if (opt.required && !opt.is_present) {
            io::printf(
                "Error: missing required option: -%c/--%s\n",
                opt.short_name,
                opt.long_name
            );
            has_errors = true;
        }
    }
    if (has_errors){
        return ArgError.MISSING_ARGUMENT?;
    }
}
fn void! ArgParse.options_check(&self) @local
{
    assert(self.arguments.len == 0, "already processed?");

    foreach(i, opt: self.options){
        if (opt._arg_type == ArgType.GROUP || opt._arg_type == ArgType.HELP) {
            continue;
        }

        if (!(opt.short_name || opt.long_name)) {
            unreachable("option[%d] both long/short_name are not set", i);
        }
        if (!opt.value) {
            unreachable("option[%d][-%c/--%s] has no valid .value= pointer set",
                        i, opt.short_name, opt.long_name);
        }

        switch (opt.value.type) {
            case bool.typeid:
            case short.typeid:
            case ushort.typeid:
            case int.typeid:
            case uint.typeid:
            case long.typeid:
            case ulong.typeid:
            case float.typeid:
            case double.typeid:
            case String.typeid:
                // resetting presence flag, it will be updated after all argument parsing
                opt.is_present = false;
            default:
                unreachable("option[%d][-%c/--%s] type[%s] is not supported", 
                            i, opt.short_name, opt.long_name, opt.value.type);
        }
    }
}


fn void! ArgParse.get_arg_val(&self, ArgOpt* opt, bool flag_unset = false)
{
    assert(opt);
    if (opt._arg_type == ArgType.HELP) {
        return ArgError.HELP_SHOW?;
    }
    assert(opt.value);

    switch (opt.value.type) {
        case bool.typeid:
            bool* pvalue = anycast(opt.value, bool)!;
            *pvalue = (flag_unset) ? false : true;
            opt.is_present = true;
        case String.typeid:
            assert(!flag_unset, "only for bool");
            String* pvalue = anycast(opt.value, String)!;
            if(self._ctx.optvalue) {
                // --arg=<optvalue> via =
                *pvalue = self._ctx.optvalue;
                self._ctx.optvalue = "";
            } else if(self._ctx.argv.len > 1) {
                self._ctx.argv = self._ctx.argv[1..];
                self._ctx.cpidx++;
                *pvalue = self._ctx.argv[0];
            }
            opt.is_present = true;
    }
//
//     assert(opt.value);
//
//     switch (opt.type) {
//         case 2 /*ARGPARSE_OPT_BOOLEAN*/:
//             if (flags & ARGPARSE_OPT_UNSET) {
//                 *(int*)opt.value = 0;
//             } else {
//                 *(int*)opt.value = 1;
//             }
//             opt.is_present = true;
//             break;
//         case 6 /*ARGPARSE_OPT_STRING*/:
//             if (self._ctx.optvalue) {
//                 *(const char**)opt.value = self._ctx.optvalue;
//                 self._ctx.optvalue = NULL;
//             } else if (self._ctx.argc > 1) {
//                 self._ctx.argc--;
//                 self._ctx.cpidx++;
//                 *(const char**)opt.value = *++self._ctx.argv;
//             } else {
//                 return argparse__error(self, opt, "requires a value", flags);
//             }
//             opt.is_present = true;
//             break;
//         case 4 /*ARGPARSE_OPT_INTEGER*/:
//             errno = 0;
//             if (self._ctx.optvalue) {
//                 if (self._ctx.optvalue[0] == '\0') {
//                     return argparse__error(self, opt, "requires a value", flags);
//                 }
//
//                 *(int*)opt.value = strtol(self._ctx.optvalue, (char**)&s, 0);
//                 self._ctx.optvalue = NULL;
//             } else if (self._ctx.argc > 1) {
//                 self._ctx.argc--;
//                 self._ctx.cpidx++;
//                 *(int*)opt.value = strtol(*++self._ctx.argv, (char**)&s, 0);
//             } else {
//                 return argparse__error(self, opt, "requires a value", flags);
//             }
//             if (errno == ERANGE) {
//                 return argparse__error(self, opt, "numerical result out of range", flags);
//             }
//             if (s[0] != '\0') { // no digits or contains invalid characters
//                 return argparse__error(self, opt, "expects an integer value", flags);
//             }
//             opt.is_present = true;
//             break;
//         case 5 /*ARGPARSE_OPT_FLOAT*/:
//             errno = 0;
//
//             if (self._ctx.optvalue) {
//                 if (self._ctx.optvalue[0] == '\0') {
//                     return argparse__error(self, opt, "requires a value", flags);
//                 }
//                 *(float*)opt.value = strtof(self._ctx.optvalue, (char**)&s);
//                 self._ctx.optvalue = NULL;
//             } else if (self._ctx.argc > 1) {
//                 self._ctx.argc--;
//                 self._ctx.cpidx++;
//                 *(float*)opt.value = strtof(*++self._ctx.argv, (char**)&s);
//             } else {
//                 return argparse__error(self, opt, "requires a value", flags);
//             }
//             if (errno == ERANGE) {
//                 return argparse__error(self, opt, "numerical result out of range", flags);
//             }
//             if (s[0] != '\0') { // no digits or contains invalid characters
//                 return argparse__error(self, opt, "expects a numerical value", flags);
//             }
//             opt.is_present = true;
//             break;
//         default:
//             uassert(false && "unhandled");
//             return Error.runtime;
//     }
//
// skipped:
//     if (opt.callback) {
//         opt.is_present = true;
//         return opt.callback(self, opt);
//     } else {
//         if (opt.short_name == 'h') {
//             argparse_usage(self);
//             return Error.argsparse;
//         }
//     }
//
//     return Error.ok;
}

fn void! ArgParse.parse_short(&self) @local
{
    foreach(&opt: self.options){
        if (opt.short_name == self._ctx.optvalue[0]) {
            self._ctx.optvalue = self._ctx.optvalue.len > 1 ? self._ctx.optvalue[1..] : "";
            return self.get_arg_val(opt);
        }
    }
    io::printf("Error: invalid argument %s\n", self._ctx.argv[0]);
    return ArgError.INVALID_ARGUMENT?;
}

fn String! prefix_skip(String s, String prefix) @local
{
    if(s.starts_with(prefix)) {
        return s[prefix.len..];
    } else {
        return ArgError.MISSING_ARGUMENT?;
    }
}

fn void! ArgParse.parse_long(&self) @local
{
    foreach(&opt: self.options){
        if (!opt.long_name) {
            continue;
        }

        int opt_flags = 0;
        bool flag_unset = false;
        String! arg = prefix_skip(self._ctx.argv[0][2..], opt.long_name);
        if(catch err = arg){
            switch(err){
                case ArgError.MISSING_ARGUMENT:
                    // NOTE: for boolean flags it's possible to pass unset with '--no-<flag_name>'
                    if (opt.value.type == bool.typeid && 
                        self._ctx.argv[0][2..].starts_with("no-"))
                    {
                        flag_unset = true;
                    } else {
                        continue;
                    } 
                default: 
                    unreachable();
            }
        } else {
            if (arg && arg[0] == '=') {
                self._ctx.optvalue = arg[1..];
            }
        }

        return self.get_arg_val(opt, flag_unset);
    }

    io::printf("Error: invalid argument %s\n", self._ctx.argv[0]);
    return ArgError.INVALID_ARGUMENT?;
}

fn void! ArgParse.parse(&self, String[] argv) {
    assert(self.arguments.len == 0, "ArgParse already initialized or double parse call");
    assert(argv.len > 0);

    self._ctx.argc = argv.len - 1;
    self._ctx.cpidx = 0;
    self._ctx.argv = argv[1..];
    self._ctx.out = argv;

    if (!self.program_name){
        self.program_name = argv[0];
    }
    self.options_check()!;

    for (; self._ctx.argc && self._ctx.argv.len; self._ctx.argc--) {
        String arg = self._ctx.argv[0];
        // io::printf("arg: %s\n", arg);

        if (arg[0] != '-' || arg[1] == '\0') {
            self._ctx.has_argument = true;

            if (self.flags.stop_at_non_option) {
                self._ctx.argc--;
                self._ctx.argv = self._ctx.argv[1..];
                break;
            } else {
                self._ctx.argv = self._ctx.argv[1..];
            }
            continue;
        }
        // short option
        if (arg[1] != '-') {
            self._ctx.optvalue = arg[1..];
            self._ctx.cpidx++;

            if (self._ctx.has_argument) {
                io::printf("Error: passing options after arguments not allowed at `%s`\n", arg);
                return ArgError.INVALID_ARGUMENT?;
            }

            self.parse_short()!;

            self._ctx.argv = self._ctx.argv[1..];

            // TODO:
            // while (self._ctx.optvalue) {
            //     e$except_silent(err, argparse__short_opt(self, self.options))
            //     {
            //         return argparse__report_error(self, err);
            //     }
            // }
            continue;
        }
        // if '--' presents
        if (arg[2] == '\0') {
            self._ctx.argc--;
            self._ctx.argv = self._ctx.argv[1..];
            self._ctx.cpidx++;
            break;
        }

        if (self._ctx.has_argument) {
            io::printf("Error: passing options after arguments not allowed at `%s`\n", arg);
            return ArgError.INVALID_ARGUMENT?;
        }

        self.parse_long()!;
        self._ctx.cpidx++;
        self._ctx.argv = self._ctx.argv[1..];
    }

    self.options_ensure_required()!;

    self.arguments = argv[self._ctx.cpidx + 1..]; // excludes 1st argv[0], program_name
}

fn void! ArgParse.print_usage(&self) {

    io::printf("\nUsage:\n");
    if (self.usage) {
        @pool() {
            // NOTE: prepending program_name to all usage line

            path::Path path = path::temp_new(self.program_name)!;
            foreach(usage:self.usage.tsplit("\n")) {
                usage = usage.trim();
                if(!usage){
                    continue;
                }
                io::printf("%s %s\n", path.basename(), usage);
            }
        };
    } else {
        io::printf("%s [options] [--] [arg1 argN]\n\n", self.program_name);
    }

    if (self.description) {
        io::printf("%s\n", self.description);
    }

    io::print("\n");

    usz usage_opts_width = 0;
    foreach(opt: self.options){
        usz len = 0;
        if(opt.short_name) {
            len += 2; 
            if(opt.long_name) len += 2; // extra for separator ', '
        }
        if(opt.long_name) {
            len += opt.long_name.len + 2;
        }

        if (opt.value){
            switch(opt.value.type) {
                case short.typeid:
                case ushort.typeid:
                case int.typeid:
                case uint.typeid:
                case long.typeid:
                case ulong.typeid:
                    len += 6; // strlen("=<int>")
                case float.typeid:
                case double.typeid:
                    len += 6; // strlen("=<flt>")
                case String.typeid:
                    len += 6; // strlen("=<str>")
            }
        }

        len = (len + 3) - ((len + 3) & 3);
        if (usage_opts_width < len) {
            usage_opts_width = len;
        }
    }
    usage_opts_width += 4; // 4 spaces prefix

    foreach(opt: self.options){
        usz pos = 0;
        usz pad = 0;
        if (opt._arg_type == ArgType.GROUP) {
            io::printf("\n%s\n", opt.help);
            continue;
        }
        pos = io::printf("    ")!;
        if (opt.short_name) {
            pos += io::printf("-%c", opt.short_name)!; 
        }
        if (opt.long_name && opt.short_name) {
            pos += io::printf(", ")!;
        }
        if (opt.long_name) {
            pos += io::printf("--%s", opt.long_name)!;
        }
        if (opt.value){
            switch(opt.value.type) {
                case short.typeid:
                case ushort.typeid:
                case int.typeid:
                case uint.typeid:
                case long.typeid:
                case ulong.typeid:
                    pos += io::printf("=<int>")!;
                case float.typeid:
                case double.typeid:
                    pos += io::printf("=<flt>")!;
                case String.typeid:
                    pos += io::printf("=<str>")!;
            }
        }

        if (pos <= usage_opts_width) {
            pad = usage_opts_width - pos;
        } else {
            io::print("\n");
            pad = usage_opts_width;
        }
        io::printf("%*s%s", (int)pad + 2, "", opt.help);
        if (!opt.required) {
            if(opt.value) io::printf(" [default: %s]", opt.value); 
        } else {
            io::printf(" (required)");
        }
        io::print("\n");
    }
    if (self.epilog) {
        io::printf("\n%s\n", self.epilog);
    }
}
