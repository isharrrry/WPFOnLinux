#!/usr/bin/env python3
# W31A · 从**真值单**里抽出本臂要用的用例的 `input` 块（**段落属性**那一半）。
#
# 【为什么需要它】`build/MilBridge/gen/layout-b34-compact.json` 是**瘦身版**：它保留了
#   `text/maxWidth/fontSize/fontKey/trimming/alwaysCollapsible/modifierStart/modifierEnd`
#   与逐行真值，但**丢掉了** `culture`/`textFormattingMode`/`flowDirection`/`textAlignment`/
#   `textWrapping`/`lineHeight`/`firstLineInParagraph`/`indent`/`paragraphIndent`。
#   那九项**必须**逐字来自真值侧 —— 猜一个默认值就等于**换了一把尺子**（本工程纪律 22/39）。
#
# 【怎么抽】`windows-results.json` 有 57 MB ⇒ **不整份 parse**（本机 MemAvailable 只有 ~2.8 GB）。
#   用"正则找 id → 括号配平取 `input` 子对象"的流式法，只对**点名的那几个 id**做 json.loads。
#
# 用法：python3 extract-inputs.py <windows-results.json> <out.json>
import hashlib
import json
import re
import sys

IDS = [
    # 被测件：5 个 M 例（产品入口臂的判据对象）
    "M_modifier_w80",
    "M_modifier_w120",
    "M_modifier_w200",
    "M_modifier_w320",
    "M_modifier_winf",
    # 阴性对照：同一档位路径（alwaysCollapsible=true ⇒ 不走 SimpleTextLine）、同一字体文件、
    # 同 fontSize、无 modifier ⇒ 必须**绿**（证明"红"不是装置/字体/档位噪声）
    "F_lat_words_winf",
    "F_lat_words_w200",
    "F_lat_words_w80",
]


def brace_match(s, i):
    """s[i] == '{' ⇒ 返回配平到对应 '}' 的子串（不 parse，只配平）。"""
    depth = 0
    for j in range(i, len(s)):
        c = s[j]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return s[i:j + 1]
    return None


def main():
    src, dst = sys.argv[1], sys.argv[2]
    raw = open(src, "r", encoding="utf-8").read()
    print("source chars = %d" % len(raw))
    sha = hashlib.sha256(raw.encode("utf-8")).hexdigest()

    out = {}
    for cid in IDS:
        m = re.search(r'"id"\s*:\s*"' + re.escape(cid) + r'"', raw)
        if not m:
            print("  !! MISSING id %s" % cid)
            continue
        k = raw.find('"input"', m.start())
        b = raw.find('{', k)
        obj = json.loads(brace_match(raw, b))
        # 只留本臂真正要用的字段（其余是逐字符 dump，收进来只是噪声）
        keep = ["text", "culture", "fontKey", "fontSize", "textFormattingMode", "flowDirection",
                "maxWidth", "textAlignment", "textTrimming", "textWrapping", "lineHeight",
                "firstLineInParagraph", "indent", "paragraphIndent", "alwaysCollapsible",
                "modifierStart", "modifierEnd"]
        out[cid] = {k2: obj.get(k2) for k2 in keep}
        print("  %-18s flow=%s align=%s wrap=%s AC=%s lineHeight=%r indent=%r PI=%r"
              % (cid, obj.get("flowDirection"), obj.get("textAlignment"), obj.get("textWrapping"),
                 obj.get("alwaysCollapsible"), obj.get("lineHeight"), obj.get("indent"),
                 obj.get("paragraphIndent")))

    payload = {
        "_note": "W31A · 真值侧 input 块（段落属性）。由 extract-inputs.py 从 windows-results.json 抽出；"
                 "**不要手改** —— 改它等于改真值。",
        "source": src,
        "sourceSha256": sha,
        "ids": IDS,
        "inputs": out,
    }
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    print("sourceSha256 = %s" % sha)
    print("wrote %s (%d ids)" % (dst, len(out)))


if __name__ == "__main__":
    main()
