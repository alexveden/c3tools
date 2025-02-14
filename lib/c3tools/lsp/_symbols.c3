module c3tools::lsp::symbols;
import std::hash::fnv32a;
import std::math;
import c3tools::ast;

const usz CHARS_PER_SYMBOL = 32;

//    SymbolCache memory alignment
//  [SymbolCache struct (header)]
//  [>>> SymbolItems array (ordered by SymbolItem.hash) ---]
//    [SymbolItem hash: 1]
//    [SymbolItem hash: 311]
//    [SymbolItem hash: 511]
//  [<<<<]
//  [>>> char blob with following sequence of bytes -- ]
//    [1byte-len][string]\0
//    [1byte-len][string]\0
//  [<<<<]
//
struct SymbolCache @align(32)
{
    uint items_len;
    uint items_capacity;
    uint names_len;
    uint names_capacity;
    // we have about 32-4-4-4-4=16 bytes here for other stuff
}

// cacheline aligned
$assert(SymbolCache.sizeof == 32);

struct SymbolItem @align(16)
{
    Fnv32a hash;  // item hash, based on its name

    bitstruct : uint
    {
        SymbolKind kind : 0..7;  // kind of the symbol
        uint name_offset : 8..31;  // from the beginning of SymbolCache.data
    }

    union ptr
    {
        AstTypeDef* type;  // can be used for keywords/builtins
        AstModule* mod;  // used for global module index
        Fnv32a module_hash;  // module hash of parent of the symbol
    }

}

// 1/4 of cacheline!
$assert(SymbolItem.sizeof == 16);

fn int cmp_symbol(SymbolItem* a, SymbolItem* b) @private
{
    assert(a.hash != 0);
    assert(b.hash != 0);
    if (a.hash < b.hash) return -1;
    if (a.hash > b.hash) return 1;
    return 0;
}

macro usz calc_data_size(uint capacity) @local
{
    return (SymbolCache.sizeof + SymbolItem.sizeof * (usz)capacity + CHARS_PER_SYMBOL * capacity);
}

fn SymbolCache* SymbolCache.new_init(uint capacity) @operator(construct)
{
    assert(capacity > 0);
    assert(capacity < 1000000);

    // NOTE: adding extra +1 to capacity for sentinel record
    SymbolCache* self = mem::calloc_aligned(calc_data_size(capacity + 1), SymbolCache.alignof);

    self.names_capacity = CHARS_PER_SYMBOL * capacity;
    self.items_capacity = capacity;

    SymbolItem* items = self.items();
    assert((usz)items % SymbolItem.alignof == 0, "bad alignment");

    // Sentinel record will have largest hash
    mem::set(&items[capacity], 0xFF, SymbolItem.sizeof, SymbolItem.alignof);

    return self;
}

macro String SymbolCache.item_name(&self, SymbolItem* item)
{
    assert(item.name_offset > 0, "not intialized name?");

    char* name = self.strings() + item.name_offset;
    char len = *(name - 1);
    return (String)name[:len];
}

fn SymbolItem* SymbolCache.item_add(&self, String name)
{
    assert(self.items_len < self.items_capacity, "overflow, you must grow SymbolCache");

    SymbolItem* items = self.items();

    Fnv32a hash;
    hash.init();
    hash.update(name);

    uint pos = self._find_insert_position(hash);
    SymbolItem* it = self._insert_item(hash, pos);

    uint name_offset = 0;

    // try to reuse existing name
    for (uint i = pos; i < self.items_len && items[i].hash == hash; i++) {
        if (&items[i] == it) continue;

        if (self.item_name(&items[i]) == name) {
            name_offset = items[i].name_offset;
            break;
        }
    }

    if (name_offset == 0) {
        // new name, adding one
        name_offset = self._insert_name(name);
    }
    assert(name_offset > 0);

    it.name_offset = name_offset;

    return it;
}

macro uint SymbolCache._insert_name(&self, String name)
{
    assert(name.len > 0, "empty name not allowed");
    assert(name.len < 255, "name is too long");

    char* names = self.strings();

    assert(name.len + 2 < self.names_capacity, "symbol name overflow");
    char* current = names + self.names_len;
    //L<string>\0
    //L - length of <string> (1 byte)
    //<string> - contents of name
    //\0 - null terminator (1 byte)
    current[0] = (char)name.len;
    mem::copy(&current[1], name.ptr, name.len);
    current[name.len + 1] = '\0';
    self.names_len += name.len + 2;
    return (uint)(&current[1] - names);
}

macro SymbolItem* SymbolCache._insert_item(&self, Fnv32a hash, uint insert_at) @private
{
    assert(insert_at <= self.items_len);
    assert(hash > (Fnv32a)0);
    assert(self.items_len < self.items_capacity, "overflow, you must grow SymbolCache");

    SymbolItem* items = self.items();
    self.items_len++;

    for (int i = self.items_len - 1; i > insert_at; i--) {
        items[i] = items[i - 1];
    }
    items[insert_at] = SymbolItem { .hash = hash };
    return &items[insert_at];
}

fn uint SymbolCache._find_insert_position(&self, Fnv32a hash) @private
{
    if (self.items_len == 0) return 0;

    SymbolItem* items = self.items();

    if (hash <= items[0].hash) return 0;
    if (hash > items[self.items_len -1].hash) return self.items_len;

    // finding insert position
    uint lo = 0;
    uint hi = self.items_len;
    while (lo < hi) {
        uint mid = (lo + hi) / 2;
        if (hash < items[mid].hash) {
            hi = mid;
        } else {
            lo = mid + 1;
        }
    }
    uint pos = lo;
    // scroll up at the beginning of the same hash cluster
    // this allow us to loop through all hash collisions later
    while (pos > 0 && items[pos - 1].hash == hash) {
        pos--;
    }
    assert(pos <= self.items_len, "pos out of bounds");
    assert(hash >= items[pos - 1].hash, "pos left side unsorted");
    assert(pos == self.items_len - 1 || hash <= items[pos + 1].hash, "pos right side unsorted");
    assert(pos == 0 || items[pos - 1].hash < hash, "we must be at the start of hash cluster");

    return pos;
}

fn SymbolCache* SymbolCache.free(&self)
{
    mem::free_aligned(self);
    return null;
}

macro SymbolItem* SymbolCache.items(&self)
{
    return (SymbolItem*)((char*)self + SymbolCache.sizeof);
}

macro char* SymbolCache.strings(&self)
{
    return ((char*)self)+SymbolCache.sizeof + SymbolItem.sizeof * (usz)(self.items_capacity + 1);
}
