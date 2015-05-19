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
           fontmanager [-v] verify FILE ...
           fontmanager list
    
    global options:
        -v  enable verbose mode
        -h  show help and exit
    
    subcommands:
        register: add fonts to the font manager
        unregister: remove fonts from the font manager
        verify: determine whether a font is supported on the current
        list: list the font names in the managerplatform
    
    register options:
        -s  scope for the operation (user or session)
    
    unregister options:
        -s  scope for the operation (user or session)
    
    list options:
        -n  list PostScript names (default)
        -f  list font familty names
        -p  list font paths
