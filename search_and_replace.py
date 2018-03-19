"""Recursively searches and replaces all strings in a given directory for a given file pattern.

USAGE:
  $ python search_and_replace.py {directory_to_search} {string_to_find} {replacement_string} {pattern}

EXAMPLE:
  The following Recursively searches for the string FOO and replaces with BAR
  for all text files in the current directory and all subdirectories.

  $ python search_and_replace.py . FOO BAR    ==> Matches ALL files, like *
  $ python search_and_replace.py . FOO BAR *  ==> Matches ALL files, like *
  $ python search_and_replace.py . FOO BAR *.txt  ==> Matches
"""
import os, fnmatch, sys
import fnmatch
import functools
import itertools
import os
import sys

def find_files(dir_path=None, patterns=None):
    """
    Returns a generator yielding files matching the given patterns
    :type dir_path: str
    :type patterns: [str]
    :rtype : [str]
    :param dir_path: Directory to search for files/directories under. Defaults to current dir.
    :param patterns: Patterns of files to search for. Defaults to ["*"]. Example: ["*.json", "*.xml"]
    """
    path = dir_path or "."
    path_patterns = patterns or ["*"]

    for root_dir, dir_names, file_names in os.walk(path):
        filter_partial = functools.partial(fnmatch.filter, file_names)

        for file_name in itertools.chain(*map(filter_partial, path_patterns)):
            if not root_dir.startswith('./.') and '.git/' not in root_dir:
                yield os.path.join(root_dir, file_name)


def search_and_replace(directory, find, replace, filePattern=None):
    for filename in find_files(directory, filePattern):
        print('Attempting to replace content in filename ' + filename)
        with open(filename) as f:
            s_old = f.read()
        s_new = s_old.replace(find, replace)
        if s_new != s_old:
            print('              REPLACING content in filename ' + filename)
        with open(filename, 'w') as f:
            f.write(s_new)

if __name__ == '__main__':
    print('directory is ' + sys.argv[1])
    print('find ' + sys.argv[2])
    print('replace with ' + sys.argv[3])
    if len(sys.argv) == 5:
        print('of file pattern ' + sys.argv[4] or None)
        search_and_replace(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        search_and_replace(sys.argv[1], sys.argv[2], sys.argv[3])
