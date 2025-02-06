#!/bin/bash
#
#   c3c test_suite validation script for c3fmt (used in CI/CD)
#   1. it processes all *.c3t files and formats them with c3fmt
#   2. then *.c3t file get compiled
#
#   The main goal to format without c3fmt errors and still have no compilation errors
#
mkdir -p ./build/c3c_test_suite

# These are for result error accumulation (otherwise it dropped to 0!)
set +m
shopt -s lastpipe

if [ -z "$1" ]; then
    echo "Error: you must provide path: "
    echo "$0 <path_to_c3c_test_suite>"
    exit 1
fi

# make sure using actual version of c3fmt
c3c --trust=full build c3fmt

# Function to process each file
process_file() {
    local file="$1"
    
    # Check if the file contains "// #error"
    if grep -q "// #error" "$file"; then
        echo "[SKIP] $file (has #error)"
        return 0

    fi
    if grep -q "// #target: elf-riscv" "$file"; then
        echo "[SKIP] $file (has #target: elf-riscv)"
        return 0
    fi

    echo "[    ] Processing: $file..."

    # Run the c3fmt command on the file (making maximally intrusive)
    if ./build/c3fmt -w 80 -i 4 "$file"; then
        if c3c compile-only --obj-out ./build/c3c_test_suite "$file"; then 
            echo "[OK  ] formatted + compiled"
            return 0
        else
            echo "[ERR ] c3c compile-only error"
        fi;
    else
        echo "[ERR ] c3fmt error"
    fi

    return 1
}

result=0

# Recursively find all .c3t/.c3c files and process them
find $1 -type f -name "*.c3t" | while read -r file; do
    if ! process_file "$file"; then
        result=$(($result + 1))
        echo "error: $result"
    fi
done

find $1 -type f -name "*.c3" | while read -r file; do
    if ! process_file "$file"; then
        result=$(($result + 1))
        echo "error: $result"
    fi
done

rm -rf ./build/c3c_test_suite

if [ $result -ne 0 ]; then
    echo "Test suite formatting finishied with #$result errors"
    exit 1
fi
