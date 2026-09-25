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
    print("FILE=%s %dx%d colors=%d magenta=%d total=%d" %
          (p, im.size[0], im.size[1], len(cols), n_mag, im.size[0] * im.size[1]))
