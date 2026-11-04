---
name: mojo-glob
description: "Match shell wildcards (fnmatch) and list files by pattern (glob, recursive **) in Mojo with mojo-glob, identical to Python's fnmatch and glob. Use for file discovery, include/exclude filters, CLI argument expansion in Mojo."
---

# mojo-glob

```mojo
from glob import glob, Pattern
var files = glob("**/*.mojo", root_dir=repo, recursive=True)   # relative paths, unsorted
var keep = Pattern("[!_]*.py")
```

- Results are in directory order: `sort(files)` for stable output.
- `**` needs `recursive=True`; hidden names need a pattern starting with `.` or `include_hidden=True`.
- In a loop, compile with `Pattern` (a `[` class costs a compile per `fnmatch` call).

Gate: `scripts/ci.sh` (Python fnmatch/glob oracle, mutants, api, quickstart).
