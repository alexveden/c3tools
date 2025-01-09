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
		String token_value_exp = "";
		switch(ttype) {
			case TOKEN_INVALID_TOKEN:
			case TOKEN_EOF:
				continue;
			case TOKEN_ARROW:
				//TOKEN_ARROW,            // -> // Not used but reserved
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

			case TOKEN_IDENT:
				token_value = "indEnt_123";
			case TOKEN_STRING:
				token_value = `"some string \n \t \u1F603"`;
			case TOKEN_RAW_STRING:
				token_value = "`raw string\n`";
			case TOKEN_INTEGER:
				token_value = "9797";
			case TOKEN_REAL:
				token_value = "97.97";
			case TOKEN_CHAR_LITERAL:
				token_value = `'\0'`;
			case TOKEN_CONST_IDENT:
				token_value = "CONST_IND1821";
			case TOKEN_TYPE_IDENT:
				token_value = "MyType_213";
			case TOKEN_CT_IDENT:
				token_value = "$foo_211";
			case TOKEN_CT_CONST_IDENT:
				token_value = "$FOOSAD_211";
			case TOKEN_CT_TYPE_IDENT:
				token_value = "$FtyPe_211";
			case TOKEN_HASH_CONST_IDENT:
				token_value = "#SO_CONTS122";
			case TOKEN_HASH_IDENT:
				token_value = "#sdo_iDentA122";
			case TOKEN_HASH_TYPE_IDENT:
				token_value = "#MyTypeo_iDentA122";
			case TOKEN_AT_CONST_IDENT:
				token_value = "@SO_CONTS122";
			case TOKEN_AT_IDENT:
				token_value = "@sdo_iDentA122";
			case TOKEN_AT_TYPE_IDENT:
				token_value = "@MyTypeo_iDentA122";
			case TOKEN_BUILTIN: 
			case TOKEN_DOLLAR:
			case TOKEN_HASH:
			case TOKEN_BYTES:
			case TOKEN_DOC_COMMENT:
			case TOKEN_DOCS_EOL:
			case TOKEN_DOCS_START:
			case TOKEN_DOCS_END:
			case TOKEN_COMMENT_SINGLE_INLINE:
			case TOKEN_COMMENT_SINGLE:
			case TOKEN_COMMENT_MULTI_INLINE:
			case TOKEN_COMMENT_MULTI:
				io::printf("TODO token: %s `%s`\n", ttype, s);
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
		if (toks[2].row == 1) {
			test::equal(toks[2].col, s.len());
			test::equal(toks[2].row, 1);
			test::equal(toks[2].offset, s.len()-1);

			test::equal(toks[3].type, TokenType.TOKEN_EOF);
			test::equal(toks[3].value, "\n");
			test::equal(toks[3].col, s.len()+1);
			test::equal(toks[3].row, 1);
			test::equal(toks[3].offset, s.len());
		}

		test::equal(toks[1].type, ttype);
		if (token_value_exp){
			test::@check(toks[1].value == token_value_exp, "\nsource: %s\ntoken: %s\n", source, toks[1]);
		} else {
			test::@check(toks[1].value == token_value, "\nsource: %s\ntoken: %s\n", source, toks[1]);
			test::@check(toks[1].col == 8, "\nsource: %s\ntoken: %s\n", source, toks[1]);
			test::equal(toks[1].row, 1);
			test::equal(toks[1].offset, 7);
		}
	}
}

fn void test_simple_comments() {
    String contents = "// foo;";
	Lexer lexer = lexer::new_init(contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(2, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_COMMENT_SINGLE_INLINE);
	test::equal(toks[0].value, "// foo;");

	test::equal(toks[1].type, TokenType.TOKEN_EOF);
}

fn void test_simple_comments_after_ident() {
    String contents = "module // foo;";
	Lexer lexer = lexer::new_init(contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_SINGLE_INLINE);
	test::equal(toks[1].value, "// foo;");
	test::equal(toks[1].col, 8);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}

fn void test_simple_comments_with_new_line() {
    String contents = "module // foo;\n";
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_SINGLE_INLINE);
	test::equal(toks[1].value, "// foo;\n");
	test::equal(toks[1].col, 8);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}

fn void test_simple_comments_with_new_line_prefix() {
    String contents = "module \n  \t  // foo;\n";
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_SINGLE);
	test::equal(toks[1].value, "// foo;\n");

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}


fn void test_simple_comments_with_new_line_prefix_inline() {
    String contents = "  \t  // foo;\n";
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(2, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_COMMENT_SINGLE_INLINE);
	test::equal(toks[0].value, "// foo;\n");

	test::equal(toks[1].type, TokenType.TOKEN_EOF);
}

fn void test_string_no_escape_codes() {
    String contents = `module "\n";`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_STRING);
	test::equal(toks[1].value, `"\n"`);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}

fn void test_multiline_comment() {
    String contents = `module /* asda`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda`);

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}


fn void test_multiline_comment_with_end() {
    String contents = `module /* asda */`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda */`);

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}


fn void test_multiline_comment_with_nesting() {
    String contents = `module /* asda /* with /* another */ */ */`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda /* with /* another */ */ */`);

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}

fn void test_multiline_comment_multiline_end() {
    String contents = "module \n  \t /* foo \n asda */";
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);

	test::equal(toks[1].type, TokenType.TOKEN_COMMENT_MULTI);
	test::equal(toks[1].value, "/* foo \n asda */");

	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}

fn void test_simple_module_multiline() {
    String contents = "module \n \t foo;";
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
	test::equal(toks[1].offset, 11);
	test::equal(toks[1].row, 2);
	test::equal(toks[1].col, 4);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, ";");
	test::equal(toks[2].offset, 14);
	test::equal(toks[2].row, 2);
	test::equal(toks[2].col, 7);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
	test::equal(toks[3].value, "\n");
	test::equal(toks[3].col, 8);
	test::equal(toks[3].row, 2);
	test::equal(toks[3].offset, contents.len);
}
