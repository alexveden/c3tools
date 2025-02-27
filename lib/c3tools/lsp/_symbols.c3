module c3tools::lsp::symbols;
import std::io;
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
    uint names_cnt;
    uint names_capacity;
    // we have about 32-4-4-4-4=16 bytes here for other stuff
}

// cacheline aligned
$assert(SymbolCache.sizeof == 32);

struct SymbolItem @align(32)
{
    Fnv32a hash;  // item hash, based on its name
    Fnv32a module_hash;  // module hash where symbol is defined

    bitstruct : ulong
    {
        uint name_offset : 0..31;  // from the beginning of SymbolCache.data
        SymbolKind kind : 32..39;  // kind of the symbol
        bool is_private : 40..40;  // symbol contains @private attribute
        bool is_conditional : 41..41;  // symbol contains @if() attribute
    }

    union ptr
    {
        AstTypeDef* type;  // can be used for keywords/builtins
        AstModule* mod;  // used for global module index
    }

    // next child of the base type (e.g. struct members implementation)
    SymbolItem* next;
}

$assert(SymbolItem.sizeof == 32);

fn SymbolCache* SymbolCache.new_init(uint capacity) @operator(construct)
{
    // NOTE: adding extra +1 to capacity for sentinel record
    usz data_size = calc_data_size(capacity + 1);
    SymbolCache* self = mem::calloc_aligned(data_size, SymbolCache.alignof);

    self.names_capacity = CHARS_PER_SYMBOL * capacity;
    self.items_capacity = capacity;

    SymbolItem* items = self.items();
    assert((usz)items % SymbolItem.alignof == 0, "bad alignment");

    // Sentinel record will have largest hash
    mem::set(&items[capacity], 0xFF, SymbolItem.sizeof, SymbolItem.alignof);

    // guard byte for strings
    ((char*)self)[data_size - 1] = 0xF0;

    return self;
}

fn SymbolCache* SymbolCache.free(&self)
{
    mem::free_aligned(self);
    return null;
}

macro uint SymbolCache.len(&self) => self.items_len;

<*
 Finds first SymbolItem* in SymbolCache with the same hash as name_or_hash,
 this method is expected to be used in a loop with SymbolCache.next() for checking all collisions.

 @param name_or_hash "Fnv32a hash or String name"
*>
macro SymbolItem* SymbolCache.first(&self, name_or_hash)
{
    Fnv32a hash;
    $switch ($typeof(name_or_hash))
        $case String:
            hash.init();
            hash.update(name_or_hash);
        $case Fnv32a:
            hash = name_or_hash;
        $default:
            $error("expected String name or Fnv32a hash");
    $endswitch

    SymbolItem* items = self.items();
    uint pos = self._find_insert_position(hash);
    if (pos == self.items_len || items[pos].hash != hash) return null;

    return &items[pos];
}

<*
 Returns next item with hash collision (if any)

 @param [in] item "Item returned by previous SymbolCache.find()"
 @return "next item or null if not exist"
 @require item != null
*>
macro SymbolItem* SymbolCache.next(&self, SymbolItem* item)
{
    SymbolItem* next = item + 1;
    return (item.hash == next.hash) ? next : null;
}

<*
 Adds new SymbolItem* by name and return its pointer for further initialization 
 NOTE: hash and name will be set, you should take care of other fields

 @ensure return != null
*>
fn SymbolItem* SymbolCache.add(&self, String name)
{
    assert(self.items_len < self.items_capacity, "overflow, you must grow SymbolCache");

    SymbolItem* items = self.items();

    Fnv32a hash;
    hash.init();
    hash.update(name);

    uint pos = self._find_insert_position(hash);
    SymbolItem* it = self._insert_item(hash, pos);

    uint name_offset = 0;

    // try to reuse existing name (this also maintains unique records of names)
    for (uint i = pos; i < self.items_len && items[i].hash == hash; i++) {
        if (&items[i] == it) continue;

        if (self.get_name(&items[i]) == name) {
            name_offset = items[i].name_offset;
            break;
        }
    }

    if (name_offset == 0) {
        // new name, adding one
        name_offset = self._insert_name(name);
    }
    assert(name_offset > 0);
    assert(name_offset < self.names_capacity);

    it.name_offset = name_offset;

    return it;
}

<*
 Returns a SymbolItem string name
*>
macro String SymbolCache.get_name(&self, SymbolItem* item)
{
    assert(item.name_offset > 0, "not intialized name?");

    char* name = self.strings() + item.name_offset;
    char len = *(name - 1);
    return (String)name[:len];
}

<*
 Growing SymbolCache to a new_capacity size.
 IMPORTANT: you must always replace your SymbolCache* pointer by return value of this function

 @require new_capacity > self.items_capacity
*>
fn SymbolCache* SymbolCache.grow(&self, uint new_capacity)
{
    usz old_data_size = calc_data_size(self.items_capacity + 1);
    usz old_names_capacity = self.names_capacity;
    usz old_items_capacity = self.items_capacity;

    // --- deal with new self / memory ---
    usz new_data_size = calc_data_size(new_capacity + 1);
    self = mem::realloc_aligned(self, new_data_size, SymbolCache.alignof);

    // cleanup newly allocated data
    mem::set((void*)self + old_data_size, 0, new_data_size - old_data_size);

    SymbolItem* items = self.items();

    // ensure sentinels are untouched
    assert(items[self.items_capacity].hash == (Fnv32a)uint.max, "malformed sentinel data");
    assert(((char*)self)[old_data_size - 1] == 0xF0, "malformed sentinel data");

    // reorganize data and expand
    ((char*)self)[old_data_size - 1] = 0;

    usz move_size = (new_capacity - old_items_capacity) * SymbolItem.sizeof;
    char* names = self.strings();
    mem::move(names + move_size, names, old_names_capacity);

    self.items_capacity = new_capacity;
    self.names_capacity = CHARS_PER_SYMBOL * new_capacity;

    // Force clean memory region which was previously allocated by names, and now it's for items
    for (usz i = old_items_capacity; i < self.items_capacity; i++) {
        items[i] = SymbolItem {};
    }

    // Restoring sentinel data for after growing
    mem::set(&items[new_capacity], 0xFF, SymbolItem.sizeof, SymbolItem.alignof);
    ((char*)self)[new_data_size - 1] = 0xF0;

    // IMPORTANT: realloc_aligned() may return new memory address (self may change!)
    return self;
}

struct SymbolNameIterator
{
    SymbolCache* cache;
    uint cursor;
    uint next_idx;
}

struct SymbolItemIterator
{
    SymbolCache* cache;
    uint cursor;
    uint next_idx;
}

macro SymbolNameIterator SymbolCache.iter_names(&self) => SymbolNameIterator { .cache = self };
macro SymbolItemIterator SymbolCache.iter_items(&self) => SymbolItemIterator { .cache = self };

macro usz SymbolNameIterator.len(self) @operator(len) => self.cache.names_cnt;
macro usz SymbolItemIterator.len(self) @operator(len) => self.cache.items_len;

macro String SymbolNameIterator.get(&self, usz idx) @operator([])
{
    assert(idx == self.next_idx);

    char* names = self.cache.strings();
    uint i = self.cursor;
    uint cnt = names[i];

    assert(cnt, "expected string len > 0");
    assert(names[i + 1 + cnt] == '\0', "no null terminator");

    self.cursor += cnt + 2;  // 2 extra bytes for len and \0
    self.next_idx++;
    return (String)(&names[i + 1])[:cnt];
}

macro SymbolItem* SymbolItemIterator.get(&self, usz idx) @operator(&[])
{
    assert(idx == self.next_idx);
    SymbolItem* items = self.cache.items();
    self.next_idx++;
    return &items[idx];
}

<*
 Checks if SymbolCache has space for adding a new symbol
*>
macro bool SymbolCache.has_capacity(&self, String symbol)
{
    assert(symbol.len > 0);
    assert(symbol.len < 255);
    return symbol.len + 3 < self.names_capacity && self.items_len < self.items_capacity;
}

macro SymbolItem* SymbolCache.items(&self)
{
    return (SymbolItem*)((char*)self + SymbolCache.sizeof);
}

macro char* SymbolCache.strings(&self)
{
    return ((char*)self)+SymbolCache.sizeof + SymbolItem.sizeof * (usz)(self.items_capacity + 1);
}

/*
*
*                  PRIVATE METHODS
*
*/

macro usz calc_data_size(uint capacity) @local
{
    assert(capacity > 0);
    assert(capacity < 1000000);
    assert(capacity * CHARS_PER_SYMBOL < 16777216);  // 2**24 - max bitstruct size for name_offset

    return (SymbolCache.sizeof + SymbolItem.sizeof * (usz)capacity + CHARS_PER_SYMBOL * capacity);
}

<*
 @ensure result < self.names_capacity
 @ensure result > 0
*>
macro uint SymbolCache._insert_name(&self, String name)
{
    assert(name.len > 0, "empty name not allowed");
    assert(name.len < 255, "name is too long");

    char* names = self.strings();

    assert(name[name.len - 1] != '\0');

    assert(name.len + 2 < self.names_capacity, "symbol name overflow");
    char* current = names + self.names_len;
    assert(current[0] == '\0');
    //L<string>\0
    //L - length of <string> (1 byte)
    //<string> - contents of name
    //\0 - null terminator (1 byte)
    current[0] = (char)name.len;
    mem::copy(&current[1], name.ptr, name.len);
    current[name.len + 1] = '\0';
    self.names_len += name.len + 2;
    self.names_cnt++;
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
    SymbolItem* items = self.items();

    if (self.items_len == 0) return 0;
    if (hash <= items[0].hash) return 0;
    if (hash > items[self.items_len - 1].hash) return self.items_len;

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
