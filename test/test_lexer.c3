module test::c3tools::lexer @test;
import c3tools::lexer;
import std::io;
import std::collections::list;

fn void test_row_col_offset() {
    String contents = `module foo`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	int cnt = 0;
	while(lexer.next_token()) {
	    if (cnt == 1) {
	        test::equal(lexer.token.type, TokenType.IDENT);
	        test::equal(lexer.token.value, "foo");
	        test::equal(lexer.token.row, 1);
	        test::equal(lexer.token.col, 8);
	    }
	    
	    cnt++;
	}
}

fn void test_simple_module() {
    String contents = `module foo;`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.IDENT);
	test::equal(toks[1].value, "foo");
	test::equal(toks[1].offset, 7);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, ";");
	test::equal(toks[2].offset, 10);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, 11);

	test::equal(toks[3].type, TokenType.EOF);
	test::equal(toks[3].value, "\n");
	test::equal(toks[3].col, 12);
	test::equal(toks[3].row, 1);
	test::equal(toks[3].offset, 11);
}

fn void test_all_available_tokens() {

	DString s = dstring::temp_new();
	foreach(ttype: TokenType.values) {
		s.clear();
		String token_value = lexer::token_type_to_string(ttype);
		String token_value_exp = "";

		// NOTE: imputing some values to tokens that don't have literal analogs
		switch(ttype) {
			case INVALID_TOKEN:
			case EOF:
			case DOCS_EOL:
			case BYTES:
			case DOC_COMMENT:
			case DOCS_START:
			case DOCS_END:
			case COMMENT_SINGLE_INLINE:
			case COMMENT_SINGLE:
			case COMMENT_MULTI_INLINE:
			case COMMENT_MULTI:
			case ARROW:
			case BUILTIN: 
			case DOLLAR:
			case HASH:
				// These are handled by separate tests 
				continue;
			case VOID:
			case BOOL:
			case CHAR:
			case DOUBLE:
			case FLOAT:
			case FLOAT16:
			case BFLOAT:
			case INT128:
			case ICHAR:
			case INT:
			case IPTR:
			case ISZ:
			case LONG:
			case SHORT:
			case UINT128:
			case UINT:
			case ULONG:
			case UPTR:
			case USHORT:
			case USZ:
			case FLOAT128:
			case ANY:
				ttype = TYPE_IDENT;

			case IDENT:
				token_value = "indEnt_123";
			case STRING:
				token_value = `"some string \n \t \u1F603"`;
			case RAW_STRING:
				token_value = "`raw string\n`";
			case INTEGER:
				token_value = "9797";
			case REAL:
				token_value = "97.97";
			case CHAR_LITERAL:
				token_value = `'\0'`;
			case CONST_IDENT:
				token_value = "CONST_IND1821";
			case TYPE_IDENT:
				token_value = "MyType_213";
			case CT_IDENT:
				token_value = "$foo_211";
			case CT_CONST_IDENT:
				token_value = "$FOOSAD_211";
			case CT_TYPE_IDENT:
				token_value = "$FtyPe_211";
			case HASH_CONST_IDENT:
				token_value = "#SO_CONTS122";
			case HASH_IDENT:
				token_value = "#sdo_iDentA122";
			case HASH_TYPE_IDENT:
				token_value = "#MyTypeo_iDentA122";
			case AT_CONST_IDENT:
				token_value = "@SO_CONTS122";
			case AT_IDENT:
				token_value = "@sdo_iDentA122";
			case AT_TYPE_IDENT:
				token_value = "@MyTypeo_iDentA122";
			default:
				continue;
		}
		s.appendf("module %s;", token_value);
		// io::printf("token: %s `%s`\n", ttype, s);

		// breakpoint();
		String source = s.str_view();
		test::equal(source.len, 8+token_value.len);
		Lexer lexer;
		lexer::init(&lexer, s.str_view());
		List(<lexer::Token>) toks = lexer.new_parse_tokens();
		defer toks.free();

		test::@check(4 == toks.len(), "\n%s", toks);
		test::equal(toks[0].type, TokenType.MODULE);
		test::equal(toks[0].value, "module");
		test::equal(toks[0].row, 1);
		test::equal(toks[0].col, 1);
		test::equal(toks[0].offset, 0);

		test::equal(toks[2].type, TokenType.EOS);
		test::equal(toks[2].value, ";");
		if (toks[2].row == 1) {
			test::equal(toks[2].col, s.len());
			test::equal(toks[2].row, 1);
			test::equal(toks[2].offset, s.len()-1);

			test::equal(toks[3].type, TokenType.EOF);
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
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(2, toks.len());
	test::equal(toks[0].type, TokenType.COMMENT_SINGLE_INLINE);
	test::equal(toks[0].value, "// foo;");

	test::equal(toks[1].type, TokenType.EOF);
}

fn void test_simple_comments_after_ident() {
    String contents = "module // foo;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_SINGLE_INLINE);
	test::equal(toks[1].value, "// foo;");
	test::equal(toks[1].col, 8);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOF);
}

fn void test_simple_comments_with_new_line() {
    String contents = "module // foo;\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_SINGLE_INLINE);
	test::equal(toks[1].value, "// foo;\n");
	test::equal(toks[1].col, 8);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOF);
}

fn void test_simple_comments_with_new_line_prefix() {
    String contents = "module \n  \t  // foo;\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_SINGLE);
	test::equal(toks[1].value, "// foo;\n");

	test::equal(toks[2].type, TokenType.EOF);
}


fn void test_simple_comments_with_new_line_prefix_inline() {
    String contents = "  \t  // foo;\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(2, toks.len());
	test::equal(toks[0].type, TokenType.COMMENT_SINGLE_INLINE);
	test::equal(toks[0].value, "// foo;\n");

	test::equal(toks[1].type, TokenType.EOF);
}

fn void test_string_no_escape_codes() {
    String contents = `module "\n";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.STRING);
	test::equal(toks[1].value, `"\n"`);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_multiline_comment() {
    String contents = `module /* asda`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda`);

	test::equal(toks[2].type, TokenType.EOF);
}


fn void test_multiline_comment_with_end() {
    String contents = `module /* asda */`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda */`);

	test::equal(toks[2].type, TokenType.EOF);
}


fn void test_multiline_comment_with_nesting() {
    String contents = `module /* asda /* with /* another */ */ */`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::equal(toks[1].value, `/* asda /* with /* another */ */ */`);

	test::equal(toks[2].type, TokenType.EOF);
}

fn void test_multiline_comment_multiline_end() {
    String contents = "module \n  \t /* foo \n asda */";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);

	test::equal(toks[1].type, TokenType.COMMENT_MULTI);
	test::equal(toks[1].value, "/* foo \n asda */");

	test::equal(toks[2].type, TokenType.EOF);
}

fn void test_simple_module_multiline() {
    String contents = "module \n \t foo;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.IDENT);
	test::equal(toks[1].value, "foo");
	test::equal(toks[1].offset, 11);
	test::equal(toks[1].row, 2);
	test::equal(toks[1].col, 4);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, ";");
	test::equal(toks[2].offset, 14);
	test::equal(toks[2].row, 2);
	test::equal(toks[2].col, 7);

	test::equal(toks[3].type, TokenType.EOF);
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
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(14, toks.len());
	test::equal(toks[0].type, TokenType.DOCS_START);
	test::equal(toks[0].value, "<*\nSome text\n");
	test::equal(toks[0].row, 2);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 1);

	test::equal(toks[1].type, TokenType.AT_IDENT);
	test::equal(toks[1].value, "@param");
	test::equal(toks[1].offset, 14);
	test::equal(toks[1].row, 4);
	test::equal(toks[1].col, 1);

	test::equal(toks[2].type, TokenType.IDENT);
	test::equal(toks[2].value, "foo");
	test::equal(toks[2].offset, 21);
	test::equal(toks[2].row, 4);
	test::equal(toks[2].col, 8);

	test::equal(toks[3].type, TokenType.STRING);
	test::equal(toks[3].value, `"asdlkj"`);
	test::equal(toks[3].offset, 25);
	test::equal(toks[3].row, 4);
	test::equal(toks[3].col, 12);

	test::equal(toks[4].type, TokenType.DOCS_EOL);
	test::equal(toks[4].value, "\n");
	test::equal(toks[4].offset, 33);
	test::equal(toks[4].row, 4);
	test::equal(toks[4].col, 20);

	test::equal(toks[5].type, TokenType.AT_IDENT);
	test::equal(toks[5].value, "@pure");
	test::equal(toks[5].offset, 34);
	test::equal(toks[5].row, 5);
	test::equal(toks[5].col, 1);

	test::equal(toks[6].type, TokenType.DOCS_EOL);
	test::equal(toks[6].value, "\n");
	test::equal(toks[6].offset, 39);
	test::equal(toks[6].row, 5);
	test::equal(toks[6].col, 6);

	test::equal(toks[7].type, TokenType.AT_IDENT);
	test::equal(toks[7].value, "@require");

	test::equal(toks[8].type, TokenType.IDENT);
	test::equal(toks[8].value, "foo");

	test::equal(toks[9].type, TokenType.GREATER);
	test::equal(toks[9].value, ">");

	test::equal(toks[10].type, TokenType.INTEGER);
	test::equal(toks[10].value, "0");

	test::equal(toks[11].type, TokenType.DOCS_EOL);

	test::equal(toks[12].type, TokenType.DOCS_END);
	test::equal(toks[12].value, "*>");

	test::equal(toks[13].type, TokenType.EOF);
}

fn void test_simple_docstring_inline() {
    String contents = `<*some text*>`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::equal(3, toks.len());
	test::equal(toks[0].type, TokenType.DOCS_START);
	test::equal(toks[0].value, "<*some text");
	test::equal(toks[1].type, TokenType.DOCS_END);
	test::equal(toks[1].value, "*>");
	test::equal(toks[2].type, TokenType.EOF);
}

fn void test_simple_docstring_compound_statement() {
    String contents = `<*
@require {| IntList* l = (IntList*) data; return l.allocator && l.capacity; |}
    *>
    `;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {DOCS_START,AT_IDENT,LBRAPIPE,TYPE_IDENT,STAR,IDENT,EQ,LPAREN,TYPE_IDENT,STAR,RPAREN,IDENT,EOS,RETURN,IDENT,DOT,IDENT,AND,IDENT,DOT,IDENT,EOS,RBRAPIPE,DOCS_EOL,DOCS_END,EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_base64_bytes()
{
    String contents = `module b64"SGVsbG8gV29ybGQh";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.BYTES);
	test::equal(toks[1].value, `b64"SGVsbG8gV29ybGQh"`);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_hex_bytes()
{
    String contents = `module x"4865 6c6c";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");
	test::equal(toks[0].row, 1);
	test::equal(toks[0].col, 1);
	test::equal(toks[0].offset, 0);

	test::equal(toks[1].type, TokenType.BYTES);
	test::equal(toks[1].value, `x"4865 6c6c"`);
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_fn_decl()
{
    String contents = `fn void ! foo(int a)`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {FN,TYPE_IDENT,BANG,IDENT,LPAREN,TYPE_IDENT,IDENT,RPAREN,EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_fn_decl_bang_is_close()
{
    String contents = `fn void! foo(int a)`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

    TokenType[] expected = {FN,TYPE_IDENT,BANG,IDENT,LPAREN,TYPE_IDENT,IDENT,RPAREN,EOF};

    // module IDENT[foo] ; EOF
	test::equal(expected.len, toks.len());
	foreach(i, e: expected) {
		test::@check(e == toks[i].type, "%s != %s at i:%d", e, toks[i], i);
	}
}

fn void test_simple_bultin() {
    String contents = "module $$bui_ltin123;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.BUILTIN);
	test::equal(toks[1].value, "$$bui_ltin123");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_simple_bultin_type() {
    String contents = "module $$TypeBuiltin;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.BUILTIN);
	test::equal(toks[1].value, "$$TypeBuiltin");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_simple_bultin_const() {
    String contents = "module $$BUILTIN_CONTS12;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.BUILTIN);
	test::equal(toks[1].value, "$$BUILTIN_CONTS12");
	test::equal(toks[1].row, 1);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 7);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 1);
	test::equal(toks[2].col, contents.len);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}

fn void test_empty_string_token() {
    String contents = "module \n   \t \t \n;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::equal(4, toks.len());
	test::equal(toks[0].type, TokenType.MODULE);
	test::equal(toks[0].value, "module");

	test::equal(toks[1].type, TokenType.EMPTY_LINE);
	test::equal(toks[1].value, "\n");
	test::equal(toks[1].row, 2);
	test::equal(toks[1].col, 8);
	test::equal(toks[1].offset, 15);

	test::equal(toks[2].type, TokenType.EOS);
	test::equal(toks[2].value, `;`);
	test::equal(toks[2].row, 3);
	test::equal(toks[2].col, 1);
	test::equal(toks[2].offset, contents.len-1);

	test::equal(toks[3].type, TokenType.EOF);
}
