# fnmatch throughput: 3 patterns over 20,000 names, compiled once (Pattern) and per call (fnmatch).
from std.time import perf_counter_ns
from glob import Pattern, fnmatch


def main():
    var names = List[String]()
    for i in range(20000):
        names.append(String("src/module_", i, "/file_", i * 7 % 1000, ".py" if i % 3 == 0 else ".txt"))
    var pats: List[String] = ["*.py", "src/module_1*/*_[0-4]?.txt", "*[!a-z]*.py"]
    var hits = 0
    for p in pats:
        var t0 = perf_counter_ns()
        var c = Pattern(p)
        for n in names:
            hits += Int(c.matches(n))
        var t1 = perf_counter_ns()
        for n in names:
            hits += Int(fnmatch(n, p))
        var t2 = perf_counter_ns()
        var k = Float64(len(names))
        print(p, " Pattern ns/match", Float64(t1 - t0) / k, " fnmatch ns/call", Float64(t2 - t1) / k)
    print("hits", hits)
