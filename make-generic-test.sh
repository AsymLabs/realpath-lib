#!/usr/bin/env bash

# make-generic-test.sh.  A test script for realpath-lib.  Use this script to
# assess compatibility on a given operating system. This script is based upon
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
#   ./make-generic-test.sh      # with executable permission
#
#   or
#
#   bash make-generic-test.sh   # without executable permission
#
# Version : 2013.11.17.00
# Usage   : ./make-generic-test.sh
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
# Written by G R Summers. Last updated on Sun Nov 17 15:50:15 GMT 2013.

#### ENVIRONMENT

source realpath-lib
readonly pwd_log="$(pwd)"
readonly pwd_phys="$(pwd -P)"
readonly suffix="$(uname -s)"'-'"$(date +%s)"'s-'"${RANDOM}${RANDOM}"'.log'
readonly stdout_log='generic-tests-'"$suffix"
readonly stderr_log='generic-errors-'"$suffix"

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

# make_test "function" "message" "path" "expected" 
function make_test() {
    local _function="$1"
    local _message="$2"
    local _path="$3"
    local _expected="$4"
    local _result=''
    local _specified="$_expected"
    local _exit_status=''
    local _printf=''

    # get _expected
    if [[ "$_expected" != 'Error Code'* ]]; then
        if [[ "$_function" = 'get_realpath' || "$1" = 'get_dirname' ]]; then
            if [[ -n "$set_logical" ]]; then
                _expected="$pwd_log/$_expected"
            else
                _expected="$pwd_phys/$_expected"
            fi
        fi
    fi

    # get _result
    _result="$($_function "$_path")"
    _exit_status=$?
    (( $_exit_status )) && _result="$(printf 'Error Code %s' "$_exit_status")"

    # produce message
    _printf="$(printf 'Try %-12s %-37s [set_logical=%-4s] ' "$_function" "$_message $_path" "$set_logical")"
    if [[ "$_result" != "$_expected" ]]; then
        echo "$_printf Fail"
        echo "--> specified \"$_specified\" but got \"$_result\""
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
hash less &>/dev/null && 
readonly file_reader='less -S' || 
readonly file_reader='more -d'

# Make header for logs.
make_header | tee "$stdout_log" > "$stderr_log"

{
    # Make directory structure required for tests.
    make_paths || exit 1

    { 

        # Series I:  Using 'set_strict=true' for all.
        echo
        echo "===============================================================================" | $tee_stderr
        echo "=    Testing Realpath-Lib as 'set_strict=true' and 'set_logical={ |true}'     =" | $tee_stderr
        echo "===============================================================================" | $tee_stderr
        echo | $tee_stderr

        # Begin tests
        echo "### Logical and physical paths from 'foo/' for symlinks that exist ############" | $tee_stderr 

        set_strict=true set_logical=true make_test get_realpath "existing symlink" "foo/bar3/baz.phys" "foo/bar3/baz.phys"
        set_strict=true                  make_test get_realpath "existing symlink" "foo/bar3/baz.phys" "foo/bar1/baz.phys"
        set_strict=true set_logical=true make_test get_realpath "existing symlink" "foo/bar2/foobaz.sym" "foo/bar2/foobaz.sym"
        set_strict=true                  make_test get_realpath "existing symlink" "foo/bar2/foobaz.sym" "foo/bar1/foo->baz.phys"
        set_strict=true set_logical=true make_test get_realpath "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar2/bazbaz.sym"
        set_strict=true                  make_test get_realpath "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar1/baz.phys"

        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "foo/bar3/baz.phys" "foo/bar3"
        set_strict=true                  make_test get_dirname  "existing symlink" "foo/bar3/baz.phys" "foo/bar1"
        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "foo/bar2/foobaz.sym" "foo/bar2"
        set_strict=true                  make_test get_dirname  "existing symlink" "foo/bar2/foobaz.sym" "foo/bar1"
        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar2"
        set_strict=true                  make_test get_dirname  "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar1"

        set_strict=true set_logical=true make_test get_filename "existing symlink" "foo/bar3/baz.phys" "baz.phys"
        set_strict=true                  make_test get_filename "existing symlink" "foo/bar3/baz.phys" "baz.phys"
        set_strict=true set_logical=true make_test get_filename "existing symlink" "foo/bar2/foobaz.sym" "foobaz.sym"
        set_strict=true                  make_test get_filename "existing symlink" "foo/bar2/foobaz.sym" "foo->baz.phys"
        set_strict=true set_logical=true make_test get_filename "existing symlink" "foo/bar2/bazbaz.sym" "bazbaz.sym"
        set_strict=true                  make_test get_filename "existing symlink" "foo/bar2/bazbaz.sym" "baz.phys"

        set_strict=true set_logical=true make_test get_stemname "existing symlink" "foo/bar3/baz.phys" "baz"
        set_strict=true                  make_test get_stemname "existing symlink" "foo/bar3/baz.phys" "baz"
        set_strict=true set_logical=true make_test get_stemname "existing symlink" "foo/bar2/foobaz.sym" "foobaz"
        set_strict=true                  make_test get_stemname "existing symlink" "foo/bar2/foobaz.sym" "foo->baz"
        set_strict=true set_logical=true make_test get_stemname "existing symlink" "foo/bar2/bazbaz.sym" "bazbaz"
        set_strict=true                  make_test get_stemname "existing symlink" "foo/bar2/bazbaz.sym" "baz"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar2/' for symlinks that exist #######" | $tee_stderr

        cd foo/bar2 &>/dev/null

        set_strict=true set_logical=true make_test get_realpath "existing symlink" "baz.sym" "foo/bar2/baz.sym"
        set_strict=true                  make_test get_realpath "existing symlink" "baz.sym" "foo/bar1/baz.phys"

        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "baz.sym" "foo/bar2"
        set_strict=true                  make_test get_dirname  "existing symlink" "baz.sym" "foo/bar1"

        set_strict=true set_logical=true make_test get_filename "existing symlink" "baz.sym" "baz.sym"
        set_strict=true                  make_test get_filename "existing symlink" "baz.sym" "baz.phys"

        set_strict=true set_logical=true make_test get_stemname "existing symlink" "baz.sym" "baz"
        set_strict=true                  make_test get_stemname "existing symlink" "baz.sym" "baz"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar3/' for symlinks that exist #######" | $tee_stderr
        
        cd foo/bar3 &>/dev/null

        set_strict=true set_logical=true make_test get_realpath "existing symlink" "baz.phys" "foo/bar3/baz.phys"
        set_strict=true                  make_test get_realpath "existing symlink" "baz.phys" "foo/bar1/baz.phys"
        set_strict=true set_logical=true make_test get_realpath "existing symlink" "foo->baz.phys" "foo/bar3/foo->baz.phys"
        set_strict=true                  make_test get_realpath "existing symlink" "foo->baz.phys" "foo/bar1/foo->baz.phys"

        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "baz.phys" "foo/bar3"
        set_strict=true                  make_test get_dirname  "existing symlink" "baz.phys" "foo/bar1"
        set_strict=true set_logical=true make_test get_dirname  "existing symlink" "foo->baz.phys" "foo/bar3"
        set_strict=true                  make_test get_dirname  "existing symlink" "foo->baz.phys" "foo/bar1"

        set_strict=true set_logical=true make_test get_filename "existing symlink" "baz.phys" "baz.phys"
        set_strict=true                  make_test get_filename "existing symlink" "baz.phys" "baz.phys"
        set_strict=true set_logical=true make_test get_filename "existing symlink" "foo->baz.phys" "foo->baz.phys"
        set_strict=true                  make_test get_filename "existing symlink" "foo->baz.phys" "foo->baz.phys"

        set_strict=true set_logical=true make_test get_stemname "existing symlink" "baz.phys" "baz"
        set_strict=true                  make_test get_stemname "existing symlink" "baz.phys" "baz"
        set_strict=true set_logical=true make_test get_stemname "existing symlink" "foo->baz.phys" "foo->baz"
        set_strict=true                  make_test get_stemname "existing symlink" "foo->baz.phys" "foo->baz"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that do not exist #####" | $tee_stderr
 
        set_strict=true set_logical=true make_test get_realpath "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"
        set_strict=true                  make_test get_realpath "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"

        set_strict=true set_logical=true make_test get_dirname  "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"
        set_strict=true                  make_test get_dirname  "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"

        set_strict=true set_logical=true make_test get_filename "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"
        set_strict=true                  make_test get_filename "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"

        set_strict=true set_logical=true make_test get_stemname "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"
        set_strict=true                  make_test get_stemname "non-existant symlink" "foo/bar2/no.foo" "Error Code 1"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that are broken #######" | $tee_stderr
 
        set_strict=true set_logical=true make_test get_realpath "broken symlink" "foo/bar2/broken.sym" "Error Code 1"
        set_strict=true                  make_test get_realpath "broken symlink" "foo/bar2/broken.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_dirname  "broken symlink" "foo/bar2/broken.sym" "Error Code 1"
        set_strict=true                  make_test get_dirname  "broken symlink" "foo/bar2/broken.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_filename "broken symlink" "foo/bar2/broken.sym" "Error Code 1"
        set_strict=true                  make_test get_filename "broken symlink" "foo/bar2/broken.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_stemname "broken symlink" "foo/bar2/broken.sym" "Error Code 1"
        set_strict=true                  make_test get_stemname "broken symlink" "foo/bar2/broken.sym" "Error Code 1"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for files that are not symlinks ####" | $tee_stderr
 
        set_strict=true set_logical=true make_test get_realpath "ordinary file" "foo/bar1/baz.phys" "foo/bar1/baz.phys"
        set_strict=true                  make_test get_realpath "ordinary file" "foo/bar1/baz.phys" "foo/bar1/baz.phys"
        set_strict=true set_logical=true make_test get_realpath "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1/foo->baz.phys"
        set_strict=true                  make_test get_realpath "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1/foo->baz.phys"

        set_strict=true set_logical=true make_test get_dirname  "ordinary file" "foo/bar1/baz.phys" "foo/bar1"
        set_strict=true                  make_test get_dirname  "ordinary file" "foo/bar1/baz.phys" "foo/bar1"
        set_strict=true set_logical=true make_test get_dirname  "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1"
        set_strict=true                  make_test get_dirname  "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1"

        set_strict=true set_logical=true make_test get_filename "ordinary file" "foo/bar1/baz.phys" "baz.phys"
        set_strict=true                  make_test get_filename "ordinary file" "foo/bar1/baz.phys" "baz.phys"
        set_strict=true set_logical=true make_test get_filename "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz.phys"
        set_strict=true                  make_test get_filename "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz.phys"

        set_strict=true set_logical=true make_test get_stemname "ordinary file" "foo/bar1/baz.phys" "baz"
        set_strict=true                  make_test get_stemname "ordinary file" "foo/bar1/baz.phys" "baz"
        set_strict=true set_logical=true make_test get_stemname "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz"
        set_strict=true                  make_test get_stemname "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz"

        echo | $tee_stderr
        echo "### Circular references, paths from 'foo/' for files that are symlinks ########" | $tee_stderr
 
        set_strict=true set_logical=true make_test get_realpath "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true                  make_test get_realpath "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true set_logical=true make_test get_realpath "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"
        set_strict=true                  make_test get_realpath "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_dirname  "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true                  make_test get_dirname  "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true set_logical=true make_test get_dirname  "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"
        set_strict=true                  make_test get_dirname  "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_filename "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true                  make_test get_filename "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true set_logical=true make_test get_filename "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"
        set_strict=true                  make_test get_filename "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"

        set_strict=true set_logical=true make_test get_stemname "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true                  make_test get_stemname "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 1"
        set_strict=true set_logical=true make_test get_stemname "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"
        set_strict=true                  make_test get_stemname "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 1"

        # Series II : Using 'set_strict=' for all. 
        # 
        echo | $tee_stderr 
        echo "===============================================================================" | $tee_stderr
        echo "=      Testing 'Realpath-Lib' as 'set_strict=' and 'set_logical={ |true}'     =" | $tee_stderr
        echo "===============================================================================" | $tee_stderr
        echo | $tee_stderr

        # Begin tests
        echo "### Logical and physical paths from 'foo/' for symlinks that exist ############" | $tee_stderr
 
                        set_logical=true make_test get_realpath "existing symlink" "foo/bar3/baz.phys" "foo/bar3/baz.phys"
                                         make_test get_realpath "existing symlink" "foo/bar3/baz.phys" "foo/bar1/baz.phys"
                        set_logical=true make_test get_realpath "existing symlink" "foo/bar2/foobaz.sym" "foo/bar2/foobaz.sym"
                                         make_test get_realpath "existing symlink" "foo/bar2/foobaz.sym" "foo/bar1/foo->baz.phys"
                        set_logical=true make_test get_realpath "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar2/bazbaz.sym"
                                         make_test get_realpath "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar1/baz.phys"

                        set_logical=true make_test get_dirname  "existing symlink" "foo/bar3/baz.phys" "foo/bar3"
                                         make_test get_dirname  "existing symlink" "foo/bar3/baz.phys" "foo/bar1"
                        set_logical=true make_test get_dirname  "existing symlink" "foo/bar2/foobaz.sym" "foo/bar2"
                                         make_test get_dirname  "existing symlink" "foo/bar2/foobaz.sym" "foo/bar1"
                        set_logical=true make_test get_dirname  "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar2"
                                         make_test get_dirname  "existing symlink" "foo/bar2/bazbaz.sym" "foo/bar1"

                        set_logical=true make_test get_filename "existing symlink" "foo/bar3/baz.phys" "baz.phys"
                                         make_test get_filename "existing symlink" "foo/bar3/baz.phys" "baz.phys"
                        set_logical=true make_test get_filename "existing symlink" "foo/bar2/foobaz.sym" "foobaz.sym"
                                         make_test get_filename "existing symlink" "foo/bar2/foobaz.sym" "foo->baz.phys"
                        set_logical=true make_test get_filename "existing symlink" "foo/bar2/bazbaz.sym" "bazbaz.sym"
                                         make_test get_filename "existing symlink" "foo/bar2/bazbaz.sym" "baz.phys"

                        set_logical=true make_test get_stemname "existing symlink" "foo/bar3/baz.phys" "baz"
                                         make_test get_stemname "existing symlink" "foo/bar3/baz.phys" "baz"
                        set_logical=true make_test get_stemname "existing symlink" "foo/bar2/foobaz.sym" "foobaz"
                                         make_test get_stemname "existing symlink" "foo/bar2/foobaz.sym" "foo->baz"
                        set_logical=true make_test get_stemname "existing symlink" "foo/bar2/bazbaz.sym" "bazbaz"
                                         make_test get_stemname "existing symlink" "foo/bar2/bazbaz.sym" "baz"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar2/' for symlinks that exist #######" | $tee_stderr
 
        cd foo/bar2 &>/dev/null

                        set_logical=true make_test get_realpath "existing symlink" "baz.sym" "foo/bar2/baz.sym"
                                         make_test get_realpath "existing symlink" "baz.sym" "foo/bar1/baz.phys"

                        set_logical=true make_test get_dirname  "existing symlink" "baz.sym" "foo/bar2"
                                         make_test get_dirname  "existing symlink" "baz.sym" "foo/bar1"

                        set_logical=true make_test get_filename "existing symlink" "baz.sym" "baz.sym"
                                         make_test get_filename "existing symlink" "baz.sym" "baz.phys"

                        set_logical=true make_test get_stemname "existing symlink" "baz.sym" "baz"
                                         make_test get_stemname "existing symlink" "baz.sym" "baz"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/bar3/' for symlinks that exist #######" | $tee_stderr
 
        cd foo/bar3 &>/dev/null

                        set_logical=true make_test get_realpath "existing symlink" "baz.phys" "foo/bar3/baz.phys"
                                         make_test get_realpath "existing symlink" "baz.phys" "foo/bar1/baz.phys"
                        set_logical=true make_test get_realpath "existing symlink" "foo->baz.phys" "foo/bar3/foo->baz.phys"
                                         make_test get_realpath "existing symlink" "foo->baz.phys" "foo/bar1/foo->baz.phys"

                        set_logical=true make_test get_dirname  "existing symlink" "baz.phys" "foo/bar3"
                                         make_test get_dirname  "existing symlink" "baz.phys" "foo/bar1"
                        set_logical=true make_test get_dirname  "existing symlink" "foo->baz.phys" "foo/bar3"
                                         make_test get_dirname  "existing symlink" "foo->baz.phys" "foo/bar1"

                        set_logical=true make_test get_filename "existing symlink" "baz.phys" "baz.phys"
                                         make_test get_filename "existing symlink" "baz.phys" "baz.phys"
                        set_logical=true make_test get_filename "existing symlink" "foo->baz.phys" "foo->baz.phys"
                                         make_test get_filename "existing symlink" "foo->baz.phys" "foo->baz.phys"

                        set_logical=true make_test get_stemname "existing symlink" "baz.phys" "baz"
                                         make_test get_stemname "existing symlink" "baz.phys" "baz"
                        set_logical=true make_test get_stemname "existing symlink" "foo->baz.phys" "foo->baz"
                                         make_test get_stemname "existing symlink" "foo->baz.phys" "foo->baz"

        cd - &>/dev/null

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that do not exist #####" | $tee_stderr
 
                        set_logical=true make_test get_realpath "non-existant symlink" "foo/bar2/no.foo" "foo/bar2/no.foo"
                                         make_test get_realpath "non-existant symlink" "foo/bar2/no.foo" "foo/bar2/no.foo"

                        set_logical=true make_test get_dirname  "non-existant symlink" "foo/bar2/no.foo" "foo/bar2"
                                         make_test get_dirname  "non-existant symlink" "foo/bar2/no.foo" "foo/bar2"

                        set_logical=true make_test get_filename "non-existant symlink" "foo/bar2/no.foo" "no.foo"
                                         make_test get_filename "non-existant symlink" "foo/bar2/no.foo" "no.foo"

                        set_logical=true make_test get_stemname "non-existant symlink" "foo/bar2/no.foo" "no"
                                         make_test get_stemname "non-existant symlink" "foo/bar2/no.foo" "no"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for symlinks that are broken #######" | $tee_stderr
 
                        set_logical=true make_test get_realpath "broken symlink" "foo/bar2/broken.sym" "foo/bar2/broken.sym"
                                         make_test get_realpath "broken symlink" "foo/bar2/broken.sym" "foo/bar1/broken.phys"

                        set_logical=true make_test get_dirname  "broken symlink" "foo/bar2/broken.sym" "foo/bar2"
                                         make_test get_dirname  "broken symlink" "foo/bar2/broken.sym" "foo/bar1"

                        set_logical=true make_test get_filename "broken symlink" "foo/bar2/broken.sym" "broken.sym"
                                         make_test get_filename "broken symlink" "foo/bar2/broken.sym" "broken.phys"

                        set_logical=true make_test get_stemname "broken symlink" "foo/bar2/broken.sym" "broken"
                                         make_test get_stemname "broken symlink" "foo/bar2/broken.sym" "broken"

        echo | $tee_stderr
        echo "### Logical and physical paths from 'foo/' for files that are not symlinks ####" | $tee_stderr

                        set_logical=true make_test get_realpath "ordinary file" "foo/bar1/baz.phys" "foo/bar1/baz.phys"
                                         make_test get_realpath "ordinary file" "foo/bar1/baz.phys" "foo/bar1/baz.phys"
                        set_logical=true make_test get_realpath "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1/foo->baz.phys"
                                         make_test get_realpath "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1/foo->baz.phys"

                        set_logical=true make_test get_dirname  "ordinary file" "foo/bar1/baz.phys" "foo/bar1"
                                         make_test get_dirname  "ordinary file" "foo/bar1/baz.phys" "foo/bar1"
                        set_logical=true make_test get_dirname  "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1"
                                         make_test get_dirname  "ordinary file" "foo/bar1/foo->baz.phys" "foo/bar1"

                        set_logical=true make_test get_filename "ordinary file" "foo/bar1/baz.phys" "baz.phys"
                                         make_test get_filename "ordinary file" "foo/bar1/baz.phys" "baz.phys"
                        set_logical=true make_test get_filename "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz.phys"
                                         make_test get_filename "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz.phys"

                        set_logical=true make_test get_stemname "ordinary file" "foo/bar1/baz.phys" "baz"
                                         make_test get_stemname "ordinary file" "foo/bar1/baz.phys" "baz"
                        set_logical=true make_test get_stemname "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz"
                                         make_test get_stemname "ordinary file" "foo/bar1/foo->baz.phys" "foo->baz"

        echo | $tee_stderr
        echo "### Circular references, paths from 'foo/' for files that are symlinks ########" | $tee_stderr
 
                        set_logical=true make_test get_realpath "circular ref" "foo/bar1/foo->bar1.sym" "foo/bar1/foo->bar1.sym"
                                         make_test get_realpath "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 6"
                        set_logical=true make_test get_realpath "circular ref" "foo/bar2/foo->bar2.sym" "foo/bar2/foo->bar2.sym"
                                         make_test get_realpath "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 6"

                        set_logical=true make_test get_dirname  "circular ref" "foo/bar1/foo->bar1.sym" "foo/bar1"
                                         make_test get_dirname  "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 6"
                        set_logical=true make_test get_dirname  "circular ref" "foo/bar2/foo->bar2.sym" "foo/bar2"
                                         make_test get_dirname  "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 6"

                        set_logical=true make_test get_filename "circular ref" "foo/bar1/foo->bar1.sym" "foo->bar1.sym"
                                         make_test get_filename "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 6"
                        set_logical=true make_test get_filename "circular ref" "foo/bar2/foo->bar2.sym" "foo->bar2.sym"
                                         make_test get_filename "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 6"

                        set_logical=true make_test get_stemname "circular ref" "foo/bar1/foo->bar1.sym" "foo->bar1"
                                         make_test get_stemname "circular ref" "foo/bar1/foo->bar1.sym" "Error Code 6"
                        set_logical=true make_test get_stemname "circular ref" "foo/bar2/foo->bar2.sym" "foo->bar2"
                                         make_test get_stemname "circular ref" "foo/bar2/foo->bar2.sym" "Error Code 6"

   } 2>> "$stderr_log"

} 1>> "$stdout_log"

make_footer | tee -a "$stdout_log" >> "$stderr_log" 

tput clear
$file_reader "$stdout_log"

tput clear
$file_reader "$stderr_log"

# end make-generic-test.sh 

