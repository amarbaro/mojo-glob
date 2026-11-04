# The Mojo side of tools/oracle.py: `cases SCENARIO DIR` prints the same lines.
from std.sys import argv
from std.os import makedirs
from std.ffi import external_call
from glob import glob, fnmatchcase


def lines(f: String) raises -> List[String]:
    var out = List[String]()
    with open("tests/data/" + f, "r") as h:
        for l in h.read().split("\n"):
            out.append(String(l))
    _ = out.pop()
    return out^


def py_repr(s: String) -> String:
    """Python repr() of a str (the cases here: quotes, backslash, printable Unicode)."""
    var q = "'"
    if "'" in s and not '"' in s:
        q = '"'
    var out = q
    for c in s.codepoint_slices():
        if c == "\\":
            out += "\\\\"
        elif c == q:
            out += "\\" + q
        elif c == "\n":
            out += "\\n"
        else:
            out += c
    return out + q


def py_list(xs: List[String]) -> String:
    var out = String("[")
    for i in range(len(xs)):
        if i:
            out += ", "
        out += py_repr(xs[i])
    return out + "]"


def tree(w: String) raises:
    for e in lines("tree.txt"):
        if " -> " in e:
            var parts = e.split(" -> ")
            var t = String(parts[1])
            var p = w + "/" + String(parts[0])
            _ = external_call["symlink", Int32](t.as_c_string_span().ptr(), p.as_c_string_span().ptr())
        elif e.endswith("/"):
            makedirs(w + "/" + e, exist_ok=True)
        else:
            with open(w + "/" + e, "w") as f:
                f.write("x")


def main() raises:
    var c = argv()[1]
    var w = String(argv()[2])
    if c == "raw":
        var raws: List[List[UInt8]] = [[0x61, 0xFF, 0x62], [0x80], [0xC3], [0xC3, 0xBC], [0x78, 0xC3], [0xF8, 0x88], [0xE2, 0x82], [0x6F, 0x6B]]
        var pats: List[String] = ["a?b", "?", "??", "*", "x?", "[!a]", "???"]
        for p in pats:
            var row = String()
            for r in raws:
                row += "T" if fnmatchcase(StringSlice(unsafe_from_utf8=Span(r)), p) else "."
            print("raw", p, row)
        return
    if c == "fn":
        var names = lines("names.txt")
        for p in lines("fnpats.txt"):
            var row = String()
            for n in names:
                row += "T" if fnmatchcase(n, p) else "."
            print("fn", py_repr(p), row)
    elif c == "glob":
        tree(w)
        for p in lines("patterns.txt"):
            for rec in [False, True]:
                for hid in [False, True]:
                    var r = glob(p, root_dir=w, recursive=rec, include_hidden=hid)
                    sort(r)
                    print("glob", py_repr(p), Int(rec), Int(hid), py_list(r))
