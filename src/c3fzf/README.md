# c3fzf C3 Symbol Search Utility

Features
* Allows listing all modules in project or stdlib
* Supports searching my module name or symbol part
* Supports code/documentation preview for selected symbols
* Allows integration with IDE tools, like NeoVim Telescope

## Installation and running

Currently c3fzf only supports build from source with latest c3c compiler.

```
git clone https://github.com/alexveden/c3tools.git
cd c3tools
c3c --trust=full build c3fzf

# Listing current project modules
./build/c3fzf .

# Listing all project and stdlib modules
 ./build/c3fzf --stdlib=../c3c/lib/std .

# Listing all module symbols, including submodules (brief mode)
./build/c3fzf --stdlib=../c3c/lib/std std::io .

# Listing module and function documentation (preview mode)
./build/c3fzf --stdlib=../c3c/lib/std --preview std::core::string .

# Finding any symbols containing `new` in `std::core::string` module
./build/c3fzf --stdlib=../c3c/lib/std --preview std::core::string new

# Finding any symbols containing Iterator in type name
./build/c3fzf --stdlib=../c3c/lib/std . Iterator

```

## Configuration

`c3fzf` parameters:
```
➜ ./build/c3fzf --help

Usage:
c3fzf [options] [.|module_filter] [.|type_filter]

c3 symbols fuzzy finder
    -h, --help        show this help message and exit

Basic options
    --stdlib=<str>    stdlib path for std symbols [default: ]
    --preview         preview symbols (requires full module name) [default: false]
    --project=<str>   project path [default: .]

```
