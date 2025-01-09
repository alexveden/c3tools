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
    foreach(i, t: toks) io::printf("%d: %s", i, t);

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
