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
	        test::eq(lexer.token.type, TokenType.IDENT);
	        test::eq(lexer.token.value, "foo");
	        test::eq(lexer.token.row, 1);
	        test::eq(lexer.token.col, 8);
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
	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");
	test::eq(toks[0].row, 1);
	test::eq(toks[0].col, 1);
	test::eq(toks[0].offset, 0);

	test::eq(toks[1].type, TokenType.IDENT);
	test::eq(toks[1].value, "foo");
	test::eq(toks[1].offset, 7);
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, ";");
	test::eq(toks[2].offset, 10);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, 11);

	test::eq(toks[3].type, TokenType.EOF);
	test::eq(toks[3].value, "\n");
	test::eq(toks[3].col, 12);
	test::eq(toks[3].row, 1);
	test::eq(toks[3].offset, 11);
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
		test::eq(source.len, 8+token_value.len);
		Lexer lexer;
		lexer::init(&lexer, s.str_view());
		List(<lexer::Token>) toks = lexer.new_parse_tokens();
		defer toks.free();

		test::@check(4 == toks.len(), "\n%s", toks);
		test::eq(toks[0].type, TokenType.MODULE);
		test::eq(toks[0].value, "module");
		test::eq(toks[0].row, 1);
		test::eq(toks[0].col, 1);
		test::eq(toks[0].offset, 0);

		test::eq(toks[2].type, TokenType.EOS);
		test::eq(toks[2].value, ";");
		if (toks[2].row == 1) {
			test::eq(toks[2].col, s.len());
			test::eq(toks[2].row, 1);
			test::eq(toks[2].offset, s.len()-1);

			test::eq(toks[3].type, TokenType.EOF);
			test::eq(toks[3].value, "\n");
			test::eq(toks[3].col, s.len()+1);
			test::eq(toks[3].row, 1);
			test::eq(toks[3].offset, s.len());
		}

		test::eq(toks[1].type, ttype);
		if (token_value_exp){
			test::@check(toks[1].value == token_value_exp, "\nsource: %s\ntoken: %s\n", source, toks[1]);
		} else {
			test::@check(toks[1].value == token_value, "\nsource: %s\ntoken: %s\n", source, toks[1]);
			test::@check(toks[1].col == 8, "\nsource: %s\ntoken: %s\n", source, toks[1]);
			test::eq(toks[1].row, 1);
			test::eq(toks[1].offset, 7);
		}
	}
}

fn void test_simple_comments_at_start_of_file() {
    String contents = "// foo\n;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.COMMENT_SINGLE);
	test::eq(toks[0].value, "// foo");

	test::eq(toks[1].type, TokenType.EOS);
	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_simple_comments_after_ident() {
    String contents = "module // foo;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	// breakpoint();
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_SINGLE_INLINE);
	test::eq(toks[1].value, "// foo;");
	test::eq(toks[1].col, 8);
	test::eq(toks[1].row, 1);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_simple_comments_with_new_line() {
    String contents = "module // foo;\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_SINGLE_INLINE);
	test::eq(toks[1].value, "// foo;");
	test::eq(toks[1].col, 8);
	test::eq(toks[1].row, 1);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_simple_comments_with_new_line_prefix() {
    String contents = "module \n  \t  // foo;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_SINGLE);
	test::eq(toks[1].value, "// foo;");

	test::eq(toks[2].type, TokenType.EOF);
}


fn void test_simple_comments_with_new_line_prefix_inline() {
    String contents = "  \t  // foo;\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(2, toks.len());
	test::eq(toks[0].type, TokenType.COMMENT_SINGLE_INLINE);
	test::eq(toks[0].value, "// foo;");

	test::eq(toks[1].type, TokenType.EOF);
}

fn void test_string_no_escape_codes() {
    String contents = `module "\n";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.STRING);
	test::eq(toks[1].value, `"\n"`);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[3].type, TokenType.EOF);
}

fn void test_multiline_comment() {
    String contents = `module /* asda`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::eq(toks[1].value, `/* asda`);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_multiline_comment_at_start() {
    String contents = "/* asda */\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(2, toks.len());
	test::eq(toks[0].type, TokenType.COMMENT_MULTI);
	test::eq(toks[0].value, `/* asda */`);

	test::eq(toks[1].type, TokenType.EOF);
}


fn void test_multiline_comment_with_end() {
    String contents = `module /* asda */`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::eq(toks[1].value, `/* asda */`);

	test::eq(toks[2].type, TokenType.EOF);
}


fn void test_multiline_comment_with_nesting() {
    String contents = "module /* asda /* with /* another */ */ */\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::eq(toks[1].value, `/* asda /* with /* another */ */ */`);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_multiline_comment_multiline_end() {
    String contents = "module \n  \t /* foo \n asda */\n";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI);
	test::eq(toks[1].value, "/* foo \n asda */");

	test::eq(toks[2].type, TokenType.EOF);
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
	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");
	test::eq(toks[0].row, 1);
	test::eq(toks[0].col, 1);
	test::eq(toks[0].offset, 0);

	test::eq(toks[1].type, TokenType.IDENT);
	test::eq(toks[1].value, "foo");
	test::eq(toks[1].offset, 11);
	test::eq(toks[1].row, 2);
	test::eq(toks[1].col, 4);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, ";");
	test::eq(toks[2].offset, 14);
	test::eq(toks[2].row, 2);
	test::eq(toks[2].col, 7);

	test::eq(toks[3].type, TokenType.EOF);
	test::eq(toks[3].value, "\n");
	test::eq(toks[3].col, 8);
	test::eq(toks[3].row, 2);
	test::eq(toks[3].offset, contents.len);
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
	test::eq(14, toks.len());
	test::eq(toks[0].type, TokenType.DOCS_START);
	test::eq(toks[0].value, "<*\nSome text\n");
	test::eq(toks[0].row, 2);
	test::eq(toks[0].col, 1);
	test::eq(toks[0].offset, 1);

	test::eq(toks[1].type, TokenType.AT_IDENT);
	test::eq(toks[1].value, "@param");
	test::eq(toks[1].offset, 14);
	test::eq(toks[1].row, 4);
	test::eq(toks[1].col, 1);

	test::eq(toks[2].type, TokenType.IDENT);
	test::eq(toks[2].value, "foo");
	test::eq(toks[2].offset, 21);
	test::eq(toks[2].row, 4);
	test::eq(toks[2].col, 8);

	test::eq(toks[3].type, TokenType.STRING);
	test::eq(toks[3].value, `"asdlkj"`);
	test::eq(toks[3].offset, 25);
	test::eq(toks[3].row, 4);
	test::eq(toks[3].col, 12);

	test::eq(toks[4].type, TokenType.DOCS_EOL);
	test::eq(toks[4].value, "\n");
	test::eq(toks[4].offset, 33);
	test::eq(toks[4].row, 4);
	test::eq(toks[4].col, 20);

	test::eq(toks[5].type, TokenType.AT_IDENT);
	test::eq(toks[5].value, "@pure");
	test::eq(toks[5].offset, 34);
	test::eq(toks[5].row, 5);
	test::eq(toks[5].col, 1);

	test::eq(toks[6].type, TokenType.DOCS_EOL);
	test::eq(toks[6].value, "\n");
	test::eq(toks[6].offset, 39);
	test::eq(toks[6].row, 5);
	test::eq(toks[6].col, 6);

	test::eq(toks[7].type, TokenType.AT_IDENT);
	test::eq(toks[7].value, "@require");

	test::eq(toks[8].type, TokenType.IDENT);
	test::eq(toks[8].value, "foo");

	test::eq(toks[9].type, TokenType.GREATER);
	test::eq(toks[9].value, ">");

	test::eq(toks[10].type, TokenType.INTEGER);
	test::eq(toks[10].value, "0");

	test::eq(toks[11].type, TokenType.DOCS_EOL);

	test::eq(toks[12].type, TokenType.DOCS_END);
	test::eq(toks[12].value, "*>");

	test::eq(toks[13].type, TokenType.EOF);
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
	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.DOCS_START);
	test::eq(toks[0].value, "<*some text");
	test::eq(toks[1].type, TokenType.DOCS_END);
	test::eq(toks[1].value, "*>");
	test::eq(toks[2].type, TokenType.EOF);
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
	test::eq(expected.len, toks.len());
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

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");
	test::eq(toks[0].row, 1);
	test::eq(toks[0].col, 1);
	test::eq(toks[0].offset, 0);

	test::eq(toks[1].type, TokenType.BYTES);
	test::eq(toks[1].value, `b64"SGVsbG8gV29ybGQh"`);
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, contents.len);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
}

fn void test_base64_bytes_long()
{
    String contents = `b64"cW9pZgAAAVQAAACpBABV/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/f39/cl/Jv39/f392jXBJv39/f392TXBJv39/f392TXBJv39/f392TXBJv39/f392TXBJv39/f392TXBJv39/f392DXBJv39/f392TXBJv39/f392TXBJv39/f392TXBJv39/f392TXBJu81Jv39zzXAJv390jXBJu01wyb9/cg1xib9/dA1wibsNcQm/f3GNcgm0zXAJv33NcEm6zXHJv39wzXIJtQ1xCb99DXBJus1wibANcEm/f3BNcgm1TXHJv3yNcEm6jXCJsE1wSb9/cA1xibZNSbANcQm/fE1wSbpNcImwjXBJv39NcUm4DXCJv3xNcEm6DXCJsM1wSb9/TXEJuI1wib98DXBJuc1wibENcEm/fw1wyblNcIm/e41wibmNcImxTXBJv37NcMm5zXBJv3uNcIm5jXCJsU1wSb9+jXEJuc1wib97TXCJuU1wibGNcEm/fk1xCboNcIm/e01wSbmNcImxjXBJv35NcMm6DXCJv3uNcEm5jXBJsc1wSb9+DXDJuk1wib97jXBJuU1wibGNcIm/fg1wyboNcIm/e81wSblNcEmxzXBJv34NcMm6TXCJv3vNcEm5TXBJsc1wSb9+DXCJuk1wib98DXBJuQ1wibHNcEm/fc1wyboNcMm/fA1wSbkNcEmxzXCJv33NcMm5jXEJv3xNcEm5DXBJsc1wSb9+DXCJuY1xSb98TXBJuM1wibGNcIm/fc1wybmNcQm/fI1wSbjNcEmxjXCJv34NcIm5zXGJv3wNcEm4zXBJsU1wyb9+DXCJug1xib97jXCJuI1wibENcMm/fk1wibrNcQm/e01wibiNcImwjXDJv37NcIm7DXEJv3sNcEm4zXBJsE1xCb9wDUm+TXCJu41wyb96zXBJuM1wSY1xSbKNcUm6jXDJvc1wibvNcMm/eo1wSbjNccmyzXIJuY1xSb3NcIm7zXEJv3pNcEm4jXGJsw1yibLNcUm0DXGJvc1wibwNcMm/ek1wSbiNcQmzTXLJsk1xybDNcImxjXHJvc1wibxNcIm/ek1wSbhNcMmzzXDJsA1xSbGNcomwjXDJsQ1ySb2NcIm8TXCJv3pNcEm4TXCJs81wibCNcUmxDXLJsI1xSbCNcQmNcIm9zXDJvA1wib96DXCJuI1wSbONcMmwzXEJsM1xibANcImwjXGJsA1xCY1wyb4NcIm7zXDJv3oNcIm4jXBJs41wibENcQmwTXGJsE1wybCNccmNcMmNcMm+TXCJtA1wibZNcIm/ek1wSbjNcEmzjXBJsU1wybANcYmwzXCJsI11Cb5NcMmzTXDJtk1wyb96TXBJuM1wSbNNcImxTXMJsM1wybCNcImwDXNJvs1wibMNcMm2TXDJv3qNcEm4zXBJs01wibFNcsmxDXDJsE1wybBNcsm/DXDJsk1xCbZNcQm/eo1wSbjNcEmzDXCJsc1yCbGNcImwjXCJsM1yCb9wDXEJsY1xCbaNcQm/es1wSbjNcEmyzXDJsY1xibJNcImwTXDJsQ1wib9xjXQJto1xCb97DXBJuM1wSbKNcQmxjXCJs01wibANcMmxTXCJv3HNc4m2jXEJv3tNcEm4zXBJsk1xibENcImzjXCJsA1wybENcMm/cg1yybbNcQm/e41wSbjNcImxzXCJjXCJsQ1wibNNcMmNcMmxTXDJv3JNcgm3DXEJv3vNcEm5DXBJsQ1xCbANcwmzTXIJsY1wyb98DXEJtg1wCb91DXBJuQ1wyY1xibCNcomzjXIJsc1wib96DXBJsE1xSbWNcAm/dc1wSblNckmxTXIJs81xybINcImzTXBJv3VNcMmNcUm1TXAJv3ZNcEm5jXHJsg1wibTNcYmyTXDJss1wSb91TXLJtQ1wCb92zXBJug1wSblNcYmyTXDJsk1wyb91TXJJtM1wCb93jXBJv3UNcQmzDXEJsU1xCb91TXJJtI1wCb94DXBJv3UNcMmzjXGJjXGJv3WNccm0jXAJv3iNcEm/dU1wSbPNc4m/dc1xibQNcAm/eU1wSb96zXLJv3YNcQm0DXAJv3nNcIm/ew1xyb92zXBJtA1wCb96jXBJv3uNcIm/fE1wCb97DXBJv39/eU1wCb9/f39/dc1wCb9/f39/dg1wCb9/f39/dg1wCbxNcUm/f39/dw1wCbxNcgm/f39/dk1wCbxNcom/f39/dc1wCbyNcQmwjXBJv39/f3VNcAm9DXCJsQ1wSb9/f390jXBJvY1wSbENcIm/f39/dA1wSb4NcAmxTXCJv39/f3O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wybONcIm9zXDJss1JjXAJv36Lsg8wQbGLscmzDDGNjjANjA2OME2MMsm5TXCJs41wyb3NcQmyTXCJv37LsgGJTwGxi7HJswwxgo4wAo2OMIwzCb5NcIm+TXFJsQ1xCb9/C7KEAbEEC7IJswwxj44wG44wzDMJvg1wib7Nc8m/f0u3CbMMMYKOMU2MMwm+DXCJvw1zSb9/cAu3CbMMMY2OMQ2MM0m9zXCJv3ANcsm/f3tMMc4wzYwzib3NcIm/cM1xib9/e8w3Sb2NcIm/f39/f3XNcMm/f397f6NjY3BJv3iNcMm/f397Tj+JycnwSb93zXFJv39/dU4/lFRUT7DJtA+wib93zXEJv39/dQ4PsYmzzg+wTQm/d81wyb9/f3UPsgmzz7COCb94DXAJv39/dU+xjgmyDg0wDgmwjg+wibCOD7GJv39/f3tPsQmyD7FJsI+wjgmwT7IJs84ND7CJsU4NMA4Jv39/f3LPsImyT7GJsE0PsImwj7IJsE4PsI4JsY+xCbEPsMmxTg0hIg0OCb9/f39PsEmyj7GJsE+wjgmwj7COMA0PsEmwTQ+yCbBPsQmxD7DJsQ+xSb9/f38PsI4JsI4wSbBPsEQOD7BJsE+wTQmwz7BOD7EJsEQPsgmwT7DJsU+wTQ4JsM+xib9/f38PsomwRA+xSbAOD7BOCbDPsgmwRA+yCbBPsUmwz7CJsQ+whA+wSb9/f38PsomwTg+xSbAND7CNMA4JsA+xzgmwRA+wBAmyT7FJsI+wibEPsI4Jv39/f3BOD7IOCbCPsUmwDQ+xSbAPsUmxBA+wBAmyz7DJsI+wzgmwj7DOCb9/f390j7COCbAOD7FJsE4NMA4JsY0PsA0Jsk+xSbCOD7DJsI4PsM4Jv39/f3bPsE0OCbNOD7AOCbJPsQ4JsE+xibBPsQ4Jv39/f39wD7EJsI+xibBPsQ4Jv39/f39yj7GJsE+wzgm/f39/f3LODT+KysrPsA4JsM+wSb9/f39/f39/f3aAAAAAAAAAAE=";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::eq(3, toks.len());

	test::eq(toks[0].type, TokenType.BYTES);
	test::@check(toks[0].value.starts_with(`b64"cW9pZgAAAVQA`));
	test::@check(toks[0].value.ends_with(`AAAAAAAAAAE="`));

	test::eq(toks[1].type, TokenType.EOS);
	test::eq(toks[1].value, `;`);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_hex_bytes()
{
    String contents = `module x"4865 6c6c";`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");
	test::eq(toks[0].row, 1);
	test::eq(toks[0].col, 1);
	test::eq(toks[0].offset, 0);

	test::eq(toks[1].type, TokenType.BYTES);
	test::eq(toks[1].value, `x"4865 6c6c"`);
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, contents.len);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
}
fn void test_hex_bytes_raw_str()
{
    String contents = `
x``ffffffffffffffffffffffffffffffff
  ffffffffffffffffffffffffffffffff
  ffffffffffffffffffffffffffffffff
  00010203040506070809ffffffffffff
  ff0a0b0c0d0e0fffffffffffffffffff
  ffffffffffffffffffffffffffffffff
  ff0a0b0c0d0e0fffffffffffffffffff
  fffffffffffffffffffffffffffffff1
  fffffffffffffffffffffffffffffff2
  fffffffffffffffffffffffffffffff3
  fffffffffffffffffffffffffffffff4
  fffffffffffffffffffffffffffffff5
  fffffffffffffffffffffffffffffff6
  fffffffffffffffffffffffffffffff7
  fffffffffffffffffffffffffffffff8
  ffffffffffffffaffffbffffcfffdff0``;`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);
    // foreach(i, t: toks) io::printf(",%s", t.type);

	test::eq(3, toks.len());

	test::eq(toks[0].type, TokenType.BYTES);
	test::@check(toks[0].value.starts_with("x`"));
	test::@check(toks[0].value.ends_with("cfffdff0`"));

	test::eq(toks[1].type, TokenType.EOS);
	test::eq(toks[1].value, `;`);

	test::eq(toks[2].type, TokenType.EOF);
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
	test::eq(expected.len, toks.len());
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
	test::eq(expected.len, toks.len());
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

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");

	test::eq(toks[1].type, TokenType.BUILTIN);
	test::eq(toks[1].value, "$$bui_ltin123");
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, contents.len);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
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

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");

	test::eq(toks[1].type, TokenType.BUILTIN);
	test::eq(toks[1].value, "$$TypeBuiltin");
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, contents.len);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
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

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");

	test::eq(toks[1].type, TokenType.BUILTIN);
	test::eq(toks[1].value, "$$BUILTIN_CONTS12");
	test::eq(toks[1].row, 1);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 7);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 1);
	test::eq(toks[2].col, contents.len);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
}

fn void test_empty_string_token() {
    String contents = "module \n   \t \t \n;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);
	test::eq(toks[0].value, "module");

	test::eq(toks[1].type, TokenType.EMPTY_LINE);
	test::eq(toks[1].value, "\n");
	test::eq(toks[1].row, 2);
	test::eq(toks[1].col, 8);
	test::eq(toks[1].offset, 15);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[2].value, `;`);
	test::eq(toks[2].row, 3);
	test::eq(toks[2].col, 1);
	test::eq(toks[2].offset, contents.len-1);

	test::eq(toks[3].type, TokenType.EOF);
}


fn void test_extending_atts_safety() {
    String contents = `@test   @export("sdf") @if($foo(@bar) || @test) @export) @foo(   add`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	
    Token* t = &lexer.token;

	int att_cnt = 0;
	while (lexer.next_token()) {
    	io::printf("%s", t);

		if(t.type == AT_IDENT){
			lexer.extend_current_attribute();
			switch(att_cnt){
				case 0:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, "@test");
				case 1:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, `@export("sdf")`);
				case 2:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, `@if($foo(@bar) || @test)`);
				case 3:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, `@export`);
				case 4:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, `@foo`);
				default: 
					unreachable();
			}

    		att_cnt++;
		}
	}

	test::eq(t.type, TokenType.EOF);
	test::eq(5, att_cnt);
}


fn void test_extending_atts() {
    String contents = `@test  (  ddd) @if($foo(@bar) || @test) @export("@bar");`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	
    Token* t = &lexer.token;

	int att_cnt = 0;
	while (lexer.next_token()) {
    	io::printf("%s", t);
    	// io::printf("current char: `%c`\n", lexer.current[0]);

		if(t.type == AT_IDENT){
    		lexer.extend_current_attribute();
			switch(att_cnt){
				case 0:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, "@test  (  ddd)");
				case 1:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, "@if($foo(@bar) || @test)");
				case 2:
					test::eq(t.type, TokenType.AT_IDENT);
					test::eq(t.value, `@export("@bar")`);
				default: 
					unreachable();
			}
		}
    	// foreach(t: toks) t.print(new_line: true);

    	att_cnt++;
	}

	// test::eq(t.type, TokenType.EOF);
	// test::eq(4, att_cnt);
}

fn void test_escape_chars() {
    String contents = `'\n'`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::eq(2, toks.len());
	test::eq(toks[0].type, TokenType.CHAR_LITERAL);
	test::eq(toks[0].value, `'\n'`);
}

fn void test_escape_chars_single_quote() {
    String contents = `'\''`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(2, toks.len());
	test::eq(toks[0].type, TokenType.CHAR_LITERAL);
	test::eq(toks[0].value, `'\''`);
}


fn void test_escape_chars_double_backslash() {
    String contents = `'\\'`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(2, toks.len());
	test::eq(toks[0].type, TokenType.CHAR_LITERAL);
	test::eq(toks[0].value, `'\\'`);
}

fn void test_multiline_comment_with_many_stars() {
    String contents = `module /******** asda **********/`;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::eq(toks[1].value, `/******** asda **********/`);

	test::eq(toks[2].type, TokenType.EOF);
}

fn void test_multiline_comment_with_many_stars_multi_line() {
    String contents = `module 
    /**
    * asda 
    */;`;
	Lexer lexer;
	lexer::init(&lexer, contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI);
	test::eq(toks[1].value, `/**
    * asda 
    */`);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[3].type, TokenType.EOF);
}

fn void test_multiline_comment_with_many_stars_multi_line_endof_line() {
    String contents = `module 
    /**
    * asda 
    */
    ;
    `;
	Lexer lexer;
	lexer::init(&lexer, contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(4, toks.len());
	test::eq(toks[0].type, TokenType.MODULE);

	test::eq(toks[1].type, TokenType.COMMENT_MULTI);
	test::eq(toks[1].value, `/**
    * asda 
    */`);

	test::eq(toks[2].type, TokenType.EOS);
	test::eq(toks[3].type, TokenType.EOF);
}

fn void test_whitespace_mode() {
    String contents = " \t\fmodule\r\n\t  ;";
	Lexer lexer;
	lexer::init(&lexer, contents);
	lexer.set_whitespace_mode(true);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: true);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(10, toks.len());
	test::eq(toks[0].type, TokenType.SPACE);
	test::eq(toks[0].value, " ");

	test::eq(toks[1].type, TokenType.SPACE);
	test::eq(toks[1].value, "\t");

	test::eq(toks[2].type, TokenType.SPACE);
	test::eq(toks[2].value, "\f");

	test::eq(toks[3].type, TokenType.MODULE);
	test::eq(toks[3].value, "module");

	test::eq(toks[4].type, TokenType.SPACE);
	test::eq(toks[4].value, "\n");

	test::eq(toks[5].type, TokenType.SPACE);
	test::eq(toks[5].value, "\t");

	test::eq(toks[6].type, TokenType.SPACE);
	test::eq(toks[6].value, " ");

	test::eq(toks[7].type, TokenType.SPACE);
	test::eq(toks[7].value, " ");


	test::eq(toks[8].type, TokenType.EOS);
	test::eq(toks[9].type, TokenType.EOF);
}

fn void test_comments_with_whitespace_mode(){
    String contents = "\n // foo;\nreturn;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	lexer.set_whitespace_mode(true);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: false);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(7, toks.len());
	test::eq(toks[0].type, TokenType.SPACE);
	test::eq(toks[1].type, TokenType.SPACE);
	test::eq(toks[2].type, TokenType.COMMENT_SINGLE);
	test::eq(toks[3].type, TokenType.SPACE);
	test::eq(toks[4].type, TokenType.RETURN);
	test::eq(toks[5].type, TokenType.EOS);
	test::eq(toks[6].type, TokenType.EOF);
}

fn void test_comments_multiline_with_whitespace_mode(){
    String contents = " /* foo;*/\n;";
	Lexer lexer;
	lexer::init(&lexer,contents);
	lexer.set_whitespace_mode(true);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();
    // foreach(t: toks) t.print(new_line: false);
    foreach(i, t: toks) io::printf("%d: %s", i, t);

	test::eq(5, toks.len());
	test::eq(toks[0].type, TokenType.SPACE);
	test::eq(toks[0].value, " ");

	test::eq(toks[1].type, TokenType.COMMENT_MULTI_INLINE);
	test::eq(toks[1].value, "/* foo;*/");

	test::eq(toks[2].type, TokenType.SPACE);
	test::eq(toks[2].value, "\n");

	test::eq(toks[3].type, TokenType.EOS);
	test::eq(toks[4].type, TokenType.EOF);
}

fn void test_simple_docstring_space_at_contr() {
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
	test::eq(14, toks.len());
	test::eq(toks[0].type, TokenType.DOCS_START);
	test::eq(toks[0].value, "<*\nSome text\n");

	test::eq(toks[1].type, TokenType.AT_IDENT);
	test::eq(toks[1].value, "@param");

	test::eq(toks[2].type, TokenType.IDENT);
	test::eq(toks[2].value, "foo");

	test::eq(toks[3].type, TokenType.STRING);
	test::eq(toks[3].value, `"asdlkj"`);

	test::eq(toks[4].type, TokenType.DOCS_EOL);
	test::eq(toks[4].value, "\n");

	test::eq(toks[5].type, TokenType.AT_IDENT);
	test::eq(toks[5].value, "@pure");

	test::eq(toks[6].type, TokenType.DOCS_EOL);
	test::eq(toks[6].value, "\n");

	test::eq(toks[7].type, TokenType.AT_IDENT);
	test::eq(toks[7].value, "@require");

	test::eq(toks[8].type, TokenType.IDENT);
	test::eq(toks[8].value, "foo");

	test::eq(toks[9].type, TokenType.GREATER);
	test::eq(toks[9].value, ">");

	test::eq(toks[10].type, TokenType.INTEGER);
	test::eq(toks[10].value, "0");

	test::eq(toks[11].type, TokenType.DOCS_EOL);

	test::eq(toks[12].type, TokenType.DOCS_END);
	test::eq(toks[12].value, "*>");

	test::eq(toks[13].type, TokenType.EOF);
}

fn void test_simple_docstring_empty() {
    String contents = `
<**>
    `;
	Lexer lexer;
	lexer::init(&lexer,contents);
	List(<lexer::Token>) toks = lexer.new_parse_tokens();
	defer toks.free();

    // foreach(t: toks) t.print(new_line: true);
    // foreach(i, t: toks) io::printf("%d: %s", i, t);

    // module IDENT[foo] ; EOF
	test::eq(3, toks.len());
	test::eq(toks[0].type, TokenType.DOCS_START);
	test::eq(toks[0].value, "<*");

	test::eq(toks[1].type, TokenType.DOCS_END);
	test::eq(toks[1].value, "*>");

	test::eq(toks[2].type, TokenType.EOF);
}
