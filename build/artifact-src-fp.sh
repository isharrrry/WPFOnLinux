#!/usr/bin/env bash
# 生成物**身份指纹**（三个工程各一份）—— **唯一实现**在 build/artifact-src-fp.py（本脚本只是包装）。
#   **两个维度**（2026-09-14 加 peer）：`fp=` 源维度 ＋ `peer_fp=` 被引产物维度
#     —— PF ⇄ Reach 真互引 ⇒ Roslyn 把被引件字节纳入输入哈希 ⇒ 该对无字节不动点、每波 sha 必变；
#        只覆盖源时 `state=ok` 是**必要不充分**。
#   rc=0 全 ok；rc=2 至少一个 stale（**note 里给 kind=src / peer / src+peer**，并点名变了的被引产物）；
#   rc=3 至少一个 noinfo（缺指纹文件 / 缺被引产物 / **旧格式记录** ⇒ 无信息，**不报绿**）
# 用法：
#   bash build/artifact-src-fp.sh               # 只读打印三个工程的两维度指纹
#   bash build/artifact-src-fp.sh --write       # 写 build/<Proj>.Linux/ARTIFACT-SRC-FP.txt（构建/发布时做）
#   bash build/artifact-src-fp.sh --check       # 门禁：重算并与文件比对
#   bash build/artifact-src-fp.sh --list <Proj> # 逐行列出参与指纹的源 + peer 产物
#   bash build/artifact-src-fp.sh --peers <Proj># 只列被引产物（可用于非被测工程，如 ReachFramework）
#   bash build/artifact-src-fp.sh --selftest    # 六极性自测（exit 0=PASS / 2=FAIL）
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/artifact-src-fp.py" "$@"
