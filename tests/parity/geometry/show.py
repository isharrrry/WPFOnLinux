#!/usr/bin/env python3
"""U1c 对拍逐例查看器：打印指定 case 的两侧结果（含向量逐元素对照）。

用法：
    python3 show.py <case-id> [<case-id> ...]        # 摘要 + 差异元素
    python3 show.py --all-nonmatch                   # 所有非一致用例
    python3 show.py --fn MilUtility_PathGeometryBounds
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name):
    with open(os.path.join(HERE, name), encoding="utf-8") as fh:
        return json.load(fh)


def fmt(v):
    if isinstance(v, float):
        if v != v:
            return "NaN"
        if v in (float("inf"), float("-inf")):
            return "+INF" if v > 0 else "-INF"
        return repr(v)
    return str(v)


def close(a, b, atol=1e-6, rtol=2e-5):
    if isinstance(a, float) and a != a:
        return isinstance(b, float) and b != b
    if a == b:
        return True
    try:
        d = abs(a - b)
    except TypeError:
        return False
    scale = max(abs(a), abs(b))
    return d <= atol or (scale > 0 and d / scale <= rtol)


def show(cid, cases, win, lin, verbose=True):
    c = cases.get(cid)
    w = win.get(cid)
    l = lin.get(cid)
    print("=" * 78)
    print(f"CASE {cid}   fn={c['fn'] if c else '?'}")
    if c and c.get("note"):
        print(f"  意图: {c['note']}")
    if w is None or l is None:
        print("  缺结果:", "win" if w is None else "", "lin" if l is None else "")
        return
    print(f"  hr    win=0x{w['Hr'] & 0xFFFFFFFF:08X} lin=0x{l['Hr'] & 0xFFFFFFFF:08X}")
    if w.get("Error") or l.get("Error"):
        print(f"  err   win={w.get('Error')} lin={l.get('Error')}")

    keys = sorted(set(w["Scalars"]) | set(l["Scalars"]))
    for k in keys:
        a, b = w["Scalars"].get(k), l["Scalars"].get(k)
        mark = "  " if close(a, b) else "!!"
        print(f"  {mark} S {k}: win={fmt(a)} lin={fmt(b)}")

    for k in sorted(set(w["Vectors"]) | set(l["Vectors"])):
        a, b = w["Vectors"].get(k), l["Vectors"].get(k)
        if a is None or b is None:
            print(f"  !! V {k}: win={None if a is None else len(a)} lin={None if b is None else len(b)}")
            continue
        if len(a) != len(b):
            print(f"  !! V {k}: 长度 win={len(a)} lin={len(b)}")
        if not verbose:
            continue
        diffs = [(i, a[i], b[i]) for i in range(min(len(a), len(b))) if not close(a[i], b[i])]
        if not diffs:
            print(f"     V {k}: [{len(a)}] 一致  win[:8]={[round(x, 6) for x in a[:8]]}")
        else:
            print(f"  !! V {k}: [{len(a)}] {len(diffs)} 处不同")
            for i, x, y in diffs[:12]:
                print(f"        [{i}] win={fmt(x)}  lin={fmt(y)}")
            if len(diffs) > 12:
                print(f"        ... 还有 {len(diffs) - 12} 处")

    for k in sorted(set(w["Buffers"]) | set(l["Buffers"])):
        a, b = w["Buffers"].get(k), l["Buffers"].get(k)
        mark = "  " if a == b else "!!"
        print(f"  {mark} B {k}: win={a} lin={b}")


def main():
    raw = load("cases.json")["Cases"]
    cases = {c["Id"]: {"fn": c["Fn"], "note": c.get("Note")} for c in raw}
    win = {r["Id"]: r for r in load("windows-results.json")["results"]}
    lin = {r["Id"]: r for r in load("linux-results.json")["results"]}

    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    if args[0] == "--all-nonmatch":
        summary = load("summary.json")
        for c in summary["cases"]:
            if c["Verdict"] not in ("Identical", "Close"):
                show(c["Id"], cases, win, lin, verbose=False)
        return
    if args[0] == "--fn":
        summary = load("summary.json")
        for c in summary["cases"]:
            if c["Fn"] == args[1]:
                show(c["Id"], cases, win, lin, verbose=False)
        return
    for cid in args:
        show(cid, cases, win, lin)


if __name__ == "__main__":
    main()
