! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.files io.files.info io.files.links io.pathnames
kernel sequences system windows.errors windows.kernel32 ;
IN: io.files.links.windows

M: windows make-link ( target symlink -- )
    [ normalize-path ] bi@ swap dup file-info
    directory? [ SYMBOLIC_LINK_FLAG_DIRECTORY ] [ SYMBOLIC_LINK_FLAG_FILE ] if
    CreateSymbolicLink win32-error=0/f ;

M: windows make-hard-link ( target link -- )
    normalize-path f CreateHardLink win32-error=0/f ;

DEFER: read-symbolic-link
M: windows read-link ( symlink -- path )
    normalize-path read-symbolic-link ;

M: windows canonicalize-path ( path -- path' )
    path-components "/"
    [ append-path dup exists? [ follow-links ] when ] reduce ;

! M: windows link-info in io.files.info.windows needs rewriting to
!  detect links and return link info.

! win32-file-type needs rewrite to include +symlink+

! Use find-first-file-stat to get a WIN32_FIND_DATA structure to
! determine whether a file or dir has a reparse point. Perform a bit &
! of dwFileAttributes with FILE_ATTRIBUTE_REPARSE_POINT. If true, read
! the tag in dwReserved0 to see if it's a IO_REPARSE_TAG_SYMLINK.

! Guard against creating a link to a link of different type: filelink
! to dir, visa versa.

! MAKE LINK
! Normalize paths involved
! Order paths as symlink target
! Determine symlink type to forge
! ... based on target's existence
! ... ... failing that target's ending in path sepatarator mean directory link
! Create symbolic link.

! HARD LINK
! Normalize paths involved
! Order paths as hardlink target
! Create hard link.

! You are likely to have ot read the reparse point in order to obtain
! the path a link points to.