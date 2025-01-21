module c3lexer;
import std::c3lang::lexer;
import std::c3lang::common;
import std::io;
import std::os::argparse;
import std::collections::list;

fn void! process_file(String file_name) {
	String contents = (String)file::load_new(file_name)!;
	io::printfn("File source:\n%s", contents);

	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	// io::printfn("Tokens:\n%s", toks);
	io::printfn("Tokens:\n");
	// breakpoint();
	foreach(t: toks)
	{
		switch(t.type)
		{
			case IDENT:
			case CT_IDENT:
			case CT_CONST_IDENT:
			case CT_TYPE_IDENT:
			case HASH_IDENT:
			case HASH_CONST_IDENT:
			case HASH_TYPE_IDENT:
			case CONST_IDENT:
			case TYPE_IDENT:
			case AT_IDENT:
			case AT_TYPE_IDENT:
			case AT_CONST_IDENT:
				io::printf("%s[%s] ", common::token_type_to_string(t.type), t.value);
				break;
			case STRING:
			case RAW_STRING:
			case INTEGER:
			case REAL:
			case CHAR_LITERAL:
			case BYTES:
			case COMMENT_SINGLE:
				io::printf("%s[%s] ", common::token_type_to_string(t.type), t.value);
				break;
			default:
				io::printf("%s ", common::token_type_to_string(t.type));
		}
	}
	toks.free();
	io::printfn("DONE");
}

fn int main(String[] args)
{
	int val = 0;
	bool flag = false;
	String s;
	float f = 0.0;
	argparse::ArgParse agp = {
		.description = "c3 lexer sample",
		.usage = "[args] source_file",
		.options = { 
			argparse::help_opt(),
		}, 
	};

	if(catch err = agp.parse(args)){
		agp.print_usage()!!;
		return 1;
	} 

	if(agp.arguments.len == 0){
		agp.print_usage()!!;
		return 1;
	
	}
	if(catch err = process_file(agp.arguments[0])) {
	    io::printfn("process_file error with: %s", err);
	    return 1;
	}


	return 0;
}

