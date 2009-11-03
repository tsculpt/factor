! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.files io.files.info io.files.links io.files.types io.pathnames libc classes.struct accessors alien alien.c-types math io.backend.windows
destructors kernel combinators sequences system windows.errors windows.kernel32 specialized-arrays strings io.encodings.utf16n io.encodings.string ;
IN: io.files.links.windows

<PRIVATE

: (make-hard-link) ( link target -- )
    normalize-path f CreateHardLink win32-error=0/f ;

: (make-symbolic-link) ( symlink target type-flag -- )
    CreateSymbolicLink win32-error=0/f ;

: (initial-reparse-data-buffer) ( -- REPARSE_DATA_BUFFER )
    MAX_REPARSE_DATA_BUFFER_SIZE 1 calloc REPARSE_DATA_BUFFER memory>struct
    IO_REPARSE_TAG_SYMLINK >>ReparseTag MAX_REPARSE_DATA_BUFFER_SIZE
    REPARSE_DATA_BUFFER heap-size - >>ReparseDataLength &free ;

: (reparse-handle) ( path -- win32-file )
    0 share-mode default-security-attributes OPEN_EXISTING
    FILE_FLAG_OPEN_REPARSE_POINT f CreateFile dup invalid-handle?
    <win32-file> &dispose ;

: (get-reparse-point) ( reparse-handle initial-reparse-data-buffer bytes-returned-out -- )
    [ [ handle>> ] [ >c-ptr ] bi* ] dip [ FSCTL_GET_REPARSE_POINT f 0 ] 2dip
    [ MAX_REPARSE_DATA_BUFFER_SIZE ] dip f DeviceIoControl win32-error=0/f ;

SPECIALIZED-ARRAY: uchar

! Need to use ReparseDataLength instead of  bytes-returned, and use PathBuffer or calc offset considing 12 bytes of other data.
: (extract-substitute-path) ( REPARSE_DATA_BUFFER bytes-returned -- substitute-path )
    [ ReparseDataUnion>> dup GenericReparseBuffer>> >c-ptr ] dip <direct-uchar-array>
    [ SymbolicLinkReparseBuffer>> [ SubstituteNameOffset>> 12 + ] [ SubstituteNameLength>> over + ] bi ] dip
    <slice> utf16n decode ;

: (read-symbolic-link) ( symlink -- path )
    [ (reparse-handle) (initial-reparse-data-buffer) 0 <ulong>
        [ (get-reparse-point) ] 2keep *ulong (extract-substitute-path)
    ] with-destructors ;

PRIVATE>

M: winnt make-link ( target link type -- )
    [ normalize-path ] dip swapd {
        { +hard-link+ [ (make-hard-link) ] }
        { +dir-soft-link+ [ SYMBOLIC_LINK_FLAG_DIRECTORY (make-symbolic-link) ] }
        { +file-soft-link+ [ SYMBOLIC_LINK_FLAG_FILE (make-symbolic-link) ] }
        [ unexpected-link-type ]
    } case ;

M: winnt read-link ( symlink -- path )
    normalize-path dup link-info type>> +symbolic-link+ =
    [ (read-symbolic-link) ] [ not-a-soft-link ] if ;

M: winnt copy-link ( target symlink -- )
    [ read-link dup file-info directory?
        [ +dir-soft-link+ ] [ +file-soft-link+ ] if
    ] dip swap make-link ;

M: winnt resolve-symlinks ( path -- path' )
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

! link-info fix size / size-on-disk