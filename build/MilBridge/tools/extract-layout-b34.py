#!/usr/bin/env python3
# T1b · 把 tests/parity/windows/layout-b34/windows-results.json（53MB，只读）
#  流式抽成 build/MilBridge/gen/layout-b34-compact.json（只留 B2 用得上的字段）。
#
# 为什么不用 json.load：53MB 一次性读进 Python 会占 ~1GB 峰值（3 核/7GB 机器上还有别的 agent）。
# 这里按大括号深度扫描，逐个 case 反序列化 —— 峰值 = 单个 case。
#
# 用法：python3 build/MilBridge/tools/extract-layout-b34.py [in.json] [out.json]
import json
import sys
import os

ROOT = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux"
SRC = sys.argv[1] if len(sys.argv) > 1 else ROOT + "/tests/parity/windows/layout-b34/windows-results.json"
DST = sys.argv[2] if len(sys.argv) > 2 else ROOT + "/build/MilBridge/gen/layout-b34-compact.json"


def iter_results(path):
    """逐个产出 results[] 里的对象（dict）。"""
    dec = json.JSONDecoder()
    with open(path, encoding="utf-8") as f:
        buf = ""
        pos = 0
        # 1) 找到 "results" 后的 '['
        while True:
            chunk = f.read(1 << 20)
            if not chunk:
                raise SystemExit("[失败] 没找到 results 数组")
            buf += chunk
            i = buf.find('"results"')
            if i >= 0:
                j = buf.find('[', i)
                if j >= 0:
                    pos = j + 1
                    break
        depth = 0
        in_str = False
        esc = False
        start = -1
        eof = False
        while True:
            if pos >= len(buf) and not eof:
                # 只丢弃**已经解析完**的前缀；正在解析的对象必须整段留在缓冲里
                keep = start if start >= 0 else pos
                buf = buf[keep:]
                pos -= keep
                if start >= 0:
                    start = 0
                chunk = f.read(1 << 20)
                if not chunk:
                    eof = True
                else:
                    buf += chunk
            if pos >= len(buf) and eof:
                return
            c = buf[pos]
            if in_str:
                if esc:
                    esc = False
                elif c == "\\":
                    esc = True
                elif c == '"':
                    in_str = False
            else:
                if c == '"':
                    in_str = True
                elif c == "{":
                    if depth == 0:
                        start = pos
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        yield dec.raw_decode(buf[start:pos + 1])[0]
                        start = -1
                elif c == "]" and depth == 0:
                    return
            pos += 1


def rect(r):
    if not isinstance(r, dict):
        return None
    return [r.get("X"), r.get("Y"), r.get("Width"), r.get("Height")]


def pick_line(L):
    p = L.get("properties") or {}
    out = {
        "i": L.get("lineIndexInText"),
        "len": p.get("Length"),
        "nl": p.get("NewlineLength"),
        "ws": p.get("TrailingWhitespaceLength"),
        "dep": p.get("DependentLength"),
        "start": p.get("Start"),
        "w": p.get("Width"),
        "witw": p.get("WidthIncludingTrailingWhitespace"),
        "h": p.get("Height"),
        "bl": p.get("Baseline"),
        "ext": p.get("Extent"),
        "hasCollapsed": p.get("HasCollapsed"),
        "isTrunc": p.get("IsTruncated"),
        "overflowed": p.get("HasOverflowed"),
        "text": L.get("text"),
        "rt": L.get("lineRuntimeType"),
    }
    lb = L.get("lineBreak")
    out["lbNull"] = None if lb is None else lb.get("isNull")
    out["lbCloneSameRef"] = None if lb is None else lb.get("cloneIsSameReference")
    out["crNull"] = L.get("collapsedRangesIsNull")
    cr = L.get("collapsedRanges")
    if isinstance(cr, list):
        out["cr"] = [[c.get("TextSourceCharacterIndex"), c.get("Length"), c.get("Width")] for c in cr]
    else:
        out["cr"] = None
    for key, tag in (("collapseCharacterEllipsis", "ce"), ("collapseEmptyArgs", "ea")):
        v = L.get(key)
        if not isinstance(v, dict):
            out[tag] = None
            continue
        cc = {
            "hasCollapsed": v.get("hasCollapsed"),
            "len": v.get("length"),
            "w": v.get("width"),
            "crIsNull": v.get("collapsedRangesIsNull"),
            "cr": v.get("collapsedRanges"),
            "text": v.get("text"),
        }
        out[tag] = cc
    if "collapseError" in L:
        out["ceErr"] = L.get("collapseError")
    tb = L.get("textBounds")
    if isinstance(tb, list) and tb:
        runs = tb[0].get("runs")
        if isinstance(runs, list):
            out["runs"] = [[r.get("TextSourceCharacterIndex"), r.get("Length"),
                            r.get("RectangleX"), r.get("RectangleWidth")] for r in runs]
    return out


def main():
    cases = []
    with open(os.path.join(os.path.dirname(SRC), "cases.json"), encoding="utf-8") as f:
        cj = json.load(f)
    byid = {c["id"]: c for c in cj["cases"]}
    n = 0
    for r in iter_results(SRC):
        cid = r.get("id")
        c = byid.get(cid, {})
        cases.append({
            "id": cid,
            "group": r.get("group"),
            "text": (r.get("input") or {}).get("text"),
            "maxWidth": (r.get("input") or {}).get("maxWidth"),
            "fontSize": (r.get("input") or {}).get("fontSize"),
            "fontKey": (r.get("input") or {}).get("fontKey"),
            "trimming": (r.get("input") or {}).get("textTrimming"),
            "alwaysCollapsible": (r.get("input") or {}).get("alwaysCollapsible"),
            "modifierStart": (r.get("input") or {}).get("modifierStart"),
            "modifierEnd": (r.get("input") or {}).get("modifierEnd"),
            "lineCount": r.get("lineCount"),
            "consumed": r.get("consumedLength"),
            "note": c.get("note"),
            "lines": [pick_line(L) for L in (r.get("lines") or [])],
        })
        n += 1
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    with open(DST, "w", encoding="utf-8") as f:
        json.dump({"source": SRC, "caseCount": n, "cases": cases}, f, ensure_ascii=False, indent=1)
    print(f"[ok] {n} 例 → {DST} ({os.path.getsize(DST)/1e6:.1f} MB)")


main()
