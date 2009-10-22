! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.files io.files.info io.files.links io.pathnames
kernel combinators sequences system windows.errors windows.kernel32 ;
IN: io.files.links.windows

<PRIVATE

: (make-hard-link) ( link target -- )
    normalize-path f CreateHardLink win32-error=0/f ;

: (make-symbolic-link) ( symlink target type-flag -- )
    CreateSymbolicLink win32-error=0/f ;

PRIVATE>

M: windows make-link ( target link type -- )
    [ normalize-path ] dip swapd {
        { +hard-link+ [ (make-hard-link) ] }
        { +dir-soft-link+ [ SYMBOLIC_LINK_FLAG_DIRECTORY (make-symbolic-link) ] }
        { +file-soft-link+ [ SYMBOLIC_LINK_FLAG_FILE (make-symbolic-link) ] }
        [ unexpected-link-type ]
    } case ;

DEFER: read-symbolic-link
M: windows read-link ( symlink -- path )
    normalize-path read-symbolic-link ;

M: windows copy-link ( target symlink -- )
    [ read-link dup file-info directory?
        [ +dir-soft-link+ ] [ +file-soft-link+ ] if
    ] dip swap make-link ;

M: windows canonicalize-path ( path -- path' )
    path-components "/"
    [ append-path dup exists? [ follow-links ] when ] reduce ;

! M: windows link-info in io.files.info.windows needs rewriting to
!  detect links and return link info.

! win32-file-type needs rewrite to include +symlink+

! Use find-first-file-stat to get a WIN32_FIND_DATA structure to
! determine whether a file or dir has a reparse point. Perform a bit
! & of dwFileAttributes with FILE_ATTRIBUTE_REPARSE_POINT using
! mask?. If true, read the tag in dwReserved0 to see if it's a
! IO_REPARSE_TAG_SYMLINK.

! You are likely to have to read the reparse point in order to obtain
! the path a link points to.