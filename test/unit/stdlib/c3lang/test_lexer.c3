module test::std::c3lang::lexer @test;
import std::io;
import std::c3lang::lexer;
import std::c3lang::common;
import std::collections::list;

fn void test_row_col_offset() {
    String contents = `module foo`;
	Lexer lexer = lexer::new_init(contents);
	int cnt = 0;
	while(lexer.next_token()) {
	    if (cnt == 1) {
	        test::equal(lexer.token_type, TokenType.TOKEN_IDENT);
	        test::equal(lexer.data.string, "foo");
	        test::equal(lexer.tok_span.row, 1);
	        test::equal(lexer.tok_span.col, 8);
	    }
	    
	    cnt++;
	}
}

fn void test_simple_module() {
    String contents = `module foo;`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.TOKEN_IDENT);
	test::equal(toks[1].value, "foo");
	test::equal(toks[1].offset, 7);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, ";");
	test::equal(toks[2].offset, 10);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, 11);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
	test::equal(toks[3].value, "\n");
	test::equal(toks[3].col, 12);
	test::equal(toks[3].row, 1);
	test::equal(toks[3].offset, 11);
}

fn void test_all_available_tokens() {

	DString s = dstring::temp_new();
	foreach(ttype: TokenType.values) {
		s.clear();
		String token_value = common::token_type_to_string(ttype);
		switch(ttype) {
			case TOKEN_INVALID_TOKEN:
			case TOKEN_EOF:
				continue;
			case TOKEN_ARROW:
				//TOKEN_ARROW,            // -> // Not used but reserved
				continue;
			case TOKEN_COMMENT_SINGLE:
				token_value = "; // a comment";
				io::printf("TODO token: %s `%s`\n", ttype, s);
				continue;
			case TOKEN_VOID:
			case TOKEN_BOOL:
			case TOKEN_CHAR:
			case TOKEN_DOUBLE:
			case TOKEN_FLOAT:
			case TOKEN_FLOAT16:
			case TOKEN_BFLOAT:
			case TOKEN_INT128:
			case TOKEN_ICHAR:
			case TOKEN_INT:
			case TOKEN_IPTR:
			case TOKEN_ISZ:
			case TOKEN_LONG:
			case TOKEN_SHORT:
			case TOKEN_UINT128:
			case TOKEN_UINT:
			case TOKEN_ULONG:
			case TOKEN_UPTR:
			case TOKEN_USHORT:
			case TOKEN_USZ:
			case TOKEN_FLOAT128:
			case TOKEN_ANY:
				ttype = TOKEN_TYPE_IDENT;

			case TOKEN_DOLLAR:
			case TOKEN_BUILTIN:
			case TOKEN_HASH:
			case TOKEN_IDENT:
			case TOKEN_CONST_IDENT:
			case TOKEN_TYPE_IDENT:
			case TOKEN_CT_IDENT:
			case TOKEN_CT_CONST_IDENT:
			case TOKEN_CT_TYPE_IDENT:
			case TOKEN_HASH_CONST_IDENT:
			case TOKEN_HASH_IDENT:
			case TOKEN_HASH_TYPE_IDENT:
			case TOKEN_AT_IDENT:
			case TOKEN_AT_CONST_IDENT:
			case TOKEN_AT_TYPE_IDENT:
			case TOKEN_STRING:
			case TOKEN_RAW_STRING:
			case TOKEN_INTEGER:
			case TOKEN_REAL:
			case TOKEN_CHAR_LITERAL:
			case TOKEN_BYTES:
			case TOKEN_DOC_COMMENT:
			case TOKEN_DOCS_EOL:
				io::printf("TODO token: %s `%s`\n", ttype, s);
				continue;

			case TOKEN_DOCS_START:
			case TOKEN_DOCS_END:
				io::printf("(!!!)BUG token: %s `%s`\n", ttype, s);
				continue;
			default:
		}
		s.appendf("module %s;", token_value);
		// io::printf("token: %s `%s`\n", ttype, s);

		// breakpoint();
		String source = s.str_view();
		test::equal(source.len, 8+token_value.len);
		Lexer lexer = lexer::new_init(s.str_view());
		List(<lexer::Token>) toks = lexer.new_parse_tokens();
		defer toks.free();

		test::@check(4 == toks.len(), "\n%s", toks);
		test::equal(toks[0].type, TokenType.TOKEN_MODULE);
		test::equal(toks[0].value, "module");
		test::equal(toks[0].row, 1);
		test::equal(toks[0].col, 1);
		test::equal(toks[0].offset, 0);

		test::equal(toks[2].type, TokenType.TOKEN_EOS);
		test::equal(toks[2].value, ";");
		test::equal(toks[2].col, s.len());
		test::equal(toks[2].row, 1);
		test::equal(toks[2].offset, s.len()-1);

		test::equal(toks[3].type, TokenType.TOKEN_EOF);
		test::equal(toks[3].value, "\n");
		test::equal(toks[3].col, s.len()+1);
		test::equal(toks[3].row, 1);
		test::equal(toks[3].offset, s.len());

		// TODO: synth token check
		test::equal(toks[1].type, ttype);
		test::equal(toks[1].value, token_value);
		test::equal(toks[1].col, 8);
		test::equal(toks[1].row, 1);
		test::equal(toks[1].offset, 7);
	}
}
