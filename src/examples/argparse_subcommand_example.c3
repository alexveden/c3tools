<*
ArgParse subcommand implementation with custom callback function with parsing logic
*>
module subcommand_example;
import std::io;
import c3lib::argparse;

struct Config
{
    struct optimization
    {
        bool batch_ops;
        bool zero_loop;
        bool remove_dead;
        bool reduce_loops;
    }
    struct compile
    {
        String path;
    }
}

fn void! command_compile(Config* config, ArgParse* agp)
{
    assert(agp.arguments[0] == "compile");

    String output = "a.out";

    ArgParse sub_args = {
        .description = "Compile command flags", 
        // fmt: off
        .options = {
            argparse::help_opt(),
            {.short_name = 'o', .value = &output, .help = "compilation output"}
        },
        // fmt: on
        .flags = {
            .require_arguments = true,
        }
    };
    if (catch err = sub_args.parse(agp.arguments)) {
        sub_args.print_usage()!!;
        return err?;
    }

    io::printfn("Compile command:");
    io::printfn(" - out: %s", output);
    io::printfn("Compile arguments:");
    io::printfn(" - %s", sub_args.arguments);
    io::printfn("optimization flags:");
    io::printfn(" - batch_ops: %s", config.optimization.batch_ops);
    io::printfn(" - zero_loop: %s", config.optimization.zero_loop);
    io::printfn(" - reduce_loops: %s", config.optimization.reduce_loops);
    io::printfn(" - remove_dead: %s", config.optimization.remove_dead);
}

// usage example: `optimization-cli -O1 --no-zero-loop compile mypath.c3`

fn int main(String[] args)
{

    // Setting sensible defaults here
    Config config = { .optimization = {.batch_ops = true, .zero_loop = true,}, };

    ArgParse agp = {
        .description = "Compiler test", 
        .usage = "compiler [options] {compile,sub_cmd} arg1...argN",
        // fmt: off
        .options = {
            argparse::help_opt(),
            {.value = &config.optimization.batch_ops, .long_name = "batch-ops", .help = "batch_ops"},
            {.value = &config.optimization.zero_loop, .long_name = "zero-loop", .help = "zero_loop"},
            {.value = &config.optimization.reduce_loops, .long_name = "reduce-loops", .help = "reduce_loops"},
            {.value = &config.optimization.remove_dead, .long_name = "remove-dead", .help = "remove_dead"},
            {
                .short_name = 'O',
                .value = &config,
                .help = "optimization level [default: O0]",
                .callback = fn void! (ArgOpt* opt, String value) {
                    Config* ctx = anycast(opt.value, Config)!;
                    int level = value.to_integer(int)!;
                    io::printfn("optimization level arg callback: -O%s", value);
                    switch(level) {
                        case 0:
                            // falling back to defaults
                            break;
                        case 1:
                            ctx.optimization.batch_ops = true;
                            ctx.optimization.zero_loop = true;
                            ctx.optimization.reduce_loops = false;
                            ctx.optimization.remove_dead = false;
                        default: // very high
                            ctx.optimization.batch_ops = false;
                            ctx.optimization.zero_loop = false;
                            ctx.optimization.reduce_loops = false;
                            ctx.optimization.remove_dead = false;
                    }
                }
            }
        },
        // fmt: on
        .flags = {
            // for subcommand
            .stop_at_non_option = true,
            .require_arguments = true,
        }
    };

    if (catch err = agp.parse(args)) {
        agp.print_usage()!!;
        return 1;
    }

    switch(agp.arguments[0]) {
        case "compile":
            if (catch err = command_compile(&config, &agp)) return 1;
        default:
            io::printfn("unknown command: %s", agp.arguments[0]);
            return 1;
    }

    return 0;
}
