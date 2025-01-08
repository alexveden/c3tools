module c3lexer;
import std::c3lang::lexer;
import std::c3lang::common;
import std::io;
import std::os::argparse;

fn void! process_file(String file_name) {
	String contents = (String)file::load_new(file_name)!;
	io::printfn("File source:\n%s", contents);

	io::printfn("Tokens:\n");
	Lexer lexer = {};
	lexer::lexer_init(&lexer, contents);
	// breakpoint();
	while (lexer::lexer_next_token(&lexer))
	{
		c3lang::common::TokenType token_type = lexer.token_type;
		switch(token_type)
		{
			case TOKEN_IDENT:
			case TOKEN_CT_IDENT:
			case TOKEN_CT_CONST_IDENT:
			case TOKEN_CT_TYPE_IDENT:
			case TOKEN_HASH_IDENT:
			case TOKEN_HASH_CONST_IDENT:
			case TOKEN_HASH_TYPE_IDENT:
			case TOKEN_CONST_IDENT:
			case TOKEN_TYPE_IDENT:
			case TOKEN_AT_IDENT:
			case TOKEN_AT_TYPE_IDENT:
			case TOKEN_AT_CONST_IDENT:
				io::printf("%s[%s] ", common::token_type_to_string(token_type), lexer.data.string);
				break;
			// case TOKEN_STRING:
			// case TOKEN_INTEGER:
			// case TOKEN_REAL:
			// case TOKEN_CHAR_LITERAL:
			// case TOKEN_BYTES:
			// 	OUTF("%s[%s] ", token_type_to_string(token_type), lexer.data.string);
			// 	break;
			default:
				io::printf("%s ", common::token_type_to_string(token_type));
		}
		if (token_type == TOKEN_EOF) break;
	}
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

