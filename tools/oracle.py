"""Oracle: Python fnmatch and glob. `oracle.py --list`; `oracle.py NAME DIR` prints its lines."""
import fnmatch, glob, os, sys
D = os.path.join(os.path.dirname(__file__), "..", "tests", "data")
def lines(f): return open(os.path.join(D, f), encoding="utf-8").read().split("\n")[:-1]
def tree(w):
    for e in lines("tree.txt"):
        if " -> " in e:
            p, t = e.split(" -> "); os.symlink(t, os.path.join(w, p))
        elif e.endswith("/"): os.makedirs(os.path.join(w, e), exist_ok=True)
        else: open(os.path.join(w, e), "w").write("x")
def fn(_):
    names = lines("names.txt")
    for p in lines("fnpats.txt"):
        print("fn", repr(p), "".join("T" if fnmatch.fnmatchcase(n, p) else "." for n in names))
def gl(w):
    tree(w)
    for p in lines("patterns.txt"):
        for rec in (False, True):
            for hid in (False, True):
                print("glob", repr(p), int(rec), int(hid), sorted(glob.glob(p, root_dir=w, recursive=rec, include_hidden=hid)))
RAW = [b"a\xffb", b"\x80", b"\xc3", b"\xc3\xbc", b"x\xc3", b"\xf8\x88", b"\xe2\x82", b"ok"]
RPATS = ["a?b", "?", "??", "*", "x?", "[!a]", "???"]
def raw(_):
    names = [b.decode("utf-8", "surrogateescape") for b in RAW]
    for p in RPATS:
        print("raw", p, "".join("T" if fnmatch.fnmatchcase(n, p) else "." for n in names))
S = {"fn": fn, "glob": gl, "raw": raw}
if sys.argv[1] == "--list": print("\n".join(S))
else: S[sys.argv[1]](sys.argv[2])
