module c3tools::ast;
import c3tools::lexer @public;


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
            if (self.scope_depth >= self.scope_stack.len) return;
            self.scope_stack[self.scope_depth] = t;
            self.scope_depth++;
        //
        //  Exiting scope
        //  
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
    assert(self.current_state != INVALID_TOKEN, "missing initialization?");
    self.last_state = self.current_state;
    self.check_scope(t.type);
    return self.current_state;
}

macro void NodeParserState.transition(&self, TokenType new_state) {
    self.current_state = new_state;
}

macro bool NodeParserState.next(&self) {
    if(self.current_state != self.last_state) {
        self.last_state = self.current_state;
        return true;
    } else {
        return false;
    }
}


fn bool Ast.parse_module(&ast, AstNode* node, Token* t, NodeParserState* state) 
{
    assert(node.type == MODULE);
    AstModule* m = (AstModule*)node;

    
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(MODULE);
    }

    switch (state.check(t)){
        case MODULE:
            state.transition(IDENT);  // expecting module identifiers
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &m.name, t);
                case SCOPE:
                    break; // skipping ::
                case AT_IDENT:
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &m.attributes, t);
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;

        case EOS:
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
    AstImport* imp = (AstImport*)node;

    
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(IMPORT);
    } 

    switch (state.check(t)){
        case IMPORT:
            state.transition(IDENT);  // expecting module identifiers
        case IDENT:
            switch(t.type) {
                case IDENT:
                    ast.@allc_add(AstNode, &imp.name, t);
                case SCOPE:
                    break; // skipping ::
                case AT_IDENT:
                case EOS:
                    state.transition(t.type);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case AT_IDENT:
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &imp.attributes, t);
                case EOS:
                    state.transition(EOS);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;

        case EOS:
            imp.iend = t.offset + t.value.len;
            return true;
        default:
            break;
    }

    return false;
}

macro parse_callable_params(Ast* ast, Token* t, AstCallable* node_func, NodeParserState* state) @local  {
    AstCallableParam* current_param = state.sub_node ? (AstCallableParam*)state.sub_node : null;

    switch(t.type) {
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
                state.transition(AT_IDENT);
                state.sub_node = null;
            } else {
                nextcase default;
            }
        case IMPLIES:  // =>
            // one liner lambda function
            state.transition(IMPLIES);
            state.sub_node = null;
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

    
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(FN);
        node_func.iscope_start = t.offset;
    }

    switch (state.check(t)){
        case FN:
            // function starts with return type definition
            state.transition(RETURN);
        case RETURN:
            // function return type
            switch(t.type) {
                case AT_IDENT:
                    state.transition(IDENT);
                case DOT:
                    // macro MyType.test_macro() case
                    AstNode** last_rtype = &node_func.ret_type;
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
                    state.transition(IDENT);
                case TYPE_IDENT:
                case IDENT:
                    // function name, make a transition if no scope and ret_type is set
                    if (state.scope_depth == 0 && node_func.ret_type) {
                        state.transition(IDENT);
                    } else {
                        nextcase default;
                    }
                default:
                    ast.@allc_add(AstNode, &node_func.ret_type, t);
            }
            if(state.next()) nextcase state.current_state;
        case IDENT:
            // function name 
            switch(t.type) {
                case AT_IDENT:
                case IDENT:
                case TYPE_IDENT:
                    // struct based functions may contain TypeName.func_name
                    ast.@allc_add(AstNode, &node_func.name, t);
                case LPAREN:
                    if(state.scope_depth == 1) state.transition(VAR);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case VAR:
            parse_callable_params(ast, t, node_func, state);
            // Defining function arguments
            if(state.next()) nextcase state.current_state;

        case AT_IDENT: // regular function attributes
            switch(t.type) {
                case AT_IDENT:
                    ast.lexer.extend_current_attribute();
                    ast.@allc_add(AstNode, &node_func.attributes, t);
                case IMPLIES:           // => 
                    state.transition(IMPLIES);
                case LBRACE:           // {
                    if (state.scope_depth == 1) state.transition(SCOPE);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    if (state.scope_depth == 1) {
                        node_func.iscope_start = t.offset;
                    }
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) state.transition(EOF);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case IMPLIES:  // lambda function fn () => ... @attr;
            switch(t.type) {
                case IMPLIES:           // => 
                    node_func.iscope_start = t.offset;
                case EOS:           // ending semicolon
                    if (state.scope_depth == 0) state.transition(EOF);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case EOF:
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
    

    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(DOCS_START);
    }

    switch (state.check(t)){
        case DOCS_START:
            switch(t.type) {
                case DOCS_END:
                    state.transition(DOCS_END);
                case AT_IDENT:
                    state.transition(AT_IDENT);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
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
                    state.transition(DOCS_END);
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
            if(state.next()) nextcase state.current_state;
        case DOCS_END:
            doc.iend = t.offset + t.value.len - 1;
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

    
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(ENUM);
    }


    switch (state.check(t)){
        case ENUM:
            state.transition(IDENT);
        case IDENT:
            switch(t.type) {
                case TYPE_IDENT:
                    if (!node_enum.name) node_enum.name = ast.@allc_str(t.value);
                case LBRACE:
                    if(state.scope_depth == 1) state.transition(SCOPE);
                case AT_IDENT:
                    if(state.scope_depth == 0) state.transition(AT_IDENT);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case AT_IDENT: // regular function attributes
            switch(t.type) {
                case AT_IDENT:
                    if(state.scope_depth == 0) {
                        ast.lexer.extend_current_attribute();
                        ast.@allc_add(AstNode, &node_enum.attributes, t);
                    }
                case LBRACE:           // {
                    if (state.scope_depth == 1) state.transition(SCOPE);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    break;
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) state.transition(EOF);
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
            if(state.next()) nextcase state.current_state;
        case EOF:
            node_enum.iend = t.offset;
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

    
    if(state.current_state == INVALID_TOKEN) {
        // Just newly created, initialize parser state
        state.transition(INTERFACE);
    }


    switch (state.check(t)){
        case INTERFACE:
            state.transition(TYPE_IDENT);
        case TYPE_IDENT:
            switch(t.type) {
                case TYPE_IDENT:
                    if (!node_ifc.name) node_ifc.name = ast.@allc_str(t.value);
                case AT_IDENT:
                    if(state.scope_depth == 0) {
                        ast.lexer.extend_current_attribute();
                        ast.@allc_add(AstNode, &node_ifc.attributes, t);
                    }
                case LBRACE:
                    if(state.scope_depth == 1) state.transition(SCOPE);
                default:
                    break;
            }
            if(state.next()) nextcase state.current_state;
        case SCOPE: // regular function scope { ... }
            switch(t.type) {
                case LBRACE:           // {
                    break;
                case RBRACE:           // ending brace
                    if (state.scope_depth == 0) state.transition(EOF);
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
            if(state.next()) nextcase state.current_state;
        case EOF:
            node_ifc.iend = t.offset;
            return true;
        default:
            unreachable();
            // return false; //
    }

    return false;
}
