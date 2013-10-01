realpath-lib
============

The lightweight and simple Bash script `realpath-lib` provdes functions that can 
resolve the full path associated with a file name.   These functions are:  

>get_realpath  
>get_dirname  
>get_filename  
>get_stemname  
>validate_path  

`realpath-lib` was inspired in part by the numerous other realpath tools that
can found.  We are not aware of a Bash specific version that does not require
external dependencies.  This is pure Bash.  

Motivation
==========

Recent work writing scripts that should function the same way across Mac, Linux,
and Windows has revealed that certain system tools are not available for all
platforms.  Quite often the standard way of resolving file names, such as the
use of `basename`, has led to portability problems.  
  
For this reason we have prepared this set of tools for use in Bash scripts.  It
uses only built-in features and should not require anything else.   

Dependencies
============

Bash 4+ and nothing else.  This could be prepared to work with earlier versions 
but we leave that exercise to others.  

Features
========

The path argument can be provded as local file names, relative paths and absolute
paths.  It might even take symlinks but we have not yet verfied this.  Functions
are classified into two groups: getters and validators.  

Getters
-------

The following functions will resolve the path argument to a full absolute path
string (if it is found) and return an exit condition of **0 for success** and 
**1 for failure** - meaning they can be used for testing purposes too.  
  
>get_realpath 'path-arg'  
>get_dirname 'path-arg'  
>get_filename 'path-arg'  
>get_stemname 'path-arg'  
>  
>where **path-arg** can be a local file, a relative path or absolute path.   

Validators
----------

The final function `validate_path` will return an exit condition of **0 for success**
or will **abort on failure**.  This leads us to the following warning: **do not use
this at the top level of your shell - it will kill it!**  
  
>validate_path 'path-arg'  
>  
>where **path-arg** is the same as above.  

Usage
=====

This is not a Bash executable.  Source it at the beginning of your executable script
with:  
  
        source '/your/path/to/realpath-lib'

That's it.
  
Examples
========

To use the 'getters' for testing purposes, do something like:  

        get_realpath "$1" &>/dev/null
        if (( $? ))  # true when non-zero.
        then
            # Do failure actions. 
            return 1 # Failure. 
        fi

While these are designed to be used exclusively in scripts, some top level
Bash shell examples are:  

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
>[user@a52j MyLib]$ validate_path 'archive.tar.gz'  
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
>[user@a52j Templates]$ validate_path '../MyLib/archive.tar.gz'  
>[user@a52j Templates]$  

Terms
=====

We offer this to the community for free and you may use it as you wish.  
  
This source is Copyright (C) Applied Numerics Ltd 2013 under the brand name 
AsymLabs (TM) and is provided to the community under the MIT license.  Although 
we have not yet encountered any issues, there is no warrany of any type given 
so you must use it at your own risk.  

Closure
=======

We hope that you find this Bash library to be of value.  Should you have any 
comments or suggestions for improvement please let us know at dv@angb.co.  

