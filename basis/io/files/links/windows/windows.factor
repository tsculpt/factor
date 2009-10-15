! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.files io.files.links io.pathnames kernel
sequences system windows.errors windows.kernel32 ;
IN: io.files.links.windows

M: windows make-link ( target symlink -- )
    normalize-path f CreateSymbolicLink win32-error=0/f ;

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