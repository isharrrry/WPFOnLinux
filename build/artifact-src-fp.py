#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""**生成物身份指纹**（ARTIFACT-SRC-FP）—— 三个工程各一份，**唯一实现**。

思路照 `build/bridge-src-fp.sh`（唯一实现 / 写进产物 / 门禁重算比对 / `--selftest` 三极性）。

【它测什么】"当前树里**决定这个工程产物**的那些输入"的指纹，**两个维度**：
  **A. 源维度（src）**
  1. **上游文本**：该工程 csproj 里 `Compile Include="$(UpstreamWpfRoot)…"` 指到的文件（**减去被 `Remove` 掉的**）；
  2. **本工程的生成物/垫片**：csproj 里 `Compile Include="$(WpfLinuxRoot)…"` 指到的文件（生成物 `*.Linux.cs`、`build/shims/**`）；
  3. **决定这些生成物的应用器**：把声明里出现 `build/<Proj>.Linux/**` 路径的应用器脚本**整份 sha** 纳入（脚本 = 声明 + 逻辑）；
  4. **port-lib 的输入**：上游 `<Proj>.csproj` 本体 + `build/port-lib.py` + `build/<Proj>.Linux/reapply-patches.py`（若有）。
  **B. 被引产物维度（peer）** ← 2026-09-14 新增，起因见下
  5. **该工程 csproj 引用的、本仓内的那些产物**（`<Reference><HintPath>$(WpfLinuxRoot)build/…</HintPath>`，如
     `PresentationCore`/`WindowsBase`/`ReachFramework`/`System.Xaml`/`UIAutomation*`/`DirectWriteForwarder`/`DirectWrite.Linux.Provider`/`CycleStub.PresentationUI` …）
     的**产物字节 sha**（**排除自指**：产物名 == 本工程名的一律不纳入）。

【为什么必须加 peer 维度（2026-09-14 主控查清的结构级事实）】
  `PresentationFramework ⇄ ReachFramework` 是**真互引**（`ReachFramework.Linux.csproj` 引用真 PF；`PresentationFramework.Linux.csproj`
  引用真 Reach；CycleStub 只用于 bootstrap pass 1）⇒ 该对**在字节上永无不动点**（交替重建 `PF⇒Reach⇒PF⇒Reach` 得四个不同 sha）。
  机制：Roslyn 确定性输出把**被引件字节**纳入输入哈希 ⇒ **`pf_sha` 每趟波必变**（#4→#8 的冻结 churn 由此而来，不是谁忘了重建）。
  ⇒ 只覆盖"源"的指纹，`state=ok` 是**必要不充分**（源没变、peer 变了 ⇒ 产物变，而指纹照样 ok）。

【读法（**本次修法的重点**）】
  * `state=ok` 的含义从此是：**源 + 被引产物都没变**；
  * `state=stale` **必须指出是哪一类变了**：
      `kind=src`   —— 源维度变了（上游文本/生成物/应用器/port-lib 输入）⇒ 本工程需重建；
      `kind=peer`  —— **被引产物**变了（本工程源一个字没动 ⇒ 因 Roslyn 把被引件字节纳入哈希，本工程产物**同样**会变）；
      `kind=src+peer` —— 两者都变；
    peer 变化时还会逐条点名（`peers_changed=…`，含旧→新短 sha），便于直接看出是哪一个 peer。
  * `state=noinfo`（rc=3）：缺本指纹文件、缺 csproj、**或某个被引产物不存在**（无信息 ⇒ **不报绿**）；
    旧格式记录（只有 `fp=` 没有 `peer_fp=`）同样记 `noinfo`：它**无法为 peer 维度背书**。

**排除**：`build/<Proj>.Linux/bin/**`、`obj/**`、`.artifacts/**`、以及本指纹文件自己
  —— 否则指纹会随"构建过一次"自变 ⇒ **恒 yes 的假警报**（`--selftest` 专测这一条）。

【边界（显式写出，否则就是脚本自己在骗人）】
  * 两个维度都是**内容指纹**：任何字节变化（**包括只加注释**）都会变 ⇒ 它是"身份"而非"语义等价"。
  * 它**不证明产物能编过**、也**不证明"产物就是这些源编出来的"**（那要靠"重建后逐字节可复现"）。
  * peer 维度**只覆盖"本仓内"被引件**（NuGet/框架件不进指纹）；csproj 若新增引用，**下次重算自动纳入**（无需改脚本）。
  * 若给某工程新增了 A 类之外的输入（新的 `build/*.props` 等），**必须回来加口径**；指纹不会自己发现。

用法
----
    python3 build/artifact-src-fp.py                 # 打印三个工程的两个维度指纹（只读）
    python3 build/artifact-src-fp.py --write         # 写 build/<Proj>.Linux/ARTIFACT-SRC-FP.txt
    python3 build/artifact-src-fp.py --check         # 重算比对：rc=0 ok / 2 stale（并给 kind）/ 3 noinfo
    python3 build/artifact-src-fp.py --list <Proj>   # 逐行列出参与指纹的源 + peer 产物（人工核对入口）
    python3 build/artifact-src-fp.py --peers <Proj>  # 只列该工程的被引产物（例如 --peers ReachFramework 看它的 peer=PF）
    python3 build/artifact-src-fp.py --selftest      # 六极性自测（源 4 + peer 2；exit 0=PASS / 2=FAIL）
"""

import argparse
import hashlib
import io
import os
import re
import shutil
import tempfile
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PROJECTS = ("PresentationCore", "WindowsBase", "PresentationFramework")
FP_NAME = "ARTIFACT-SRC-FP.txt"
TOOLS_REL = "src/WpfGfx.Linux.Native/tools"
WAVE_REL = "build/integration-wave.sh"


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def excluded(rel):
    """bin/obj/.artifacts/指纹文件自己 ⇒ 排除（`obj/` 里会有构建生成的 AssemblyInfo ⇒ 纳入就自变）。"""
    parts = rel.split("/")
    if any(x in ("bin", "obj", ".artifacts") for x in parts):
        return True
    if rel.endswith(FP_NAME):
        return True
    return False


def csproj_of(proj):
    return os.path.join(ROOT, "build", proj + ".Linux", proj + ".Linux.csproj")


def referenced_artifacts(proj, root=None):
    """**被引工程的产物**（peer 维度）：从 csproj 里抽 `$(WpfLinuxRoot)` 指向的引用件。

    覆盖两类写法：`<Reference …><HintPath>$(WpfLinuxRoot)<rel></HintPath>` 与
    `<ProjectReference Include="$(WpfLinuxRoot)build/<X>.Linux/<X>.Linux.csproj">`（后者折算成
    `build/<X>.Linux/bin/Debug/<X>.dll`）。**只算 repo 内的**（NuGet/框架件不进指纹）。
    **排除自指**：产物文件名 == `<proj>.dll` 的一律跳过（互引环的另一半要纳入，自己不要）。
    返回 `( [(rel, sha256)], [缺件的 rel] )`，按 rel 排序。
    """
    root = root or ROOT
    cp = os.path.join(root, "build", proj + ".Linux", proj + ".Linux.csproj")
    if not os.path.exists(cp):
        return [], ["build/%s.Linux/%s.Linux.csproj" % (proj, proj)]
    text = io.open(cp, encoding="utf-8-sig", errors="replace").read()
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)          # 注释掉的 <ProjectReference> 不算
    rels = set()
    # ⚠️【`#38`】把 `$(Configuration)` 展开成波自己的配置（Debug）再扫 —— 否则
    #   `…/bin/$(Configuration)/System.Windows.Extensions.dll` 会被当成**字面路径** ⇒
    #   工具报"缺被引产物" ⇒ `ARTIFACT_SRC_FP … state=written note=；⚠️ 缺被引产物` ⇒ 指纹记为**无信息**。
    #   （别的 HintPath 都是写死 `bin/Debug/` 的，本行对它们零影响。样本用的
    #    `$(WpfLinuxSelfBuiltConfiguration)` 不在本工具的扫描面内。）
    text = text.replace('$(Configuration)', 'Debug')
    for m in re.finditer(r'<HintPath>\s*\$\(WpfLinuxRoot\)([^<"]+?)\s*</HintPath>', text):
        rels.add(m.group(1).replace("\\", "/").lstrip("/"))
    for m in re.finditer(r'<ProjectReference\s+Include="\$\(WpfLinuxRoot\)([^"]+\.csproj)"', text):
        rel = m.group(1).replace("\\", "/").lstrip("/")
        name = os.path.basename(rel)[:-len(".csproj")]           # 例如 X.Linux
        asm = name[:-len(".Linux")] if name.endswith(".Linux") else name
        rels.add("build/%s/bin/Debug/%s.dll" % (name, asm))
    out, missing = [], []
    for rel in sorted(rels):
        if os.path.basename(rel) == proj + ".dll":               # **自指排除**
            continue
        p = os.path.join(root, rel)
        if os.path.exists(p):
            out.append((rel, sha256_file(p)))
        else:
            missing.append(rel)
    return out, missing


def parse_csproj_inputs(proj):
    """从生成 csproj 里抽出 (上游文件 rel, 本仓文件 rel)，已按 Remove 折抵。"""
    cp = csproj_of(proj)
    if not os.path.exists(cp):
        return None, None, f"缺 csproj {os.path.relpath(cp, ROOT)}"
    text = io.open(cp, encoding="utf-8-sig", errors="replace").read()
    ups, repos, removed_up, removed_repo = set(), set(), set(), set()
    for m in re.finditer(r'<Compile\s+(Remove|Include)="\$\((UpstreamWpfRoot|WpfLinuxRoot)\)([^"]+)"', text):
        kind, rootvar, rel = m.group(1), m.group(2), m.group(3)
        rel = rel.replace("\\", "/").lstrip("/")
        tgt = removed_up if rootvar == "UpstreamWpfRoot" else removed_repo
        add = ups if rootvar == "UpstreamWpfRoot" else repos
        (tgt if kind == "Remove" else add).add(rel)
    ups -= removed_up
    repos -= removed_repo
    return ups, repos, None


def appliers_of(proj):
    """声明里出现 `build/<Proj>.Linux/` 的应用器脚本（含 wave 显式表 + 兜底 glob）。"""
    names, seen = [], set()
    wave = os.path.join(ROOT, WAVE_REL)
    if os.path.exists(wave):
        lines = io.open(wave, encoding="utf-8", errors="replace").read().split("\n")
        i = 0
        while i < len(lines):
            if re.match(r"^APPLIERS_EXPLICIT\+?=\(", lines[i]):
                buf = [lines[i].split("(", 1)[1]]
                j = i
                if ")" not in buf[0]:
                    while j + 1 < len(lines):
                        j += 1
                        buf.append(lines[j])
                        if lines[j].strip().startswith(")"):
                            break
                for line in buf:
                    for tok in line.split("#")[0].split():
                        tok = tok.strip().strip(")")
                        if tok and not tok.startswith("(") and tok not in seen:
                            seen.add(tok)
                            names.append(tok)
                i = j
            i += 1
    globbed = []
    if os.path.isdir(os.path.join(ROOT, TOOLS_REL)):
        globbed = sorted(f[:-3] for f in os.listdir(os.path.join(ROOT, TOOLS_REL))
                         if f.startswith("patch-presentation") and f.endswith(".py"))
    for n in globbed:
        if n not in seen:
            seen.add(n)
            names.append(n)

    out = []
    marker = "build/" + proj + ".Linux/"
    for n in names:
        p = os.path.join(ROOT, TOOLS_REL, n + ".py")
        if not os.path.exists(p):
            continue
        txt = io.open(p, encoding="utf-8", errors="replace").read()
        if marker in txt.replace("\\", "/") or (proj + ".Linux.csproj") in txt:
            out.append(os.path.relpath(p, ROOT))
    return sorted(set(out))


def upstream_csproj(proj):
    """上游 `<Proj>.csproj`（port-lib 的输入）。多个匹配就全收（排序）。"""
    found = []
    up = os.path.join(ROOT, "upstream", "wpf")
    for dirpath, dirnames, filenames in os.walk(up):
        dirnames[:] = [d for d in dirnames if d not in ("bin", "obj", ".git")]
        if proj + ".csproj" in filenames:
            found.append(os.path.relpath(os.path.join(dirpath, proj + ".csproj"), ROOT))
    return sorted(found)


def manifest(proj):
    """返回 ([(relpath, sha256)], 说明)。全相对仓库根、已排序、已去重。"""
    ups, repos, err = parse_csproj_inputs(proj)
    if err:
        return None, err
    entries, missing = {}, []
    for rel in sorted(ups):
        p = os.path.join(ROOT, "upstream", "wpf", rel)
        if os.path.exists(p):
            entries["upstream/wpf/" + rel] = sha256_file(p)
        else:
            missing.append("upstream/wpf/" + rel)
    for rel in sorted(repos):
        p = os.path.join(ROOT, rel)
        if os.path.exists(p):
            entries[rel] = sha256_file(p)
        else:
            missing.append(rel)
    for rel in upstream_csproj(proj):
        entries[rel] = sha256_file(os.path.join(ROOT, rel))
    for rel in ("build/port-lib.py", "build/%s.Linux/reapply-patches.py" % proj):
        p = os.path.join(ROOT, rel)
        if os.path.exists(p):
            entries[rel] = sha256_file(p)
    for rel in appliers_of(proj):
        entries[rel] = sha256_file(os.path.join(ROOT, rel))
    clean = {k: v for k, v in entries.items() if not excluded(k)}
    note = "" if not missing else ("; 缺输入：" + ", ".join(missing[:3]) + ("…" if len(missing) > 3 else ""))
    return sorted(clean.items()), note


def fp_of(entries):
    h = hashlib.sha256()
    for rel, sha in entries:
        h.update(("%s  %s\n" % (sha, rel)).encode("utf-8"))
    return h.hexdigest()[:16]


def compute(proj):
    """两个维度一起算。返回 dict：src_fp/src_n/peer_fp/peer_n/peers/missing/note。缺 csproj ⇒ src_fp=None。"""
    entries, note = manifest(proj)
    peers, missing_peers = referenced_artifacts(proj)
    d = {"proj": proj, "entries": entries, "peers": peers,
         "peer_n": len(peers), "missing_peers": missing_peers, "note": note}
    if entries is None:
        d.update({"src_fp": None, "src_n": 0, "peer_fp": None})
        return d
    d.update({"src_fp": fp_of(entries), "src_n": len(entries),
              "peer_fp": fp_of(peers) if peers else fp_of([])})
    return d


def fp_path(proj):
    return os.path.join(ROOT, "build", proj + ".Linux", FP_NAME)


def fmt_line(d, state="", note=None):
    """机读行。**向后兼容**：`proj=`/`fp=`/`n=`/`state=`/`note=` 语义不变，新增 `peer_fp=`/`peer_n=`。"""
    s = "ARTIFACT_SRC_FP proj=%s fp=%s n=%d peer_fp=%s peer_n=%d" % (
        d["proj"], d["src_fp"] or "-", d["src_n"], d["peer_fp"] or "-", d["peer_n"])
    if state:
        s += " state=" + state
    nt = d["note"] if note is None else note
    if nt:
        s += " note=" + nt
    return s


def stale_kind(rec_src, rec_peer, cur_src, cur_peer):
    """`stale` 的**分类**（本次修法的重点）：源变了 / 被引产物变了 / 两者都变。"""
    src = (rec_src != cur_src)
    peer = (rec_peer != cur_peer)
    if src and peer:
        return "src+peer"
    if src:
        return "src"
    if peer:
        return "peer"
    return None


def do_write():
    rc = 0
    for proj in PROJECTS:
        d = compute(proj)
        if d["src_fp"] is None:
            print(fmt_line(d, "noinfo"))
            rc = 3
            continue
        p = fp_path(proj)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with io.open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write("# %s 由 build/artifact-src-fp.py **生成**，不要手改。\n" % FP_NAME)
            f.write("# 维度 A（src）：上游被编译的源 + 本工程生成物/垫片 + 决定它们的应用器脚本 + port-lib 输入\n")
            f.write("# 维度 B（peer）：本工程 csproj 引用的**本仓内产物**字节（自指已排除）—— 2026-09-14 加\n")
            f.write("#   【为什么】PF ⇄ Reach 真互引 ⇒ Roslyn 把被引件字节纳入输入哈希 ⇒ 该对无字节不动点、`pf` 每波必变；\n")
            f.write("#   只覆盖 src 时 `state=ok` 是**必要不充分**（源没变、peer 变了 ⇒ 产物照样变）。\n")
            f.write("# 排除：build/%s.Linux/{bin,obj}/**、.artifacts/**、本文件自己\n" % proj)
            f.write("# 重算比对：python3 build/artifact-src-fp.py --check（缺本文件 / 缺被引产物 / 旧格式 ⇒ noinfo，**不报绿**）\n")
            f.write("fp=%s\nn=%d\npeer_fp=%s\npeer_n=%d\n" % (d["src_fp"], d["src_n"], d["peer_fp"], d["peer_n"]))
            f.write("tool_sha256=%s\n" % sha256_file(os.path.abspath(__file__)))
            f.write("# 被引产物（sha256 前 16 + 仓库相对路径；**产物字节**，不是源）\n")
            for rel, sha in d["peers"]:
                f.write("peer=%s  %s\n" % (sha[:16], rel))
            # ── 逐文件（2026-09-14 T1c §43 加）：**源侧**记录"本仓自有输入"的逐件 sha ─────────────
            #   为什么加：`grep -c HbTextLine ARTIFACT-SRC-FP.txt` 曾是 0 ⇒ "PC 到底编的是哪一份 shim"
            #   答不了；`hbtextline_shim_stale` 只能靠 **mtime 代理**（同内容重写 ⇒ 假报警；`cp -p` 保旧
            #   mtime ⇒ 假红）。有本段即可做**内容比对**。
            #   格式 `file=<sha256 前 16>  <relpath>`：与 `peer=` 同布局；与 `fp=`/`n=`/`peer_fp=`/
            #   `peer_n=`/`peer=`/`tool_sha256=` **互不为前缀** ⇒ 既有解析器读不到、更不会读错；
            #   控制台机读行 `ARTIFACT_SRC_FP … state=…` **不变**。
            #   覆盖取舍：**只列本仓自有输入**（PC 34 / WB 23 / PF 18 条量级；`build/shims/**` 自动在内）；
            #   `upstream/**` 不逐条列（会把文件吹到 ~150KB 且无新信息，`fp=` 已覆盖其聚合）⇒ 用 `--list` 看全量。
            #   ⚠️ 诚实边界：本段只记**源的样子**（写入时刻该文件的 sha），**不证明产物里真的编进了它**；
            #      "产物内 sha" 另需 build 侧手段（构建时把内容哈希生成进产物 / 读 PDB 编译单元哈希）。
            f.write("# 逐文件（**源侧**）：sha256 前 16 + 仓库相对路径；只列**本仓自有输入**（`upstream/**` 不列，用 --list 看全量）\n")
            for rel, sha in d["entries"]:
                if not rel.startswith("upstream/"):
                    f.write("file=%s  %s\n" % (sha[:16], rel))
            if d["missing_peers"]:
                f.write("# ⚠️ 缺被引产物（未纳入）：" + ", ".join(d["missing_peers"]) + "\n")
        miss = ("；⚠️ 缺被引产物：" + ", ".join(d["missing_peers"][:3])) if d["missing_peers"] else ""
        print(fmt_line(d, "written", (d["note"] or "") + miss))
        if d["missing_peers"]:
            rc = 3
    return rc


def do_check():
    worst = 0
    for proj in PROJECTS:
        d = compute(proj)
        p = fp_path(proj)
        if d["src_fp"] is None:
            print(fmt_line(d, "noinfo"))
            worst = max(worst, 3)
            continue
        if d["missing_peers"]:
            print(fmt_line(d, "noinfo", "缺被引产物：" + ", ".join(d["missing_peers"][:3])
                          + ("…" if len(d["missing_peers"]) > 3 else "") + " ⇒ peer 维度无信息，**不报绿**"))
            worst = max(worst, 3)
            continue
        if not os.path.exists(p):
            print(fmt_line(d, "noinfo", "缺 " + os.path.relpath(p, ROOT) + " ⇒ 无信息，**不报绿**"))
            worst = max(worst, 3)
            continue
        rec_src, rec_peer, rec_peers = None, None, {}
        for line in io.open(p, encoding="utf-8", errors="replace").read().split("\n"):
            if line.startswith("fp="):
                rec_src = line[3:].strip()
            elif line.startswith("peer_fp="):
                rec_peer = line[len("peer_fp="):].strip()
            elif line.startswith("peer="):
                parts = line[len("peer="):].split(None, 1)
                if len(parts) == 2:
                    rec_peers[parts[1].strip()] = parts[0]
        if rec_peer is None:
            print(fmt_line(d, "noinfo", "**旧格式记录**（只有 fp=、没有 peer_fp=）⇒ 无法为 peer 维度背书；"
                                          "请跑 --write 重记（在此之前**不报绿**）"))
            worst = max(worst, 3)
            continue
        kind = stale_kind(rec_src, rec_peer, d["src_fp"], d["peer_fp"])
        if kind is None:
            print(fmt_line(d, "ok"))
            continue
        note = "kind=" + kind
        if kind in ("src", "src+peer"):
            note += "；源记录 %s ≠ 重算 %s（⇒ 本工程需重建）" % (rec_src, d["src_fp"])
        if kind in ("peer", "src+peer"):
            cur = {rel: sha[:16] for rel, sha in d["peers"]}
            parts = []
            for rel in sorted(set(cur) | set(rec_peers)):
                old, new = rec_peers.get(rel), cur.get(rel)
                if old is None:
                    parts.append("%s(新增 %s)" % (rel, new))
                elif new is None:
                    parts.append("%s(已移除)" % rel)
                elif old != new:
                    parts.append("%s %s→%s" % (rel, old, new))
            note += "；**被引产物变了**（源一个字没动，但 Roslyn 会把被引件字节纳入输入哈希 ⇒ 本工程产物同样会变）：" \
                    + (", ".join(parts[:4]) + ("…" if len(parts) > 4 else "") if parts else "（聚合变了）")
        print(fmt_line(d, "stale", note))
        worst = max(worst, 2)
    return worst


def do_list(proj):
    rels, missing = referenced_artifacts(proj)
    entries, note = manifest(proj)
    if entries is None:
        print("note=" + note)
        return 3
    print("# ── 维度 A（src）：%d 条 ──" % len(entries))
    for rel, sha in entries:
        print("%s  %s" % (sha[:16], rel))
    print("# ── 维度 B（peer）：%d 条（自指已排除）──" % len(rels))
    for rel, sha in rels:
        print("%s  %s" % (sha[:16], rel))
    for rel in missing:
        print("**缺**  %s" % rel)
    d = compute(proj)
    print(fmt_line(d))
    return 0


def do_peers(proj):
    """只列某工程的被引产物。**也可用于不是本工具被测对象的工程**（例如 ReachFramework ⇒ 它的 peer 是 PF）。"""
    rels, missing = referenced_artifacts(proj)
    print("ARTIFACT_PEERS proj=%s peer_n=%d missing=%d" % (proj, len(rels), len(missing)))
    for rel, sha in rels:
        print("peer=%s  %s" % (sha[:16], rel))
    for rel in missing:
        print("missing=%s" % rel)
    return 0 if not missing else 3


def do_selftest():
    """六极性：源 ①内容变 ⇒ 变 ②还原 ⇒ 逐位回绿 ③obj/ 加文件 ⇒ 不变 ④bin/ 加 ⇒ 不变；
    peer ⑤改被引产物字节 ⇒ peer 指纹变、还原 ⇒ 逐位回、自指被排除 ⑥分类 src/peer/src+peer/None 正确。"""
    proj = "WindowsBase"
    fp0 = compute(proj)["src_fp"]
    probe_dir = os.path.join(ROOT, "build", proj + ".Linux")
    # ① 在**本工程目录**放一个"被 csproj 引用的生成物"（模拟语义突变）—— 用 csproj 输入之外的文件不算，
    #    所以这里直接改**参与指纹的**文件：临时改上游一个被编译的源（然后原样还原）。
    ups, repos, err = parse_csproj_inputs(proj)
    target = None
    for rel in sorted(ups or []):
        p = os.path.join(ROOT, "upstream", "wpf", rel)
        if os.path.exists(p):
            target = p
            break
    if target is None:
        print("FP_SELFTEST=FAIL（找不到可做牙齿的上游源）")
        return 2
    backup = target + ".fp-selftest-bak"
    shutil.copy2(target, backup)
    try:
        with io.open(target, "a", encoding="utf-8") as f:
            f.write("\n// fp selftest probe\n")
        fp1 = compute(proj)["src_fp"]
        shutil.copy2(backup, target)
        fp2 = compute(proj)["src_fp"]
        objprobe = os.path.join(probe_dir, "obj", "__fp_selftest_probe.cs")
        os.makedirs(os.path.dirname(objprobe), exist_ok=True)
        io.open(objprobe, "w", encoding="utf-8").write("// should be EXCLUDED\n")
        fp3 = compute(proj)["src_fp"]
        os.remove(objprobe)
        binprobe = os.path.join(probe_dir, "bin", "__fp_selftest_probe.cs")
        os.makedirs(os.path.dirname(binprobe), exist_ok=True)
        io.open(binprobe, "w", encoding="utf-8").write("// should be EXCLUDED\n")
        fp4 = compute(proj)["src_fp"]
        os.remove(binprobe)
    finally:
        shutil.copy2(backup, target)
        os.remove(backup)
    print("FP_SELFTEST proj=%s fp0=%s" % (proj, fp0))
    print("FP_SELFTEST fp1=%s（给上游被编译的源加一行注释 ⇒ 期望 != fp0；**实测**：内容指纹 ⇒ 会变）" % fp1)
    print("FP_SELFTEST fp2=%s（还原 ⇒ 期望 == fp0，逐位）" % fp2)
    print("FP_SELFTEST fp3=%s（只在 obj/ 加 .cs ⇒ 期望 == fp0）" % fp3)
    print("FP_SELFTEST fp4=%s（只在 bin/ 加 .cs ⇒ 期望 == fp0）" % fp4)

    # ── peer 维度极性（**沙箱**，不碰真产物）：假 csproj + 假被引件 ⇒ 改字节必变、还原必回、自指必被排除 ──
    sand = tempfile.mkdtemp(prefix="fp-peer-selftest-")
    try:
        os.makedirs(os.path.join(sand, "build", "Foo.Linux"), exist_ok=True)
        io.open(os.path.join(sand, "build", "Foo.Linux", "Foo.Linux.csproj"), "w", encoding="utf-8").write(
            '<Project Sdk="Microsoft.NET.Sdk"><ItemGroup>\n'
            '  <Reference Include="Bar"><HintPath>$(WpfLinuxRoot)build/Bar.Linux/bin/Debug/Bar.dll</HintPath></Reference>\n'
            '  <Reference Include="Foo"><HintPath>$(WpfLinuxRoot)build/Foo.Linux/bin/Debug/Foo.dll</HintPath></Reference>\n'
            '</ItemGroup></Project>\n')
        for d2, n2 in (("Bar.Linux", "Bar.dll"), ("Foo.Linux", "Foo.dll")):
            dd = os.path.join(sand, "build", d2, "bin", "Debug")
            os.makedirs(dd, exist_ok=True)
            io.open(os.path.join(dd, n2), "wb").write(b"A")
        bar = os.path.join(sand, "build", "Bar.Linux", "bin", "Debug", "Bar.dll")
        p1, m1 = referenced_artifacts("Foo", root=sand)
        peer1 = fp_of(p1)
        io.open(bar, "wb").write(b"B")
        peer2 = fp_of(referenced_artifacts("Foo", root=sand)[0])
        io.open(bar, "wb").write(b"A")
        peer3 = fp_of(referenced_artifacts("Foo", root=sand)[0])
        self_ok = (len(p1) == 1 and p1[0][0].endswith("Bar.dll") and not m1)
        peer_ok = (peer1 != peer2 and peer3 == peer1)
    finally:
        shutil.rmtree(sand, ignore_errors=True)
    print("FP_SELFTEST_PEER peer1=%s（沙箱：1 个被引件 + 1 个自指件 ⇒ 期望只纳入 Bar、自指 Foo 被排除：%s）"
          % (peer1, "是" if self_ok else "**否**"))
    print("FP_SELFTEST_PEER peer2=%s（改被引件字节 ⇒ 期望 != peer1）／peer3=%s（还原 ⇒ 期望 == peer1）" % (peer2, peer3))

    # ── 分类极性（**纯函数**，离线）：src / peer / src+peer ──
    kinds = [stale_kind("a", "p", "b", "p"),        # 只有源变
             stale_kind("a", "p", "a", "q"),        # 只有 peer 变
             stale_kind("a", "p", "b", "q"),        # 两者都变
             stale_kind("a", "p", "a", "p")]        # 都没变 ⇒ None
    kind_ok = (kinds == ["src", "peer", "src+peer", None])
    print("FP_SELFTEST_KIND kinds=%s（期望 ['src','peer','src+peer',None]）" % kinds)

    if fp1 != fp0 and fp2 == fp0 and fp3 == fp0 and fp4 == fp0 and self_ok and peer_ok and kind_ok:
        print("FP_SELFTEST=PASS（六极性全对：源能变/能逐位回绿/obj 与 bin 真被排除/peer 能变能回/自指被排除/分类正确）")
        return 0
    print("FP_SELFTEST=FAIL（至少一条极性不成立 ⇒ 别拿它当闸门）")
    return 2


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--list", metavar="PROJ")
    ap.add_argument("--peers", metavar="PROJ", help="只列该工程的被引产物（可用于非被测工程，如 ReachFramework）")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        return do_selftest()
    if args.write:
        return do_write()
    if args.check:
        return do_check()
    if args.list:
        return do_list(args.list)
    if args.peers:
        return do_peers(args.peers)
    rc = 0
    for proj in PROJECTS:
        d = compute(proj)
        print(fmt_line(d) if d["src_fp"] is not None else fmt_line(d, "noinfo"))
        if d["src_fp"] is None:
            rc = 3
    return rc


if __name__ == "__main__":
    sys.exit(main())
