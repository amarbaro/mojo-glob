# Every public call once, plus the README example.
from std.os import makedirs
from glob import glob, fnmatch, fnmatchcase, filter, has_magic, Pattern


def check(ok: Bool, what: String) raises:
    if not ok:
        raise Error("FAIL api: " + what)


def main() raises:
    check(fnmatch("train.py", "*.py") and not fnmatchcase("a.PY", "*.py"), "fnmatch")
    check(fnmatch("日本.md", "??.md"), "codepoints")
    var names: List[String] = ["a.py", "b.txt", "c.py"]
    check(len(filter(names, "*.py")) == 2, "filter")
    check(has_magic("a/*") and not has_magic("a/b"), "has_magic")
    var p = Pattern("[!.]*")
    check(p.matches("x") and not p.matches(".x"), "Pattern")
    makedirs(".work/apitree/x/y", exist_ok=True)
    with open(".work/apitree/x/y/z.txt", "w") as f:
        f.write("z")
    var r = glob("**/*.txt", root_dir=".work/apitree", recursive=True)
    check(len(r) == 1 and r[0] == "x/y/z.txt", "glob recursive")
    print("PASS api")
