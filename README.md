realpath-lib
============

The lightweight and simple Bash library **realpath-lib** provides functions that
can resolve the full path associated with symlinks and file names.  There are 
several environments available but by default the function **get_realpath** will
emulate the popular, but often not available, command utility **readlink -f**.  
  
Core functions are:  

>get_realpath  
>get_dirname  
>get_filename  
>get_stemname  
>get_extension  
>validate_realpath  

**realpath-lib** was inspired in part by realpath tools that are available in
other programming languages.  This script illustrates that path processing 
can be done in Bash with minimal dependencies. This script requires only the 
widely used Posix&reg; compliant standard utility **ls** to resolve symlinked
file names only.  
   
Although we have not tested this script widely, it should work across most, if
not all, Unix systems and variants.  

Motivation
==========

Recent work writing scripts that should function the same way across Mac, Linux
and Windows has revealed that certain system/Bash tools are not available for
all platforms. Quite often the recommended way of resolving file names is to use
utilities such as *readlink*, *basename*, *dirname* or perhaps others that have 
often led to portability issues.  
  
For this reason we have prepared this set of tools for use in Bash scripts with
only simple built-in features and one widely available Posix&reg; standard utility
**ls**.  

Features
========

There are number of beneficial features:  

* **Bash 4+** and only one dependency, the Posix&reg; standard **ls**.  
* Almost complete portability across Unix systems, Mac (and Windows?).   
* Emulation of **readlink -f** (without readlink!) by default.  
* No need for external dependencies basename, dirname or readlink.
* Diagnostic investigation of symlinks, circular references, and chains.  
* **set_strict**, ensuring targets are regular, not broken and exist.  
* **set_logical**, for efficient determination of logical absolute paths.  
* Test scripts to assess platform compatabiity and readlink emulation.  
* Robust design approach, minimal side effects with custom environments.  
* Exception system that throws exit status and suggests solutions.  
* Compact, efficient source that is well commented and easy to maintain.  
* Free and open source, under the liberal terms of the **MIT license**.  
  
The path argument can be provided as a local file name, relative path or an
absolute path.  It permits symlinks to be resolved by default by emulating
**readlink -f**.  Interface methods are classified into two groups: getters
and validators.  

There are a number of environments that are summarized under the section 
that follows.  These are also explained in detail in the source code file.  

Getters
-------

The following functions will resolve the path argument to a full absolute path
string (if it exists) and throw a status condition of **0 for success** or
**1 to 7 for failure** - meaning they can be used for testing purposes too.  
  
>get_realpath  'path-arg'  
>get_dirname   'path-arg'  
>get_filename  'path-arg'  
>get_stemname  'path-arg'  
>get_extension 'path-arg'  
  
where **path-arg** can be a local file, a relative path or absolute path.  
  
Validators
----------

The function **validate_realpath** will throw a status condition of **0 for success**
or will **abort on failure**.  This leads us to the following warning: **do not
use validate_realpath at the top level of your shell - as a failure to validate
will kill the shell and any sub-processes!**  
  
>validate_realpath 'path-arg'  
   
where **path-arg** is the same as above.  

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
  
**set_strict**: setting this environment enforces strict checking of target paths.
A path must exist and must lead to a regular file, a symlink target must exist,
and a symlink cannot be broken.  This is at odds with the command **readlink -f**.  
  
Note that a given system may have system limits on link recursion.  So invoking
the environment **set_strict** may lead to an unspecified error where very
deep symlink chains exist.

**set_logical**: setting this environment will see that symlinked files will not be 
resolved to the physical system.  This is at odds with the command **readlink -f**.  
  
Note that the environment **set_max_depth** is not used nor will symlink chains
be assessed when **set_logical** is invoked.
  
**set_max_depth**: setting this environment controls the depth of symlink recursion.
Recursion exits on three conditions: 1) when a duplicate reference occcurs (as a
circular reference), 2) when the set_max_depth is reached, or 3) when the built-in
internal limit (40) is reached, whichever occurs first.  So if the set_max_depth
is set to greater than 40, it will be disregarded, and 40 shall be enforced.  Of
course this limit can be changed, but will require modification of the source.
  
Dependencies
------------
  
Dependencies are Bash 4+, Posix&reg; standard **ls** and nothing else. This
could be refactored to work with earlier Bash versions but we leave this as 
an exercise for others.  
  
Where the dependency **ls** is required but cannot be found (only in the 
special case where symlinks are files, it is not needed to resolve directory
symlinks), the script will throw a non-zero status and exit with a message 
to stderr.  
  
Usage
=====
  
This is not a Bash executable.  Source it at the beginning of your executable
script with:  

    source '/your/path/to/realpath-lib'

As indicated previously, the default setting is to emulate the command utility 
**readlink -f**. Environment settings can be incorporated within your script or
inline as:

    get_realpath 'path-arg' # emulate readlink -f, traverse a link chain of 5  
    set_strict=true set_logical=true set_max_depth=20 get_realpath 'path-arg'  
    set_strict=     set_logical=true set_max_depth=10 get_stemname 'path-arg'  

and so on.  
  
Test Scripts
============
  
Two test scripts have been added that were developed following an issue
thread of November 2013 that can be found 
[here](https://github.com/AsymLabs/realpath-lib/issues/1).  
  
The scripts are: 1) **make-generic-test.sh** and 2) **make-readlink-test.sh**.
The **generic** test script can be used to test the script on a specific system,
whereas the **readlink** script can be used to assess the library against the 
**readlink** command if it is available on your system.  The scripts can also 
be used to gain a better understanding of realpath-lib.  
  
As part of tests, a directory and subdirectories are created that are traversed
in order to test such things as chained symlinks, symlinks of circular 
reference, broken symlinks, non-existent symlinks or files and others. A tree
for this found in the source code files.  It can also be examined by the 
command **tree foo** after running the script.
  
Both scripts will produce a uniquely stamped test log and error log that will be
displayed upon completion.  These can be used for diagnostic purposes on any
given Bash system.  The logs can be supplied to us should you have problems
using **realpath-lib** on your system.  

The following is an excerpt from the test output (stdout) of **make-generic-test.sh**:  

    ### Circular references, paths from 'foo/' for files that are symlinks ########
    Try get_realpath   circular ref foo/bar1/foo->bar1.sym   set_logical=true  Pass
    Try get_realpath   circular ref foo/bar1/foo->bar1.sym   set_logical=      Pass
    Try get_realpath   circular ref foo/bar2/foo->bar2.sym   set_logical=true  Pass
    Try get_realpath   circular ref foo/bar2/foo->bar2.sym   set_logical=      Pass
    Try get_dirname    circular ref foo/bar1/foo->bar1.sym   set_logical=true  Pass
    Try get_dirname    circular ref foo/bar1/foo->bar1.sym   set_logical=      Pass
    Try get_extension  circular ref foo/bar1/foo->bar1.sym   set_logical=true  Pass
    Try get_extension  circular ref foo/bar1/foo->bar1.sym   set_logical=      Pass
    ....  

The following is an excerpt from the error output (stderr) of **make-generic-test.sh**:   

    ### Circular references, paths from 'foo/' for files that are symlinks ########
    L [00] -> /home/user/realpath-test/foo/bar2/foo->bar2.sym
    L [01] -> /home/user/realpath-test/foo/bar1/foo->bar1.sym
    L [02] -> /home/user/realpath-test/foo/bar2/foo->bar2.sym
    E [06] Symlink circular reference issue has been detected ...
    -----> Symlink circular reference should be investigated manually ...
    L [00] -> /home/user/realpath-test/foo/bar1/foo->bar1.sym
    L [01] -> /home/user/realpath-test/foo/bar2/foo->bar2.sym
    L [02] -> /home/user/realpath-test/foo/bar1/foo->bar1.sym
    E [06] Symlink circular reference issue has been detected ...
    -----> Symlink circular reference should be investigated manually ...
    L [00] -> /home/user/realpath-test/foo/bar2/foo->bar2.sym
    L [01] -> /home/user/realpath-test/foo/bar1/foo->bar1.sym
    L [02] -> /home/user/realpath-test/foo/bar2/foo->bar2.sym
    E [06] Symlink circular reference issue has been detected ...
    -----> Symlink circular reference should be investigated manually ...
    ...  

Where:  
  
    L [..] denotes the link (shallow to deep).   
    E [..] denotes the error message emitted.  
    -----> denotes a possible solution.  

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

    [user@host MyLib]$ ls '/home/user/MyLib/archive.tar.gz'  
    /home/user/MyLib/archive.tar.gz  
      
    [user@host MyLib]$ source realpath-lib  
    [user@host MyLib]$  
      
    [user@host MyLib]$ get_realpath 'archive.tar.gz'  
    /home/user/MyLib/archive.tar.gz  
      
    [user@host MyLib]$ get_dirname 'archive.tar.gz'  
    /home/user/MyLib  
      
    [user@host MyLib]$ get_filename 'archive.tar.gz'  
    archive.tar.gz  
      
    [user@host MyLib]$ get_stemname 'archive.tar.gz'  
    archive  
      
    [user@host MyLib]$ validate_realpath 'archive.tar.gz'  
    [user@host MyLib]$  
      
    [user@host MyLib]$ cd ../Templates  
    [user@host Templates]$  
      
    [user@host Templates]$ get_realpath '../MyLib/archive.tar.gz'  
    /home/user/MyLib/archive.tar.gz  
      
    [user@host Templates]$ get_dirname '../MyLib/archive.tar.gz'  
    /home/user/MyLib  
      
    [user@host Templates]$ get_filename '../MyLib/archive.tar.gz'  
    archive.tar.gz  
      
    [user@host Templates]$ get_stemname '../MyLib/archive.tar.gz'  
    archive  
      
    [user@host Templates]$ validate_realpath '../MyLib/archive.tar.gz'  
    [user@host Templates]$  
  
Design
======

The library is designed with private and interface methods in mind.  The 
function **get_realpath** is the core function for the system and the
only function that is permitted to emit error messages and status.  The
other interface functions are wrappers that simply pass through the return
status of **get_realpath**.  So it is possible to do the following (as a
contrived example) and expect consistent results:  

    get_realpath 'path'  
    get_stemname 'path'  
    get_stemname "$(get_realpath 'path')"  
    get_realpath "$(get_realpath 'path')"  
    get_stemname "$(get_realpath "$(get_realpath 'path')")"  
  
The last three examples will not be as efficient as the first two and are
not recommended, but the robust nature is illustrated.  
  
The non-zero status conditions are not necessarily errors.  For example,
**readlink -f** returns nothing if a circular reference is encountered.
This condition will throw a status 3 under **get_realpath** but this is
not an error.  It is intentional behaviour by default.  
  
Finally, we have attempted to use naming conventions that should avoid 
collisions with other scripts.  This is not ensured, however, and care
is required.  

Terms
=====

We offer this to the community for free and you may use it as you wish.  
  
This source is Copyright (C) Applied Numerics Ltd 2013 Great Britain under the
brand name AsymLabs (TM) and is provided to the community under the MIT license.
Although we have not yet encountered any issues, there is no warranty of any
type given so you must use it at your own risk.  

Closure
=======

We are interested in the user experience with this library.  If you wish, 
contact us to let us know if it works for your platform.  
  
We can be contacted by email (as below) or you may start an issue thread 
that provides the results of your tests if you wish.  We'll try to address
your concerns.  
  
We hope that you find this Bash library to be of value.  Should you decide to 
use it on your project, or should you have any comments or suggestions for
improvement, please contact us at dv@angb.co.  

