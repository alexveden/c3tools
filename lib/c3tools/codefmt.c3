module c3tools::codefmt;
import c3tools::codegen;

struct CodeFmt {
    int max_line_width;
    CodeGen code;
}


<*
@require max_line_width >= 80 : "too short"
@require max_line_width <= 120 : "too long"
*>
fn CodeFmt CodeFmt.new_init(int max_line_width=80) @operator(construct) {
    CodeFmt self = {
        .max_line_width = max_line_width
    };
    self.code.new_init(); 
    return self;
}

fn void CodeFmt.free(&self) {
    self.code.free();
}


<*
Code test cases helper code (see test/c3fmt_corpus files)
*>
module c3tools::codecorpus @private;
import std::collections::list;
import std::io;

fault CodeCorpusError {
    EMPTY_FILE,
    BAD_FORMAT,
}

struct CodeCorpus {
    String file_name;
    usz line;
    int phase;
    String case_name;
    String case_input;
    String case_output;
}

fn bool CodeCorpus.compare_output(&self, String actual) {
    String[] lines_expected = self.case_output.split("\n"); 
    String[] lines_actual = actual.split("\n"); 

    defer allocator::heap().release(lines_expected.ptr, true);
    defer allocator::heap().release(lines_actual.ptr, true);

    int n_errors  = 0;
    for(int i=0, int j=0; i < lines_expected.len || j < lines_actual.len; i++, j++){
        if (n_errors > 5) return false;

        if (i < lines_expected.len && j < lines_actual.len) {
            if (lines_expected[i] != lines_actual[j]){
                io::printfn("Expected at line %3d: `%s`", i, lines_expected[i]);
                io::printfn("Actual  at line  %3d: `%s`", j, lines_actual[j]);
                n_errors++;
            }
        } else {
            if (i < lines_expected.len){
                io::printfn("Expected at line %3d: `%s`", i, lines_expected[i]);
                io::printfn("Actual  at line  %3d: <too short>", i);
            } else {
                io::printfn("Expected at line %3d: <too short>", j);
                io::printfn("Actual  at line  %3d: `%s`", j, lines_actual[j]);
            }
            n_errors++;
        }
    }

    return n_errors == 0;
}

fn List(<CodeCorpus>)! new_parse(String file_name) {
    String contents = (String)file::load_new(file_name)!;
    List(<CodeCorpus>) result;
    result.new_init();

    String[] lines = contents.split("\n"); 
    defer allocator::heap().release(lines.ptr, true);

    if (!lines) return CodeCorpusError.EMPTY_FILE?;
    
    CodeCorpus current = {.file_name = file_name, .line = 1};

    foreach(i, l:  lines) {
        assert(l.ptr >= contents.ptr && l.ptr <= contents.ptr + contents.len, "doesn't belong to file contents");
        assert(!l.contains("\r") && !l.contains("\t"));

        // io::printfn("%s:%s:%s", current.phase, i, l);
        if(l.starts_with("======")) {
            if (l.len != 80){
                io::printfn("===== line must be exact 80 chars long (%s:%s), got length %s", 
                            file_name, i+1, l.len);
                return CodeCorpusError.BAD_FORMAT?;
            }

            if (current.phase > 2) {
                if (!current.file_name 
                    || !current.line 
                    || !current.case_name 
                    || !current.case_input 
                    || current.phase != 4
                    || !current.case_output) {
                    io::printfn("Bad file format (%s:%s)", file_name, i);
                    io::printfn("Current corpus:");
                    io::printfn("file_name: %s", current.file_name);
                    io::printfn("line: %s", current.line);
                    io::printfn("phase: %s", current.phase);
                    io::printf("input:```\n%s", current.case_input);
                    io::printfn("```");
                    io::printf("output:\n%s", current.case_output);
                    io::printfn("```");
                    return CodeCorpusError.BAD_FORMAT?;
                }
                
                result.push(current);
                current = CodeCorpus{.file_name = file_name, .line = i + 1};
            } 


            current.phase++;
            if (current.phase > 1) {
                if (!current.case_name){
                    io::printfn("Probably missing case name (%s:%s)",  file_name, i+1);
                    return CodeCorpusError.BAD_FORMAT?;
                }
            }
            continue;
        }

        if(l.starts_with("-----")) {
            if (l.len != 80){
                io::printfn("---- line must be exact 80 chars long (%s:%s), got length %s", 
                            file_name, i+1, l.len);
                return CodeCorpusError.BAD_FORMAT?;
            }

            if (current.phase != 3) {
                io::printfn("---- line is probably is out of order at (%s:%s)",  file_name, i+1);
                return CodeCorpusError.BAD_FORMAT?;
            }

            current.phase++;
            continue;
        }

        if (current.phase == 1) {
            // TODO: check if case_name is alphanumeric
            current.case_name = l.trim();
            current.phase++;
        } else if(current.phase == 3) {
            if (!current.case_input) {
                // skip empty lines until first text
                if (!l) continue;
                current.case_input = l;
            } else {
                assert(l.ptr != null);
                if (l.ptr >= contents.ptr + contents.len) continue;

                // extending string by pointer arithmetic, because code is adjacent
                usz input_len = l.ptr - current.case_input.ptr + l.len;
                assert (input_len < 1024);

                current.case_input = (String)(current.case_input.ptr)[..input_len];
            }
        }
        else if(current.phase == 4) {
            if (!current.case_output) {
                // skip empty lines until first text
                if (!l) continue;
                current.case_output = l;
            } else {
                assert(l.ptr != null);
                if (l.ptr >= contents.ptr + contents.len) continue;

                usz output_len = l.ptr - current.case_output.ptr + l.len;
                assert (output_len < 1024);

                current.case_output = (String)(current.case_output.ptr)[..output_len];
            }
        }
        else {
            io::printfn("Unexpected phase count (%s:%s)",  file_name, i+1);
            return CodeCorpusError.BAD_FORMAT?;
        }
         
    }

    // handling last before EOF
    if(current.line > 0) result.push(current);
    
    return result;
}
