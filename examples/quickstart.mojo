# List Mojo sources under the current directory, recursively, then filter test files.
from glob import glob, fnmatch


def main():
    var files = glob("**/*.mojo", recursive=True)
    var tests = 0
    for f in files:
        if fnmatch(f, "tests/*"):
            tests += 1
    print(len(files), "Mojo files,", tests, "under tests/")
