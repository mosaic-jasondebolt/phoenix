""" Recursively searches and replaces all strings in a given directory for a given file pattern.

USAGE:
  $ python search_and_replace.py {directory_to_search} {string_to_find} {replacement_string} {pattern}

EXAMPLE:
  The following Recursively searches for the string FOO and replaces with BAR
  for all text files in the current directory and all subdirectories.

  $ python search_and_replace.py . FOO BAR *.txt
"""
import os, fnmatch, sys

def search_and_replace(directory, find, replace, filePattern):
    for path, dirs, files in os.walk(os.path.abspath(directory)):
        for filename in fnmatch.filter(files, filePattern):
            filepath = os.path.join(path, filename)
            with open(filepath) as f:
                s = f.read()
            s = s.replace(find, replace)
            with open(filepath, 'w') as f:
                f.write(s)

if __name__ == '__main__':
    search_and_replace(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
