module c3tools::utils_port;
// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Copyright (c) 2025 Alex Veden <i@alexveden.com>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.

macro bool char_is_lower(char c)
{
    return c >= 'a' && c <= 'z';
}

macro bool char_is_lower_(char c)
{
    return c == '_' || (c >= 'a' && c <= 'z');
}

macro bool char_is_upper(char c)
{
    return c >= 'A' && c <= 'Z';
}

macro bool char_is_oct(char c)
{
    return c >= '0' && c <= '7';
}

macro bool char_is_oct_or_(char c)
{
    return c == '_' || (c >= '0' && c <= '7');
}

macro bool char_is_binary(char c)
{
    return c == '0' || c == '1';
}

macro bool char_is_binary_or_(char c)
{
    return c == '0' || c == '1' || c == '_';
}

macro bool char_is_digit_or_(char c)
{
    return c == '_' || (c >= '0' && c <= '9');
}

macro bool char_is_digit(char c)
{
    return c >= '0' && c <= '9';
}

const char[256] HEX_CONV = {
    ['0'] = 1,
    ['1'] = 2,
    ['2'] = 3,
    ['3'] = 4,
    ['4'] = 5,
    ['5'] = 6,
    ['6'] = 7,
    ['7'] = 8,
    ['8'] = 9,
    ['9'] = 10,
    ['A'] = 11,
    ['B'] = 12,
    ['C'] = 13,
    ['D'] = 14,
    ['E'] = 15,
    ['F'] = 16,
    ['a'] = 11,
    ['b'] = 12,
    ['c'] = 13,
    ['d'] = 14,
    ['e'] = 15,
    ['f'] = 16,
};

macro int char_hex_to_nibble(char c)
{
    return HEX_CONV[c] - 1;
}

macro bool char_is_hex_or_(char c)
{
    switch (c) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case 'a':
        case 'b':
        case 'c':
        case 'd':
        case 'e':
        case 'f':
        case 'A':
        case 'B':
        case 'C':
        case 'D':
        case 'E':
        case 'F':
        case '_':
            return true;
        default:
            return false;
    }
}

macro ichar char_is_valid_escape(char c)
{
    switch (c) {
        case 'a':
            return '\a';
        case 'b':
            return '\b';
        case 'e':
            return 0x1B;
        case 'f':
            return '\f';
        case 'n':
            return '\n';
        case 'r':
            return '\r';
        case 't':
            return '\t';
        case 'v':
            return '\v';
        case 'x':
            return 'x';
        case 'u':
            return 'u';
        case 'U':
            return 'U';
        case '\'':
            return '\'';
        case '"':
            return '"';
        case '\\':
            return '\\';
        case '0':
            return '\0';
        default:
            return -1;
    }
}

macro bool char_is_base64(char c)
{
    return (
        (c >= 'A' && c <= 'Z') ||
        (c >= 'a' && c <= 'z') ||
        (c >= '0' && c <= '9') ||
        c == '+' ||
        c == '/'
    );
}

macro bool char_is_hex(char c)
{
    return HEX_CONV[(char)c] != 0;
}

macro char char_nibble_to_hex(int c)
{
    char* conv = "0123456789ABCDEF";
    return conv[c];
}

macro bool is_space(char c)
{
    return c == ' ' || c == '\t';
}

macro bool char_is_whitespace(char c)
{
    switch (c) {
        case ' ':
        case '\t':
        case '\n':
            return true;
        case '\r':
            unreachable();
        default:
            return false;
    }
}

macro bool char_is_alphanum_(char c)
{
    switch (c) {
        case 'a':
        case 'b':
        case 'c':
        case 'd':
        case 'e':
        case 'f':
        case 'g':
        case 'h':
        case 'i':
        case 'j':
        case 'k':
        case 'l':
        case 'm':
        case 'n':
        case 'o':
        case 'p':
        case 'q':
        case 'r':
        case 's':
        case 't':
        case 'u':
        case 'v':
        case 'w':
        case 'x':
        case 'y':
        case 'z':
            nextcase;

        case 'A':
        case 'B':
        case 'C':
        case 'D':
        case 'E':
        case 'F':
        case 'G':
        case 'H':
        case 'I':
        case 'J':
        case 'K':
        case 'L':
        case 'M':
        case 'N':
        case 'O':
        case 'P':
        case 'Q':
        case 'R':
        case 'S':
        case 'T':
        case 'U':
        case 'V':
        case 'W':
        case 'X':
        case 'Y':
        case 'Z':
            nextcase;

        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '_':
            return true;
        default:
            return false;
    }
}

macro bool char_is_lower_alphanum_(char c)
{
    switch (c) {
        case 'a'..'z':
        case '0'..'9':
        case '_':
            return true;
        default:
            return false;
    }
}

macro bool char_is_upper_alphanum_(char c)
{
    switch (c) {
        case 'A'..'Z':
        case '0'..'9':
        case '_':
            return true;
        default:
            return false;
    }
}

macro bool char_is_letter(char c)
{
    switch (c) {
        case 'a'..'z':
        case 'A'..'Z':
            return true;
        default:
            return false;
    }
}

macro bool char_is_letter_(char c)
{
    switch (c) {
        case 'a'..'z':
        case 'A'..'Z':
        case '_':
            return true;
        default:
            return false;
    }
}
