#!/usr/bin/env python3
# T1b · 用真机 oracle（build/MilBridge/gen/layout-b34-compact.json）独立复算三类记账口径。
#   **不读 verify.py / verify-report.txt** —— 那是采集方自己的工具，本项目"验证工具会撒谎"有前科。
#   本脚本只读 compact（来源 = 只读的 windows-results.json）。
#
# 输出：build/MilBridge/gen/layout-b34-accounting.txt
import json
import os
import sys
from collections import Counter, defaultdict

ROOT = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux"
SRC = sys.argv[1] if len(sys.argv) > 1 else ROOT + "/build/MilBridge/gen/layout-b34-compact.json"
DST = ROOT + "/build/MilBridge/gen/layout-b34-accounting.txt"

d = json.load(open(SRC, encoding="utf-8"))
cases = d["cases"]
out = []


def p(s=""):
    out.append(s)
    print(s)


def isnl(ch):
    return ch in "\n\r\u2028\u2029\u000b\u000c\u0085"


p("=" * 100)
p(f"T1b · 真机 oracle 三类记账独立复算（{d['source']}）")
p(f"用例 {len(cases)}；行 {sum(len(c['lines']) for c in cases)}")
p("=" * 100)

# ---------- 0. 总览 ----------
groups = Counter(c["group"] for c in cases)
p(f"分组: {dict(groups)}")
nlkinds = Counter()
casesWithNL = []
for c in cases:
    t = c["text"]
    ks = sorted({repr(ch) for ch in t if isnl(ch)})
    if ks:
        casesWithNL.append(c["id"])
        nlkinds[",".join(ks)] += 1
p(f"含硬断/特殊换行字符的用例: {len(casesWithNL)} 例；字符种类分布: {dict(nlkinds)}")
p(f"  用例: {casesWithNL}")
p()

# 行实现类型
p(f"行实现分布: {dict(Counter(L['rt'] for c in cases for L in c['lines']))}")
p()

# ---------- 断言 ①：行区间是否包含硬断字符 ----------
p("-" * 100)
p("【①】行区间**是否包含**换行符 —— 判据：dump 的行原文 len(text) == Length？结尾是不是那个换行字符？")
p("-" * 100)
lines_hard = 0        # NewlineLength>0 且是段落中间行（真硬断）
lines_soft = 0
lines_eop = 0
ok_len, bad_len = 0, []
ok_char, bad_char = 0, []
hardcases = set()
for c in cases:
    lines = c["lines"]
    if not lines:
        continue
    for idx, L in enumerate(lines):
        t = L["text"] or ""
        islast = idx == len(lines) - 1
        if L["nl"] and L["nl"] > 0:
            if islast:
                lines_eop += 1
            else:
                lines_hard += 1
                hardcases.add(c["id"])
        else:
            lines_soft += 1
        # (a) 行原文长度 == Length ?
        if len(t) == L["len"]:
            ok_len += 1
        else:
            bad_len.append((c["id"], idx, L["len"], len(t), repr(t)[:60]))
        # (b) 硬断行的原文结尾是否就是换行字符
        if L["nl"] and L["nl"] > 0:
            tail = t[-L["nl"]:] if L["nl"] <= len(t) else t
            if all(isnl(ch) for ch in tail) and len(tail) == L["nl"]:
                ok_char += 1
            else:
                bad_char.append((c["id"], idx, L["nl"], repr(t), L["json"] if "json" in L else ""))
        else:
            if t and isnl(t[-1]):
                bad_char.append((c["id"], idx, 0, repr(t), "（nl=0 但原文以换行结尾）"))
            else:
                ok_char += 1
nLines = sum(len(c["lines"]) for c in cases)
p(f"行数 {nLines}：NewlineLength>0 且非末行（真硬断行）{lines_hard}；NewlineLength>0 且为末行（EOP）{lines_eop}；NewlineLength=0（软换行/单行）{lines_soft}")
p(f"涉及真硬断的用例数: {len(hardcases)}  {sorted(hardcases)}")
p(f"(a) dump 行原文长度 == Length         : 一致 {ok_len} / 不一致 {len(bad_len)}")
for b in bad_len[:10]:
    p(f"     ❌ {b}")
p(f"(b) NewlineLength 与行原文结尾字符相符 : 一致 {ok_char} / 不一致 {len(bad_char)}")
for b in bad_char[:10]:
    p(f"     ❌ {b}")
verdict1 = (len(bad_len) == 0 and len(bad_char) == 0 and lines_hard > 0)
p(f"⇒ 裁定：行区间 **{'包含' if verdict1 else '口径不明'}** 硬断字符（Length 把它算进去，NewlineLength 单独给出个数；末行 NewlineLength=1 表示 EOP 而非真换行）")
p()

# ---------- 断言 ②：相邻 \n ⇒ 零长度行？----------
p("-" * 100)
p("【②】相邻 `\\n` 产出的是「零长度行」还是「Length=1 内容='\\n' 的行」？")
p("-" * 100)
blank_cases = [c for c in cases if "\n\n" in c["text"]]
p(f"源文本含连续 '\\n\\n' 的用例: {len(blank_cases)} 例  {[c['id'] for c in blank_cases]}")
ok_blank, bad_blank = 0, []
blank_h = []
for c in blank_cases:
    hnorm = None
    for L in c["lines"]:
        if (L["text"] or "") not in ("\n", "\n\n") and L["len"] > 0:
            hnorm = L["h"]
            break
    for L in c["lines"]:
        t = L["text"] or ""
        if t.strip("\n\r") == "" and t != "" and L["len"] <= 2:
            blank_h.append((c["id"], L["len"], L["w"], L["h"], L["bl"], repr(t)))
            if L["len"] == len(t) and L["w"] == 0 and L["h"] == hnorm:
                ok_blank += 1
            else:
                bad_blank.append((c["id"], L["len"], L["w"], L["h"], hnorm, repr(t)))
p(f"识别出的空行（原文仅由换行字符组成）: {len(blank_h)} 行")
p(f"  一致（Length==len(原文) 且 Width==0 且 Height 与同例普通行相同）: {ok_blank} / 不一致 {len(bad_blank)}")
for b in bad_blank[:10]:
    p(f"     ❌ {b}")
p("  原始读数（全部空行）:")
for b in blank_h[:24]:
    p(f"     {b[0]:<24} Length={b[1]} Width={b[2]} Height={b[3]:.6f} Baseline={b[4]:.6f} 原文={b[5]}")
p(f"  零长度行（Length==0）总数: {sum(1 for c in cases for L in c['lines'] if L['len'] == 0)}")
_v2 = "Length=1 且原文就是换行字符的普通行" if (ok_blank and not bad_blank) else "需要复核"
p("⇒ 裁定：相邻 \\n **不是零长度行，而是 " + _v2 + "**（Width=0 但占一行高）")
p()

# ---------- 断言 ③：行尾空白不占宽但占区间 ----------
p("-" * 100)
p("【③】行尾空白：占区间（Length）但**不占 Width**？")
p("-" * 100)
ws_lines = [(c["id"], L) for c in cases for L in c["lines"] if (L["ws"] or 0) > 0]
nows_lines = [(c["id"], L) for c in cases for L in c["lines"] if (L["ws"] or 0) == 0]
p(f"TrailingWhitespaceLength>0 的行: {len(ws_lines)}（覆盖 {len({i for i, _ in ws_lines})} 例）")
p(f"TrailingWhitespaceLength=0 的行: {len(nows_lines)}")
# (a) ws>0 ⇒ Width < WidthIncludingTrailingWhitespace
badA = [x for x in ws_lines if not (x[1]["witw"] is not None and x[1]["w"] is not None and x[1]["witw"] > x[1]["w"] + 1e-9)]
# (b) ws==0 ⇒ Width == WITW
badB = [x for x in nows_lines if not (x[1]["witw"] is not None and abs(x[1]["witw"] - x[1]["w"]) <= 1e-9)]
# (c) 行尾空白确实在区间里：行原文末尾 ws 个字符都是空白
badC = []
for cid, L in ws_lines:
    t = L["text"] or ""
    k = L["ws"]
    if not (len(t) >= k and all(ch.isspace() for ch in t[len(t) - k:]) and (len(t) == k or not t[len(t) - k - 1].isspace())):
        badC.append((cid, L["len"], k, repr(t)))
p(f"(a) ws>0  ⇒ Width < WITW                : 一致 {len(ws_lines)-len(badA)} / 不一致 {len(badA)}")
for b in badA[:8]:
    p(f"     ❌ {b[0]} len={b[1]['len']} w={b[1]['w']} witw={b[1]['witw']} ws={b[1]['ws']}")
p(f"(b) ws=0  ⇒ Width == WITW               : 一致 {len(nows_lines)-len(badB)} / 不一致 {len(badB)}")
for b in badB[:8]:
    p(f"     ❌ {b[0]} len={b[1]['len']} w={b[1]['w']} witw={b[1]['witw']}")
p(f"(c) 行原文末尾确有恰好 ws 个空白字符   : 一致 {len(ws_lines)-len(badC)} / 不一致 {len(badC)}")
for b in badC[:8]:
    p(f"     ❌ {b}")
p("  原始读数（样例，含差额）:")
for cid, L in ws_lines[:12]:
    p(f"     {cid:<24} 行起点={L['i']:<4} Length={L['len']:<4} ws={L['ws']} Width={L['w']:.4f} WITW={L['witw']:.4f} 差={L['witw']-L['w']:.4f} 原文={L['text']!r}")
p(f"⇒ 裁定：行尾空白 **{'占区间、不占 Width、差额由 WidthIncludingTrailingWhitespace 给出' if not (badA or badB or badC) else '需要复核'}**")
p()

# ---------- GetTextLineBreak / GetTextCollapsedRanges / Collapse ----------
p("-" * 100)
p("【④】GetTextLineBreak / GetTextCollapsedRanges / Collapse 的真机形态")
p("-" * 100)
lbN = sum(1 for c in cases for L in c["lines"] if L["lbNull"] is False)
lbNull = sum(1 for c in cases for L in c["lines"] if L["lbNull"] is True)
p(f"GetTextLineBreak(): null {lbNull} 行 / 非 null {lbN} 行")
for c in cases:
    for L in c["lines"]:
        if L["lbNull"] is False:
            p(f"  非 null: {c['id']} 行#{L['i']} rt={L['rt']} len={L['len']} 行原文={L['text']!r} cloneSameRef={L['lbCloneSameRef']} 源文本={c['text'][:70]!r}")
p(f"GetTextCollapsedRanges(): null {sum(1 for c in cases for L in c['lines'] if L['crNull'])} 行 / 非 null {sum(1 for c in cases for L in c['lines'] if L['crNull'] is False)} 行")
p(f"Collapse(空参): 有记录的行 {sum(1 for c in cases for L in c['lines'] if L['ea'])}；hasCollapsed=true {sum(1 for c in cases for L in c['lines'] if L['ea'] and L['ea']['hasCollapsed'])}")
ce = [(c, L) for c in cases for L in c["lines"] if L["ce"]]
p(f"Collapse(TextTrailingCharacterEllipsis): 有记录的行 {len(ce)}；其中 hasCollapsed=true {sum(1 for _, L in ce if L['ce']['hasCollapsed'])}")
errs = Counter(str(L.get("ceErr")) for c in cases for L in c["lines"] if L.get("ceErr"))
p(f"Collapse 异常: {dict(errs)}")
p("  真实折叠样例（全部 hasCollapsed=true 的行，最多 30 条）:")
n = 0
for c, L in ce:
    if not L["ce"]["hasCollapsed"]:
        continue
    n += 1
    if n > 30:
        break
    p(f"     {c['id']:<22} trim={c['trimming']:<17} 行#{L['i']:<3} 行原文={L['text']!r} 行Length={L['len']} 行Width={L['w']:.4f} ws={L['ws']}")
    p(f"        ↳ 折后 Length={L['ce']['len']} Width={L['ce']['w']} crIsNull={L['ce']['crIsNull']} cr={L['ce']['cr']} 折后原文={L['ce']['text']!r}")
p(f"  hasCollapsed=true 的行总数 = {n if n <= 30 else '>30'}")
p()

# ---------- 与 73 例相关的 A 组结构 ----------
p("-" * 100)
p("【⑤】A 组（CJK / 中英混排）结构 —— 73 例规则集对拍的候选基准")
p("-" * 100)
A = [c for c in cases if c["group"] == "A"]
p(f"A 组 {len(A)} 例；fontKey={dict(Counter(c['fontKey'] for c in A))}；fontSize={dict(Counter(c['fontSize'] for c in A))}")
texts = defaultdict(list)
for c in A:
    texts[c["text"]].append(c)
p(f"A 组不同文本样本 {len(texts)} 个：")
for t, cs in texts.items():
    cjk = sum(1 for ch in t if ord(ch) >= 0x2E80)
    p(f"   w档 {len(cs):>3} 个  长度{len(t):>3}  CJK字符{cjk:>3}  fontKey={cs[0]['fontKey']:<5} trim={cs[0]['trimming']:<17} text={t[:64]!r}")

os.makedirs(os.path.dirname(DST), exist_ok=True)
open(DST, "w", encoding="utf-8").write("\n".join(out) + "\n")
print(f"\n[ok] → {DST}")
