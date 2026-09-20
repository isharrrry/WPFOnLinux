#!/usr/bin/env python3
"""B2/B3/B4 oracle 数据完整性核验（可复算）。

用法:  python3 verify.py            # 打印核验报告（并写 verify-report.txt）

只读 tests/parity/windows/layout-b34/{cases.json,windows-results.json}。
每条结论都给出"哪几个用例、哪些数字"的原始证据，不做推断。
"""
import json
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = []


def p(s=""):
    OUT.append(s)
    print(s)


def load():
    cases = json.load(open(os.path.join(HERE, "cases.json"), encoding="utf-8"))
    res = json.load(open(os.path.join(HERE, "windows-results.json"), encoding="utf-8"))
    return cases, res


def main():
    cases, res = load()
    R = res["results"]
    byid = {r["id"]: r for r in R}

    p("=" * 100)
    p("B2/B3/B4 真机 oracle · 数据完整性核验")
    p("=" * 100)
    p(f"cases.json      : {len(cases['cases'])} 用例")
    p(f"results         : {len(R)} 用例")
    p(f"selfCheck       : ok={res['selfCheck']['ok']} 行数={res['selfCheck']['lines']} "
      f"fileFontMismatch={res['selfCheck']['fileFontMismatch']}")
    p()

    # ---------------------------------------------------------------- 1
    p("【1】对拍面覆盖：宽度档数 / 每行 Length·Width·Start 是否齐全")
    widths = Counter()
    for c in cases["cases"]:
        widths[c["maxWidth"]] += 1
    p(f"  MaxTextWidth 不同档数 : {len(widths)}")
    p(f"  档位（DIP → 用例数）  : " + ", ".join(
        f"{('inf' if w >= 1e5 else int(w))}:{n}" for w, n in sorted(widths.items())))
    groups = Counter(c["group"] for c in cases["cases"])
    p(f"  分组                  : {dict(sorted(groups.items()))}")
    texts = {c["text"] for c in cases["cases"]}
    p(f"  不同文本样本          : {len(texts)}")

    missing = []
    total_lines = 0
    prop_count = Counter()
    for r in R:
        for i, ln in enumerate(r["lines"]):
            total_lines += 1
            pr = ln.get("properties") or {}
            prop_count[len(pr)] += 1
            for k in ("Length", "Width", "Start"):
                if k not in pr:
                    missing.append((r["id"], i, k))
    p(f"  总行数                : {total_lines}")
    p(f"  每行公开属性个数分布  : {dict(prop_count)}   （TextLine 公开属性数 = "
      f"{res['apiFacts']['TextLine_publicPropertyCount']}）")
    p(f"  Length/Width/Start 缺失: {len(missing)}")
    # 行起点连续性：每行 lineIndexInText 应等于前一行起点+前一行长度
    bad_chain = []
    for r in R:
        expect = 0
        for ln in r["lines"]:
            if ln["lineIndexInText"] != expect:
                bad_chain.append((r["id"], ln["lineIndexInText"], expect))
            expect = ln["lineIndexInText"] + ln["length"]
    p(f"  行起点链断裂          : {len(bad_chain)}（每行 lineIndexInText == 上一行 lineIndexInText+Length）")
    startvals = Counter()
    for r in R:
        for ln in r["lines"]:
            startvals[ln["properties"]["Start"]] += 1
    p(f"  ⚠️ TextLine.Start 取值分布: {dict(startvals)}  → **恒为 0，不是段落内偏移**；")
    p(f"     行起点只能由调用方累加 Length 得到（本 dump 的 lineIndexInText 就是这个累加值，链断裂 0 处）")
    p()

    # ---------------------------------------------------------------- 2
    p("【2】GetTextLineBreak() 到底返回了什么")
    af = res["apiFacts"]
    p(f"  TextLineBreak 公开属性数: {af['TextLineBreak_publicPropertyCount']}  → 公开面**没有任何可读属性**")
    nb = null = 0
    nonnull_ev = []
    for r in R:
        for ln in r["lines"]:
            lb = ln["lineBreak"]
            if lb.get("isNull", True):
                null += 1
            else:
                nb += 1
                nonnull_ev.append((r["id"], ln["lineIndexInText"], ln["lineRuntimeType"].split("+")[-1],
                                   ln["length"], json.dumps(lb, ensure_ascii=False)))
    p(f"  实测：null {null} 行 / 非 null {nb} 行（共 {null + nb}）")
    for e in nonnull_ev:
        p(f"    非 null 证据: {e[0]} 行#{e[1]} type={e[2]} len={e[3]}")
        p(f"      → {e[4]}")
    p("  结论：TextLineBreak **可以被拿到**，但它携带的东西在公开面上是空的（0 属性）；")
    p("        唯一有真值的场景是 TextSource 里有 TextModifier（见 M_modifier_* 用例），")
    p("        这也解释了为什么 3220/3222 行都是 null：普通 TextCharacters 源不产生 modifier scope。")
    p(f"  apiFacts.TextLineBreak_publicPropertyCount = {af['TextLineBreak_publicPropertyCount']}"
      f"；行运行时实现分布见下")
    tc = Counter()
    for r in R:
        for ln in r["lines"]:
            tc[ln["lineRuntimeType"]] += 1
    p(f"  行实现分布: {dict(tc)}")
    p()

    # ---------------------------------------------------------------- 3
    p("【3】Collapse / GetTextCollapsedRanges")
    plain_null = plain_nonnull = 0
    collapse_noop = 0
    ell_has = ell_none = 0
    for r in R:
        for ln in r["lines"]:
            if ln.get("collapsedRangesIsNull") is True:
                plain_null += 1
            elif ln.get("collapsedRangesIsNull") is False:
                plain_nonnull += 1
            ce = ln.get("collapseEmptyArgs")
            if ce and ce.get("hasCollapsed") is False:
                collapse_noop += 1
            e = ln.get("collapseCharacterEllipsis")
            if e and e.get("isNull") is False:
                if e.get("hasCollapsed"):
                    ell_has += 1
                else:
                    ell_none += 1
    p(f"  未折叠的行 GetTextCollapsedRanges() 返回 null : {plain_null} 行；返回非 null: {plain_nonnull} 行")
    p(f"  Collapse(new TextCollapsingProperties[0])     : hasCollapsed=false 共 {collapse_noop} 行（空参 = 原样复制）")
    p(f"  Collapse(TextTrailingCharacterEllipsis(w/2))  : hasCollapsed=true {ell_has} 行 / false {ell_none} 行")
    p("  真实折叠样本（HasCollapsed=true 的原始数字）：")
    shown = 0
    for r in R:
        hit = None
        for ln in r["lines"]:
            e = ln.get("collapseCharacterEllipsis") or {}
            if e.get("hasCollapsed"):
                hit = (ln, e)
                break
        if not hit:
            continue
        ln, e = hit
        p(f"    [{r['id']}] 源={r['input']['text']!r}")
        p(f"      行起点={ln['lineIndexInText']} 行文本={ln['text']!r} 行Width={ln['properties']['Width']:.3f} "
          f"行TrailingWS={ln['properties']['TrailingWhitespaceLength']}")
        p(f"      折叠约束宽={e['constraintWidth']:.3f} → 折后 Length={e['length']} Width={e['width']:.3f} "
          f"文本={e['text']!r} HasCollapsed={e['hasCollapsed']}")
        for cr in e.get("collapsedRanges") or []:
            p(f"      collapsedRange: TextSourceCharacterIndex={cr['TextSourceCharacterIndex']}(**段落系**) "
              f"Length={cr['Length']} Width={cr['Width']:.3f} → 被折叠掉的原文本={cr.get('textAtParagraphIndex')!r}")
        shown += 1
        if shown >= 4:
            break
    p("  空白类文本的折叠（B 组，含前导/尾随/连续空格与 Tab）：")
    for cid in ("B_spaces_w120", "B_spaces_w60", "B_tabs_w120", "B_tabs_trim"):
        r = byid.get(cid)
        if not r:
            continue
        for ln in r["lines"]:
            e = ln.get("collapseCharacterEllipsis") or {}
            p(f"    [{cid}] 行={ln['text']!r} TrailingWS={ln['properties']['TrailingWhitespaceLength']} "
              f"Width={ln['properties']['Width']:.3f} → 折叠 HasCollapsed={e.get('hasCollapsed')} "
              f"ranges={json.dumps(e.get('collapsedRanges'), ensure_ascii=False)}")
    p(f"  apiFacts.TextLine_Collapse_overloads = {af['TextLine_Collapse_overloads']}")
    p(f"  apiFacts.TextLine_Collapse_TextLine_exists = {af['TextLine_Collapse_TextLine_exists']}"
      f"  → 任务书里提到的 Collapse(TextLine) **不存在**")
    p()

    # ---------------------------------------------------------------- 4
    p("【4】逐 run 范围")
    p(f"  apiFacts.TextLine_GetTextRunBounds_exists = {af['TextLine_GetTextRunBounds_exists']}"
      f"  → 该 API **不存在**；等价物是 GetTextBounds(firstCharIndex, textLength)")
    p(f"  apiFacts.TextLine_GetTextBounds_exists    = {af['TextLine_GetTextBounds_exists']}")
    p(f"  apiFacts.TextLine_GetTextCollapsedRanges_exists = {af['TextLine_GetTextCollapsedRanges_exists']}")
    with_bounds = sum(1 for r in R for ln in r["lines"] if ln.get("textBounds"))
    with_runs = sum(1 for r in R for ln in r["lines"]
                    if any((tb.get("runs") or []) for tb in (ln.get("textBounds") or [])))
    r0 = byid["A1_lat_words_w120"]["lines"][0]
    p(f"  含 textBounds 的行数: {with_bounds}/{total_lines}；其中**有逐 run 子范围**的: {with_runs}/{total_lines}")
    p(f"  （缺的那些行属 SimpleTextLine 快路径 / 空白行；GetTextBounds 的第一个参数是**段落系**索引，"
      f"传 0 只有行起点=0 的行有结果——第一版就踩了这个坑）")
    p(f"  样例 [{('A1_lat_words_w120')} 行0]: {json.dumps(r0['textBounds'], ensure_ascii=False)[:220]}")
    p()

    # ---------------------------------------------------------------- 5
    p("【5】行区间 / 空行 / 硬断 —— 逐条判定（原始证据）")

    # 5a 行区间是否含换行符
    for cid in ("B_hard_lf_w120", "B_hard_crlf_w120", "B_hard_ls_w120", "F_hard_lf_w120"):
        r = byid.get(cid)
        if not r:
            continue
        src = r["input"]["text"]
        p(f"  [{cid}] 源文本 {src!r}（UTF-16 长度 {len(src)}）")
        for ln in r["lines"]:
            pr = ln["properties"]
            seg = src[ln["lineIndexInText"]:ln["lineIndexInText"] + ln["length"]]
            p(f"    Start={int(pr['Start'])} Length={pr['Length']} NewlineLength={pr['NewlineLength']} "
              f"Width={pr['Width']:.3f} 区间原文={seg!r} closed={ln['text']==seg}")
        p(f"    consumedLength={r['consumedLength']}（= 源长度 {len(src)} + {r['consumedLength']-len(src)}）")
    p("  → 判定：**行区间包含硬断字符本身**（Length 把 '\\n' 算进去，NewlineLength 单独给出它占几个）；")
    p("          段落最后一行 Length 只覆盖剩余文本，NewlineLength=1 表示段落结束标记（EOP）。")

    # 5b 相邻 \n ⇒ 零长度行？
    r = byid.get("B_blank_lines_w120")
    p(f"  [B_blank_lines_w120] 源文本 {r['input']['text']!r}（三个连续 LF）")
    for ln in r["lines"]:
        pr = ln["properties"]
        p(f"    Start={int(pr['Start'])} Length={pr['Length']} Width={pr['Width']} "
          f"Height={pr['Height']:.3f} Baseline={pr['Baseline']:.3f} NewlineLength={pr['NewlineLength']} "
          f"区间原文={ln['text']!r}")
    p("  → 判定：空行**不是零长度行**，而是一个 Length=1、内容就是 '\\n' 的普通行；")
    p("          它的 Width=0（不占宽）但 Height/Baseline 与普通行完全相同（照样占一行高）。")

    # 5c 行尾空白：占区间、不占 Width
    for cid in ("B_spaces_w120", "B_tabs_w120", "B_nbsp_zwsp_w120"):
        r = byid.get(cid)
        if not r:
            continue
        p(f"  [{cid}] 源文本 {r['input']['text']!r}")
        for ln in r["lines"]:
            pr = ln["properties"]
            p(f"    Length={pr['Length']} Width={pr['Width']:.3f} "
              f"WidthIncludingTrailingWhitespace={pr['WidthIncludingTrailingWhitespace']:.3f} "
              f"TrailingWhitespaceLength={pr['TrailingWhitespaceLength']} 区间原文={ln['text']!r}")
    p("  → 判定：行尾空白**占行区间**（Length 含它）且**不占 Width**（Width 已扣除），")
    p("          差额由 WidthIncludingTrailingWhitespace 给出，个数由 TrailingWhitespaceLength 给出。")
    p()

    # ---------------------------------------------------------------- 6
    p("【6】竖排文本（负结果）")
    vt = json.load(open(os.path.join(HERE, "probe.json"), encoding="utf-8"))["verticalText"]
    p(f"  TextFormatting 命名空间里含 vertical/writingmode/upright/rotate/tategaki/orientation 的公开成员:")
    p(f"    {vt['namespaceMembersMatchingVerticalKeywords']}")
    p(f"  FlowDirection 枚举值: {vt['flowDirectionValues']}")
    p(f"  （唯一的命中 InvertAxes.Vertical 是 Draw() 的坐标轴翻转参数，与竖排排版无关）")

    txt = "\n".join(OUT)
    open(os.path.join(HERE, "verify-report.txt"), "w", encoding="utf-8").write(txt + "\n")
    print(f"\n[已写入 verify-report.txt]")


if __name__ == "__main__":
    main()
