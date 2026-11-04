# API

`from glob import glob, fnmatch, fnmatchcase, filter, has_magic, Pattern`

| Call | Does |
|---|---|
| `glob(pathname, root_dir="", recursive=False, include_hidden=False) -> List[String]` | Python `glob.glob`. Results in directory order (unsorted), relative to `root_dir` when given. `**` matches any depth only with `recursive=True`. Names starting with `.` match only a pattern starting with `.`, unless `include_hidden`. |
| `fnmatch(name, pat)`, `fnmatchcase(name, pat) -> Bool` | Whole-name match; identical on POSIX. |
| `filter(names, pat) -> List[String]` | Names matching `pat`, pattern compiled once. |
| `has_magic(s) -> Bool` | Contains `*`, `?` or `[`. |
| `Pattern(pat)`, `p.matches(name) -> Bool` | Compiled pattern for repeated matching. |

Pattern syntax: `*` any run, `?` one codepoint, `[abc]`, `[a-z]`, `[!abc]` (negated). An unclosed `[` is literal; `]` first in a class is a member. No escape character, as in Python (use `[*]`).
