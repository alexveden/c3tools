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

fn List(<CodeCorpus>)! new_parse(String file_name) {
    String contents = (String)file::load_new(file_name)!;
    List(<CodeCorpus>) result;
    result.new_init();

    String[] lines = contents.split("\n"); 
    // FIX: defer allocator::free(lines);

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

                // extending string by pointer arithmetic, because code is adjacent
                usz input_len = l.ptr - current.case_input.ptr + l.len;
                current.case_input = (String)(current.case_input.ptr)[..input_len];
            }
        }
        else if(current.phase == 4) {
            if (!current.case_output) {
                // skip empty lines until first text
                if (!l) continue;
                current.case_output = l;
            } else {
                usz output_len = l.ptr - current.case_output.ptr + l.len;
                current.case_output = (String)(current.case_output.ptr)[..output_len];
            }
        }
    }

    // handling last before EOF
    if(current.line > 0) result.push(current);
    
    return result;
}
