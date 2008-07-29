USING: tools.test state-parser kernel io strings ascii ;

[ "hello" ] [ "hello" [ take-rest ] string-parse ] unit-test
[ 2 4 ] [ "12\n123" [ take-rest drop get-line get-column ] string-parse ] unit-test
[ "hi" " how are you?" ] [ "hi how are you?" [ [ get-char blank? ] take-until take-rest ] string-parse ] unit-test
[ "foo" ";bar" ] [ "foo;bar" [ CHAR: ; take-char take-rest ] string-parse ] unit-test
[ "foo " " bar" ] [ "foo and bar" [ "and" take-string take-rest ] string-parse ] unit-test
[ "baz" ] [ " \n\t baz" [ pass-blank take-rest ] string-parse ] unit-test