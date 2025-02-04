module std::core::test;
import std::core::runtime @public;

<*
 Check if left == right

 @param left `left argument of any comparable type`
 @param right `right argument of any comparable type`
*>
macro equal(left, right)
{
    test::is_equal(left, right);
}

macro not_equal(left, right)
{
    test::is_not_equal(left, right);
}

macro greater(left, right)
{
    test::is_greater_equal(left, right);
}
