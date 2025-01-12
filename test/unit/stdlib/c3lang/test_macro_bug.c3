module macro_ast_test @test;
/*

struct AstNode {
    uint a;
    AstNode* next;
}
struct Foo {
    inline AstNode* n;
}
struct Bar {
    Foo* modules;
}

macro AstNode* AstNode.@node_add(#self, AstNode* new) @local 
{
    if (#self == null) {
        (#self) = new;
    } else {
        AstNode* node = #self.next;
        while(node.next) {
            node = node.next;            
        }
        node.next = new;
    }
    return new;
}
fn void test_ok_cool() {
    AstNode* node = null;

    AstNode n1 = {.a = 1};
    Bar bar = {.modules = null};

    // AstNode* pnode = bar.modules.@node_add(&n1);
    AstNode* pnode = AstNode.@node_add((AstNode*)bar.modules, &n1);

    assert(bar.modules != null);
}
<*
asdoi
@param collection `any collection`
*>
macro AstNode* @node_add_wrong(AstNode* collection, AstNode* new) @local
{    
    return collection.@node_add(new);
} 


fn void test_ok() {
    AstNode n1 = {.a = 1};
    AstNode n2 = {.a = 2};

    AstNode* node = null;

    AstNode* pnode = node.@node_add(&n1);
    assert(node != null);
    assert(node == &n1);
    assert(node.next == null);
    assert(node.a == 1);
}



fn void test_fails() {
    AstNode n1 = {.a = 1};
    AstNode n2 = {.a = 2};

    AstNode* node = null;

    AstNode* pnode = @node_add_wrong(node, &n1);

    // No compilation errors, test runs but fails to set node
    assert(node != null);
    assert(node == &n1);
    assert(node.next == null);
}
*/
