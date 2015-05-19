# fontmanager

Basic OS X font manager command line utility.

## Build

Xcode must be installed for the build.

In the project root, run:

    make
   
which will produce ```build/Release/fontmanager```.

## Usage

Running ```fontmanager -h``` will show this help:

    usage: fontmanager [-v] register [-s SCOPE] FILE ...
           fontmanager [-v] unregister [-s SCOPE] FILE ...
           fontmanager [-v] list [-n] [-p] [-f]
           fontmanager [-v] verify [-s SCOPE] FILE ...
    
    global options:
        -v  enable verbose mode
        -h  show help and exit
    
    subcommands:
        register: add fonts to the font manager
        unregister: remove fonts to the font manager
        list: list the font names in the manager
        verify: determine whether a font is supported on the current platform
    
    register options:
        -s  scope for the operation, user (default) or session
    
    register options:
        -s  scope for the operation, user (default) or session
    
    list options:
        -p  list font paths (default)
        -n  list PostScript names
        -f  list font familty names
    
        The -p and -n options may be combined to print out the
        PostScript name and the font path. The -f option can only
        be used by itself however.
