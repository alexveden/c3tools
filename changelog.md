# C3 Tools Release Notes

`c3tools` project follows C3 version notation, which means tooling expected to be compatibe with the `c3c` of that version. 

## 0.6.8-1 Change list

### Changes / improvements
- `c3fzf` - first release

### Fixes
- `c3fmt` - added support of new C-style designated initializers `(Foo){.bar = 1, .baz = 2}`
- `c3fmt` - fixed formating of pointer arithmetic, e.g. `((char*)self) + SomeType.sizeof`
