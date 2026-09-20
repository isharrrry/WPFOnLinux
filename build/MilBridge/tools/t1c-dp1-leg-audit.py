#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1c · D-P1「`Text` DP 腿」判据审计器（**只吃日志，不产出任何构建物**）。

它回答**一个**问题，并且只回答这一个：

    「容器已经变成新值」之后，**`TextBox.Text`（DP 读路径）到底有没有被读过？读到了什么？**

为什么需要它
------------
`TextBox.OnTextContainerChanged`（`PresentationFramework/…/Controls/TextBox.cs:1214-1216`）按上游设计
写进 DP 的是 **`DeferredTextReference`**，字符串由 `DeferredTextReference.GetValue`
（`…/Controls/DeferredTextReference.cs:41-43`）**在有人读 DP 时现算**。因此：

  · 写侧读数（`W5/W4a/W6*/W10`）**结构上无法**区分「DP 已更新」与「DP 陈旧」——两种情况下写侧长得一样；
  · 判「陈旧」**必须**有**写后读数**（写之后有人读过 DP）；
  · **没有写后读数 = 无信息**（既不许报绿，也不许报红）。这正是本工具存在的意义：
    把「无信息」从「陈旧/回归」里切出来，并给出**用了哪些行**（可复核）。

接受的日志词汇（一条不对就报 `noinfo`，并把你缺的那类打出来）
--------------------------------------------------------------
写侧（deferred 写）：
  `W5 **写入口 SetValueCommon** 写入的 value=DeferredTextReference … target=<Obj> dp.GlobalIndex=<N>`
  `W4a SetValueCommon **newEntry.Value = value** target=<Obj> dp.GlobalIndex=<N> … value=DeferredTextReference … isDeferredReference=True`
容器真值（容器侧读数，**不读 DP**）：
  `Q4d SetSelectedText 返回后 … len=<n> text="…"`、`Q5c **Changed 已 raise** … 容器 len=<n> text="…"`、
  `Q7a … （进入时 容器 len=<n> text="…"）`、`Q7b **已 SetCurrentDeferredValue(…)** … （此时 容器 len=<n> text="…"）`、
  `W6a UpdateEffectiveValue **之前** … oldEntry.Value=string(len=<n>) "…"`（**写前**的 DP 值）
读侧（**能给出取值**的）：`Q8b GetTextInternal 取到 len=<n> text="…"`（解引用点）、
  `WFP_POSTWRITE-EVENT TextChanged #k text='…'`（**TextChanged 处理器内**读 DP）、`WFP_POSTWRITE t=<ms> {变更|心跳} text='…'`、
  `WFP_TEXTWATCH t=<ms> text='…'`、`WFP_TEXTDP t2|t3|t4='…' c<n>=<k>`
读侧（**只说"读发生了"**、无取值）：`W1 GetValue(…) 读 "Text" OwnerType=TextBox`、`Q8a DeferredTextReference.GetValue **DP 来读了**`
红牌：`WFP_POSTWRITE t=<ms> 读取异常 <Ex>`（`(string)GetValue(...)` 抛 ⇒ DP 返回的不是字符串 ⇒ 引用**没被解析**）
注入标记（用来判「写后读数」是不是真的在**注入之后**）：`[KEY_DIAG] XEV KeyPress`、`[MSGFLOW] push WM_CHAR`
"应用自证序列"（无探针时的替代证据，**另立口径、单独标注**）：`WFP_TEXTDP t1='…' c1=…` → `t2/t3/t4` 值变化 + `c` 递增

判定（**优先级从上到下**；每条都打印触发它的行号）
--------------------------------------------------
 1. 写后出现红牌                                    ⇒ `defect` rc=2
 2. 写后有取值读，且与容器真值**不等**               ⇒ `defect` rc=2
 3. 写后有取值读，且与容器真值**相等**               ⇒ `closed` rc=0
 4. 写后有取值读，无容器真值，但与**写前值不同**     ⇒ `closed` rc=0（口径：仅证「DP 更新过」，打印此限制）
 5. 应用自证序列（t1→t2 变值且 `c` 递增）            ⇒ `closed(app-seq)` rc=0（**只对"容器写→DP 读"这条链**背书）
 6. 其余（含：写后只有"读发生"无取值 / 只有写侧 / 写后读值=写前值且无容器真值） ⇒ `noinfo` rc=3

用法
----
    python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --log <probe.log> [--log <另一份>] [--dp-index 432]
    python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --selftest        # 四极性自检（不读任何真实文件）
    python3 build/MilBridge/tools/t1c-dp1-leg-audit.py --log L --allow-pre-injection   # 关掉"必须在注入之后"

退出码：`0` closed / `2` defect / `3` **noinfo（无信息）** / `1` 用法或读文件失败。
机读行：`DP1_LEG state=… rc=… writes=… reads_after_write=… object=… dp=…`
"""

import argparse
import io
import os
import re
import sys

OBJ_DEFAULT = "TextBox#"
DP_INDEX_DEFAULT = 432

# --------------------------------------------------------------------------------------
#  词汇表：每条 = (键, 正则)。**宽松处只在 obj/dp 过滤上**，取值/长度一律要求逐字匹配（防"同一行两义"）。
# --------------------------------------------------------------------------------------
RE_WRITE_W5 = re.compile(
    r"W5 \*\*写入口 SetValueCommon\*\* 写入的 value=DeferredTextReference\b.*?"
    r"target=(?P<obj>\S+)\s+dp\.GlobalIndex=(?P<idx>\d+)")
RE_WRITE_W4A = re.compile(
    r"W4a SetValueCommon \*\*newEntry\.Value = value\*\* target=(?P<obj>\S+)\s+dp\.GlobalIndex=(?P<idx>\d+)\b.*?"
    r"value=DeferredTextReference\b.*?isDeferredReference=True")
RE_PRE_W6A = re.compile(
    r"W6a UpdateEffectiveValue \*\*之前\*\*.*?oldEntry\.Value=string\(len=(?P<len>\d+)\) \"(?P<val>[^\"]*)\"")
RE_CONTAINER = [
    re.compile(r"Q4d SetSelectedText 返回后.*?len=(?P<len>\d+) text=\"(?P<val>[^\"]*)\""),
    re.compile(r"Q5c \*\*Changed 已 raise\*\*.*?容器 len=(?P<len>\d+) text=\"(?P<val>[^\"]*)\""),
    re.compile(r"Q7a TextBox\.OnTextContainerChanged 入口.*?（进入时 容器 len=(?P<len>\d+) text=\"(?P<val>[^\"]*)\"）"),
    re.compile(r"Q7b \*\*已 SetCurrentDeferredValue\(TextProperty, \S+\)\*\*.*?（此时 容器 len=(?P<len>\d+) text=\"(?P<val>[^\"]*)\"）"),
]
RE_CHAIN = [
    ("Q5c Changed 已 raise", re.compile(r"Q5c \*\*Changed 已 raise\*\*")),
    ("Q7a TextBox.OnTextContainerChanged 入口", re.compile(r"Q7a TextBox\.OnTextContainerChanged 入口")),
    ("Q7b 已 SetCurrentDeferredValue", re.compile(r"Q7b \*\*已 SetCurrentDeferredValue\(TextProperty")),
    ("Q6b 即将 OnTextChanged", re.compile(r"Q6b 即将 OnTextChanged")),
]
RE_READ_VALUED = [
    ("Q8b(解引用点取到的串)", re.compile(r"Q8b GetTextInternal 取到 (?:\(null\)|len=(?P<len>\d+) text=\"(?P<val>[^\"]*)\")")),
    ("WFP_POSTWRITE-EVENT(TextChanged 处理器内读 DP)", re.compile(r"WFP_POSTWRITE-EVENT TextChanged #\d+ text='(?P<val>[^']*)'")),
    ("WFP_POSTWRITE(轮询读 DP)", re.compile(r"WFP_POSTWRITE t=(?P<ms>\d+) (?:变更|心跳) text='(?P<val>[^']*)'")),
    ("WFP_TEXTWATCH(轮询读 DP)", re.compile(r"WFP_TEXTWATCH t=(?P<ms>\d+) text='(?P<val>[^']*)'")),
]
RE_READ_TEXTPDP = re.compile(r"WFP_TEXTDP t(?P<n>\d)='(?P<val>[^']*)' c(?P<n2>\d)=(?P<c>\d+)")
RE_READ_MERE = [
    ("W1(读路径入口)", re.compile(r"W1 GetValue\(…\) 读 \"Text\" OwnerType=TextBox")),
    ("Q8a(解引用点被调)", re.compile(r"Q8a DeferredTextReference\.GetValue \*\*DP 来读了\*\*")),
]
RE_RED = [
    ("读 DP 抛异常", re.compile(r"WFP_POSTWRITE t=\d+ 读取异常 (?P<ex>\w+)")),
]
RE_INJECT = re.compile(r"\[KEY_DIAG\] XEV KeyPress|\[MSGFLOW\] push WM_CHAR")


def _as_text(val, ln, text):
    """取值归一：去掉不可见空白差异，返回 (值, 行号, 原文截断)。"""
    return {"val": val, "ln": ln, "raw": text[:200]}


def analyze(lines, obj=OBJ_DEFAULT, dp_index=DP_INDEX_DEFAULT, allow_pre_injection=False):
    """纯函数：给日志行 ⇒ 判定字典（无副作用，`--selftest` 直接调它）。"""
    ev = {"writes": [], "pre": [], "container": [], "reads_valued": [], "reads_mere": [],
          "red": [], "chain": {}, "inject": [], "appseq": []}

    for i, text in enumerate(lines, start=1):
        m = RE_WRITE_W5.search(text) or RE_WRITE_W4A.search(text)
        if m and m.group("obj").startswith(obj) and m.group("idx") == str(dp_index):
            ev["writes"].append(_as_text("DeferredTextReference", i, text))
        m = RE_PRE_W6A.search(text)
        if m:
            ev["pre"].append(_as_text(m.group("val"), i, text))
        for rx in RE_CONTAINER:
            m = rx.search(text)
            if m:
                ev["container"].append(_as_text(m.group("val"), i, text))
                break
        for name, rx in RE_READ_VALUED:
            m = rx.search(text)
            if m:
                ev["reads_valued"].append(dict(_as_text(m.group("val"), i, text), how=name))
                break
        m = RE_READ_TEXTPDP.search(text)
        if m:
            ev["appseq"].append({"n": int(m.group("n")), "val": m.group("val"),
                                 "c": int(m.group("c")), "ln": i, "raw": text[:200]})
        for name, rx in RE_READ_MERE:
            if rx.search(text):
                ev["reads_mere"].append(dict(_as_text(None, i, text), how=name))
                break
        for name, rx in RE_RED:
            m = rx.search(text)
            if m:
                ev["red"].append(dict(_as_text(m.group("ex"), i, text), how=name))
        for name, rx in RE_CHAIN:
            if rx.search(text):
                ev["chain"][name] = ev["chain"].get(name, 0) + 1
        if RE_INJECT.search(text):
            ev["inject"].append(i)

    def _appseq_note(a, b):
        return ("应用自证序列：`WFP_TEXTDP t1='%s' c1=%d` → `t%d='%s' c%d=%d`（容器写后**同一步**读 DP，"
                "值变化且 TextChanged 递增）⇒ **容器写→Changed→DP 写→DP 读**这条链闭合"
                "（**口径限制**：背书的是『经文本对象模型改容器』那一族写，不逐字等于键入路径的 `Q4d`）"
                % (a["val"], a["c"], b["n"], b["val"], b["n"], b["c"]))

    def _appseq(ev, ctx):
        seq = sorted(ev["appseq"], key=lambda z: z["ln"])
        for a, b in zip(seq, seq[1:]):
            if a["n"] == 1 and b["n"] >= 2 and b["val"] != a["val"] and b["c"] > a["c"]:
                return {"state": "closed(app-seq)", "rc": 0, "ev": ev, "ctx": ctx,
                        "hit": {"ln": b["ln"], "val": b["val"], "raw": b["raw"]},
                        "why": _appseq_note(a, b)}
        return None

    w = ev["writes"]
    if not w:
        hit = _appseq(ev, {})
        if hit:
            return hit
        return {"state": "noinfo", "rc": 3, "ev": ev,
                "why": "本日志**没有 deferred 写读数**（`W5 … value=DeferredTextReference` / `W4a … isDeferredReference=True`），"
                       "也没有成对的应用自证序列（`WFP_TEXTDP t1→t2`）"
                       "⇒ 这不是这条链的日志（或那趟没开 INPUT_TRACE/MSGFLOW_TRACE）"}

    last_write = max(x["ln"] for x in w)
    first_inject = ev["inject"][0] if ev["inject"] else None

    def decisive(ln):
        """写后**且**（若有注入标记）在注入之后 ⇒ 才算决定性读数。"""
        if ln <= last_write:
            return False, "写前"
        if first_inject is not None and ln < first_inject and not allow_pre_injection:
            return False, "写后但**注入前**(L%d < L%d)" % (ln, first_inject)
        return True, "写后"

    reads = [(x, *decisive(x["ln"])) for x in sorted(ev["reads_valued"], key=lambda z: z["ln"])]
    mere = [(x, *decisive(x["ln"])) for x in sorted(ev["reads_mere"], key=lambda z: z["ln"])]
    red = [(x, *decisive(x["ln"])) for x in sorted(ev["red"], key=lambda z: z["ln"])]
    good_reads = [x for x, ok, _ in reads if ok]
    good_mere = [x for x, ok, _ in mere if ok]
    good_red = [x for x, ok, _ in red if ok]

    ctx = {"last_write": last_write, "first_inject": first_inject,
           "reads": reads, "mere": mere, "red": red,
           "container_after": [c for c in ev["container"] if c["ln"] > last_write],
           "pre_last": ev["pre"][-1]["val"] if ev["pre"] else None}

    # 1) 红牌（最高优先级：DP 读**抛异常** ⇒ 引用没被解析）
    if good_red:
        r = good_red[0]
        return {"state": "defect", "rc": 2, "ev": ev, "ctx": ctx, "hit": r,
                "why": "写后读 DP **抛异常**（%s）⇒ DP 返回的不是字符串 ⇒ deferred 引用**没被解析**" % r["val"]}

    # 2/3/4) 写后有取值读：与**该读发生时**的容器真值（as-of）比 —— 注入语义变了也不影响
    #   【为什么必须 as-of】真值是**量出来的**（`Q4d/Q5c/Q7a/Q7b` 各报自己那一刻的容器文本），
    #   绝不从"注入方式"推断；而"读到的是**更早**一次编辑的值"必须判红（DP 滞后），
    #   不能因为"这个值在别的时刻确实是容器真值"就报绿（那是本工具的假绿口子）。
    if good_reads:
        cont_vals = [c['val'] for c in ev['container'] if c['ln'] > last_write]
        pre = ctx['pre_last']

        def as_of(ln):
            prior = [c for c in ev['container'] if c['ln'] <= ln]
            return prior[-1] if prior else None

        for r in good_reads:
            t0 = as_of(r['ln'])
            if t0 is None:
                continue
            if r['val'] == t0['val']:
                return {'state': 'closed', 'rc': 0, 'ev': ev, 'ctx': ctx, 'hit': r,
                        'why': '写后读到的 DP 值 == **该读发生时**的容器真值（%r @L%d）⇒ 该链**当场闭合**'
                               % (t0['val'], t0['ln'])}
            extra = ''
            if pre is not None and r['val'] == pre:
                extra = '；且它正是**写前**的值'
            elif r['val'] in cont_vals:
                extra = '；它是**更早一次**容器读数的值 ⇒ 滞后'
            return {'state': 'defect', 'rc': 2, 'ev': ev, 'ctx': ctx, 'hit': r,
                    'why': '写后读到的 DP 值（%r）≠ **那一刻**的容器真值（%r @L%d）⇒ DP 滞后/未更新（陈旧）%s'
                           % (r['val'], t0['val'], t0['ln'], extra)}
        if pre is not None:
            fresh = [r for r in good_reads if r['val'] != pre]
            if fresh:
                return {'state': 'closed', 'rc': 0, 'ev': ev, 'ctx': ctx, 'hit': fresh[-1],
                        'why': '写后读到的 DP 值（%r）≠ 写前 DP 值（%r）⇒ DP 确实更新过'
                               '（**注意口径**：本日志**没有**任何容器侧读数可作对照，故只证「更新过」，不证「== 容器」）'
                               % (fresh[-1]['val'], pre)}
        return {'state': 'noinfo', 'rc': 3, 'ev': ev, 'ctx': ctx, 'hit': good_reads[-1],
                'why': '写后读到的值（%r）与写前相同，且日志里**没有**容器侧对照读数 ⇒ '
                       '**无法区分「陈旧」与「本来没变」**' % good_reads[-1]['val']}

    # 5) 应用自证序列（无探针侧的写读数时也可用）
    hit = _appseq(ev, ctx)
    if hit:
        return hit

    # 6) 其余
    if good_mere:
        return {"state": "noinfo", "rc": 3, "ev": ev, "ctx": ctx,
                "why": "写后**确实有读发生**（%s @L%d），但日志**没有打印取值** ⇒ 仍无信息（补 `Q8b`/`WFP_POSTWRITE` 一类带值的读数）"
                       % (good_mere[0]["how"], good_mere[0]["ln"])}
    late = [x for x, ok, why in reads + mere if not ok and "注入前" in why]
    return {"state": "noinfo", "rc": 3, "ev": ev, "ctx": ctx,
            "why": "**写后没有任何 DP 读数**（最后写 L%d；最后一次读 L%s）⇒ 「DP 陈旧」**未被测**"
                   "%s" % (last_write,
                           max([x["ln"] for x in ev["reads_valued"] + ev["reads_mere"]], default=0) or "无",
                           "；另有 %d 条读数在写后但**注入之前**（不算决定性）" % len(late) if late else "")}


def report(path, res, ev_limit=12):
    ev, ctx = res["ev"], res.get("ctx", {})
    print("DP1_LEG state=%s rc=%d write_rows=%d reads_after_write=%d object=%s dp=%d file=%s%s"
          % (res["state"], res["rc"], len(ev["writes"]),
             len([1 for x, ok, _ in ctx.get("reads", []) if ok]),
             OBJ_DEFAULT, DP_INDEX_DEFAULT, os.path.basename(path),
             (" hit@L%d" % res["hit"]["ln"]) if res.get("hit") else ""))
    print("DP1_LEG_LOG file=%s lines=%d sha256_16=%s" % (path, res["_lines"], res["_sha"]))
    print("DP1_LEG_CHAIN " + " ".join("%s=%d" % (k, v) for k, v in sorted(ev["chain"].items())))
    print("DP1_LEG_WHY " + res["why"])
    if ctx:
        print("DP1_LEG_WINDOW last_write=L%d first_inject=%s"
              % (ctx["last_write"], ("L%d" % ctx["first_inject"]) if ctx["first_inject"] else "无"))
        rows = ([("读(带值)", x, ok, why) for x, ok, why in ctx["reads"]]
                + [("读(仅发生)", x, ok, why) for x, ok, why in ctx["mere"]]
                + [("红牌", x, ok, why) for x, ok, why in ctx["red"]])
        rows.sort(key=lambda r: r[1]["ln"])
        for kind, x, ok, why in rows[:ev_limit]:
            print("DP1_LEG_EV %-10s L%-6d %-16s val=%r" % (kind, x["ln"], why, x["val"]))
        if len(rows) > ev_limit:
            print("DP1_LEG_EV …（另有 %d 条，未打印）" % (len(rows) - ev_limit))


def sha16(data):
    import hashlib
    return hashlib.sha256(data).hexdigest()[:16]


def selftest():
    """四极性：写后读=新值 ⇒ closed/0；写后读=旧值(容器已变) ⇒ defect/2；只有写侧 ⇒ noinfo/3；写后读在注入前 ⇒ noinfo/3。"""
    head = [
        "[INPUT_TRACE] W5 **写入口 SetValueCommon** 写入的 value=DeferredTextReference target=TextBox#33cafbe dp.GlobalIndex=432 entryIndex=9",
        "[INPUT_TRACE] W6a UpdateEffectiveValue **之前** operationType=Unknown newEntry.Value=DeferredTextReference oldEntry.Value=string(len=7) \"seed-文本\"",
        "[KEY_DIAG] XEV KeyPress window=0x200005 send_event=0",
        "[MSGFLOW] push WM_CHAR 入队 码点=65(0x0041 'A')",
        "[INPUT_TRACE] Q4d SetSelectedText 返回后（**文档到底变了没有**）len=1 text=\"A\"",
        "[INPUT_TRACE] Q7b **已 SetCurrentDeferredValue(TextProperty, DeferredTextReference#3d7e188)** TextBox#33cafbe（此时 容器 len=1 text=\"A\"）",
    ]
    # 桥那趟的形态：**写后有一条读数，但它落在注入之前** ⇒ 不是"注入条件下的写后读数" ⇒ 无信息
    before_inject = [
        "[INPUT_TRACE] W5 **写入口 SetValueCommon** 写入的 value=DeferredTextReference target=TextBox#33cafbe dp.GlobalIndex=432",
        "[INPUT_TRACE] W6a UpdateEffectiveValue **之前** oldEntry.Value=string(len=7) \"seed-文本\"",
        "[INPUT_TRACE] Q4d SetSelectedText 返回后（**文档到底变了没有**）len=1 text=\"A\"",
        "WFP_TEXTWATCH t=17021 text='seed-文本' len=7 sel=0,7 changes=0 focused=True",
        "[KEY_DIAG] XEV KeyPress window=0x200005 send_event=0",
    ]
    cases = [
        ("closed", 0, head + ["[INPUT_TRACE] Q8b GetTextInternal 取到 len=1 text=\"A\" 容器 len=1 text=\"A\""], {}),
        ("defect", 2, head + ["WFP_POSTWRITE t=9000 变更 text='seed-文本' len=7 sel=0,7 changes=1"], {}),
        ("defect-ex", 2, head + ["WFP_POSTWRITE t=9000 读取异常 InvalidCastException"], {}),
        ("noinfo-only-write", 3, head, {}),
        # **本轮的核心形态**：写后读数存在，但在注入之前 ⇒ 无信息（不许报绿，也不许报红）
        ("noinfo-read-before-inject", 3, before_inject, {}),
        # 同一份日志 + `--allow-pre-injection` ⇒ 那条读数变成决定性且读到旧值 ⇒ 红（证明这个开关真的在起作用）
        ("defect-with-allow-pre", 2, before_inject, {"allow_pre_injection": True}),
        # **主控点名的风险**：容器已经走到 "AB"，写后读却拿到**更早一次**的 "A" ⇒ 必须判红（假绿口子）
        ("defect-lag-one-edit", 2, [
            "[INPUT_TRACE] W5 **写入口 SetValueCommon** 写入的 value=DeferredTextReference target=TextBox#33cafbe dp.GlobalIndex=432",
            "[INPUT_TRACE] W6a UpdateEffectiveValue **之前** oldEntry.Value=string(len=7) \"seed-文本\"",
            "[INPUT_TRACE] Q4d SetSelectedText 返回后 len=1 text=\"A\"",
            "[INPUT_TRACE] Q4d SetSelectedText 返回后 len=2 text=\"AB\"",
            "WFP_POSTWRITE t=22500 变更 text='A' len=1 sel=1,0 changes=2",
        ], {}),
        ("closed-app-seq", 0, [
            "WFP_TEXTDP t1='seed-文本' c1=0 sel='' line0='seed-文本'",
            "WFP_TEXTDP t2='A' c2=1 sel='A' line0='A'",
        ], {}),
    ]
    bad = 0
    for name, want_rc, lines, kw in cases:
        res = analyze(lines, **kw)
        ok = res["rc"] == want_rc
        print("DP1_LEG_SELFTEST case=%-26s want_rc=%d got_rc=%d state=%-14s %s"
              % (name, want_rc, res["rc"], res["state"], "OK" if ok else "**FAIL**"))
        if not ok:
            print("                     why=%s" % res["why"])
        bad += 0 if ok else 1
    print("DP1_LEG_SELFTEST=%s（%d/%d）" % ("PASS" if bad == 0 else "FAIL", len(cases) - bad, len(cases)))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", action="append", default=[], help="探针日志（可多次）")
    ap.add_argument("--object", default=OBJ_DEFAULT, help="目标 DO 前缀（默认 TextBox#）")
    ap.add_argument("--dp-index", type=int, default=DP_INDEX_DEFAULT, help="目标 DP 的 GlobalIndex（默认 432=TextBox.Text）")
    ap.add_argument("--allow-pre-injection", action="store_true",
                    help="允许把「写后但注入前」的读数也算决定性（**默认不许**）")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        return selftest()
    if not args.log:
        ap.error("至少给一个 --log（或用 --selftest）")

    worst = 0
    for path in args.log:
        try:
            with io.open(path, "rb") as f:
                data = f.read()
        except OSError as e:
            print("DP1_LEG state=error rc=1 file=%s err=%s" % (path, e))
            worst = max(worst, 1)
            continue
        lines = data.decode("utf-8", "replace").splitlines()
        res = analyze(lines, obj=args.object, dp_index=args.dp_index,
                      allow_pre_injection=args.allow_pre_injection)
        res["_lines"] = len(lines)
        res["_sha"] = sha16(data)
        if not args.quiet:
            report(path, res)
        else:
            print("DP1_LEG state=%s rc=%d file=%s" % (res["state"], res["rc"], path))
        # closed=0 与 noinfo=3 并存时取"最需要人看"的那个：defect(2) > noinfo(3) > closed(0)
        worst = max(worst, res["rc"]) if res["rc"] != 3 else (3 if worst == 0 else worst)
    return worst


if __name__ == "__main__":
    sys.exit(main())
