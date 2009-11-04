! Copyright (C) 2008 Slava Pestov, Doug Coleman, 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators io.backend io.files.info io.files.types
io.pathnames kernel math namespaces system vocabs.loader ;
IN: io.files.links

HOOK: make-link os ( target link type -- )

HOOK: read-link os ( symlink -- path )

HOOK: copy-link os ( target symlink -- )

SYMBOL: +hard-link+ inline

SYMBOL: +file-soft-link+ inline

SYMBOL: +dir-soft-link+ inline

SYMBOL: symlink-depth
10 symlink-depth set-global

ERROR: too-many-symlinks path n ;

ERROR: unexpected-link-type type ;

ERROR: not-a-soft-link path ;

{
    { [ os unix? ] [ "io.files.links.unix" ] }
    { [ os winnt? ] [ "io.files.links.windows" ] }
} cond require

: follow-link ( path -- path' )
    [ parent-directory ] [ read-link ] bi append-path ;

<PRIVATE

: (follow-links) ( n path -- path' )
    over 0 = [ symlink-depth get too-many-symlinks ] when
    dup link-info type>> +symbolic-link+ =
    [ [ 1 - ] [ follow-link ] bi* (follow-links) ]
    [ nip ] if ; inline recursive

PRIVATE>

: follow-links ( path -- path' )
    [ symlink-depth get ] dip normalize-path (follow-links) ;
