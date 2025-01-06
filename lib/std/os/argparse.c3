module std::os::argparse;
import std::io;
import std::io::path;

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
    String help;
    bool required;
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

    struct flags {
        bool ignore_unknown_args;
        bool stop_at_non_option;
    }

    struct _ctx {
        // Internal ArgParse state after calling argparse::parse()

        int argc;
        char** argv;
        char** out;
        int cpidx;
        char* optvalue; 
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

fn void! ArgParse.parse(&self, String[] argv) {
    assert(self._ctx.argc == 0, "ArgParse already initialized or double parse call");
    assert(argv.len > 0);

    self._ctx.argc = argv.len;

    if (!self.program_name){
        self.program_name = argv[0];
    }
}

fn void! ArgParse.print_usage(&self) {
    assert(self._ctx.argc != 0, "ArgParse.parse() was not called?");

    io::printf("Usage:\n");
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
        io::printf("%*s%s\n", (int)pad + 2, "", opt.help);
    }
    if (self.epilog) {
        io::printf("\n%s\n", self.epilog);
    }
}
