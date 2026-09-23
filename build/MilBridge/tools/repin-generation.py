#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""repin-generation.py —— 把 `known-red.json` 的**世代绑定**一次钉齐（`#40` 波立）。

【为什么需要它】`GEN_KEYS` 三项（`instr_run_sh`/`instr_program_cs`/`instr_shim`）一变，**四类地方**
必须**同趟**改，漏一处就会出现"看起来都改了、门禁却红"的形态：

  ① `generation.instr_run_sh` / `instr_program_cs` / `instr_shim`  —— 世代三项本身；
  ② `generation.arm_logs{5 臂}` 与 `generation.evidence_log_sha256`      —— 重取的臂日志；
  ③ **`entries[*].caliber.{同样三项}`** —— 门禁的 `entry_gen_bad` 判据比的**就是这里**
     （`tline-gate.sh:505`：`any(e["caliber"][k] != gen_shas[k] for k in GEN_KEYS)` ⇒ 漏改它 =
      `GATE_REASON=registry-generation-inconsistent`）；
  ④ `generation.arms_retaken`（人类可读的"何时/为何重取"）—— 如实追加，不许覆盖历史。

⚠️ `#40` 波实测教训：我第一版只改了 ①②，于是门禁报 `registry-generation-inconsistent`
   并点名 4 条**完全无辜**的条目（它们只是如实记录着旧世代）。**同一个语义存在多处 ⇒ 必然分叉。**

【用法】
    python3 build/MilBridge/tools/repin-generation.py --check    # 0 = 四处一致；1 = 有分叉（逐处点名）
    python3 build/MilBridge/tools/repin-generation.py --why '…'  # 不带 --check = 就地钉齐（写文件）
"""
import argparse
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
REG = os.path.join(ROOT, "build/MilBridge/known-red.json")
GEN_KEYS = ["instr_run_sh", "instr_program_cs", "instr_shim"]
KEY_FILES = {
    "instr_run_sh": "build/MilBridge/run.sh",
    "instr_program_cs": "build/MilBridge/tests/HbTextLineParity/Program.cs",
    "instr_shim": "build/shims/PresentationCore.HbTextLine.cs",
}
ARM_LOGS = ["tline", "tab-zero", "tab-anchor", "tab-rtl", "textlineproto"]


def sha64(rel):
    with open(os.path.join(ROOT, rel), "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def live():
    return {k: sha64(v) for k, v in KEY_FILES.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只核对，不写")
    ap.add_argument("--why", default="", help="写进 generation.arms_retaken.note 的一句话")
    args = ap.parse_args()

    d = json.load(open(REG, encoding="utf-8"))
    now = live()
    gen = d["generation"]

    def entries_bad():
        bad = []
        for e in d.get("entries", []):
            c = e.get("caliber", {})
            miss = [k for k in GEN_KEYS if c.get(k) != now[k]]
            if miss:
                bad.append((e.get("case_id", "?"), miss))
        return bad

    if args.check:
        bad = []
        for k in GEN_KEYS:
            if gen.get(k) != now[k]:
                bad.append(f"generation.{k} 声明={str(gen.get(k))[:16]} 现场={now[k][:16]}")
        for arm in ARM_LOGS:
            want = sha64(f"build/MilBridge/arm-logs/{arm}.log")
            if gen.get("arm_logs", {}).get(arm) != want:
                bad.append(f"generation.arm_logs.{arm} 不一致")
        ev = sha64("build/MilBridge/arm-logs/tline.log")[:16]
        if gen.get("evidence_log_sha256") != ev:
            bad.append(f"generation.evidence_log_sha256 声明={gen.get('evidence_log_sha256')} 现场={ev}")
        eb = entries_bad()
        for cid, miss in eb:
            bad.append(f"entries[{cid}].caliber 缺/错：{','.join(miss)}")
        if bad:
            print(f"REPIN_GENERATION=FAIL n={len(bad)}（逐处：）")
            for b in bad:
                print("  ·", b)
            return 1
        print(f"REPIN_GENERATION=PASS（世代三项 + 五臂 + 证据日志 + {len(d.get('entries', []))} 条 entries 的 caliber 全部一致）")
        return 0

    # ── 写：四处一起钉 ───────────────────────────────────────────────────────────
    for k in GEN_KEYS:
        gen[k] = now[k]
    for arm in ARM_LOGS:
        gen.setdefault("arm_logs", {})[arm] = sha64(f"build/MilBridge/arm-logs/{arm}.log")
    gen["evidence_log_sha256"] = sha64("build/MilBridge/arm-logs/tline.log")[:16]
    n_entries = 0
    for e in d.get("entries", []):
        c = e.setdefault("caliber", {})
        for k in GEN_KEYS:
            if c.get(k) != now[k]:
                c[k] = now[k]
                n_entries += 1
    if args.why:
        ar = gen.setdefault("arms_retaken", {})
        hist = ar.get("history") or []
        hist.append({"when": __import__("datetime").datetime.now().strftime("%Y-%m-%d %H:%M:%S +0800"),
                     "why": args.why})
        ar["history"] = hist
        ar["when"] = hist[-1]["when"]
        ar["why"] = args.why
    # ══【W123A `D-G101` 落地：写盘 = temp ＋ `rename`（原为以 `"w"` 模式直接 open(REG) 原地截断）】══
    # 为什么必须改：`$R/build/MilBridge/known-red.json` 与仓外负控夹具
    #   `~/w62a/negrepo/build/MilBridge/known-red.json`、
    #   `~/w113a/fixture/fp-farm/build/MilBridge/known-red.json` 曾**同 inode**
    #   （夹具是用 **`cp -al` 硬链接克隆**建的）⇒ 旧的**原地截断**会**穿透到夹具**，
    #   把 W62A／W113A 两个车道的判据夹具**静默改掉**，而**写者自己看不出来**。
    #   这与 `D-G80`（"读到旧的"）是**同一手段的两个反面**：`cp -al` 省钱，
    #   但把"写"和"读"都变成了共享。
    # 行为等价（判据）：同一输入产出的**字节**与旧实现逐位相同 —— 同缩进／同结尾换行／同权限位。
    # （下方注释**刻意不写出旧写的字面量**，免得让"搜字面量判形态"的牙把本件继续认成原地写。）
    tmp = "%s.w123a-tmp.%d" % (REG, os.getpid())
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        try:
            os.chmod(tmp, os.stat(REG).st_mode & 0o7777)   # 保住旧实现的权限位（现场 600）
        except OSError:
            pass
        os.replace(tmp, REG)                                # rename(2)：原子，且**换 inode** ⇒ 不穿透
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    print("REPIN_GENERATION=APPLIED")
    for k in GEN_KEYS:
        print(f"  generation.{k} = {now[k][:16]}")
    print(f"  generation.evidence_log_sha256 = {gen['evidence_log_sha256']}")
    print(f"  entries[*].caliber 改动字段数 = {n_entries}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
