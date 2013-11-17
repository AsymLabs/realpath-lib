realpath-lib
============

The lightweight and simple Bash library **realpath-lib** provides functions that
can resolve the full path associated with symlinks and file names.  There are a 
number of environment setttings but by default the function `get_realpath` will
emulate the popular, but often not available, command utility `readlink -f`.  
  
Core functions are:  

>get_realpath  
>get_dirname  
>get_filename  
>get_stemname  
>validate_realpath  

**realpath-lib** was inspired in part by realpath tools that are available in
other programming languages.  This script illustrates that path processing 
can be done in Bash with minimal dependencies. This script requires only the 
widely used Posix&reg; compliant standard utility **ls** to resolve symlinked
file names only.  There are no other dependencies.  It should work across most
if not all Unix systems and variants.  

Motivation
==========

Recent work writing scripts that should function the same way across Mac, Linux
and Windows has revealed that certain system/Bash tools are not available for
all platforms.  Quite often the standard way of resolving file names, such as
the use of *readlink*, *basename*, *dirname* or others has led to portability
issues.  
  
For this reason we have prepared this set of tools for use in Bash scripts with
only simple built-in features and one widely available Posix&reg; standard utility
**ls**.   

Dependencies
============

Dependencies are Bash 4+, Posix&reg; standard **ls** and nothing else.  This could
be revised to work with earlier Bash versions but we leave this as an exercise for
others.  

Test Scripts
============

Two test scripts have been added that were developed following an issue
thread of November 2013: https://github.com/AsymLabs/realpath-lib/issues/1 .  
  
The scripts are: 1) **make-generic-test.sh** and 2) **make-readlink-test.sh**.
The **generic** test script can be used to test the script on a specific system,
whereas the **readlink** script can be used to assess the library against the 
**readlink** command if it is available on your system.  The scripts can also 
be used to gain a better understanding of realpath-lib.  
  
As part of test, a directory and subdirectories are created that are traversed
in order to test such things as chained symlinks, symlinks of circular 
reference, broken symlinks, non-existent symlinks or files and others.  
  
Both scripts will produce a uniquely stamped test log and error log.  These can
be used for diagnostic purposes on any given system.  The logs can also be 
supplied to us should you have problems using **realpath-lib** on your system.  

Features
========

The path argument can be provided as a local file name, relative path or an
absolute path.  It permits symlinks (logical locations) by default but this
behaviour can be changed when invoked or globally.  Interface methods are 
classified into two groups: getters and validators.  

There are a number of environment settings that are identified in detail 
within the library.

Getters
-------

The following functions will resolve the path argument to a full absolute path
string (if it exists) and return exit conditions **0 for success** and 
**1, 2 or 3 for failure** - meaning they can be used for testing purposes too.  
  
>get_realpath 'path-arg'  
>get_dirname 'path-arg'  
>get_filename 'path-arg'  
>get_stemname 'path-arg'  
>  
>where **path-arg** can be a local file, a relative path or absolute path.   

Validators
----------

The function `validate_realpath` will return an exit condition of **0 for success**
or will **abort on failure**.  This leads us to the following warning: **do not
use `validate_realpath` at the top level of your shell - as a failure to validate
will kill the shell and any sub-processes!**  
  
>validate_realpath 'path-arg'  
>  
>where **path-arg** is the same as above.  

Environment
-----------

There are three settable environments (default values are shown):  

>set_strict=  
>set_logical=  
>set_max_depth=5  
  
As indicated previously, the default (out of the box) settings are done to emulate
the command **readlink -f**.  Another interesting feature of the default settings
is that the chain of symlinks for a given path can be unwound where an error is
thrown - useful for diagnostic purposes.  Capture stderr to view this information.
The test scripts are illustrative.  
  
set_strict : setting this environment enforces strict checking of target paths.  They
must exist, the symlink target must exist, cannot be broken and the ultimate target
must be a regular file.

set_logical : setting this environment will see that symlinked files will not be 
resolved to the physical system.  This is at odds with the command **readlink**.  
  
set_max_depth : setting this environment controls the depth of symlink recursion.
Recursion exits on three conditions: 1) when a duplicate reference occcurs (as a
circular reference), 2) when the set_max_depth is reached, or 3) when the built-in
internal limit (40) is reached, whichever occurs first.  So if the set_max_depth
is set to greater than 40, it will be disregarded.  

Usage
=====

This is not a Bash executable.  Source it at the beginning of your executable
script with:  

    source '/your/path/to/realpath-lib'

As indicated previoulsy, the default setting is to emulate the command utility 
**readlink -f**. Environment settings can be incorporated within your script or
inline as:

    set_strict=true set_logical=true set_max_depth=20 get_realpath 'path-arg'
    set_strict=     set_logical=true set_max_depth=10 get_stemname 'path-arg'

and so on.  
  
Examples
========

To use the 'getters' for testing purposes, do something like:  

    get_realpath "$1" &>/dev/null
    if (( $? ))  # true when non-zero.
    then
        # Do failure actions. 
        return 1 # Failure. 
    fi

While these are designed to be used exclusively in scripts, some top level shell
examples are:  

>[user@a52j MyLib]$ ls '/home/user/MyLib/archive.tar.gz'  
>/home/user/MyLib/archive.tar.gz  
>  
>[user@a52j MyLib]$ source realpath-lib  
>[user@a52j MyLib]$  
>  
>[user@a52j MyLib]$ get_realpath 'archive.tar.gz'  
>/home/user/MyLib/archive.tar.gz  
>  
>[user@a52j MyLib]$ get_dirname 'archive.tar.gz'  
>/home/user/MyLib  
>  
>[user@a52j MyLib]$ get_filename 'archive.tar.gz'  
>archive.tar.gz  
>  
>[user@a52j MyLib]$ get_stemname 'archive.tar.gz'  
>archive  
>  
>[user@a52j MyLib]$ validate_realpath 'archive.tar.gz'  
>[user@a52j MyLib]$  
>  
>[user@a52j MyLib]$ cd ../Templates  
>[user@a52j Templates]$  
>  
>[user@a52j Templates]$ get_realpath '../MyLib/archive.tar.gz'  
>/home/user/MyLib/archive.tar.gz  
>  
>[user@a52j Templates]$ get_dirname '../MyLib/archive.tar.gz'  
>/home/user/MyLib  
>  
>[user@a52j Templates]$ get_filename '../MyLib/archive.tar.gz'  
>archive.tar.gz  
>  
>[user@a52j Templates]$ get_stemname '../MyLib/archive.tar.gz'  
>archive  
>  
>[user@a52j Templates]$ validate_realpath '../MyLib/archive.tar.gz'  
>[user@a52j Templates]$  

Terms
=====

We offer this to the community for free and you may use it as you wish.  
  
This source is Copyright (C) Applied Numerics Ltd 2013 Great Britain under the
brand name AsymLabs (TM) and is provided to the community under the MIT license.
Although we have not yet encountered any issues, there is no warranty of any
type given so you must use it at your own risk.  

Closure
=======

We hope that you find this Bash library to be of value.  Should you have any
comments or suggestions for improvement please let us know at
dv@angb.co.  
