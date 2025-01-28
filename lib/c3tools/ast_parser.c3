module c3tools::ast;
import std::io;
import c3tools::lexer @public;

<* 
Returns TokenType of current scope 

@param offset "1 - last, 2 - last-2, etc.."
@return "current scope, or INVALID_TOKEN if offset if too high or no scope at all"
@require offset > 0
*>
macro TokenType NodeParserState.prev_scope(&self, usz offset) {
    if (self.scope_depth < offset) return INVALID_TOKEN;
    return self.scope_stack[self.scope_depth-offset];
}

macro NodeParserState.check_scope(&self, TokenType t) {

    switch(t){
        //
        //  Entering new scope
        //  
        case LBRACE:           // {
        case LBRACKET:         // [
        case LPAREN:           // (
        case LBRAPIPE:         // {|
        case LGENPAR:          // (<
        case LVEC:             // [<
        case DOCS_START:       // <*
	    // case CT_FOR:               // $for
	    // case CT_FOREACH:           // $foreach
	    // case CT_IF:                // $if
	    // case CT_SWITCH:            // $switch
            if (self.scope_depth >= self.scope_stack.len) return;
            self.scope_stack[self.scope_depth] = t;
            self.scope_depth++;
        //
        //  Exiting scope
        //  
        case CT_ENDIF:
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == CT_IF) nextcase EOF;
        case CT_ENDSWITCH:
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == CT_SWITCH) nextcase EOF;
        case CT_ENDFOR:
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == CT_FOR) nextcase EOF;
        case CT_ENDFOREACH:
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == CT_FOREACH) nextcase EOF;
        case RBRACE:           // }
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRACE) nextcase EOF;
        case RBRACKET:         // ]
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRACKET) nextcase EOF;
        case RPAREN:           // )
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LPAREN) nextcase EOF;
        case RBRAPIPE:         // |}
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LBRAPIPE) nextcase EOF;
        case RGENPAR:          // >)
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LGENPAR) nextcase EOF;
        case RVEC:             // >)
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == LVEC) nextcase EOF;
        case DOCS_END:             // *>
            if (self.scope_depth == 0) nextcase default;
            if (self.scope_stack[self.scope_depth-1] == DOCS_START) nextcase EOF;
        case EOF:             
            // synthetic action to unscope stack
            if (self.scope_depth == 0) nextcase default;
            self.scope_stack[self.scope_depth-1] = INVALID_TOKEN;
            self.scope_depth--;
        default:
            break;
    }

}

macro TokenType NodeParserState.check(&self, Token* t) {
    // assert(self.current_state != INVALID_TOKEN, "missing initialization?");
    self.last_token = self.current_token;
    self.current_token = t.type;
    self.check_scope(t.type);
    return self.current_state;
}

macro TokenType NodeParserState.transition(&self, TokenType new_state) {
    self.current_state = new_state;
    return new_state;
}

fn bool Ast.parse_module(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == MODULE);
    AstModule* m = (AstModule*)node;

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            state.transition(IDENT);  // expecting module identifiers
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &m.name, t);
                case SCOPE:
                    break; // skipping ::
                case AT_IDENT:
                case EOS:
                    nextcase STATE: state.transition(t.type);
                default:
                    break;
            }
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &m.attributes, t);
                case EOS:
                    nextcase STATE: state.transition(t.type);
                default:
                    break;
            }

        case EOS:
            ast.state_stack.remove_last();
            m.iend = t.offset + t.value.len;
            return true;
        default:
            break;
    }

    return false;
}

fn bool Ast.parse_import(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == IMPORT);
    AstImport* imp = (AstImport*)ast::@node_last(node);

    
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            state.transition(IDENT);  // expecting module identifiers
        case COMMA:
            Token ptok = {
                .type = TokenType.IMPORT,
                .value = "import",
                .row = t.row,
                .col = t.col,
                .offset = t.offset,
            };
            ast.@allc_add(AstImport, &imp.next, &ptok);
            state.transition(IDENT);
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &imp.name, t);
                case SCOPE:
                    break; // skipping ::
                case AT_IDENT:
                case EOS:
                    nextcase STATE: state.transition(t.type);
                case COMMA:
                    nextcase STATE: state.transition(COMMA);
                default:
                    break;
            }
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &imp.attributes, t);
                case EOS:
                    nextcase STATE: state.transition(EOS);
                case COMMA:
                    nextcase STATE: state.transition(COMMA);
                default:
                    break;
            }
        case EOS:
            ast.state_stack.remove_last();
            imp.iend = t.offset + t.value.len;
            return true;
        default:
            break;
    }

    return false;
}

macro parse_callable_params(Ast* ast, Token* t, AstCallable* node_func, NodeParserState* state) @local  {
    AstCallableParam* current_param = state.sub_node ? (AstCallableParam*)state.sub_node : null;

    switch (t.type) {
        case LPAREN:
            // opening '(' or a part of type definition
            if (state.scope_depth != 1) nextcase default;
        case COMMA:
        case EOS:
            // next parameter
            if (state.scope_depth == 1 && current_param) {
                // Next parameter definition
                assert(current_param.type == TokenType.VAR);
                current_param = (AstCallableParam*)ast.@allc_add(AstCallableParam, &node_func.params, &ast.lexer.token); 
                current_param.value = "";
                current_param.type = TokenType.VAR;
                state.sub_node = current_param;
            } else {
                nextcase default;
            }
        case RPAREN:
            // Done with parameters, looking for AT_IDENT or SCOPE
            if (state.scope_depth == 0) {
                state.sub_node = null;
                state.transition(AT_IDENT);
            } else {
                nextcase default;
            }
        case IMPLIES:  // =>
            // one liner lambda function
            state.sub_node = null;
            state.transition(IMPLIES);
        case COMMENT_SINGLE_INLINE:
        case COMMENT_SINGLE:
        case COMMENT_MULTI:
        case EMPTY_LINE:
        case AMP:  // & in parameters, i.e. &self case, it's safe to ignore
        case COMMENT_MULTI_INLINE:
            break;
        case TYPE_IDENT:
        case IDENT:
        case HASH_IDENT:
        case CT_IDENT:
            if (state.sub_node == null) {
                current_param = (AstCallableParam*)ast.@allc_add(AstCallableParam, &node_func.params, &ast.lexer.token); 
                current_param.value = "";
                current_param.type = TokenType.VAR;
                state.sub_node = current_param;
            }
            if (!current_param.value && t.type != TYPE_IDENT)
            {
                if (node_func.name && node_func.name.next && !node_func.params.next) {
                    // If it's a first parameter without type and signatue is MyType.my_func()
                    // set it as a method `self` to MyType
                    Token ptok = {
                        .type = TokenType.TYPE_IDENT,
                        .value = node_func.name.value,
                        .row = t.row,
                        .col = t.col,
                        .offset = t.offset,
                    };
                    ast.@allc_add(AstNode, &current_param.param_type, &ptok);
                }
                current_param.value = ast.@allc_str(t.value);
            } else {
                nextcase default;
            }
        case AT_IDENT:
            if (current_param) {
                if(current_param.value){
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &current_param.attributes, t);
                } else {
                    // macro @for_each(list; @body(it))
                    current_param.value = ast.@allc_str(t.value);
                }
            }
        default:
            // all other goes to type
            if (current_param) {
                ast.@allc_add(AstNode, &current_param.param_type, t);
            }
    }
}

// fn bool osldfkjslf(int self, int b @used) {
//     return true;
// }

fn bool Ast.parse_function(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == FN || node.type == MACRO);
    AstCallable* node_func = (AstCallable*)node;

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            node_func.iscope_start = t.offset;
            state.transition(RETURN);
        case RETURN:
            // function return type
            switch(t.type) {
                case AT_IDENT:
                    nextcase STATE: state.transition(IDENT);
                case DOT:
                    // macro MyType.test_macro() case
                    AstNode** last_rtype = &node_func.ftype;
                    while(*last_rtype) {
                        if(!last_rtype[0].next) {
                            assert(node_func.name == null);
                            if(last_rtype[0].type == TYPE_IDENT) {
                                // attaching the func name to the last ret type node
                                node_func.name = *last_rtype;                            
                                // no return type anymore
                                last_rtype[0] = null;
                            }
                            break;
                        } 
                        last_rtype = &last_rtype[0].next;
                    }
                    nextcase STATE: state.transition(IDENT);
                case IDENT:
                    if (state.scope_depth == 0) nextcase STATE: state.transition(IDENT);
                case TYPE_IDENT:
                    // function name, make a transition if no scope and ret_type is set
                    if (state.scope_depth == 0 && node_func.ftype) {
                        nextcase STATE: state.transition(IDENT);
                    } else {
                        nextcase default;
                    }
                default:
                    ast.@allc_add(AstNode, &node_func.ftype, t);
            }
        case IDENT:
            // function name 
            switch(t.type) {
                case AT_IDENT:
                case IDENT:
                case TYPE_IDENT:
                    // struct based functions may contain TypeName.func_name
                    ast.@allc_add(AstNode, &node_func.name, t);
                case LPAREN:
                    if(state.scope_depth == 1) {
		                DString fname = dstring::temp_new();
		                node_func.value = ast.@allc_str(ast.@node_join(node_func.name, fname, "."));
                        nextcase STATE: state.transition(VAR);
                    }
                default:
                    break;
            }
        case VAR:
            // Defining function arguments
            parse_callable_params(ast, t, node_func, state);

        case AT_IDENT: // regular function attributes
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &node_func.attributes, t);
                case IMPLIES:           // => 
                    nextcase STATE: state.transition(IMPLIES);
                case LBRACE:           // {
                    if (state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    if (state.scope_depth == 1) {
                        node_func.iscope_start = t.offset;
                    }
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
                default:
                    break;
            }
        case IMPLIES:  // lambda function fn () => ... @attr;
            switch(t.type) {
                case IMPLIES:           // => 
                    node_func.iscope_start = t.offset;
                case EOS:           // ending semicolon
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
                default:
                    break;
            }
        case EOF:
            ast.state_stack.remove_last();
            node_func.iend = t.offset;
            return true;
        default:
            unreachable();
    }

    return false;
}

fn bool Ast.parse_docstring(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == DOCS_START);
    AstDoc* doc = (AstDoc*)node;
    
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            nextcase STATE: state.transition(DOCS_START);
        case DOCS_START:
            switch(t.type) {
                case DOCS_END:
                    nextcase STATE: state.transition(DOCS_END);
                case AT_IDENT:
                    nextcase STATE: state.transition(AT_IDENT);
                default:
                    break;
            }
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    if (state.sub_node == null) {
                        // add new contract, otherwise malformed contract or something
                        state.sub_node = ast.@allc_add(AstDocContract, &doc.contracts, &ast.lexer.token); 
                    }
                case DOCS_EOL:
                    state.sub_node = null;
                case DOCS_END:
                    nextcase STATE: state.transition(DOCS_END);
                default:
                    assert(state.sub_node != null);
                    AstDocContract* contract = (AstDocContract*)state.sub_node;
                    if (contract.value == "@param") {
                        // excluding [&inout] shit
                        if(state.scope_depth == 1 && t.type != RBRACKET) {
                            ast.@allc_add(AstNode, &contract.items, &ast.lexer.token); 
                        }
                    } else {
                        ast.@allc_add(AstNode, &contract.items, &ast.lexer.token); 
                    }
                    break;
            }
        case DOCS_END:
            doc.iend = t.offset + t.value.len - 1;
            ast.state_stack.remove_last();
            return true;
        default:
            break;
    }

    return false;
}

fn bool Ast.parse_enumerable(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == ENUM || node.type == FAULT);
    AstTypeDefEnumerable* node_enum = (AstTypeDefEnumerable*)node;

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            node_enum.value = ""; // place for a type name
            state.transition(IDENT);
        case IDENT:
            switch(t.type) {
                case TYPE_IDENT:
                    if (!node_enum.value) node_enum.value = ast.@allc_str(t.value);
                case LBRACE:
                    if(state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                case AT_IDENT:
                    if(state.scope_depth == 0) nextcase STATE: state.transition(AT_IDENT);
                default:
                    break;
            }
        case AT_IDENT: // regular function attributes
            switch(t.type) {
                case AT_IDENT:
                    if(state.scope_depth == 0) {
                        ast.lexer.extend_current_attribute();
                        ast.@allc_add(AstNode, &node_enum.attributes, t);
                    }
                case LBRACE:           // {
                    if (state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    break;
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
                case CONST_IDENT:
                    if(state.scope_depth == 1 && !state.sub_node) {
                        state.sub_node = ast.@allc_add(AstNode, &node_enum.values, &ast.lexer.token); 
                    }
                case COMMA:
                    // next iterm resetting state
                    state.sub_node = null; 
                default:
                    break;
            }
        case EOF:
            node_enum.iend = t.offset;
            ast.state_stack.remove_last();
            return true;
        default:
            unreachable();
            // return false; //
    }

    return false;
}

fn bool Ast.parse_interface(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == INTERFACE);
    AstTypeDefInterface* node_ifc = (AstTypeDefInterface*)node;

    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            node_ifc.value = "";
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:
            switch(t.type) {
                case TYPE_IDENT:
                    if (!node_ifc.value) node_ifc.value = ast.@allc_str(t.value);
                case AT_IDENT:
                    if(state.scope_depth == 0) {
                        ast.lexer.extend_current_attribute();
                        ast.@allc_add(AstNode, &node_ifc.attributes, t);
                    }
                case LBRACE:
                    if(state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    break;
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
                case DOCS_START:
                    if(state.scope_depth == 2 && !state.sub_node) {
                        ast.@allc_add(AstDoc, &state.sub_node, &ast.lexer.token); 
                        ast.state_stack.push(NodeParserState{});
                        assert(state.sub_node.type == TokenType.DOCS_START);
                        ast.parse_docstring(state.sub_node, &ast.lexer.token, &ast.state_stack[1]);
                        assert(ast.state_stack.len() == 2);
                    }
                case FN:
                    if(state.scope_depth == 1) {
                        assert(!state.sub_node || state.sub_node.type == DOCS_START);

                        AstCallable* f = (AstCallable*)ast.@allc_add(AstCallable, &node_ifc.functions, &ast.lexer.token); 
                        f.docs = (AstDoc*)state.sub_node;

                        if(ast.state_stack.len() > 1) ast.state_stack.remove_last()!!;
                        ast.state_stack.push(NodeParserState{});

                        state.sub_node = f;
                        assert(state.sub_node.type == TokenType.FN);
                        assert(ast.state_stack.len() == 2);
                        ast.parse_function(state.sub_node, &ast.lexer.token, &ast.state_stack[1]);
                    }
                case EOS:
                    // ';' item resetting state, but skipping all the stuff in doc strings
                    if (state.scope_depth == 1) {
                        if(ast.state_stack.len() > 1) {
                            while(ast.state_stack.len() > 1) {
                                ast.state_stack.remove_last()!!;
                            }
                        }
                        state.sub_node = null; 
                    } 
                default:
                    if(!state.sub_node) break;
                    
                    if(state.sub_node.type == TokenType.FN) {
                        assert(ast.state_stack.len() == 2);
                        ast.parse_function(state.sub_node, &ast.lexer.token, &ast.state_stack[1]);
                    } else if(state.sub_node.type == TokenType.DOCS_START) {
                        assert(ast.state_stack.len() == 2);
                        ast.parse_docstring(state.sub_node, &ast.lexer.token, &ast.state_stack[1]);
                    }
            }
        case EOF:
            ast.state_stack.remove_last();
            node_ifc.iend = t.offset;
            return true;
        default:
            unreachable();
            // return false; //
    }

    return false;
}

fn bool Ast.parse_structural(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node);
    assert(node.type == STRUCT || node.type == UNION || node.type == BITSTRUCT);
    AstTypeDefStructural* node_struct = (AstTypeDefStructural*)node;
    
    switch STATE: (state.check(t)){
        case INVALID_TOKEN: // got struct keyword
            node_struct.value = "";
            state.transition(TYPE_IDENT);
        case TYPE_IDENT: // parse struct type and attributes
            switch(t.type) {
                case TYPE_IDENT:
                    if (!node_struct.value) node_struct.value = ast.@allc_str(t.value);
                case IDENT:
                    if(ast.state_stack.len() > 1) {
                        // sub-structs have IDENT instead of TYPE_IDENT!
                        if (!node_struct.value) node_struct.value = ast.@allc_str(t.value);
                    }
                case AT_IDENT:
                    if(state.scope_depth == 0) {
                        ast.lexer.extend_current_attribute();
                        ast.@allc_add(AstNode, &node_struct.attributes, t);
                    }
                case LBRACE:
                    if(state.scope_depth == 1) nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case DOCS_START:
            switch(t.type) {
                case DOCS_START:
                    assert(state.sub_node == null);
                    ast.@allc_add(AstDoc, &state.sub_node, &ast.lexer.token); 
                    nextcase default;
                case DOCS_END:
                    nextcase STATE: state.transition(SCOPE);
                default:
                    break;
            }
        case SCOPE: // struct scope, let's find any sub-structs or members
            switch(t.type) {
                case LBRACE:           // scope entry
                    break;

                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
            
                case UNION:
                case STRUCT:
                case BITSTRUCT:        // sub type member 
                    if (state.scope_depth == 1) nextcase STATE: state.transition(FOREACH);

                case INLINE:
                case TYPE_IDENT:
                    if (state.scope_depth != 1) break;
                    nextcase STATE: state.transition(VAR); // start parsing structure field

                case DOCS_START:
                    if (state.scope_depth != 2) break;
                    nextcase STATE: state.transition(DOCS_START); // docstrings for field

                default:
                    break;
            }
        case VAR: // found individual field start parsing it
            switch(t.type) {
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) nextcase STATE: state.transition(EOF);
                case INLINE:
                case TYPE_IDENT:
                    AstTypeDefStructural* s = (AstTypeDefStructural*)state.sub_node;
                    if(state.sub_node == null || state.sub_node.type == DOCS_START) {
                        // new field, state enter
                        s = (AstTypeDefStructural*)ast.@allc_add(
                                    AstTypeDefStructural, &node_struct.members, &ast.lexer.token); 

                        s.docs = (AstDoc*)state.sub_node;
                        if (t.type == TYPE_IDENT)  ast.@allc_add(AstNode, &s.ftype, t);
                        s.value = "";
                        state.sub_node = s;
                    } else {
                        // Adding to existing type field (e.g. generic List(<MyType>) )
                        ast.@allc_add(AstNode, &s.ftype, t);
                    }
                case IDENT:
                    assert(state.sub_node);
                    if(state.scope_depth != 1) break;
                    state.sub_node.value = ast.@allc_str(t.value);

                case AT_IDENT: // member level attributes
                    assert(state.sub_node);
                    if(state.scope_depth != 1) break;

                    switch(state.sub_node.type){
                        case INLINE:
                        case TYPE_IDENT:
                        case STRUCT:
                        case UNION:
                        case BITSTRUCT:
                            AstTypeDef* _type = (AstTypeDef*)state.sub_node;
                            ast.lexer.extend_current_attribute();
                            ast.@allc_add(AstNode, &_type.attributes, t);
                        default:
                            break;
                    }
                case EOS:           
                    // field was defined, try find next in SCOPE
                    state.sub_node = null;
                    nextcase STATE: state.transition(SCOPE);
                default:
                    assert(state.sub_node);
                    AstTypeDefStructural* s = (AstTypeDefStructural*)state.sub_node;
                    ast.@allc_add(AstNode, &s.ftype, t);
                    break;
            }
        case FOREACH: // parsing sub structs
            switch(t.type) {
                case STRUCT:
                case UNION:
                case BITSTRUCT:
                    if(state.sub_node == null || state.sub_node.type == DOCS_START) {
                        // adding only when where are no pending FOREACH parsers
                        AstTypeDefStructural* s = (AstTypeDefStructural*)ast.@allc_add(
                                    AstTypeDefStructural, &node_struct.members, &ast.lexer.token); 
                        s.docs = (AstDoc*)state.sub_node;
                        ast.state_stack.push(NodeParserState{});
                        state.sub_node = s;
                    }
                    nextcase default; // initialize processing substructure
                default:
                    assert(ast.state_stack.len() > 1);
                    assert(state.sub_node);
                    AstTypeDefStructural* s = (AstTypeDefStructural*)state.sub_node;
                    if(ast.parse_structural(ast.state_stack[^2].sub_node, &ast.lexer.token, &ast.state_stack[^1])){
                        // substructure stack was cleared at EOF, use last stack to change state
                        ast.state_stack[^1].sub_node = null;
                        ast.state_stack[^1].transition(SCOPE);
                    }
                    return false;
            }
        case EOF:
            ast.state_stack.remove_last();
            node_struct.iend = t.offset;
            return true;
        default:
            unreachable();
            // return false; //
    }

    return false;
}

fn bool Ast.parse_typedef(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == DEF || node.type == DISTINCT);
    AstTypeDef* node_typedef = (AstTypeDef*)node;
    
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            node_typedef.value = "";
            state.transition(IDENT);
        case IDENT:
            switch(t.type) {
                case AT_TYPE_IDENT:
                case TYPE_IDENT:
                    if (!node_typedef.value) node_typedef.value = ast.@allc_str(t.value);
                case IDENT:
                    if (!node_typedef.value) node_typedef.value = ast.@allc_str(t.value);
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &node_typedef.attributes, t);
                case EQ:
                    nextcase STATE: state.transition(TYPE_IDENT);
                case EOS:
                    nextcase STATE: state.transition(EOF);
                default:
                    break;
            }
        case TYPE_IDENT:
            switch(t.type) {
                case EQ:
                case INLINE:
                    break;
                case EOS:
                    nextcase STATE: state.transition(EOF);
                default:
                    ast.@allc_add(AstNode, &node_typedef.ftype, t);
            }

        case EOF:
            ast.state_stack.remove_last();
            node_typedef.iend = t.offset + t.value.len - 1;
            return true;
        default:
            break;
    }

    return false;
}

fn bool Ast.parse_constants(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == CONST);
    AstTypeDef* node_typedef = (AstTypeDef*)node;
    
    switch STATE: (state.check(t)){
        case INVALID_TOKEN:
            node_typedef.value = "";
            state.transition(IDENT);
        case IDENT:
            switch(t.type) {
                case CONST_IDENT:
                    if (!node_typedef.value) node_typedef.value = ast.@allc_str(t.value);
                case TYPE_IDENT:
                    ast.@allc_add(AstNode, &node_typedef.ftype, t);
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &node_typedef.attributes, t);
                case EQ:
                    nextcase STATE: state.transition(EOS);
                case EOS:
                    nextcase STATE: state.transition(EOF);
                default:
                    break;
            }
        case EOS:
            switch(t.type) {
                case EOS:
                    nextcase STATE: state.transition(EOF);
                default:
                    break;
            }
        case EOF:
            ast.state_stack.remove_last();
            node_typedef.iend = t.offset + t.value.len - 1;
            return true;
        default:
            break;
    }

    return false;
}
