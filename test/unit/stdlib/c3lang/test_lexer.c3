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

		// NOTE: imputing some values to tokens that don't have literal analogs
		switch(ttype) {
			case TOKEN_INVALID_TOKEN:
			case TOKEN_EOF:
			case TOKEN_DOCS_EOL:
			case TOKEN_BYTES:
			case TOKEN_DOC_COMMENT:
			case TOKEN_DOCS_START:
			case TOKEN_DOCS_END:
			case TOKEN_COMMENT_SINGLE_INLINE:
			case TOKEN_COMMENT_SINGLE:
			case TOKEN_COMMENT_MULTI_INLINE:
			case TOKEN_COMMENT_MULTI:
			case TOKEN_ARROW:
			case TOKEN_BUILTIN: 
			case TOKEN_DOLLAR:
			case TOKEN_HASH:
				// These are handled by separate tests 
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
			default:
				continue;
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

fn void test_simple_docstring() {
    String contents = `
<*
Some text
@param foo "asdlkj"
@pure
@require foo > 0
*>
    `;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(14, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_DOCS_START);
	test::equal(toks[0].value, "<*\nSome text\n");
	test::equal(toks[0].row, 2);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 1);

	test::equal(toks[1].type, TokenType.TOKEN_AT_IDENT);
	test::equal(toks[1].value, "@param");
	test::equal(toks[1].offset, 14);
	test::equal(toks[1].row, 4);
	test::equal(toks[1].col, 1);

	test::equal(toks[2].type, TokenType.TOKEN_IDENT);
	test::equal(toks[2].value, "foo");
	test::equal(toks[2].offset, 21);
	test::equal(toks[2].row, 4);
	test::equal(toks[2].col, 8);

	test::equal(toks[3].type, TokenType.TOKEN_STRING);
	test::equal(toks[3].value, `"asdlkj"`);
	test::equal(toks[3].offset, 25);
	test::equal(toks[3].row, 4);
	test::equal(toks[3].col, 12);

	test::equal(toks[4].type, TokenType.TOKEN_DOCS_EOL);
	test::equal(toks[4].value, "\n");
	test::equal(toks[4].offset, 33);
	test::equal(toks[4].row, 4);
	test::equal(toks[4].col, 20);

	test::equal(toks[5].type, TokenType.TOKEN_AT_IDENT);
	test::equal(toks[5].value, "@pure");
	test::equal(toks[5].offset, 34);
	test::equal(toks[5].row, 5);
	test::equal(toks[5].col, 1);

	test::equal(toks[6].type, TokenType.TOKEN_DOCS_EOL);
	test::equal(toks[6].value, "\n");
	test::equal(toks[6].offset, 39);
	test::equal(toks[6].row, 5);
	test::equal(toks[6].col, 6);

	test::equal(toks[7].type, TokenType.TOKEN_AT_IDENT);
	test::equal(toks[7].value, "@require");

	test::equal(toks[8].type, TokenType.TOKEN_IDENT);
	test::equal(toks[8].value, "foo");

	test::equal(toks[9].type, TokenType.TOKEN_GREATER);
	test::equal(toks[9].value, ">");

	test::equal(toks[10].type, TokenType.TOKEN_INTEGER);
	test::equal(toks[10].value, "0");

	test::equal(toks[11].type, TokenType.TOKEN_DOCS_EOL);

	test::equal(toks[12].type, TokenType.TOKEN_DOCS_END);
	test::equal(toks[12].value, "*>");

	test::equal(toks[13].type, TokenType.TOKEN_EOF);
}

fn void test_simple_docstring_inline() {
    String contents = `<*some text*>`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_DOCS_START);
	test::equal(toks[0].value, "<*some text");
	test::equal(toks[1].type, TokenType.TOKEN_DOCS_END);
	test::equal(toks[1].value, "*>");
	test::equal(toks[2].type, TokenType.TOKEN_EOF);
}

fn void test_simple_docstring_compound_statement() {
    String contents = `<*
@require {| IntList* l = (IntList*) data; return l.allocator && l.capacity; |}
    *>
    `;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {TOKEN_DOCS_START,TOKEN_AT_IDENT,TOKEN_LBRAPIPE,TOKEN_TYPE_IDENT,TOKEN_STAR,TOKEN_IDENT,TOKEN_EQ,TOKEN_LPAREN,TOKEN_TYPE_IDENT,TOKEN_STAR,TOKEN_RPAREN,TOKEN_IDENT,TOKEN_EOS,TOKEN_RETURN,TOKEN_IDENT,TOKEN_DOT,TOKEN_IDENT,TOKEN_AND,TOKEN_IDENT,TOKEN_DOT,TOKEN_IDENT,TOKEN_EOS,TOKEN_RBRAPIPE,TOKEN_DOCS_EOL,TOKEN_DOCS_END,TOKEN_EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_base64_bytes()
{
    String contents = `module b64"SGVsbG8gV29ybGQh";`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.TOKEN_BYTES);
	test::equal(toks[1].value, `b64"SGVsbG8gV29ybGQh"`);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}

fn void test_hex_bytes()
{
    String contents = `module x"4865 6c6c";`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.TOKEN_BYTES);
	test::equal(toks[1].value, `x"4865 6c6c"`);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}

fn void test_fn_decl()
{
    String contents = `fn void ! foo(int a)`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {TOKEN_FN,TOKEN_TYPE_IDENT,TOKEN_BANG,TOKEN_IDENT,TOKEN_LPAREN,TOKEN_TYPE_IDENT,TOKEN_IDENT,TOKEN_RPAREN,TOKEN_EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_fn_decl_bang_is_close()
{
    String contents = `fn void! foo(int a)`;
	Lexer lexer = lexer::new_init(contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {TOKEN_FN,TOKEN_TYPE_IDENT,TOKEN_BANG,TOKEN_IDENT,TOKEN_LPAREN,TOKEN_TYPE_IDENT,TOKEN_IDENT,TOKEN_RPAREN,TOKEN_EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_simple_bultin() {
    String contents = "module $$bui_ltin123;";
	Lexer lexer = lexer::new_init(contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.TOKEN_BUILTIN);
	test::equal(toks[1].value, "$$bui_ltin123");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}

fn void test_simple_bultin_type() {
    String contents = "module $$TypeBuiltin;";
	Lexer lexer = lexer::new_init(contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.TOKEN_BUILTIN);
	test::equal(toks[1].value, "$$TypeBuiltin");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}

fn void test_simple_bultin_const() {
    String contents = "module $$BUILTIN_CONTS12;";
	Lexer lexer = lexer::new_init(contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.TOKEN_MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.TOKEN_BUILTIN);
	test::equal(toks[1].value, "$$BUILTIN_CONTS12");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.TOKEN_EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.TOKEN_EOF);
}
