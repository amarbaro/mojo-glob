"""fnmatch: `*`, `?`, `[seq]`, `[!seq]` over Unicode codepoints, the rules of Python fnmatch on POSIX
(including its class parsing: ranges split at `-`, empty ranges merged away)."""


def _cp(b: Span[UInt8, _], i: Int) -> Tuple[Int, Int]:
    """(codepoint, byte length) of the UTF-8 sequence at i. An invalid byte (stray continuation, 0xF8 and up,
    or a truncated sequence) counts as one character on its own, as Python's surrogateescape decoding does."""
    var c = Int(b[i])
    if c < 0x80:
        return (c, 1)
    var n = 2 if (c >= 0xC2 and c < 0xE0) else (3 if (c >= 0xE0 and c < 0xF0) else (4 if (c >= 0xF0 and c < 0xF5) else 0))
    if n == 0 or i + n > len(b):
        return (0xDC00 + c, 1)
    for k in range(1, n):
        if (Int(b[i + k]) & 0xC0) != 0x80:
            return (0xDC00 + c, 1)
    if n == 2:
        return (((c & 0x1F) << 6) | (Int(b[i + 1]) & 0x3F), 2)
    if n == 3:
        return (((c & 0x0F) << 12) | ((Int(b[i + 1]) & 0x3F) << 6) | (Int(b[i + 2]) & 0x3F), 3)
    return (((c & 0x07) << 18) | ((Int(b[i + 1]) & 0x3F) << 12) | ((Int(b[i + 2]) & 0x3F) << 6) | (Int(b[i + 3]) & 0x3F), 4)


comptime _LIT = 0
comptime _ANY = 1
comptime _STAR = 2
comptime _CLASS = 3
comptime _NEVER = 4


@fieldwise_init
struct _Class(Copyable, Movable):
    var ranges: List[Int]  # flat lo, hi pairs
    var neg: Bool

    def has(self, c: Int) -> Bool:
        var hit = False
        for k in range(0, len(self.ranges), 2):
            if self.ranges[k] <= c and c <= self.ranges[k + 1]:
                hit = True
                break
        return hit != self.neg


def _class(body: List[Int]) -> Tuple[Int, _Class]:
    """Python fnmatch._translate for one `[...]` body (codepoints): (token kind, class)."""
    var neg = len(body) > 0 and body[0] == 33
    var chunks = List[List[Int]]()
    var dash = False
    for c in body:
        if c == 45:
            dash = True
    if not dash:
        chunks.append(body.copy())
    else:
        var start = 0
        var k = 2 if neg else 1
        while True:
            var f = -1
            for q in range(k, len(body)):
                if body[q] == 45:
                    f = q
                    break
            if f < 0:
                break
            chunks.append(List[Int](body[start:f]))
            start = f + 1
            k = f + 3
        if start < len(body):
            chunks.append(List[Int](body[start:]))
        else:
            chunks[len(chunks) - 1].append(45)
        var m = len(chunks) - 1
        while m > 0:
            if len(chunks[m - 1]) > 0 and len(chunks[m]) > 0 and chunks[m - 1][len(chunks[m - 1]) - 1] > chunks[m][0]:
                var merged = List[Int](chunks[m - 1][: len(chunks[m - 1]) - 1])
                for c in chunks[m][1:]:
                    merged.append(c)
                chunks[m - 1] = merged^
                _ = chunks.pop(m)
            m -= 1
    var total = 0
    for ch in chunks:
        total += len(ch)
    total += len(chunks) - 1
    if total <= 0:
        return (_NEVER, _Class(List[Int](), False))
    if total == 1 and neg:
        return (_ANY, _Class(List[Int](), False))
    var r = List[Int]()
    for m2 in range(len(chunks)):
        for q in range(len(chunks[m2])):
            if not (neg and m2 == 0 and q == 0):
                r.append(chunks[m2][q])
                r.append(chunks[m2][q])
        if m2 > 0 and len(chunks[m2 - 1]) > 0 and len(chunks[m2]) > 0:
            r.append(chunks[m2 - 1][len(chunks[m2 - 1]) - 1])
            r.append(chunks[m2][0])
    return (_CLASS, _Class(r^, neg))


comptime _RUN = 5  # literal bytes: vals = offset into lit, lens = byte count


struct Pattern(Movable):
    """A compiled shell pattern; match many names without re-parsing. Literal runs compare as bytes,
    and a `*` followed by a literal run jumps to the next occurrence instead of stepping."""

    var kinds: List[UInt8]
    var vals: List[Int]  # class index for _CLASS, lit offset for _RUN
    var lens: List[Int]  # byte length for _RUN
    var lit: List[UInt8]
    var classes: List[_Class]

    def __init__(out self, pat: StringSlice[_]):
        self.kinds = List[UInt8]()
        self.vals = List[Int]()
        self.lens = List[Int]()
        self.lit = List[UInt8]()
        self.classes = List[_Class]()
        var p = pat.as_bytes()
        var i = 0
        while i < len(p):
            var c = _cp(p, i)
            var at = i
            i += c[1]
            if c[0] == 42:
                if len(self.kinds) == 0 or self.kinds[len(self.kinds) - 1] != _STAR:
                    self._tok(_STAR, 0, 0)
            elif c[0] == 63:
                self._tok(_ANY, 0, 0)
            elif c[0] == 91:
                var j = i
                if j < len(p) and p[j] == 33:
                    j += 1
                if j < len(p) and p[j] == 93:
                    j += 1
                while j < len(p) and p[j] != 93:
                    j += _cp(p, j)[1]
                if j >= len(p):
                    self._lit(p, at, 1)
                    continue
                var body = List[Int]()
                var q = i
                while q < j:
                    var d = _cp(p, q)
                    body.append(d[0])
                    q += d[1]
                var t = _class(body)
                self._tok(UInt8(t[0]), len(self.classes), 0)
                self.classes.append(t[1].copy())
                i = j + 1
            else:
                self._lit(p, at, c[1])

    def _tok(mut self, k: UInt8, v: Int, n: Int):
        self.kinds.append(k)
        self.vals.append(v)
        self.lens.append(n)

    def _lit(mut self, p: Span[UInt8, _], at: Int, n: Int):
        var last = len(self.kinds) - 1
        if last < 0 or self.kinds[last] != _RUN:
            self._tok(_RUN, len(self.lit), 0)
            last += 1
        for k in range(n):
            self.lit.append(p[at + k])
        self.lens[last] += n

    def _run_at(self, t: Int, s: Span[UInt8, _], si: Int) -> Bool:
        var n = self.lens[t]
        if si + n > len(s):
            return False
        var o = self.vals[t]
        for k in range(n):
            if s[si + k] != self.lit[o + k]:
                return False
        return True

    def _find(self, t: Int, s: Span[UInt8, _], frm: Int) -> Int:
        """First position >= frm where run t matches, on a codepoint boundary; -1 if none."""
        var n = self.lens[t]
        var first = self.lit[self.vals[t]]
        var i = frm
        while i + n <= len(s):
            if s[i] == first and (s[i] & 0xC0) != 0x80 and self._run_at(t, s, i):
                return i
            i += 1
        return -1

    def matches(self, name: StringSlice[_]) -> Bool:
        """Whole-name match; backtracks to the last `*` only (linear for a fixed pattern)."""
        var s = name.as_bytes()
        var n = len(self.kinds)
        # `*literal` at the end: the literal can only sit at the very end
        var si = 0
        var pi = 0
        var star_p = -1
        var star_s = 0
        while si < len(s) or pi < n:
            if pi < n:
                var k = self.kinds[pi]
                if k == _STAR:
                    pi += 1
                    if pi == n:
                        return True
                    if self.kinds[pi] == _RUN:
                        if pi == n - 1:
                            var e = len(s) - self.lens[pi]
                            return e >= si and (e == len(s) or (s[e] & 0xC0) != 0x80) and self._run_at(pi, s, e)
                        var f = self._find(pi, s, si)
                        if f < 0:
                            return False
                        si = f
                    star_p = pi
                    star_s = si
                    continue
                if k == _RUN:
                    if self._run_at(pi, s, si):
                        si += self.lens[pi]
                        pi += 1
                        continue
                elif si < len(s):
                    var c = _cp(s, si)
                    if k == _ANY or (k == _CLASS and self.classes[self.vals[pi]].has(c[0])):
                        si += c[1]
                        pi += 1
                        continue
            if star_p < 0 or star_s >= len(s):
                return False
            star_s += _cp(s, star_s)[1]
            if self.kinds[star_p] == _RUN:
                var f = self._find(star_p, s, star_s)
                if f < 0:
                    return False
                star_s = f
            si = star_s
            pi = star_p
        return True


def _simple(s: Span[UInt8, _], p: Span[UInt8, _]) -> Bool:
    """Patterns without `[`: match straight off the bytes, no allocation."""
    if len(p) > 1 and p[0] == 42:
        var plain = True
        for k in range(1, len(p)):
            if p[k] == 42 or p[k] == 63:
                plain = False
                break
        if plain:  # `*literal`: an ends-with check
            var e = len(s) - (len(p) - 1)
            if e < 0 or (e < len(s) and (s[e] & 0xC0) == 0x80):
                return False
            for k in range(1, len(p)):
                if s[e + k - 1] != p[k]:
                    return False
            return True
    var si = 0
    var pi = 0
    var star_p = -1
    var star_s = 0
    while si < len(s):
        if pi < len(p):
            var pc = p[pi]
            if pc == 42:
                while pi < len(p) and p[pi] == 42:
                    pi += 1
                if pi == len(p):
                    return True
                star_p = pi
                star_s = si
                continue
            if pc == 63:
                si += _cp(s, si)[1]
                pi += 1
                continue
            if pc == s[si]:
                si += 1
                pi += 1
                continue
        if star_p < 0:
            return False
        star_s += _cp(s, star_s)[1]
        si = star_s
        pi = star_p
    while pi < len(p) and p[pi] == 42:
        pi += 1
    return pi == len(p)


def fnmatchcase(name: StringSlice[_], pat: StringSlice[_]) -> Bool:
    """Whole-name match. Compile once with `Pattern` when matching many names."""
    for c in pat.as_bytes():
        if c == 91:
            return Pattern(pat).matches(name)
    return _simple(name.as_bytes(), pat.as_bytes())


def fnmatch(name: StringSlice[_], pat: StringSlice[_]) -> Bool:
    """Same as fnmatchcase on POSIX (os.path.normcase is the identity there)."""
    return fnmatchcase(name, pat)


def filter(names: List[String], pat: StringSlice[_]) -> List[String]:
    var p = Pattern(pat)
    var out = List[String]()
    for n in names:
        if p.matches(n):
            out.append(n.copy())
    return out^


def has_magic(s: StringSlice[_]) -> Bool:
    for c in s.as_bytes():
        if c == 42 or c == 63 or c == 91:
            return True
    return False
