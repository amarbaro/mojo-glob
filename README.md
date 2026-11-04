# mojo-glob

<!-- badges -->
[![ci](https://github.com/amarbaro/mojo-glob/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/amarbaro/mojo-glob/actions/workflows/ci.yml) [![latest release](https://img.shields.io/github/v/release/amarbaro/mojo-glob)](https://github.com/amarbaro/mojo-glob/releases/latest) [![license](https://img.shields.io/github/license/amarbaro/mojo-glob)](https://github.com/amarbaro/mojo-glob/blob/main/LICENSE) [![checks](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/amarbaro/mojo-glob/badges/checks.json)](https://github.com/amarbaro/mojo-glob/actions/workflows/ci.yml)
<!-- /badges -->

Shell-style wildcards for Mojo: `fnmatch` and `glob` with the exact behaviour of Python's `fnmatch` and `glob` modules (3.14) on POSIX: `*`, `?`, `[seq]`, `[!seq]` over Unicode codepoints, hidden names skipped, recursive `**`, `root_dir`. Pure Mojo, 365 lines of code (`mojo-loc`).

```mojo
from glob import glob, fnmatch, Pattern

var sources = glob("src/**/*.mojo", recursive=True)
print(fnmatch("train.py", "*.py"))          # True
var p = Pattern("*_[0-9][0-9].txt")         # compile once, match many
var names: List[String] = ["run_01.txt", "notes.md"]
for name in names:
    if p.matches(name):
        print(name)
```

**Checked against Python 3.14:** 42 patterns (Python's class-parsing corner cases included: `[]]`, `[!]]`, `[z-a]`, `[a-c-e]`, `[a-a]`) against 37 names, and 33 glob patterns x recursive x include_hidden on a tree with hidden files, a symlink, a dangling link and Unicode names, byte-identical (`scripts/check.sh`, each twice). 6 of 6 mutants caught. Builds and passes on Mojo 1.2.0 and the 1.3 nightly.

Invalid UTF-8 in names counts one character per bad byte, as Python's surrogateescape names do. Directory symlinks are followed with `**` (as in Python); a symlink loop recurses until the path gets too long.

**Speed** (20,000 names, 7800X3D):

| pattern | `Pattern.matches` | `fnmatch` | Python `fnmatchcase` |
|---|---|---|---|
| `*.py` | 16 ns | 11 ns | 168 ns |
| `src/module_1*/*_[0-4]?.txt` | 123 ns | 1,314 ns | 245 ns |
| `*[!a-z]*.py` | 82 ns | 812 ns | 208 ns |

`fnmatch` compiles a pattern with `[` on every call (Python caches it); use `Pattern` in loops. `glob` and `filter` already compile once.

- API: [docs/api.md](docs/api.md) · design: [docs/design.md](docs/design.md) · agent skill: [skills/mojo-glob/SKILL.md](skills/mojo-glob/SKILL.md)
- License: Apache-2.0 (portions ported from CPython, PSF-2.0: see NOTICE and LICENSE-python)
