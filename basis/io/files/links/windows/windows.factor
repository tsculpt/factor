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

! : (read-symbolic-link) ( symlink -- path )
DEFER: (read-symbolic-link)

PRIVATE>

M: windows make-link ( target link type -- )
    [ normalize-path ] dip swapd {
        { +hard-link+ [ (make-hard-link) ] }
        { +dir-soft-link+ [ SYMBOLIC_LINK_FLAG_DIRECTORY (make-symbolic-link) ] }
        { +file-soft-link+ [ SYMBOLIC_LINK_FLAG_FILE (make-symbolic-link) ] }
        [ unexpected-link-type ]
    } case ;

M: windows read-link ( symlink -- path )
    normalize-path ;
!    dup link-info 

!    normalize-path dup symbolic-link?
!    [ (read-symbolic-link) ] [ not-a-soft-link ] if ;

M: windows copy-link ( target symlink -- )
    [ read-link dup file-info directory?
        [ +dir-soft-link+ ] [ +file-soft-link+ ] if
    ] dip swap make-link ;

M: windows canonicalize-path ( path -- path' )
    path-components "/"
    [ append-path dup exists? [ follow-links ] when ] reduce ;

! M: windows link-info in io.files.info.windows needs rewriting to
! detect links and return file-info using find-first-file-stat, and
! also set size-on-disk to 0 when file, or max of size/4096 when
! directory symlink.

! win32-file-type needs rewrite to include +symlink+

! Use find-first-file-stat to get a WIN32_FIND_DATA structure to
! determine whether a file or dir has a reparse point. The
! attribute +reparse-point+ will be set. Need to keep the struct to
! then dig out the reparse tag in dwReserved0 to see if it's a
! IO_REPARSE_TAG_SYMLINK.

! You are likely to have to read the reparse point in order to obtain
! the path a link points to.

! get-file-information-stat does not dispose handle to file?