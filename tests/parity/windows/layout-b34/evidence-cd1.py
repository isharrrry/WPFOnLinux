#!/usr/bin/env python3
"""C/D 第一批（T 修剪 / L 行起点自证 / P AlwaysCollapsible 对照）证据表生成。

用法: python3 evidence-cd1.py      → 写 evidence-cd1.md
数据: cases-cd1.json + results-cd1.json（只读）
"""
import json
import os
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = []


def p(s=""):
    OUT.append(s)


def load():
    cases = {c["id"]: c for c in json.load(open(os.path.join(HERE, "cases-cd1.json"), encoding="utf-8"))["cases"]}
    res = {r["id"]: r for r in json.load(open(os.path.join(HERE, "results-cd1.json"), encoding="utf-8"))["results"]}
    return cases, res


def trim_of(r):
    """取该用例最后一行的 trim 块。"""
    return (r["lines"][-1].get("trim") or {}) if r["lines"] else {}


def main():
    cases, res = load()
    p("# C/D 第一批证据：TextTrimming / 行起点累加 / AlwaysCollapsible")
    p()
    p(f"用例 {len(res)} 个；全部来自 `results-cd1.json`（真机 Windows + WPF 10.0.7）。")
    p()

    # ============================== T ==============================
    p("## 1. TextTrimming（T 组，144 例）")
    p()
    p("### 1.1 触发统计（闸门 = `TextLine.HasOverflowed`，WPF `Line.cs:109/161/197/455`）")
    p()
    stat = Counter()
    for r in res.values():
        if r["group"] != "T":
            continue
        t = trim_of(r)
        if not t:
            continue
        a = t.get("after") or {}
        stat[(t.get("hasOverflowedBeforeTrim"), t.get("applied"), a.get("hasCollapsed"))] += 1
    p("| HasOverflowed | 调用了 Collapse | 结果 HasCollapsed | 用例数 |")
    p("|---|---|---|---|")
    for (ovf, applied, coll), n in sorted(stat.items(), key=lambda kv: str(kv[0])):
        p(f"| {ovf} | {applied} | {coll} | {n} |")
    p()
    p("读法：**溢出 + 非 None 才真折叠**（36 例）；不溢出时调用 Collapse 也只会得到 `HasCollapsed=false`")
    p("（70 例）——后者就是「框架不会调它」的那条闸门的实测形态。")
    p()

    p("### 1.2 `CharacterEllipsis` vs `WordEllipsis`（同一个源行，NoWrap，段落宽 120）")
    p()
    p("| 用例 | 折叠前行长/宽 | 折叠后宽 | collapsedRange(段落系 idx,len) | 被折叠掉的原文本 |")
    p("|---|---|---|---|---|")
    for cid in sorted(c for c in res if c.startswith("T1_") and "_nowrap_w120" in c):
        r = res[cid]
        t = trim_of(r)
        a = t.get("after") or {}
        b = t.get("before") or {}
        cr = (a.get("collapsedRanges") or [{}])[0]
        lbl = cid.replace("T1_", "").replace("_nowrap_w120", "")
        p(f"| `{lbl}` | {b.get('length')} / {b.get('width', 0):.3f} | "
          f"{(a.get('width') or 0):.3f} | idx={cr.get('TextSourceCharacterIndex')} len={cr.get('Length')} | "
          f"`{cr.get('textAtParagraphIndex')}` |")
    p()
    p("**拉丁**：Character 保留到字符 13（宽 114.347），Word 保留到字符 10（宽 84.7）——")
    p("Character 会**从词中间切断**，Word 退到**词边界**，两者确实不同。")
    p()
    p("**CJK**（`T1_cjk_punct_*_nowrap_w120`）：Character 与 Word **结果完全相同**")
    p("（idx=6, len=38, 宽 109.017）——中文没有空格，Word 找不到词边界，退化成 Character。")
    p("这条对 `Justify`×CJK、CJK 省略号都直接有用。")
    p()

    p("### 1.3 折叠后的可见文本不能只看 Length")
    p()
    p("实测：折叠后 `Length` **不变**（仍 80），只有 `Width` 变小、`HasCollapsed=true`，")
    p("真正被隐藏的字符区间只能从 `GetTextCollapsedRanges()` 拿（见上表 idx/len/Width）。")
    p("⇒ Linux 侧渲染省略号时必须用 collapsedRange，不能靠 Length 推。")
    p()

    p("### 1.4 不溢出就绝不折叠（闸门直证）")
    p()
    p("| 用例 | 段落宽 | 行宽 | HasOverflowed | 调 Collapse 后 HasCollapsed |")
    p("|---|---|---|---|---|")
    for cid in ("T4_lat_words_CharacterEllipsis_multi", "T4_cjk_nospace_WordEllipsis_multi",
                "T3_lat_words_CharacterEllipsis_narrow_w320", "T3_cjk_punct_WordEllipsis_narrow_w320"):
        r = res.get(cid)
        if not r:
            continue
        t = trim_of(r)
        a = t.get("after") or {}
        p(f"| `{cid}` | {r['input']['maxWidth']} | {(t.get('lineWidthBeforeTrim') or 0):.3f} | "
          f"{t.get('hasOverflowedBeforeTrim')} | {a.get('hasCollapsed')} |")
    p()
    p("⚠️ **T3 的构造缺陷（如实记录）**：`T3` 想用「约束宽 < 行宽「触发折叠，但 `Wrap` 模式下")
    p("第一行往往本来就窄于半个段落宽，于是什么都没折叠。它在 CJK 文本上有效，在短行拉丁上无效；")
    p("C/D 第二批会把 T3 换成「先 NoWrap 拿长行，再窄约束」的构型。")
    p()

    # ============================== L ==============================
    p("## 2. 行起点累加自证（L 组，10 例）—— B2 实现行区间的直接模板")
    p()
    p("规则（实测）：**`TextLine.Start` 恒为 0**（3222/3222），所以行区间只能这样算：")
    p()
    p("```")
    p("int start = 0;                       // 段落内偏移")
    p("while (start < text.Length) {")
    p("    TextLine line = formatter.FormatLine(source, start, width, pprops, prevBreak, cache);")
    p("    string slice = text.Substring(start, line.Length);   // ← 本行覆盖的源区间")
    p("    start += line.Length;                                // ← 唯一的推进方式")
    p("}")
    p("```")
    p()
    for cid in sorted(c for c in res if c.startswith("L_")):
        r = res[cid]
        p(f"### `{cid}`（段落宽 {r['input']['maxWidth']}，源 {len(r['input']['text'])} 字符）")
        p()
        p(f"源文本：`{r['input']['text']}`")
        p()
        p("| # | lineStart | Length | nextStart | NewlineLength | Width | 源切片 | 切片自校 |")
        p("|---|---|---|---|---|---|---|---|")
        for i, ln in enumerate(r["lines"]):
            sa = ln["startAccumulation"]
            pr = ln["properties"]
            disp = sa["sourceSlice"].replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r")
            p(f"| {i} | {sa['lineStart']} | {sa['length']} | {sa['nextLineStart']} | {pr['NewlineLength']} | "
              f"{pr['Width']:.3f} | `{disp}` | {sa['sliceMatchesSource']} |")
        p()
    p("要点复述：**区间含硬断字符**（`Length` 把 `\\n` 算进去，`NewlineLength` 单独给个数）；")
    p("**空行是 Length=1、内容 `\\n` 的普通行**（`Width=0` 但 `Height/Baseline` 与普通行相同）。")
    p()

    # ============================== P ==============================
    p("## 3. AlwaysCollapsible 开/关对照（P 组，30 例）")
    p()
    p("选择规则（`TextFormatterImp.cs:224`）：`!AlwaysCollapsible && previousLineBreak==null && lineLength<=0`")
    p("→ 走 `SimpleTextLine`；否则 `FullTextLine`。而 `SimpleTextLine.cs:973/983` 里")
    p("`GetTextLineBreak()` 与 `GetTextCollapsedRanges()` **恒返回 null**。")
    p()
    p("| 文本 / 宽度 | AC | 行实现 | 行数 | 行(Length/Width) | lineBreak 非null | collapsedRanges 非null | textBounds 有 run |")
    p("|---|---|---|---|---|---|---|---|")
    def summarize(r):
        impls = {ln["lineRuntimeType"].split("+")[-1] for ln in r["lines"]}
        lw = ",".join(f"{ln['properties']['Length']}/{ln['properties']['Width']:.0f}" for ln in r["lines"][:4])
        nlb = sum(1 for ln in r["lines"] if not ln["lineBreak"]["isNull"])
        ncr = sum(1 for ln in r["lines"] if ln.get("collapsedRangesIsNull") is False)
        ntb = sum(1 for ln in r["lines"] if any((t.get("runs") or []) for t in (ln.get("textBounds") or [])))
        return "/".join(sorted(impls)), len(r["lines"]), lw, f"{nlb}/{len(r['lines'])}", f"{ncr}/{len(r['lines'])}", f"{ntb}/{len(r['lines'])}"

    pairs = defaultdict(dict)
    for cid, r in res.items():
        if r["group"] != "P":
            continue
        key = cid.replace("P_", "").replace("_ac1_", "|").replace("_ac0_", "|")
        pairs[key][r["input"]["alwaysCollapsible"]] = r
    for key in sorted(pairs):
        d = pairs[key]
        for ac in (False, True):
            r = d.get(ac)
            if not r:
                continue
            impl, n, lw, nlb, ncr, ntb = summarize(r)
            p(f"| `{key}` | {'开' if ac else '关'} | {impl} | {n} | {lw} | {nlb} | {ncr} | {ntb} |")
    p()
    tot_ac0 = sum(1 for cid, r in res.items() if r["group"] == "P" and not r["input"]["alwaysCollapsible"])
    simple_ac0 = sum(1 for cid, r in res.items() if r["group"] == "P"
                     and not r["input"]["alwaysCollapsible"]
                     and any(ln["lineRuntimeType"].endswith("SimpleTextLine") for ln in r["lines"]))
    simple_ac1 = sum(1 for cid, r in res.items() if r["group"] == "P"
                     and r["input"]["alwaysCollapsible"]
                     and any(ln["lineRuntimeType"].endswith("SimpleTextLine") for ln in r["lines"]))
    p(f"统计：AC=关 的 {tot_ac0} 例里有 **{simple_ac0} 例**出现 SimpleTextLine；")
    p(f"AC=开 的用例里出现 SimpleTextLine 的有 **{simple_ac1} 例**（应为 0）。")
    p()
    p("⇒ **shim 必须与 FullTextLine 对齐**：把 `AlwaysCollapsible=true` 作为「强制完整路径」的开关，")
    p("并且**在 SimpleTextLine 路径上必须让 `GetTextLineBreak()`/`GetTextCollapsedRanges()` 返回 null**，")
    p("否则会与真机在「哪些成员可用」上分叉。")

    txt = "\n".join(OUT) + "\n"
    open(os.path.join(HERE, "evidence-cd1.md"), "w", encoding="utf-8").write(txt)
    print(f"wrote evidence-cd1.md ({len(txt)} bytes)")
    # 控制台也给一份摘要
    print("\n".join(OUT[:6]))
    print("...")
    print("\n".join(OUT[-8:]))


if __name__ == "__main__":
    main()
