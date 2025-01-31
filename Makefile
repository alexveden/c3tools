.PHONY: test test-all clean all

all:
	c3c --trust=full build c3ast
	c3c --trust=full build c3fzf

test-all:
	c3c --trust=full test -- -c 

test:
	c3c --trust=full test -- --no-sort -c -f $(t) 

test-debug:
	c3c --trust=full test -- --no-sort -c -f $(t) || echo "Test failed"
	../gf/gf2 --args ./build/testrun --no-sort -c -b -f $(t)
