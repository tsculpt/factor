! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: fry io.directories io.files.links io.files.unique io.pathnames
kernel math math.parser namespaces sequences tools.test namespaces ;
IN: io.files.links.windows.tests

: make-test-links ( n path -- )
    [ [ iota ] dip '[ [ 1 + ] keep [ number>string _ prepend ] bi@ make-link ] each ]
    [ [ number>string ] dip prepend touch-file ] 2bi ; inline

[ t ] [
    [
        current-temporary-directory get [
            5 "lol" make-test-links
            "lol0" follow-links
            current-temporary-directory get "lol5" append-path =
        ] with-directory
    ] cleanup-unique-directory
] unit-test

[
    [
        current-temporary-directory get [
            100 "laf" make-test-links "laf0" follow-links
        ] with-directory
    ] with-unique-directory
] [ too-many-symlinks? ] must-fail-with

[ t ] [
    110 symlink-depth [
        [
            current-temporary-directory get [
                100 "laf" make-test-links
                "laf0" follow-links
                current-temporary-directory get "laf100" append-path =
            ] with-directory
        ] cleanup-unique-directory
    ] with-variable
] unit-test
