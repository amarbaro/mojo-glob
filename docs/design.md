# Design

- **Python as the specification.** The class parser is `fnmatch._translate` ported line by line: split at `-` (skipping the first member), merge empty ranges such as `z-a` away, `[]` cases, `[!]`-style negation, empty set never matches, negated empty set matches any one character.
- **Codepoints, not bytes.** `?` and classes consume one UTF-8 sequence; literal runs compare as bytes and are only tried on codepoint boundaries.
- **Compiled matcher.** `Pattern` turns the pattern into tokens (literal run, any, star, class, never). After a `*`, a following literal run jumps to its next occurrence instead of stepping one character at a time; `*literal` at the end is a single ends-with check. Backtracking returns only to the last `*`, which is exact for shell patterns.
- **No allocation on the common path.** `fnmatch` without `[` matches straight off the two byte spans.
- **glob** is Python 3.14's `_iglob`, `_glob0`, `_glob1`, `_glob2` and `_rlistdir` with the same order of checks (`lexists` for plain names, `isdir` for trailing slashes, directory-only intermediate levels, symlinks followed like `entry.is_dir()`).
- `match` is a keyword since Mojo 1.2, so the matcher module is `fnmatch.mojo`.
