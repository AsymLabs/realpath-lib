realpath-lib
============

The lightweight and simple Bash library `realpath-lib` provides functions that
can resolve the full path associated with a file name.   These functions are:  

>get_realpath  
>get_dirname  
>get_filename  
>get_stemname  
>validate_realpath  

`realpath-lib` was inspired in part by realpath tools that are available in
other programming languages.  This script illustrates that path processing 
can be done in Bash with minimal dependencies. This script requires only the 
widely used posix standard utility **ls** to resolve symlinked file names only.
There are no other dependencies.  It should work across Unix systems and variants.  

Motivation
==========

Recent work writing scripts that should function the same way across Mac, Linux
and Windows has revealed that certain system/Bash tools are not available for
all platforms.  Quite often the standard way of resolving file names, such as
the use of *basename*, *readlink* or others has led to portability problems.  
  
For this reason we have prepared this set of tools for use in Bash scripts with
only simple built-in features and one widely available posix standard utility **ls**.   

Dependencies
============

Bash 4+, posix standard **ls** and nothing else.  This could be revised to work 
with earlier Bash versions but we leave this as an exercise for others.  

Features
========

The path argument can be provided as a local file name, relative path or an
absolute path.  It permits symlinks (logical locations) by default but this
behaviour can be changed when invoked or globally.  Interface methods are 
classified into two groups: getters and validators.  

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
use validate_realpath at the top level of your shell - as a failure to validate
will kill the shell and any sub-processes!**  
  
>validate_realpath 'path-arg'  
>  
>where **path-arg** is the same as above.  

Usage
=====

This is not a Bash executable.  Source it at the beginning of your executable
script with:  

    source '/your/path/to/realpath-lib'

To avoid symlinks completely (use the physical system), uncomment `no_symlinks=on`
under 'Environment' (near the beginning of the script), or invoke when called as:

    no_symlinks='on' get_realpath 'path-arg'
    no_symlinks='on' get_stemname 'path-arg'

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
