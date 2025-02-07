# c3tools helper scripts

* `c3fmt_gentests.c3` - test corpus generation script uses `../test/c3tools/codefmt/c3fmt_corpus/*.txt` files and generates c3 unit test file for `c3fmt`
* `c3fmt_c3c_test_suite.sh` - runs `c3fmt` on full c3c `test_suite/**/*.c3t` files in order to check that c3fmt doesn't return errors on valid code and formatted code still compiles without errors
