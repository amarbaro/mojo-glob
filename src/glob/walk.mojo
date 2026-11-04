"""glob: Python 3.14 glob.glob over the file system (hidden names skipped, `**` with recursive=True, root_dir)."""
from std.os import listdir
from std.os.path import isdir, lexists
from .fnmatch import Pattern, has_magic


def _split(p: String) -> Tuple[String, String]:
    """os.path.split: (head without trailing slashes unless all slashes, tail)."""
    var b = p.as_bytes()
    var i = len(b)
    while i > 0 and b[i - 1] != 47:
        i -= 1
    var head = String(p[byte=0:i])
    var tail = String(p[byte=i:])
    var hb = head.as_bytes()
    var e = len(hb)
    while e > 0 and hb[e - 1] == 47:
        e -= 1
    if e > 0:
        var trimmed = String(head[byte=0:e])
        return (trimmed^, tail^)
    return (head^, tail^)


def _pjoin(a: String, b: String) -> String:
    """os.path.join for two parts."""
    if b.startswith("/") or not a:
        return b.copy()
    return a + b if a.endswith("/") else a + "/" + b


def _join(a: String, b: String) -> String:
    """glob._join: drop empty parts."""
    if not a or not b:
        return a.copy() if a else b.copy()
    return _pjoin(a, b)


def _hidden(s: String) -> Bool:
    return s.startswith(".")


def _list(d: String, dironly: Bool) -> List[String]:
    var out = List[String]()
    try:
        var names = listdir(d if d else ".")
        for n in names:
            if not dironly or isdir(_pjoin(d, n)):
                out.append(n.copy())
    except:
        pass
    return out^


def _glob0(d: String, base: String) -> List[String]:
    var out = List[String]()
    if (base and lexists(_join(d, base))) or (not base and isdir(d)):
        out.append(base.copy())
    return out^


def _glob1(d: String, pat: String, p: Pattern, dironly: Bool, hidden: Bool) -> List[String]:
    """Names in d matching the pattern, compiled once by the caller for every directory."""
    var out = List[String]()
    for n in _list(d, dironly):
        if (hidden or _hidden(pat) or not _hidden(n)) and p.matches(n):
            out.append(n.copy())
    return out^


def _rlist(d: String, dironly: Bool, hidden: Bool, mut out: List[String], prefix: String):
    for x in _list(d, dironly):
        if hidden or not _hidden(x):
            out.append(_join(prefix, x))
            _rlist(_join(d, x), dironly, hidden, out, _join(prefix, x))


def _glob2(d: String, dironly: Bool, hidden: Bool) -> List[String]:
    var out = List[String]()
    if not d or isdir(d):
        out.append(String())
    _rlist(d, dironly, hidden, out, String())
    return out^


def _iglob(path: String, root: String, recursive: Bool, dironly: Bool, hidden: Bool) -> List[String]:
    var sp = _split(path)
    var dirname = sp[0].copy()
    var base = sp[1].copy()
    var out = List[String]()
    if not has_magic(path):
        if (base and lexists(_join(root, path))) or (not base and isdir(_join(root, dirname))):
            out.append(path.copy())
        return out^
    var rec = recursive and base == "**"
    if not dirname:
        return _glob2(root, dironly, hidden) if rec else _glob1(root, base, Pattern(base), dironly, hidden)
    var dirs = List[String]()
    if dirname != path and has_magic(dirname):
        dirs = _iglob(dirname, root, recursive, True, hidden)
    else:
        dirs.append(dirname.copy())
    var cp = Pattern(base)  # compiled once for every directory below
    for d in dirs:
        var full = _join(root, d)
        var names = _glob2(full, dironly, hidden) if (has_magic(base) and rec) else (_glob1(full, base, cp, dironly, hidden) if has_magic(base) else _glob0(full, base))
        for n in names:
            out.append(_pjoin(d, n))
    return out^


def glob(pathname: String, root_dir: String = "", recursive: Bool = False, include_hidden: Bool = False) -> List[String]:
    """Paths matching `pathname`, relative to `root_dir` when given. Order is directory order (unsorted)."""
    var out = _iglob(pathname, root_dir, recursive, False, include_hidden)
    if (not pathname or (recursive and pathname.startswith("**"))) and len(out) > 0 and not out[0]:
        _ = out.pop(0)
    return out^
