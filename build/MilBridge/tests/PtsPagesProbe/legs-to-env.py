#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 session_inner.sh 的 session.txt 转成守卫的证据契约 `leg_<k>.env`。

契约（守卫 `pts-pages-guard.sh` 的输入）——每腿一个文件、三段：
    LEG   k=<23|24> alive=<yes|no> app_rc=<int> magenta=<int> colors=<int> ns=<页类名> ae=<int>
    NAMED managed_unavail=<0|1> err=<int|-> native_gap=<int> native_err=<int|->
    DEV   x_up=<yes|no> five_stable=<yes|no> shim=<sha16> pf=<sha16>
另有 `<outdir>/device.txt`（X_UP=…）。

纪律：**解析任一侧为空必须响亮失败**（不许把"空"读成 0）——
本器对每个必需格都做显式断言，缺格 ⇒ 打 `PARSE-ERR` 并 **rc=1**。
用法: legs-to-env.py <session.txt> <device.txt> <shots_root> <outdir>
"""
import os
import re
import sys


def die(msg):
    print("PARSE-ERR %s" % msg)
    sys.exit(1)


def req(m, what, ctx):
    if m is None:
        die("%s 缺失（ctx=%s）" % (what, ctx))
    return m.group(1)


def parse_click(block, k, logfile=None):
    """从一组的原文里取点击 k 的读数。

    ⚠️ **不许用"单行正则"**：实测过一种机读行被**拆成多行**而值仍正确的形态
    （`$(grep -c … || echo 0)` 在零命中时给两行）⇒ 单行正则**匹配不上**、会误报"读不到"。
    本器改用 **token 扫描**：从 `^CLICK k=<k>` 起、到 `^PHASE` 或下一条分隔线止，
    取该区域里**首次**出现的每个 `key=value`。裸行（如多出来的 `0`）没有 `=` ⇒ 自然被忽略。

    ⚠️ 托管侧具名行 `err` 以 **原始 app 日志**（`logfile`）为**权威**：
    实测 `session_inner.sh` 第一版的提取式 `grep -o -m1 'PTS-UNAVAILABLE[^\\n]*err=…'`
    **恒空** —— 在 `grep -E` 的括号表达式里 `[^\\n]` 是"非反斜杠且非 n"，**不是**"非换行"
    ⇒ 会把好腿读成"无具名行"⇒ **假红**。改为从原始日志直取，并与 session 里的字段**交叉核对**
    （两者都在且不等 ⇒ **响亮失败**，不许挑一个）。
    """
    start = re.search(r"^CLICK k=%d\b" % k, block, re.M)
    if start is None:
        return None
    rest = block[start.end():]
    stop = re.search(r"^(?:PHASE |--- |=============== |alive_after_seq=|APP_RC=)", rest, re.M)
    region = rest[:stop.start()] if stop else rest
    tok = {}
    for km, vm in re.findall(r"([A-Za-z_]+)=(\S+)", region):
        tok.setdefault(km, vm)
    need = ["alive", "AE", "pts_unavail", "pts_gap", "ns_last"]
    miss = [n for n in need if n not in tok]
    if miss:
        die("k=%d 的 CLICK 行缺格 %s（region 前 200 字：%s）" % (k, miss, region[:200].replace("\n", "\\n")))
    alive, ae, ns = tok["alive"], tok["AE"], tok["ns_last"]
    punav = tok["pts_unavail"]
    # 洋红/色数：取该组里该 k 的那一张截图的 shotstat 行
    shot = None
    for sm in re.finditer(r"^\s*FILE=(\S+\.png) (\d+)x(\d+) colors=(\d+) magenta=(\d+) total=(\d+)$",
                          block, re.M):
        if re.search(r"/k%d\.png$" % k, sm.group(1)):
            shot = sm
    if shot is None:
        die("k=%d 的 shotstat 行缺失（截图没落或 shotstat 没跑）" % k)
    colors, magenta = shot.group(4), shot.group(5)
    # ⚠️ `managed_err` 允许**空值**（`\S+` 会匹配不上空串 ⇒ 好腿被读成"PHASE 行缺失"）
    ph = re.search(r"^PHASE k=%d c1_ep=(\S+) c2_pts_gap=(\S+) c3_pts_unavail=(\S+) "
                   r"c4_unrecoverable=(\S+) managed_err=(\S*) native_err=(\S*)$" % k,
                   block, re.M)
    if ph is None:
        die("k=%d 的 PHASE 行缺失（相位读器没跑）" % k)
    def _n(v):
        """把 `err=-10000` / `-10000` 一律归一成 `-10000`。
        ⚠️ 不归一 ⇒ 契约里会写出 `err=err=-10000` ⇒ 守卫读成 "missing-or-err=err=-10000"
        ⇒ **把好腿判红（假红）**。这是本器合成自测抓到的真缺陷。
        """
        m = re.search(r"(-?\d+)$", v or "")
        return m.group(1) if m else "-"

    merr, nerr = _n(ph.group(5)), _n(ph.group(6))
    # ── 权威源 = **原始 app 日志**（见 docstring 里 `[^\n]` 那个真缺陷）──────────────
    if logfile and os.path.isfile(logfile):
        raw = open(logfile, encoding="utf-8", errors="replace").read()
        mm = re.search(r"\[PTS-UNAVAILABLE\] .*?err=(-?\d+)", raw)
        nn = re.search(r"PTS_GAP entry=.*?err=(-?\d+)", raw)
        merr_raw = mm.group(1) if mm else "-"
        nerr_raw = nn.group(1) if nn else "-"
        if merr != "-" and merr_raw != "-" and merr != merr_raw:
            die("k=%d 两个口径的托管 err 不一致：session=%s 原始日志=%s（禁挑一个）"
                % (k, merr, merr_raw))
        if nerr != "-" and nerr_raw != "-" and nerr != nerr_raw:
            die("k=%d 两个口径的 native err 不一致：session=%s 原始日志=%s" % (k, nerr, nerr_raw))
        src_managed = merr_raw if merr_raw != "-" else merr
        src_native = nerr_raw if nerr_raw != "-" else nerr
        _merr_raw = merr_raw
        merr, nerr = src_managed, src_native
    punav_n = int(punav)
    # 交叉核对：`managed_unavail` 计数格 ⇔ 原始日志里到底有没有具名行（**不一致 ⇒ 响亮失败**）
    if logfile and os.path.isfile(logfile) and "_merr_raw" in dir():
        if (1 if punav_n else 0) != (1 if _merr_raw != "-" else 0):
            die("k=%d 计数格与原始日志不一致：session pts_unavail=%d，原始日志具名行=%s"
                % (k, punav_n, "有" if _merr_raw != "-" else "无"))
    # native 台账条数：**原始 app 日志**是唯一权威（session 块里并不打这几行 —— 本器第一版
    # 从 block 里数，恒得 0 ⇒ 守卫把 A 臂读成 `native-ledger-absent` ⇒ 假红）
    ngap = 0
    if logfile and os.path.isfile(logfile):
        ngap = len(re.findall(r"PTS_GAP entry=", open(logfile, encoding="utf-8", errors="replace").read()))
    return dict(alive=alive, app_rc=None, magenta=magenta, colors=colors, ns=ns, ae=ae,
                managed_unavail=1 if punav_n else 0, err=merr, native_gap=ngap,
                native_err=nerr, pts_unavail_n=punav_n, pts_gap_n=int(tok["pts_gap"]))


def main():
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(2)
    sess, devf, _shots, outdir = sys.argv[1:5]
    if not os.path.isfile(sess):
        die("session.txt 不存在: %s" % sess)
    txt = open(sess, encoding="utf-8", errors="replace").read()
    os.makedirs(outdir, exist_ok=True)
    dev = ""
    if os.path.isfile(devf):
        dev = open(devf, encoding="utf-8", errors="replace").read()
    xup = "yes" if re.search(r"^X_UP=yes", dev, re.M) else "no"

    blocks = re.split(r"(?=^=============== GROUP )", txt, flags=re.M)
    wrote = 0
    for b in blocks:
        h = re.match(r"=============== GROUP (\d+) arm=(\S+) clicks=\[([^\]]*)\]", b)
        if not h:
            continue
        gi, arm, ks = h.groups()
        rc_m = re.search(r"^APP_RC=(\d+)$", b, re.M)
        if rc_m is None:
            die("GROUP %s 的 APP_RC 行缺失（腿没跑完 / 被 timeout 杀掉）" % gi)
        app_rc = rc_m.group(1)
        five = re.search(r"^FIVE_STABLE_G%s=(YES|NO)$" % gi, b, re.M)
        fstable = five.group(1).lower() if five else "no"
        # ⚠️ 两者在**同一行**（`shim_sha16=… pf_sha16=…`）⇒ **不能**要求行首锚
        shim = re.search(r"shim_sha16=(\S+)", b, re.M)
        pf = re.search(r"pf_sha16=(\S+)", b, re.M)
        for k in [int(x) for x in ks.split(",") if x.strip()]:
            if k not in (23, 24):
                continue
            logf = os.path.join(os.path.dirname(os.path.abspath(sess)), "app_g%s.log" % gi)
            d = parse_click(b, k, logf)
            if d is None:
                die("GROUP %s 点了 k=%d 但读不到 CLICK 行" % (gi, k))
            d["app_rc"] = int(app_rc)
            # 多臂时**按臂分目录**（否则同 k 的不同臂会互相覆盖 —— 本器第一版就撞过）
            armdir = os.path.join(outdir, "arm_%s" % arm)
            os.makedirs(armdir, exist_ok=True)
            p = os.path.join(armdir, "leg_%d.env" % k)
            p_primary = os.path.join(outdir, "leg_%d.env" % k) if arm == "A" else None
            with open(p, "w", encoding="utf-8") as f:
                f.write("LEG k=%d alive=%s app_rc=%d magenta=%s colors=%s ns=%s ae=%s\n"
                        % (k, d["alive"], d["app_rc"], d["magenta"], d["colors"], d["ns"], d["ae"]))
                f.write("NAMED managed_unavail=%d err=%s native_gap=%d native_err=%s\n"
                        % (d["managed_unavail"], d["err"], d["native_gap"], d["native_err"]))
                f.write("DEV x_up=%s five_stable=%s shim=%s pf=%s\n"
                        % (xup, fstable,
                           shim.group(1) if shim else "-", pf.group(1) if pf else "-"))
                f.write("# arm=%s group=%s\n" % (arm, gi))
            if p_primary:
                with open(p_primary, "w", encoding="utf-8") as f2:
                    f2.write(open(p, encoding="utf-8").read())
            write_dev = os.path.join(armdir, "device.txt")
            write_dev_root = os.path.join(outdir, "device.txt")
            dm = re.search(r"display=(\S+)", dev)
            devline = "X_UP=%s display=%s\n" % (xup, dm.group(1) if dm else "-")
            for wd in (write_dev, write_dev_root):
                with open(wd, "w", encoding="utf-8") as f:
                    f.write(devline)
            wrote += 1
            print("WROTE %s k=%d arm=%s alive=%s app_rc=%d magenta=%s colors=%s"
                  % (p, k, arm, d["alive"], d["app_rc"], d["magenta"], d["colors"]))
    if wrote == 0:
        die("一个 leg_*.env 都没写出（session.txt 里没有 23/24 的组）")
    print("LEGS_TO_ENV=OK wrote=%d outdir=%s" % (wrote, outdir))


if __name__ == "__main__":
    main()
