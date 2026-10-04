#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""W86A 截图机读器：数**洋红占位**像素（#FF00FF）+ 色数 + 总像素。
用法: shotstat.py <png> [<png> ...]
输出（每图一行，机读）: FILE=… WxH=… colors=N magenta=N total=N
判据用途：`magenta>0` = 页级"不支持"占位**真的画出来了**（不是空白）。"""
import sys
from PIL import Image

for p in sys.argv[1:]:
    try:
        im = Image.open(p).convert("RGB")
    except Exception as e:
        print("FILE=%s ERROR=%s" % (p, e)); continue
    cols = im.getcolors(maxcolors=1 << 24) or []
    n_mag = sum(c for c, rgb in cols if rgb == (255, 0, 255))
    # ── `t12`（`TASK-0302` 判据反转的**证据位**）：`ink` = 「既不是占位洋红、也不是该图出现最多的那个颜色
    #   （页底/背景）」的像素数。定义**无阈值**：它只是把"除底色与占位之外还有多少内容"变成一个数；
    #   判据侧怎么用它由 `pts-pages-guard.sh` 的 `phase=` 分支决定（realized 期要求 `magenta==0 ∧ ink>0`）。
    n_total = im.size[0] * im.size[1]
    n_dom = max((c for c, _rgb in cols), default=0)
    n_ink = n_total - n_mag - n_dom
    if n_ink < 0: n_ink = 0
    print("FILE=%s %dx%d colors=%d magenta=%d total=%d ink=%d" %
          (p, im.size[0], im.size[1], len(cols), n_mag, n_total, n_ink))
