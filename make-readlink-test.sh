#!/usr/bin/env bash

# make-readlink-test.sh.  A test script for realpath-lib.  Use this script to
# assess compatibility with GNU readlink -f.  This script is based upon
# concepts and contributions by Mikael Auno that can be found within the issues
# thread 1 of November 2013 at:
#
#   https://github.com/AsymLabs/realpath-lib/issues/1 
#
# Note that this will create a directory structure, identified by root 'foo', 
# that is shown below:
#
#   foo
#   ├── bar1
#   │   ├── baz.phys
#   │   ├── foo->bar1.sym -> ../bar2/foo->bar2.sym
#   │   └── foo->baz.phys
#   ├── bar2
#   │   ├── bazbaz.sym -> baz.sym 
#   │   ├── baz.sym -> ../bar1/baz.phys
#   │   ├── broken.sym -> ../bar1/broken.phys
#   │   ├── foo->bar2.sym -> ../bar1/foo->bar1.sym
#   │   └── foobaz.sym -> ../bar1/foo->baz.phys
#   └── bar3 -> bar1
#
# If the root 'foo' already exists then no modifications will be made.  To
# use it, unpack realpath-lib-master.zip (or acquire it from the repo using
# git), change into the root directory and do:
#
#   ./make-readlink-test.sh      # with executable permission
#
#   or
#
#   bash make-readlink-test.sh   # without executable permission
#
# Version : 2013.11.19.00
# Usage   : ./make-readlink-test.sh
# Output  : results of tests.    
#
# This script requires Bash 4+ and a few POSIX standard utilities, 'mkdir',
# 'date', 'uname', 'ln', 'tee', 'tput' and 'more' (or 'less', if installed
# but 'less' is not posix). The results are stored in a local file that is 
# uniquely stamped and suffixed with the extension '.log'.  The content of
# this file is displayed upon completion of execution.
#
# Note that no warranty is given, either implied or expressed, and the 
# license terms are according to the MIT license that is included within
# this repository.  Use at your own risk! You have been warned!
#
# Written by G R Summers. Last updated on Tue Nov 19 11:19:45 GMT 2013.

#### ENVIRONMENT

source realpath-lib
readonly pwd_log="$(pwd)"
readonly pwd_phys="$(pwd -P)"
readonly suffix="$(uname -s)"'-'"$(date +%s)"'s-'"${RANDOM}${RANDOM}"'.log'
readonly stdout_log='readlink-tests-'"$suffix"
readonly stderr_log='readlink-errors-'"$suffix"

#### FUNCTIONS

# check _dependencies : confirm that dependencies are installed.
function check_dependencies(){
 
    # Posix utilties.
    hash mkdir &&
    hash date &&
    hash uname &&
    hash ln &&
    hash tee &&
    hash tput &&
    hash more || {
        echo "One or more dependencies cannot be found, throwing exit condition ..."
        return 1
    }

}

# make_header : produces file header for results of tests
function make_header(){
    echo "INITIATED TESTS OF REALPATH-LIB V$RPL_VERSION ON $(date)"
    echo "SYSTEM: $(uname -srm)"
    echo
}

# make_footer : produces file foolter for results of tests.
function make_footer(){
    local _failed;
    echo
    if (( $failcntr )); then
        if (( $failcntr > 1 )); then
            _failed="THERE ARE ($failcntr) FAILURES."
        else
            _failed="THERE IS ONE (1) FAILURE."
        fi
        echo "SUMMARY OF RESULTS: OF ($totalcntr) TESTS PERFORMED, $_failed"
    else
        echo "SUMMARY OF RESULTS: OF ($totalcntr) TESTS PERFORMED, ALL TESTS HAVE PASSED."
    fi
    echo "COMPLETED TESTS OF REALPATH-LIB V$RPL_VERSION ON $(date)"
}

# make_paths : make path (directory) structure.
function make_paths(){
    # Very simple safety check.
    if [[ ! -d 'foo' ]]; then
        echo "Directory 'foo' does not exist, creating..."
        {
            mkdir foo
            mkdir foo/bar1
            mkdir foo/bar2
            ln -s bar1 foo/bar3
            echo 'test file' > foo/bar1/baz.phys
            echo 'test file' > foo/bar1/foo-\>baz.phys
            ln -s ../bar1/baz.phys foo/bar2/baz.sym
            ln -s baz.sym foo/bar2/bazbaz.sym
            ln -s ../bar1/foo-\>bar1.sym foo/bar2/foo-\>bar2.sym # circular
            ln -s ../bar2/foo-\>bar2.sym foo/bar1/foo-\>bar1.sym # circular
            ln -s ../bar1/broken.phys foo/bar2/broken.sym
            ln -s ../bar1/foo-\>baz.phys foo/bar2/foobaz.sym
        } &>/dev/null || {
            echo "Could not create test directories, throwing exit condition..."
            return 1
        }
    else
        echo "Directory 'foo' already exists, proceeding..."
    fi
}

# make_test "function" "message" "path" 
function make_test() {
    local _function="$1"
    local _message="$2"
    local _path="$3"
    local _expected="$4"
    local _result=''
    local _printf=''

    # get _result
    _result="$($_function "$_path")"

    # produce message
    _printf="$(printf 'Try %-14s %-37s set_logical=%-4s ' "$_function" "$_message $_path" "$set_logical")"
    if [[ "$_result" != "$_expected" ]]; then
        echo "$_printf Fail"
        echo "--> specified \"$_expected\" but got \"$_result\""
        ((failcntr++))
    else
        echo "$_printf Pass"
    fi
    ((totalcntr++))

}

#### MAIN PROCEDURES

# Confirm dependencies.
check_dependencies || exit 1

# Initialize counters
failcntr=0  # failing test counter.
totalcntr=0 # total test counter.

# Initialize tee_stderr
readonly tee_stderr='tee -a /dev/stderr'

# Initialize file_reader
hash less &>/dev/null && readonly file_reader='less -S' || readonly file_reader='more -d'

# Make header for logs.
make_header | tee "$stdout_log" > "$stderr_log"

{
    # Make directory structure required for tests.
    make_paths || exit 1

    { 

        # Using 'set_strict=' for all. 
        # 
        echo | $tee_stderr 
        echo "==================================================================================" | $tee_stderr
        echo "=     Testing 'Realpath-Lib' as default 'set_strict=' and 'set_logical='         =" | $tee_stderr
        echo "=    (default settings will emulate the results of GNU command 'readlink -f')    =" | $tee_stderr
        echo "==================================================================================" | $tee_stderr
        echo | $tee_stderr

        # Begin tests
        echo "### Logical and physical paths from 'foo/' for symlinks that exist ############" | $tee_stderr
 
        make_test get_realpath  "existing symlink" "foo/bar3/baz.phys"   "$pwd_phys/foo/bar1/baz.phys"
        make_test get_realpath  "existing symlink" "foo/bar2/foobaz.sym" "$pwd_phys/foo/bar1/foo->baz.phys"
        make_test get_realpath  "existing symlink" "foo/bar2/bazbaz.sym" "$pwd_phys/foo/bar1/baz.phys"

        make_test get_dirname   "existing symlink" "foo/bar3/baz.phys"   "$pwd_phys/foo/bar1"
        make_test get_dirname   "existing symlink" "foo/bar2/foobaz.sym" "$pwd_phys/foo/bar1"
        make_test get_dirname   "existing symlink" "foo/bar2/bazbaz.sym" "$pwd_phys/foo/bar1"

        make_test get_filename  "existing symlink" "foo/bar3/baz.phys"   "baz.phys"
        make_test get_filename  "existing symlink" "foo/bar2/foobaz.sym" "foo->baz.phys"
        make_test get_filename  "existing symlink" "foo/bar2/bazbaz.sym" "baz.phys"

        make_test get_stemname  "existing symlink" "foo/bar3/baz.phys"   "baz"
        make_test get_stemname  "existing symlink" "foo/bar2/foobaz.sym" "foo->baz"
        make_test get_stemname  "existing symlink" "foo/bar2/bazbaz.sym" "baz"

        make_test get_extension "existing symlink" "foo/bar3/baz.phys"   "phys"
        make_test get_extension "existing symlink" "foo/bar2/foobaz.sym" "phys"
        make_test get_extension "existing symlink" "foo/bar2/bazbaz.sym" "phys"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar2/' for symlinks that exist #######" | $tee_stderr
 
        cd foo/bar2 &>/dev/null

        make_test get_realpath  "existing symlink" "baz.sym" "$pwd_phys/foo/bar1/baz.phys"
        make_test get_dirname   "existing symlink" "baz.sym" "$pwd_phys/foo/bar1"
        make_test get_filename  "existing symlink" "baz.sym" "baz.phys"
        make_test get_stemname  "existing symlink" "baz.sym" "baz"
        make_test get_extension "existing symlink" "baz.sym" "phys"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar3/' for symlinks that exist #######" | $tee_stderr
 
        cd foo/bar3 &>/dev/null

        make_test get_realpath  "existing symlink" "baz.phys"      "$pwd_phys/foo/bar1/baz.phys"
        make_test get_realpath  "existing symlink" "foo->baz.phys" "$pwd_phys/foo/bar1/foo->baz.phys"
        make_test get_dirname   "existing symlink" "baz.phys"      "$pwd_phys/foo/bar1"
        make_test get_dirname   "existing symlink" "foo->baz.phys" "$pwd_phys/foo/bar1"
        make_test get_filename  "existing symlink" "baz.phys"      "baz.phys"
        make_test get_filename  "existing symlink" "foo->baz.phys" "foo->baz.phys"
        make_test get_stemname  "existing symlink" "baz.phys"      "baz"
        make_test get_stemname  "existing symlink" "foo->baz.phys" "foo->baz"
        make_test get_extension "existing symlink" "baz.phys"      "phys"
        make_test get_extension "existing symlink" "foo->baz.phys" "phys"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that do not exist #####" | $tee_stderr
 
        make_test get_realpath  "non-existant symlink" "foo/bar2/no.foo" "$pwd_phys/foo/bar2/no.foo"
        make_test get_dirname   "non-existant symlink" "foo/bar2/no.foo" "$pwd_phys/foo/bar2"
        make_test get_filename  "non-existant symlink" "foo/bar2/no.foo" "no.foo"
        make_test get_stemname  "non-existant symlink" "foo/bar2/no.foo" "no"
        make_test get_extension "non-existant symlink" "foo/bar2/no.foo" "foo"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that are broken #######" | $tee_stderr
 
        make_test get_realpath  "broken symlink" "foo/bar2/broken.sym" "$pwd_phys/foo/bar1/broken.phys"
        make_test get_dirname   "broken symlink" "foo/bar2/broken.sym" "$pwd_phys/foo/bar1"
        make_test get_filename  "broken symlink" "foo/bar2/broken.sym" "broken.phys"
        make_test get_stemname  "broken symlink" "foo/bar2/broken.sym" "broken"
        make_test get_extension "broken symlink" "foo/bar2/broken.sym" "phys"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for files that are not symlinks ####" | $tee_stderr

        make_test get_realpath  "ordinary file" "foo/bar1/baz.phys"      "$pwd_phys/foo/bar1/baz.phys"
        make_test get_realpath  "ordinary file" "foo/bar1/foo->baz.phys" "$pwd_phys/foo/bar1/foo->baz.phys"
        make_test get_dirname   "ordinary file" "foo/bar1/baz.phys"      "$pwd_phys/foo/bar1"
        make_test get_dirname   "ordinary file" "foo/bar1/foo->baz.phys" "$pwd_phys/foo/bar1"
        make_test get_filename  "ordinary file" "foo/bar1/baz.phys"      "baz.phys"
        make_test get_filename  "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz.phys"
        make_test get_stemname  "ordinary file" "foo/bar1/baz.phys"      "baz"
        make_test get_stemname  "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz"
        make_test get_extension "ordinary file" "foo/bar1/baz.phys"      "phys"
        make_test get_extension "ordinary file" "foo/bar1/foo->baz.phys" "phys"

        echo | $tee_stderr
        echo "### Circular references, paths from 'foo/' for files that are symlinks ########" | $tee_stderr
 
        make_test get_realpath  "circular ref" "foo/bar1/foo->bar1.sym" ""
        make_test get_realpath  "circular ref" "foo/bar2/foo->bar2.sym" ""
        make_test get_dirname   "circular ref" "foo/bar1/foo->bar1.sym" ""
        make_test get_dirname   "circular ref" "foo/bar2/foo->bar2.sym" ""
        make_test get_filename  "circular ref" "foo/bar1/foo->bar1.sym" ""
        make_test get_filename  "circular ref" "foo/bar2/foo->bar2.sym" ""
        make_test get_stemname  "circular ref" "foo/bar1/foo->bar1.sym" ""
        make_test get_stemname  "circular ref" "foo/bar2/foo->bar2.sym" ""
        make_test get_extension "circular ref" "foo/bar1/foo->bar1.sym" ""
        make_test get_extension "circular ref" "foo/bar2/foo->bar2.sym" ""

   } 2>> "$stderr_log"

} 1>> "$stdout_log"

make_footer | tee -a "$stdout_log" >> "$stderr_log" 

tput clear
$file_reader "$stdout_log"

tput clear
$file_reader "$stderr_log"

# end make-readlink-test.sh 

