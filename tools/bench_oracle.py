import fnmatch, time
names = [f"src/module_{i}/file_{i*7%1000}{'.py' if i%3==0 else '.txt'}" for i in range(20000)]
pats = ["*.py", "src/module_1*/*_[0-4]?.txt", "*[!a-z]*.py"]
for p in pats:
    t = time.perf_counter(); h = sum(fnmatch.fnmatchcase(n, p) for n in names)
    print(p, " python fnmatchcase ns/call", round((time.perf_counter() - t) / len(names) * 1e9))
