#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""W86A 导航点击器 —— 比 W60A 的 `navsweep.py` 多两道**身份牙**（防"认错对象"）。

【为什么必须重写】W86A 第一趟实测（`$HOME/w86a/logs/w86a-m1`）：`navsweep.py click 24`
在 G2 里**点到了第 26 项**（应用自报 `[NS] loaded …BorderDemo`）—— 而读数表面上写着 `K=24`。
根因：`ensure_item()` 算出的坐标在"滚动还在沉降"时就会变（GEO 块 1 Hz，点用的是**上一块**的坐标）
⇒ 这就是本仓反复登记的那一族：**认错了对象，读数照给**（`D-G79` 同族）。

本器件的判据（全部机读输出）：
  ① **坐标稳定才点**：读两次 GEO（间隔 --settle），`item[k]` 的 `scr/wh` 必须**逐字相同**；
  ② **拥有者核对**：点必须落在 `item[k]` 自己的矩形里（按矩形包含关系算，不是"我以为"）；
  ③ **身份按应用自报**：点后 `[NS] loaded …<期望页名>` 必须出现（这是应用自己说的页面身份）；
  ④ 进程死时无 `[NS]` ⇒ 如实打 `ns=-`，由调用方按**崩溃签名**归因（死进程没法报自己的页）。

用法
----
    navclick.py --log <app.log> --pid <pid> --display :196 --out <dir> \
                --item 24 --expect FlowDocumentDemo
输出（机读，每行一个键）：
    BEFORE item=24 nm=FlowDocument stable=yes owner=ok rect=268,1122,203x27 point=369,1135
    AFTER  item=24 alive=yes ns=HandyControlDemo.UserControl.FlowDocumentDemo ns_delta=1 try=1
"""
import argparse
import os
import re
import subprocess
import sys
import time

GEO_CTL = re.compile(r'^\[GEO\] ([A-Za-z_][A-Za-z_0-9]*)#(\S*)(.*)$')
GEO_ITEM = re.compile(r'^\[GEO\]\s+item\[(\d+)\]\s+(\w+)\s+(.*)$')
NS = re.compile(r'^\[NS\] loaded (\S+)', re.M)   # ⚠️ 必须 re.M：不加时 `^` 只在**整个串**开头匹配
                                                 #    ⇒ `ns_pages()` 恒返回 []（W86A 第一版实测：
                                                 #      `expect_hit=no` 而日志里 `[NS] loaded …FlowDocumentDemo` 明明在
                                                 #      ⇒ **仪器假红**，不是产品没加载）。


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def kv(s):
    return dict(re.findall(r'([A-Za-z_]+)=(\S+)', s))


def rect(f):
    m = re.match(r'^(-?\d+),(-?\d+)$', f.get('scr', ''))
    w = re.match(r'^(\d+)x(\d+)$', f.get('wh', ''))
    if not m or not w:
        return None
    return (int(m.group(1)), int(m.group(2)), int(w.group(1)), int(w.group(2)))


def inside(pt, r):
    x, y = pt
    return r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3]


class App:
    def __init__(self, log, pid, display, out):
        self.log, self.pid, self.display, self.out = log, int(pid), display, out

    def text(self):
        try:
            with open(self.log, 'r', errors='replace') as f:
                return f.read()
        except FileNotFoundError:
            return ''

    def alive(self):
        try:
            os.kill(self.pid, 0)
            return True
        except OSError:
            return False

    def geo(self):
        """最后一块 GEO：(items{idx:(nm,rect)}, ctls{key:fields})。"""
        t = self.text()
        starts = [m for m in re.finditer(r'\[GEO\] ======== begin \d+ ========', t)]
        if not starts:
            return {}, {}
        seg = t[starts[-1].start():]
        e = seg.find('======== end')
        if e >= 0:
            seg = seg[:e]
        items, ctls = {}, {}
        for ln in seg.splitlines():
            m = GEO_ITEM.match(ln)
            if m:
                f = kv(m.group(3))
                r = rect(f)
                if r:
                    items[int(m.group(1))] = (f.get('nm', '?'), r)
                continue
            m = GEO_CTL.match(ln)
            if m:
                ctls[m.group(1) + '#' + m.group(2)] = kv(m.group(3))
        return items, ctls

    def listbox_rect(self, ctls):
        f = ctls.get('ListBox#ListBoxDemo')
        return rect(f) if f else None

    def ns_pages(self):
        return NS.findall(self.text())

    def xdo(self, *a):
        return sh(['xdotool'] + list(a), env=dict(os.environ, DISPLAY=self.display))

    def click(self, x, y):
        self.xdo('mousemove', str(x), str(y))
        time.sleep(0.2)
        self.xdo('click', '1')
        time.sleep(0.2)

    def wheel(self, x, y, btn, n=1):
        self.xdo('mousemove', str(x), str(y))
        time.sleep(0.1)
        for _ in range(n):
            self.xdo('click', str(btn))
            time.sleep(0.1)

    def focus(self):
        r = self.xdo('search', '--name', 'HandyControlDemo')
        ids = [i for i in r.stdout.split() if i]
        best, besta = None, -1
        for i in ids:
            g = self.xdo('getwindowgeometry', '--shell', i).stdout
            d = dict(re.findall(r'^(\w+)=(-?\d+)$', g, re.M))
            try:
                a = int(d.get('WIDTH', 0)) * int(d.get('HEIGHT', 0))
            except ValueError:
                a = 0
            if a > besta:
                best, besta = i, a
        if not best:
            return None
        self.xdo('windowactivate', '--sync', best)
        self.xdo('windowfocus', '--sync', best)
        time.sleep(0.4)
        return best


def point_in_view(lb, r, margin=6):
    """item 矩形与**列表视口**的交集中心（够大才算可点）。"""
    x0 = max(r[0], lb[0] + 2)
    y0 = max(r[1], lb[1] + 2)
    x1 = min(r[0] + r[2], lb[0] + lb[2] - margin)
    y1 = min(r[1] + r[3], lb[1] + lb[3] - 2)
    if x1 - x0 < 20 or y1 - y0 < 8:
        return None
    return ((x0 + x1) // 2, (y0 + y1) // 2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--log', required=True)
    ap.add_argument('--pid', required=True)
    ap.add_argument('--display', default=':196')
    ap.add_argument('--out', required=True)
    ap.add_argument('--item', type=int, required=True)
    ap.add_argument('--expect', default='')
    ap.add_argument('--settle', type=float, default=1.2)
    ap.add_argument('--tries', type=int, default=4)
    a = ap.parse_args()
    app = App(a.log, a.pid, a.display, a.out)
    os.makedirs(a.out, exist_ok=True)

    wid = app.focus()
    if not wid:
        print('BEFORE item=%d NO-WINDOW' % a.item)
        return 2

    items, ctls = app.geo()
    nm0 = items.get(a.item, ('?', None))[0]
    for attempt in range(1, a.tries + 1):
        if not app.alive():
            print('BEFORE item=%d DEAD' % a.item)
            return 3
        # ① 滚进视口（最多 30 格）
        for _ in range(30):
            items, ctls = app.geo()
            lb = app.listbox_rect(ctls)
            if not lb or a.item not in items:
                time.sleep(1.0)
                continue
            nm, r = items[a.item]
            if point_in_view(lb, r):
                break
            below = r[1] > lb[1] + lb[3]
            app.wheel(lb[0] + lb[2] // 2, lb[1] + lb[3] // 2, 5 if below else 4, 2)
            time.sleep(0.6)
        # ② 坐标稳定才点
        items, ctls = app.geo()
        lb = app.listbox_rect(ctls)
        if not lb or a.item not in items:
            print('BEFORE item=%d UNREACHED(no-geo)' % a.item)
            continue
        nm, r1 = items[a.item]
        p1 = point_in_view(lb, r1)
        time.sleep(a.settle)
        items2, ctls2 = app.geo()
        lb2 = app.listbox_rect(ctls2)
        if a.item not in items2 or not lb2:
            continue
        nm2, r2 = items2[a.item]
        p2 = point_in_view(lb2, r2)
        stable = (r1 == r2 and p1 == p2 and p1 is not None)
        print('BEFORE item=%d nm=%s stable=%s rect=%d,%d,%dx%d point=%s expect=%s try=%d'
              % (a.item, nm2, 'yes' if stable else 'no', r2[0], r2[1], r2[2], r2[3],
                 ('%d,%d' % p2) if p2 else '-', a.expect or '-', attempt))
        if not stable:
            time.sleep(a.settle)
            continue
        # ③ 拥有者核对：点必须落在 item[item] 自己的矩形里
        if not inside(p2, r2):
            print('  OWNER=FAIL point-not-in-item')
            continue
        ns_before = len(app.ns_pages())
        app.click(*p2)
        time.sleep(1.8)
        alive = app.alive()
        pages = app.ns_pages()
        delta = pages[ns_before:]
        got = delta[-1] if delta else '-'
        ok = alive and (not a.expect or any(a.expect in p for p in delta))
        print('AFTER  item=%d alive=%s ns=%s ns_delta=%d try=%d expect_hit=%s'
              % (a.item, 'yes' if alive else 'no', got, len(delta), attempt,
                 'yes' if (a.expect and any(a.expect in p for p in delta)) else 'no'))
        if ok or not alive:
            return 0 if alive else 1
        # 身份没对上（点到别项了）⇒ 重试
        time.sleep(1.0)
    return 4


if __name__ == '__main__':
    sys.exit(main())
