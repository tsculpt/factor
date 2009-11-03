! Copyright (C) 2009 Brad Christensen.
! See http://factorcode.org/license.txt for BSD license.

USING: accessors alien alien.c-types classes.struct combinators
destructors io.backend io.backend.windows io.encodings.string
io.encodings.utf16n io.files io.files.info io.files.links
io.files.types io.pathnames kernel libc math math.bitwise sequences
specialized-arrays strings system windows.errors windows.kernel32 ;

IN: io.files.links.windows

SPECIALIZED-ARRAY: uchar

<PRIVATE

: (make-hard-link) ( link target -- )
    normalize-path f CreateHardLink win32-error=0/f ;

: (make-symbolic-link) ( symlink target type-flag -- )
    CreateSymbolicLink win32-error=0/f ;

: (initial-reparse-data-buffer) ( -- REPARSE_DATA_BUFFER )
    MAX_REPARSE_DATA_BUFFER_SIZE malloc REPARSE_DATA_BUFFER memory>struct
    IO_REPARSE_TAG_SYMLINK >>ReparseTag MAX_REPARSE_DATA_BUFFER_SIZE
    REPARSE_DATA_BUFFER heap-size - >>ReparseDataLength &free ;

: (reparse-handle) ( path -- win32-file )
    0 share-mode default-security-attributes OPEN_EXISTING
    { FILE_FLAG_BACKUP_SEMANTICS FILE_FLAG_OPEN_REPARSE_POINT } flags f
    CreateFile dup invalid-handle? <win32-file> &dispose ;

: (get-reparse-point) ( reparse-handle initial-reparse-data-buffer bytes-returned-out -- )
    [ [ handle>> ] [ >c-ptr ] bi* ] dip [ FSCTL_GET_REPARSE_POINT f 0 ] 2dip
    [ MAX_REPARSE_DATA_BUFFER_SIZE ] dip f DeviceIoControl win32-error=0/f ;

: (extract-substitute-path) ( REPARSE_DATA_BUFFER -- substitute-path )
    dup ReparseDataLength>>
    [ ReparseDataUnion>> SymbolicLinkReparseBuffer>>
        [ SubstituteNameOffset>> ]
        [ SubstituteNameLength>> over + ]
        [ PathBuffer>> >c-ptr ] tri
    ] dip <direct-uchar-array> <slice> utf16n decode ;

: (read-symbolic-link) ( symlink -- path )
    [ (reparse-handle) (initial-reparse-data-buffer) 0 <ulong>
        [ (get-reparse-point) ] 2keep *ulong drop (extract-substitute-path)
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

! Same as unix hook, factor into normal word?
M: winnt resolve-symlinks ( path -- path' )
    path-components "/"
    [ append-path dup exists? [ follow-links ] when ] reduce ;

! Should win32-file-type include +symbolic-link+ ?

! get-file-information-stat does not dispose handle to file?

! link-info fix size / size-on-disk
