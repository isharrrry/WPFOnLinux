#!/usr/bin/env python3
"""C/D 第二批（AL 对齐 / BD bidi / LH 行高）证据表。用法: python3 evidence-cd2.py → evidence-cd2.md"""
import json
import os
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = []


def p(s=""):
    OUT.append(s)


def runs_of(ln):
    return [(b["TextSourceCharacterIndex"], b["Length"], b["RectangleX"], b["RectangleWidth"])
            for tb in (ln.get("textBounds") or []) for b in (tb.get("runs") or [])]


def main():
    cases = {c["id"]: c for c in json.load(open(os.path.join(HERE, "cases-cd2.json"), encoding="utf-8"))["cases"]}
    res = {r["id"]: r for r in json.load(open(os.path.join(HERE, "results-cd2.json"), encoding="utf-8"))["results"]}

    p("# C/D 第二批证据：对齐（AL）/ bidi（BD）/ 行高（LH）")
    p()
    p(f"{len(res)} 例：AL {sum(1 for r in res.values() if r['group']=='AL')}、"
      f"BD {sum(1 for r in res.values() if r['group']=='BD')}、"
      f"LH {sum(1 for r in res.values() if r['group']=='LH')}。来源 `results-cd2.json`（真机 WPF 10.0.7）。")
    p()

    # ---------------- AL ----------------
    p("## 1. 对齐（AL 组）：观察量是 run 矩形的 X 偏移")
    p()
    p("`TextLine.Width` **不随对齐变化**（仍是文本宽度），对齐体现在 `GetTextBounds()` 的 `Rectangle.X`：")
    p()
    p("| 用例 | 行 | Length | Width | run X | 与公式比对 |")
    p("|---|---|---|---|---|---|")
    for al, formula in (("Left", "0"), ("Right", "w-W"), ("Center", "(w-W)/2")):
        cid = f"AL_lat_words_{al}_w200"
        r = res.get(cid)
        if not r:
            continue
        for i, ln in enumerate(r["lines"][:3]):
            rr = runs_of(ln)
            W = ln["properties"]["Width"]
            x = rr[0][2] if rr else None
            expect = 0 if al == "Left" else ((200 - W) if al == "Right" else (200 - W) / 2)
            p(f"| `{al}` 行{i} | {i} | {ln['properties']['Length']} | {W:.3f} | {x:.3f} | "
              f"{formula} → {expect:.3f} |")
    p()
    # 全量公式核对
    ok = bad = 0
    for al in ("Right", "Center"):
        for tid in ("lat_words", "cjk_punct", "cjk_nospace", "mixed"):
            for w in (120, 200, 320, 600):
                r = res.get(f"AL_{tid}_{al}_w{w}")
                if not r:
                    continue
                for ln in r["lines"]:
                    rr = runs_of(ln)
                    if not rr:
                        continue
                    W = ln["properties"]["Width"]
                    expect = (w - W) if al == "Right" else (w - W) / 2
                    if abs(rr[0][2] - expect) < 0.6:
                        ok += 1
                    else:
                        bad += 1
    p(f"**全量核对**：Right 用 `w-W`、Center 用 `(w-W)/2`，符合 **{ok}** 行，不符 **{bad}** 行"
      f"（容差 0.6 DIP）。")
    p()
    p("### 1.1 Justify：非末行拉到段落宽，**末行不拉伸**")
    p()
    rj = res["AL_lat_words_Justify_w200"]
    rl = res["AL_lat_words_Left_w200"]
    p("| 行 | Justify Width | Left Width | NewlineLength | 是末行 |")
    p("|---|---|---|---|---|")
    for i, (a, b) in enumerate(zip(rj["lines"], rl["lines"])):
        p(f"| {i} | {a['properties']['Width']:.3f} | {b['properties']['Width']:.3f} | "
          f"{a['properties']['NewlineLength']} | {i == len(rj['lines']) - 1} |")
    p()
    p("⇒ 非末行 `Width` **恰好等于段落宽**（200.000），末行保持自然宽（61.770）且 `NewlineLength=1`（段落结束）。")
    p()
    p("### 1.2 ★ Justify × CJK：与 Left **逐行完全相同**")
    p()
    p("| 用例对 | 行数 | 逐行 (Length,Width) 相同 |")
    p("|---|---|---|")
    for tid in ("cjk_punct", "cjk_nospace"):
        for w in (120, 200, 320, 600):
            a = res.get(f"AL_{tid}_Justify_w{w}")
            b = res.get(f"AL_{tid}_Left_w{w}")
            if not a or not b:
                continue
            same = ([(x["properties"]["Length"], x["properties"]["Width"]) for x in a["lines"]] ==
                    [(x["properties"]["Length"], x["properties"]["Width"]) for x in b["lines"]])
            p(f"| `{tid}` w={w} | {a['lineCount']} | {same} |")
    p()
    p("⇒ **WPF 的 Justify 只拉伸「空格」**；CJK 文本没有空格 ⇒ **完全不拉伸**，结果与 Left 逐行一致。")
    p("这条直接决定 Linux 侧 CJK 两端对齐的实现：没有可拉伸空格时应当原样输出，不能自作聪明按字间距均分。")
    p()

    # ---------------- BD ----------------
    p("## 2. bidi / RTL（BD 组）")
    p()
    p("字体全部落在 `SEGOEUI.TTF`（**逐例**记了物理文件 sha256，取自 `fontProof.fontFileSha256`）：")
    shas = sorted({r["fontProof"].get("fontFileSha256") for r in res.values() if r["group"] == "BD"})
    for s in shas:
        p(f"* `{s}`")
    p()
    p("| 文本 | 段落方向 | runs | 逻辑序（TextSourceCharacterIndex） | 视觉序（按 run X 排序） | 同序 | 行宽 |")
    p("|---|---|---|---|---|---|---|")
    for tid in ("he_only", "ar_only", "he_lat_digits", "ar_parens", "mixed_3way"):
        for flow in ("ltr", "rtl"):
            r = res.get(f"BD_{tid}_{flow}_w240")
            if not r:
                continue
            ln = r["lines"][0]
            rr = runs_of(ln)
            logical = [int(i) for i, _, _, _ in rr]
            visual = [int(i) for i, _, _, _ in sorted(rr, key=lambda x: x[2])]
            p(f"| `{tid}` | {flow.upper()} | {len(rr)} | {logical} | {visual} | {logical == visual} | "
              f"{ln['properties']['Width']:.2f} |")
    p()
    p("读法：**RTL 段落**下视觉序 == 逻辑序（5/5 文本）；**LTR 段落里的 RTL 片段会被重排**")
    p("（`ar_parens` 视觉序 `[24,21,0,32]`、`mixed_3way` `[0,17,11,6,20]`）。")
    p("另外 `mixed_3way` 在 LTR 下是 **5 个 run**、RTL 下是 **6 个 run** —— **run 切分本身随段落方向变化**，")
    p("Linux 侧不能假设两边 run 数一致。")
    p()
    p("`GetTextBounds()` 的 `FlowDirection` 字段给出每个 text-bounds 条目的方向（纯希伯来文本在 **LTR 段落**里也报 `RightToLeft`）。")
    p()

    # ---------------- LH ----------------
    p("## 3. 行高（LH 组）—— `LineStackingStrategy` 无公开面，只覆盖 `LineHeight`")
    p()
    p("| 文本 | LineHeight | Height | Baseline | TextHeight | MarkerHeight |")
    p("|---|---|---|---|---|---|")
    for tid in ("lat_words", "cjk_punct"):
        nat = res[f"LH_{tid}_lhunset"]["lines"][0]["properties"]
        p(f"| `{tid}` | 未设置 | {nat['Height']:.3f} | {nat['Baseline']:.3f} | {nat['TextHeight']:.3f} | "
          f"{nat['MarkerHeight']:.3f} |")
        for lh in (10, 30, 50):
            q = res[f"LH_{tid}_lh{lh}"]["lines"][0]["properties"]
            p(f"| `{tid}` | {lh} | {q['Height']:.3f} | {q['Baseline']:.3f} | {q['TextHeight']:.3f} | "
              f"{q['MarkerHeight']:.3f} |")
    p()
    p("实测三条公式（6 组数据全对）：")
    p()
    p("1. `Height = LineHeight`（未设置时 = 字体自然行高）")
    p("2. `TextHeight` **恒为字体自然文本高**（不随 LineHeight 变）⇒ `TextHeight ≠ Height`")
    p("3. `Baseline = LineHeight × (自然Baseline / 自然Height)`")
    p()
    p("| 文本 | 自然比值 | LineHeight | Baseline 实测 | 公式预测 | Δ |")
    p("|---|---|---|---|---|---|")
    worst = 0.0
    for tid in ("lat_words", "cjk_punct"):
        nat = res[f"LH_{tid}_lhunset"]["lines"][0]["properties"]
        ratio = nat["Baseline"] / nat["Height"]
        for lh in (10, 30, 50):
            q = res[f"LH_{tid}_lh{lh}"]["lines"][0]["properties"]
            pred = lh * ratio
            worst = max(worst, abs(q["Baseline"] - pred))
            p(f"| `{tid}` | {ratio:.6f} | {lh} | {q['Baseline']:.3f} | {pred:.3f} | {q['Baseline']-pred:+.4f} |")
    p()
    p(f"最大偏差 **{worst:.4f} DIP**（float32 量级）。`MarkerHeight` 也跟随 `Height`。")
    p()
    p("`AlwaysCollapsible=true` 那一格（`LH_*_lh30_ac1`）与 `ac0` 数值完全一致 ⇒ 行高不受实现选择影响。")
    p()
    p("⚠️ **`LineStackingStrategy`（`MaxHeight` / `BlockLineHeight`）在 `TextFormatter` 公开面上拿不到**：")
    p("`TextParagraphProperties` 的公开与非公开成员里都没有它（见 `probe.json.apiSurface` + "
      "`windows-results.json.apiFacts`）。要它只能走 `TextBlock`/`FlowDocument` 那一层，属于另一个 API 面。")

    txt = "\n".join(OUT) + "\n"
    open(os.path.join(HERE, "evidence-cd2.md"), "w", encoding="utf-8").write(txt)
    print(f"wrote evidence-cd2.md ({len(txt)} bytes)")


if __name__ == "__main__":
    main()
