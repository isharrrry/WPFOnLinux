#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# proto-attribution-check.sh —— 「**谁写了这条 X 请求**」的**协议级归因牙**（`TASK-0744`／`D-G144`）
#
# 【它挡的是什么】
#   托管层 X11 的 P/Invoke 走 `NativeLibrary` **句柄**解析（`SetDllImportResolver` ＋
#   `TryLoad("libX11.so.6")`，`src/WpfGfx.Linux/Windowing/X11Native.cs:11/27/49/291`）⇒
#   **不经过 ELF PLT** ⇒ `LD_PRELOAD` 的符号级 hook（`CALL XResizeWindow` 那一族）**恒瞎**。
#   现场实测：红腿的符号级台账里**没有**任何几何类 `CALL`，而**线上真有** `PROTO op0=12`。
#   ⇒ 拿符号级台账判「谁调用了什么」，会把真凶（**应用自己**）读成「没人调用」= **假结论**。
#   本牙把「谁写的字节」做成**会咬的**判据：吃 **wire 台账**（socket 写）＋ 调用链 ＋ 服务器侧成对事件。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）—— `§8.3` 口径】
#   `ATTRIBUTED`      ① `PROTO op0=12` 解码自洽且几何 = 屏尺寸／BASE 之一；② 该行 `fd` 被**同趟**
#                     断言为 X socket；③ `chain` 的最外层**应用**帧可命名；④ 服务器侧在 `Δ≤50 ms`
#                     内出现**同几何** `ConfigureNotify`。四条**全**满足。
#   `NOT_ATTRIBUTED`  ①–③ 满足但**没有任何**服务器侧事件成对（= 请求**被拦/没生效**，
#                     **不是**"没人发"）。两式具名：`cut-removed-effect`（线上被等长 `NoOperation`
#                     换掉 ⇒ 意图已证 ∧ 效果被移走）／`no-server-side-pair`。
#   `NOINFO`          缺任一格（**既不算绿也不算红**）。**"符号级台账里没有 CALL"永远不许当
#                     `NOT_ATTRIBUTED`**（`D-G144`）—— 它只配 `NOINFO reason=symbol-level-not-evidence`。
#
# 【判定次序（**逐条写死；实现照此顺序短路**）】
#   1 前提：`geom` 空/非 `WxH` 形状 ⇒ `premise`；`op0` **非数字且非 `-`** ⇒ `premise`。
#     ⚠️ **裁定**：`op0=-`（空）**不是**前提缺失，而是「**该腿根本没有 `op0=12` 行**」= 无触发物。
#        理由：契约第 9/10 条要求 `no-trigger` **可达**；若把 `op0=-` 归给 `premise`，
#        `no-trigger` 分支**结构性不可达** ⇒ 死牙（恒不触发 = 恒绿方向）。此事已在报告里点名。
#   2 解码自洽（子句**逐条**，失败即 `NOINFO reason=decode-inconsistent` 并具名 `dfail=`）：
#     `hlen` 可数 → `hlen>=12` → `op0==12` → `mask` 可数 → `mask!=0` → `mask<=0x3fff`
#     → `win` 可数 → **`win!=0`** → `rl` 可数 → `rl==12+4*popcount(mask)` → `rl∈[16,64]`。
#     ⚠️ **`win!=0` 这一条是契约点名要补的**：参考取数器的 `dec_cfg()` **没有**它（它只在装置侧
#        `cp_patch()` 里查）⇒ 本牙在**判据侧**补齐，并把 `dfail=win-zero` 印出来。
#   3 几何必须 == `SCREEN` 或 == `BASE`，否则 `geom-not-screen-or-base`。
#   4 `sock_id != present` ⇒ `sock-id-absent`（**这一格是闸**；每行判词都印 `sock_id=`）。
#   5 `chain` 的最外层**应用**帧：按 denylist **过滤**（`[hook]` 逐字／`<jit/anon>` 逐字／
#     `libX11*`／`libxcb*`／`xwrap*` 前缀）；滤完为空 ⇒ `no-app-frame`。
#     ⚠️ **不照抄**参考实现的 `mods[-1]`（它取链末帧、**零过滤**）⇒ 本牙同时印
#     `app_frame=`（滤后的最外层）**与** `raw_last_frame=`（原样末帧）供交叉核对。
#   6 `sym_call==none` **永不**产出 `NOT_ATTRIBUTED`（印 `SYM_ONLY=never-sufficient`）；
#     若符号级台账是**唯一**证据（无触发物 ∧ 无 cut）⇒ `NOINFO reason=symbol-level-not-evidence`。
#   7 有成对服务器侧事件（同几何 ∧ `|Δ|≤50 ms`）⇒ `ATTRIBUTED reason=paired-server-event`。
#   8 无成对事件 ∧ `cut_proto` 在 ⇒ `NOT_ATTRIBUTED reason=cut-removed-effect`。
#   9 无成对事件 ∧ 无 `cut_proto` ∧ 有已解码请求 ⇒ `NOT_ATTRIBUTED reason=no-server-side-pair`。
#   10 无已解码请求 ∧ 无 `cut_proto` ⇒ `NOINFO reason=no-trigger`（**永不许读成"反极成立"**）。
#   附：无触发物 ∧ `cut_proto` 在 = 自相矛盾 ⇒ `NOINFO reason=cut-without-request`（响亮另立，
#       不混进 `no-trigger`）。另：成对事件 ∧ `cut_proto` 在（`cut_and_pair=`）仍按第 7 条给
#       `ATTRIBUTED`（次序如此写死），但**逐行印出**并计入花名册 —— 它其实是"拦了也照旧发生"的
#       反证形态，属于极性臂的判词，不是本牙逐例判词的射程。
#
# 【机读行（**恒为最后一行**）】
#   `PROTO_ATTR=<ATTRIBUTED|NOT_ATTRIBUTED|NOINFO> cases=<n> pass=<n> fail=<n> noinfo=<n> rc=<n>`
#   `rc`：0 = 门禁 PASS｜1 = 门禁 FAIL｜3 = 查不动。`pass`/`fail`/`noinfo` = **逐例判词的三态计数**
#   （`pass`=`ATTRIBUTED` 例数、`fail`=`NOT_ATTRIBUTED` 例数、`noinfo`=`NOINFO` 例数）；
#   **断言层**的计数另印在 `PROTO_ATTR_ROSTER`（`mismatch=`／`bad_expect=`／`posctl_att=`）——
#   两个口径**分开**，不许互相顶替。
#   `PROTO_ATTR=ATTRIBUTED` ⇔ rc=0；`=NOT_ATTRIBUTED` ⇔ rc=1；`=NOINFO` ⇔ rc=3。
#
# 【`--cases` 的语料契约（唯一真值来源；**不许有硬编码期望**）】
#   TAB 分隔 ＋ **必须有表头行**；列**定序**（前 14 列按契约定序，后 2 列是本牙追加的解码输入）：
#     `tag role op0 fd mask win geom sock_id chain_app sym_call cn_seq cut_proto expect reason rl hlen`
#   · `sock_id` = `present`|`absent`（模拟装置**有没有印 socket 身份**）。
#   · `chain_app` = 该 `PROTO` 行的 `chain:` **原样帧表**（`;` 连接；`-` = 无）⇒ **过滤在牙里做**。
#   · `cn_seq` = `-` 或 `kind:WxH@rel_ms` 逐项 `;` 连接；`kind` ∈ `restore|push|other`。
#     ⚠️ **归一化裁定**：`rel_ms` **一律相对本行那条请求**（请求 = 0；`Δ` 就是它的绝对值）。
#        理由：契约的 `cn_seq` 是**唯一**带时间的列，而第 7 条要判 `Δ≤50 ms`；不归一化则 `Δ` 无从求。
#     ⚠️ `kind` 是**读数标签**（审计用）：判据**不读它** —— 判据只问"有没有同几何成对事件"。
#   · `sym_call` = `none`|`XResizeWindow`（模拟**符号级**台账；见第 6 条）。
#   · `rl`／`hlen` = 该请求的 `rl`（字节）与 `head=` 的可解字节数 —— 第 2 条的子句**只**能由它们表达，
#     故必须在语料里；追加在**最后一列之后**，按列名消费，不破坏前 14 列的定序。
#   · `mask`/`win`/`rl`/`hlen` 接受**十进制或 `0x` 十六进制**（同时容纳台账原样与手写可读值）。
#   · `expect` ∈ `ATTRIBUTED|NOT_ATTRIBUTED|NOINFO`；`reason` = 期望的**理由 token**（逐字比对）。
#   · `--expect N` = **行数常量**（语料被截断/被扩表 ⇒ 响亮 `FAIL`）。
#   · 至少一行 `role=POSCTL` 且**真判** `ATTRIBUTED`，否则 `FAIL reason=untriggerable`（阳性对照是门槛）。
#
# 【`--legs` 的诚实边界（本牙自己印在读数里，**不许粉饰**）】
#   归档装置**只印 `fd=<n>`**、**不印** socket 身份（`getpeername` 的结果没有随行字段）
#   ⇒ `§8.3` 的第 ② 格**恒缺** ⇒ 真归档腿**必然** `NOINFO reason=sock-id-absent`。
#   ⇒ **`ATTRIBUTED` 在真腿上不可达**，直到装置随行打印那条连接的 socket 身份
#     （`sun_path` 或 fd 的 socket inode）。本牙对"只差这一格"的腿额外印
#     `would_be=<若 sock_id 在则会判什么>` —— 证"不可达**只因缺这一格**"，不是别的原因。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：verify-all.sh 的 run_step "PROTO-ATTR" bash build/MilBridge/tools/proto-attribution-check.sh
#   ——⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#   ⚠️ 本条是**自洽的硬要求**：本牙落地时**必须与接线同趟**（否则判「自述 vs 接线」的对手牙当场判红）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零重活），14 例，
#   其中大部分是「**必须红或 NOINFO**」的负例 ＋ 阳性对照 ＋ 空边 ＋ 通用性（翻转期望必红并点名）。
#   用法：bash proto-attribution-check.sh [--cases TSV] [--expect N] [--legs DIR…]
#                                      [--repo DIR] [--screen WxH] [--base WxH]
#                                      [--selftest] [--debug-tmp]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
REAL_ROOT="$(cd -- "$SELF_DIR/../../.." && pwd)"

RC_PASS=0; RC_FAIL=1; RC_NOINFO=3
SCREEN="1280x1024"
BASE="800x600"
REPO=""
CASES=""
EXPECT=""
LEG_DIRS=()
KEEP_TMP=0

TMPBASE="${TMPDIR:-$HOME/.cache/wpf-linux/tmp}"
WORK=""
ST_DIR=""

say() { printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }
now_iso() { date -Iseconds 2>/dev/null || date; }

# 命中判定（**不用管道、不用 `grep -c`**：算术只吃 awk 的计数）
has() {  # has <text> <needle>；命中 ⇒ rc 0
    local v
    v="$(awk -v n="$2" 'index($0,n)>0{f=1} END{printf "%d", (f?1:0)}' <<<"$1")"
    [ "$v" = 1 ]
}
# 从「名=值」行里取值（找不到 ⇒ 空）
field_of() {  # field_of <line> <name>
    awk -v n="$2" '{ for (i=1;i<=NF;i++) { p=index($i,"="); if (p>1 && substr($i,1,p-1)==n) { print substr($i,p+1); exit } } }' <<<"$1"
}

# ── 判据本体（**唯一实现**：`--cases` 与 `--legs` 吃同一个 awk；两处只有**输入归一**不同）────
#   ⚠️ 本 awk 程序内**不用单引号**（外层是单引号串）、不用 `{n}` 区间、不用 3 参 `match()`（mawk 1.3.4）。
pat_judge() {  # pat_judge <check_expect:0|1> <tsv>
    awk -v SCREEN="$SCREEN" -v BASE="$BASE" -v PREFIX="${JUDGE_PREFIX:-CASE}" -v CHECK_EXPECT="${1:-1}" '
    BEGIN { FS="\t"
            examined=0; att=0; notatt=0; noinfo=0; mismatch=0; bad_expect=0
            posctl_rows=0; posctl_att=0; cut_and_pair=0 }
    function tonum(s,   v,i,c,d) {
        if (s ~ /^0[xX]/) { v=0
            if (length(s) < 3) return -1
            for (i=3;i<=length(s);i++) { c=tolower(substr(s,i,1)); d=index("0123456789abcdef",c)-1
                if (d<0) return -1; v = v*16 + d }
            return v }
        if (s ~ /^[0-9]+$/) return s+0
        return -1 }
    function popcount(m,   c) { c=0; while (m > 0) { c = c + (m % 2); m = int(m / 2) } return c }
    function modof(f,   m) { m=f; sub(/^[^@]*@/,"",m); sub(/\+0x.*$/,"",m)
                             gsub(/^[ \t]+/,"",m); gsub(/[ \t]+$/,"",m); return m }
    function denied(m) { return (m=="[hook]" || m=="<jit/anon>" || m ~ /^libX11/ || m ~ /^libxcb/ || m ~ /^xwrap/) }
    function app_frame(s,   n,i,t,last) {
        V_APP="-"; V_RAW="-"
        if (s=="" || s=="-") return 0
        n=split(s, t, ";"); if (n<1) return 0
        for (i=1;i<=n;i++) { gsub(/^[ \t]+/,"",t[i]); gsub(/[ \t]+$/,"",t[i]) }
        if (t[n] != "") V_RAW=t[n]
        last="-"
        for (i=1;i<=n;i++) { if (t[i]=="") continue; if (!denied(modof(t[i]))) last=t[i] }
        V_APP=last
        return 1 }
    function pair_of(cn, geom,   n,i,it,p,wh,rel,k,d,best,bestd) {
        best="-"; bestd=0; V_DELTA="-"
        if (cn=="" || cn=="-") return "-"
        n=split(cn, C2, ";")
        for (i=1;i<=n;i++) {
            it=C2[i]; gsub(/^[ \t]+/,"",it); gsub(/[ \t]+$/,"",it)
            if (it=="") continue
            p=index(it,"@"); if (p<1) continue
            wh=substr(it,1,p-1); rel=substr(it,p+1)+0
            k=index(wh,":"); if (k>0) wh=substr(wh,k+1)
            if (wh != geom) continue
            d=rel; if (d<0) d=-d
            if (d<=50 && (best=="-" || d<bestd)) { best=it; bestd=d }
        }
        if (best != "-") V_DELTA=bestd
        return best }
    function judge(force,   op0,geom,sock,sym,cn,cut,rl,hlen,mask,win,absent,hn,on,mn,wn,rn) {
        V_VERDICT="NOINFO"; V_REASON=""; V_DFAIL="-"; V_PAIR="-"; V_DELTA="-"; V_SYMONLY="-"
        app_frame(R[9])
        op0=R[3]; geom=R[7]; sock=R[8]; sym=R[10]; cn=R[11]; cut=R[12]; rl=R[15]; hlen=R[16]
        mask=R[5]; win=R[6]
        if (force==1) sock="present"
        if (geom=="" || geom=="-" || geom !~ /^[0-9]+x[0-9]+$/) { V_REASON="premise"; return }
        absent=0
        if (op0=="" || op0=="-") absent=1
        else if (tonum(op0) < 0) { V_REASON="premise"; return }
        if (sym=="none") V_SYMONLY="never-sufficient"
        if (absent==1) {
            if (sym=="none" && cut!="present") { V_REASON="symbol-level-not-evidence"; return }
            if (cut=="present") { V_REASON="cut-without-request"; return }
            V_REASON="no-trigger"; return
        }
        hn=tonum(hlen)
        if (hn < 0)        { V_DFAIL="hlen-malformed";    V_REASON="decode-inconsistent"; return }
        if (hn < 12)       { V_DFAIL="hlen-lt-12";        V_REASON="decode-inconsistent"; return }
        on=tonum(op0)
        if (on != 12)      { V_DFAIL="op0-not-12";        V_REASON="decode-inconsistent"; return }
        mn=tonum(mask)
        if (mn < 0)        { V_DFAIL="mask-malformed";    V_REASON="decode-inconsistent"; return }
        if (mn == 0)       { V_DFAIL="mask-zero";         V_REASON="decode-inconsistent"; return }
        if (mn > 16383)    { V_DFAIL="mask-out-of-range"; V_REASON="decode-inconsistent"; return }
        wn=tonum(win)
        if (wn < 0)        { V_DFAIL="win-malformed";     V_REASON="decode-inconsistent"; return }
        if (wn == 0)       { V_DFAIL="win-zero";          V_REASON="decode-inconsistent"; return }
        rn=tonum(rl)
        if (rn < 0)        { V_DFAIL="rl-malformed";      V_REASON="decode-inconsistent"; return }
        if (rn != 12 + 4*popcount(mn)) { V_DFAIL="rl-popcount"; V_REASON="decode-inconsistent"; return }
        if (rn < 16 || rn > 64) { V_DFAIL="rl-out-of-range"; V_REASON="decode-inconsistent"; return }
        if (geom != SCREEN && geom != BASE) { V_REASON="geom-not-screen-or-base"; return }
        if (sock != "present") { V_REASON="sock-id-absent"; return }
        if (V_APP=="-") { V_REASON="no-app-frame"; return }
        V_PAIR=pair_of(cn, geom)
        if (V_PAIR != "-") { V_VERDICT="ATTRIBUTED"; V_REASON="paired-server-event"; return }
        V_VERDICT="NOT_ATTRIBUTED"
        if (cut=="present") { V_REASON="cut-removed-effect"; return }
        V_REASON="no-server-side-pair"; return }
    NR==1 && $1=="tag" { next }
    {
        if ($1=="") next
        for (i=1;i<=16;i++) R[i]=$i
        examined++
        judge(0)
        v=V_VERDICT; rs=V_REASON; df=V_DFAIL; pr=V_PAIR; dl=V_DELTA; ap=V_APP; rw=V_RAW; sy=V_SYMONLY
        judge(1)
        wb="-"; if (rs=="sock-id-absent") wb=V_VERDICT
        # 审计用：真实判词在 socket 闸短路时 cn_pair 还没算出来，故用强制 sock_id 在场那一趟的读数补上
        #   （只作审计展示；判词与计数一律用 judge(0) 的结果）
        if (pr == "-" && V_PAIR != "-") { pr=V_PAIR; dl=V_DELTA }
        if (v=="ATTRIBUTED") att++
        else if (v=="NOT_ATTRIBUTED") notatt++
        else noinfo++
        if (R[2]=="POSCTL") { posctl_rows++; if (v=="ATTRIBUTED") posctl_att++ }
        if (v=="ATTRIBUTED" && R[12]=="present") cut_and_pair++
        dls="-"; if (dl != "-") dls=sprintf("%.1f", dl+0)
        printf "%s tag=%s role=%s verdict=%s reason=%s sock_id=%s app_frame=%s raw_last_frame=%s geom=%s screen=%s base=%s cn_pair=%s delta_ms=%s dfail=%s sym_call=%s SYM_ONLY=%s cut_proto=%s expect=%s want_reason=%s would_be=%s rl=%s hlen=%s mask=%s win=%s fd=%s\n", PREFIX, R[1], R[2], v, rs, R[8], ap, rw, R[7], SCREEN, BASE, pr, dls, df, R[10], sy, R[12], R[13], R[14], wb, R[15], R[16], R[5], R[6], R[4]
        if (CHECK_EXPECT=="1") {
            want=R[13]; wr=R[14]
            if (want!="ATTRIBUTED" && want!="NOT_ATTRIBUTED" && want!="NOINFO") {
                bad_expect++; mismatch++
                printf "❌ tag=%s rule=bad-expect expect=%s\n", R[1], want
            } else if (v != want || rs != wr) {
                mismatch++
                printf "❌ tag=%s want=%s got=%s want_reason=%s got_reason=%s dfail=%s\n", R[1], want, v, wr, rs, df
            }
        }
    }
    END {
        printf "PROTO_ATTR_ROWS cases=%d examined=%d att=%d not_attributed=%d noinfo=%d mismatch=%d bad_expect=%d posctl_rows=%d posctl_att=%d cut_and_pair=%d\n", examined, examined, att, notatt, noinfo, mismatch, bad_expect, posctl_rows, posctl_att, cut_and_pair
    }' "$2"
}

# ── 输入归一（生产者 ①）：真腿目录 → 16 列记录（**判据不在这里**）──────────────────────────
#   诚实边界：`sock_id` **恒 absent** —— 归档装置只印 `fd=<n>`，socket 身份从未随行打印。
leg_record() {  # leg_record <legdir> ⇒ 一行 16 列（TAB）；不可判 ⇒ 空
    local d="$1"; shift
    local files=("$d/probe.txt" "$d/xwrap.log")
    [ -f "$d/observer.log" ] && files+=("$d/observer.log")
    awk -v SCREEN="$SCREEN" -v BASE="$BASE" -v TAG="$(basename "$d")" '
    function tonum(s,   v,i,c,dd) {
        if (s ~ /^0[xX]/) { v=0
            for (i=3;i<=length(s);i++) { c=tolower(substr(s,i,1)); dd=index("0123456789abcdef",c)-1
                if (dd<0) return -1; v = v*16 + dd }
            return v }
        if (s ~ /^[0-9]+$/) return s+0
        return -1 }
    function hex2(s) { return tonum("0x" s) }
    function emit(   wh,k,rel,item) {
        if (cw < 0 || chh < 0) return
        wh = cw "x" chh
        k = "other"
        if (wh == BASE) k = "restore"
        else if (wh == SCREEN) k = "push"
        rel = (cus - requs) / 1000.0
        item = k ":" wh "@" (rel >= 0 ? "+" : "") sprintf("%.1f", rel)
        cns = (cns == "") ? item : cns ";" item
        have=0 }
    FNR==1 { f=FILENAME; if (sym == "") sym="none"; if (cut == "") cut="absent" }
    f ~ /probe\.txt$/ {
        if (match($0,/^SCREEN_LEG=[^ \t]+/)) scr=substr($0,12)
        if (match($0,/^BASE geom=[^ \t]+/)) { b=substr($0,11); p=index(b,"@"); if (p>1) b=substr(b,1,p-1)
            if (b ~ /^[0-9]+x[0-9]+$/) base=b }
        next }
    f ~ /xwrap\.log$/ {
        if (index($0,"CUT_PROTO")>0) cut="present"
        if (index($0,"CALL XResizeWindow ")>0) sym="XResizeWindow"
        if (index($0,"PROTO")<=0) next
        if (index($0,"op0=12 ")<=0) next
        t=$2+0
        fdv="-"; if (match($0,/ fd=[0-9]+/)) fdv=substr($0,RSTART+4,RLENGTH-4)
        if (!match($0,/head=[0-9a-f ]+/)) next
        hs=substr($0,RSTART+5,RLENGTH-5)
        cnt=split(hs, HB, " "); nb=0
        for (i=1;i<=cnt;i++) { if (HB[i] != "") { nb++; B[nb]=hex2(HB[i]) } }
        if (nb < 12) next
        op0v=B[1]; rlv=(B[3] + B[4]*256)*4
        winv=B[5] + B[6]*256 + B[7]*65536 + B[8]*16777216
        mskv=B[9] + B[10]*256
        p=13; wv=""; hv=""
        for (bi=1; bi<=5; bi++) {
            bit = 2^(bi-1)
            if (int(mskv/bit) % 2 == 1) {
                if (p+3 > nb) break
                val = B[p] + B[p+1]*256 + B[p+2]*65536 + B[p+3]*16777216
                if (bit==4) wv=val
                if (bit==8) hv=val
                p = p + 4
            }
        }
        g = ""; if (wv != "" && hv != "") g = wv "x" hv
        ch = "-"; if (match($0,/chain: /)) { ch=substr($0,RSTART+RLENGTH); gsub(/ <- /,";",ch) }
        if (g == SCREEN || requs == 0) { requs=t; rop=op0v; rrl=rlv; rwin=winv; rmsk=mskv; rnb=nb; rfd=fdv; rg=g; rch=ch }
        next }
    f ~ /observer\.log$/ {
        rest=$0
        if (match($0,/^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]+/)) { cur=substr($0,1,RLENGTH)+0; rest=substr($0,RLENGTH+1) }
        if (index(rest,"ConfigureNotify event")>0) {
            if (have) emit()
            have=1; cus=cur; cw=-1; chh=-1
            next }
        if (have && cw < 0) {
            if (match(rest,/width [0-9]+/)) cw=substr(rest,RSTART+6,RLENGTH-6)+0
            if (match(rest,/height [0-9]+/)) chh=substr(rest,RSTART+7,RLENGTH-7)+0
            if (cw >= 0 && chh >= 0) emit()
            next }
        next }
    END {
        if (have) emit()
        if (scr == "") scr = SCREEN
        if (base == "") base = BASE
        opv = (requs == 0) ? "-" : rop
        gv  = (requs == 0) ? SCREEN : rg
        chv = (requs == 0) ? "-" : rch
        rlv2 = (requs == 0) ? "-" : rrl
        nbv  = (requs == 0) ? "-" : rnb
        printf "%s\tLEG\t%s\t%s\t%s\t%s\t%s\tabsent\t%s\t%s\t%s\t%s\t-\t-\t%s\t%s\n", TAG, opv, rfd, rmsk, rwin, gv, chv, sym, (cns=="" ? "-" : cns), cut, rlv2, nbv
    }' "${files[@]}"
}

# ── 模式 ①：`--cases`（`verify-all` 走这条）────────────────────────────────────────────
mode_cases() {
    local tsv="$1" exp="${2:-}" out sum rows examined att notatt noi mm be pr pa cp hdr want_hdr reason_ok greason
    if [ -z "$tsv" ]; then
        say "PROTO_ATTR=NOINFO reason=usage:--cases-needs-file cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    if [ ! -e "$tsv" ]; then
        say "PROTO_ATTR=NOINFO reason=cases-absent file=$tsv cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    if [ ! -s "$tsv" ]; then
        say "PROTO_ATTR=NOINFO reason=cases-empty file=$tsv cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    hdr="$(awk 'NR==1{print}' "$tsv")"
    want_hdr="$(printf 'tag\trole\top0\tfd\tmask\twin\tgeom\tsock_id\tchain_app\tsym_call\tcn_seq\tcut_proto\texpect\treason\trl\thlen')"
    if [ "$hdr" != "$want_hdr" ]; then
        say "PROTO_ATTR=NOINFO reason=bad-header file=$tsv got=$(printf '%s' "$hdr" | tr '\t' ',') cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    rows="$(awk 'NR>1 && $1!="" {n++} END{print n+0}' "$tsv")"
    if [ "${rows:-0}" -eq 0 ]; then
        say "PROTO_ATTR=NOINFO reason=zero-examined file=$tsv cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    out="$(JUDGE_PREFIX=CASE pat_judge 1 "$tsv" 2>&1)"
    printf '%s\n' "$out"
    sum="$(awk '/^PROTO_ATTR_ROWS /{last=$0} END{print last}' <<<"$out")"
    examined="$(field_of "$sum" examined)"; att="$(field_of "$sum" att)"; notatt="$(field_of "$sum" not_attributed)"
    noi="$(field_of "$sum" noinfo)"; mm="$(field_of "$sum" mismatch)"; be="$(field_of "$sum" bad_expect)"
    pr="$(field_of "$sum" posctl_rows)"; pa="$(field_of "$sum" posctl_att)"; cp="$(field_of "$sum" cut_and_pair)"
    : "${examined:=0}"; : "${att:=0}"; : "${notatt:=0}"; : "${noi:=0}"
    : "${mm:=0}"; : "${be:=0}"; : "${pr:=0}"; : "${pa:=0}"; : "${cp:=0}"
    say "PROTO_ATTR_ROSTER cases=$rows examined=$examined att=$att not_attributed=$notatt noinfo=$noi mismatch=$mm bad_expect=$be posctl_rows=$pr posctl_att=$pa cut_and_pair=$cp expect=${exp:--} screen=$SCREEN base=$BASE corpus=$(basename "$tsv") sha16=$(sha16 "$tsv") at=$(now_iso)"
    if [ "$examined" -eq 0 ]; then
        say "❌ rule=zero-examined（零例被检查 ⇒ 绝不给 PASS）"
        say "PROTO_ATTR=NOINFO reason=zero-examined cases=$rows pass=$att fail=$notatt noinfo=$noi rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    reason_ok=1; greason="-"
    if [ -n "$exp" ] && [ "$rows" != "$exp" ]; then
        say "❌ rule=row-count-mismatch actual=$rows expect=$exp（语料被截断或被扩表）"
        reason_ok=0; if [ "$greason" = "-" ]; then greason="row-count-mismatch"; fi
    fi
    if [ "$be" != 0 ]; then
        say "❌ rule=bad-expect n=$be（expect 列不是三态之一）"
        reason_ok=0; if [ "$greason" = "-" ]; then greason="bad-expect"; fi
    fi
    if [ "$mm" != 0 ]; then
        reason_ok=0; if [ "$greason" = "-" ]; then greason="case-mismatch"; fi
    fi
    if [ "$pa" -eq 0 ]; then
        say "❌ 阳性对照不成立：role=POSCTL 的行里一行真 ATTRIBUTED 都没有 ⇒ rule=untriggerable"
        reason_ok=0; if [ "$greason" = "-" ]; then greason="untriggerable"; fi
    fi
    if [ "$reason_ok" = 1 ]; then
        say "PROTO_ATTR_GATE=PASS examined=$examined mismatch=0 bad_expect=0 posctl=$pa/$pr cut_and_pair=$cp"
        say "PROTO_ATTR=ATTRIBUTED cases=$rows pass=$att fail=$notatt noinfo=$noi rc=$RC_PASS"
        return $RC_PASS
    fi
    say "PROTO_ATTR_GATE=FAIL reason=$greason examined=$examined mismatch=$mm bad_expect=$be posctl_att=$pa"
    say "PROTO_ATTR=NOT_ATTRIBUTED cases=$rows pass=$att fail=$notatt noinfo=$noi rc=$RC_FAIL"
    return $RC_FAIL
}

# ── 模式 ②：`--legs`（真腿目录；输入可用性由 bash 判，判据本体仍是同一 awk）────────────────
mode_legs() {
    local out sum n=0 att=0 notatt=0 noi=0 inabsent=0 sockmiss=0 d rec tsv
    if [ "$#" -eq 0 ]; then
        say "PROTO_ATTR=NOINFO reason=usage:--legs-needs-dir cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    tsv="$WORK/legs.tsv"
    printf 'tag\trole\top0\tfd\tmask\twin\tgeom\tsock_id\tchain_app\tsym_call\tcn_seq\tcut_proto\texpect\treason\trl\thlen\n' > "$tsv"
    for d in "$@"; do
        if [ ! -d "$d" ]; then
            say "PROTO_ATTR_LEG tag=$d verdict=NOINFO reason=leg-dir-absent"; inabsent=$((inabsent + 1)); continue
        fi
        if [ ! -f "$d/probe.txt" ] || [ ! -f "$d/xwrap.log" ]; then
            say "PROTO_ATTR_LEG tag=$(basename "$d") verdict=NOINFO reason=leg-files-absent"; inabsent=$((inabsent + 1)); continue
        fi
        rec="$(leg_record "$d")"
        # 符号级台账的**审计行**（`D-G144` 的正证：符号级看不见那条几何请求）
        local symc
        symc="$(awk 'index($0,"CALL XResizeWindow ")>0{r=1}
                     index($0,"CALL XConfigureWindow ")>0{c=1}
                     index($0,"CALL XMoveResizeWindow ")>0{m=1}
                     END{ s=""; if(r)s=s"XResizeWindow,"; if(c)s=s"XConfigureWindow,"; if(m)s=s"XMoveResizeWindow,"
                          if(s=="")s="none"; sub(/,$/,"",s); print s }' "$d/xwrap.log")"
        say "PROTO_ATTR_LEG_SYM tag=$(basename "$d") sym_geom_calls=$symc note=symbol-ledger-may-be-blind-per-D-G144"
        if [ -z "$rec" ]; then
            say "PROTO_ATTR_LEG tag=$(basename "$d") verdict=NOINFO reason=record-empty（无任何可解码的 PROTO op0=12 行）"
            inabsent=$((inabsent + 1)); continue
        fi
        n=$((n + 1))
        printf '%s\n' "$rec" >> "$tsv"
    done
    if [ "$n" -eq 0 ]; then
        say "PROTO_ATTR=NOINFO reason=zero-examined legs=$inabsent cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    out="$(JUDGE_PREFIX=PROTO_ATTR_LEG pat_judge 0 "$tsv" 2>&1)"
    printf '%s\n' "$out"
    sum="$(awk '/^PROTO_ATTR_ROWS /{last=$0} END{print last}' <<<"$out")"
    att="$(field_of "$sum" att)"; notatt="$(field_of "$sum" not_attributed)"; noi="$(field_of "$sum" noinfo)"
    : "${att:=0}"; : "${notatt:=0}"; : "${noi:=0}"
    sockmiss="$(awk '/reason=sock-id-absent/{k++} END{print k+0}' <<<"$out")"
    say "PROTO_ATTR_LEGS cases=$n input_absent=$inabsent att=$att not_attributed=$notatt noinfo=$noi sock_id_absent=$sockmiss screen=$SCREEN base=$BASE at=$(now_iso)"
    if [ "$sockmiss" -gt 0 ]; then
        say "PROTO_ATTR_NOTE ATTRIBUTED 在真腿上不可达：归档装置只印 fd 号、不印 socket 身份 ⇒ §8.3 第 ② 格恒缺 ⇒ 每腿 NOINFO reason=sock-id-absent（逐行 would_be= 即「只差这一格」的佐证）。后续：装置须随行打印那条连接的 socket 身份（sun_path 或 fd 的 socket inode），本牙才有射程。"
    fi
    if [ "$att" -gt 0 ] && [ "$notatt" -eq 0 ]; then
        say "PROTO_ATTR=ATTRIBUTED cases=$n pass=$att fail=$notatt noinfo=$noi rc=$RC_PASS"; return $RC_PASS
    fi
    if [ "$notatt" -gt 0 ]; then
        say "PROTO_ATTR=NOT_ATTRIBUTED cases=$n pass=$att fail=$notatt noinfo=$noi rc=$RC_FAIL"; return $RC_FAIL
    fi
    say "PROTO_ATTR=NOINFO cases=$n pass=$att fail=$notatt noinfo=$noi rc=$RC_NOINFO"; return $RC_NOINFO
}

# ── 模式 ③：`--selftest`（零 X、零 dotnet、零重活）─────────────────────────────────────
st_hdr() { printf 'tag\trole\top0\tfd\tmask\twin\tgeom\tsock_id\tchain_app\tsym_call\tcn_seq\tcut_proto\texpect\treason\trl\thlen'; }
st_row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
CHAIN_OK='_XSend@libX11.so.6+0x15e;xcb_writev@libxcb.so.1+0x48;wpfgfx_cor3.so+0x131b36;wpfgfx_cor3.so+0x16fa4a'
CHAIN_LIB='_XSend@libX11.so.6+0x15e;xcb_writev@libxcb.so.1+0x48;writev@xwrap.so+0xd8'

st_assert() {  # st_assert <id> <desc> <got_rc> <want_rc> <out> <needle>
    local id="$1" desc="$2" got="$3" want="$4" out="$5" needle="$6"
    local ok=1 why="" k="" IFS='|'
    if [ "$got" != "$want" ]; then ok=0; why="rc got=$got want=$want"; fi
    for k in $needle; do
        if ! has "$out" "$k"; then ok=0; why="$why needle-absent:$k"; fi
    done
    tot=$((tot + 1))
    if [ "$want" = "$RC_NOINFO" ]; then noinfo_n=$((noinfo_n + 1)); fi
    if [ "$ok" = 1 ]; then
        pass=$((pass + 1)); say "SELFTEST $id want_rc=$want got_rc=$got = OK  $desc"
    else
        fail=$((fail + 1)); say "SELFTEST $id want_rc=$want got_rc=$got = FAIL  $desc  [$why]"
        printf '%s\n' "$out" | awk 'NR<=6{print "        | " $0}'
    fi
}

st_build_fixtures() {
    local f
    f="$ST_DIR/s1.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'restore:800x600@-75.7;push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
    } > "$f"
    f="$ST_DIR/s2.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'restore:800x600@-75.7;push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-CUT NEG 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'restore:800x600@-59.3' present NOT_ATTRIBUTED cut-removed-effect 20 24
    } > "$f"
    f="$ST_DIR/s3.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-SOCK NEG 12 134 0xc 8388612 1280x1024 absent "$CHAIN_OK" none 'push:1280x1024@+4.7' absent NOINFO sock-id-absent 20 24
    } > "$f"
    f="$ST_DIR/s4.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-SYM NEG - - - - 1280x1024 present "$CHAIN_OK" none - absent NOINFO symbol-level-not-evidence - -
    } > "$f"
    f="$ST_DIR/s5.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-WIN0 NEG 12 134 0xc 0 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent NOINFO decode-inconsistent 20 24
    } > "$f"
    f="$ST_DIR/s6.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-RL NEG 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent NOINFO decode-inconsistent 24 24
    } > "$f"
    f="$ST_DIR/s7.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-CHAIN NEG 12 134 0xc 8388612 1280x1024 present "$CHAIN_LIB" none 'push:1280x1024@+4.7' absent NOINFO no-app-frame 20 24
    } > "$f"
    f="$ST_DIR/s8.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-TRIG NEG - - - - 1280x1024 present "$CHAIN_OK" XResizeWindow - absent NOINFO no-trigger - -
    } > "$f"
    f="$ST_DIR/s9.tsv"; { st_hdr; echo
        st_row N-CUT NEG 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'restore:800x600@-59.3' present NOT_ATTRIBUTED cut-removed-effect 20 24
    } > "$f"
    f="$ST_DIR/s12.tsv"; { st_hdr; echo
        st_row P-L5 POSCTL 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'push:1280x1024@+4.7' absent ATTRIBUTED paired-server-event 20 24
        st_row N-NOPAIR NEG 12 134 0xc 8388612 1280x1024 present "$CHAIN_OK" none 'restore:800x600@-75.7' absent ATTRIBUTED no-server-side-pair 20 24
    } > "$f"
}

selftest() {
    local out rc
    tot=0; pass=0; fail=0; noinfo_n=0
    st_build_fixtures
    out="$(mode_cases "$ST_DIR/s1.tsv" 1 2>&1)"; rc=$?
    st_assert S1 "阳性对照：归档世界形态 ⇒ ATTRIBUTED ∧ 门禁 PASS" "$rc" "$RC_PASS" "$out" "verdict=ATTRIBUTED reason=paired-server-event"
    out="$(mode_cases "$ST_DIR/s2.tsv" 2 2>&1)"; rc=$?
    st_assert S2 "反极：cut 命中且无成对事件 ⇒ NOT_ATTRIBUTED reason=cut-removed-effect" "$rc" "$RC_PASS" "$out" "tag=N-CUT role=NEG verdict=NOT_ATTRIBUTED reason=cut-removed-effect"
    out="$(mode_cases "$ST_DIR/s3.tsv" 2 2>&1)"; rc=$?
    st_assert S3 "sock_id 缺 ⇒ NOINFO reason=sock-id-absent ∧ 印 would_be 证只差这一格" "$rc" "$RC_PASS" "$out" "tag=N-SOCK role=NEG verdict=NOINFO reason=sock-id-absent"
    out="$(mode_cases "$ST_DIR/s4.tsv" 2 2>&1)"; rc=$?
    st_assert S4 "符号级台账为唯一证据 ⇒ NOINFO（**不是** NOT_ATTRIBUTED）" "$rc" "$RC_PASS" "$out" "tag=N-SYM role=NEG verdict=NOINFO reason=symbol-level-not-evidence"
    out="$(mode_cases "$ST_DIR/s5.tsv" 2 2>&1)"; rc=$?
    st_assert S5 "win=0 ⇒ NOINFO decode-inconsistent ∧ dfail=win-zero" "$rc" "$RC_PASS" "$out" "tag=N-WIN0 role=NEG verdict=NOINFO reason=decode-inconsistent|dfail=win-zero"
    out="$(mode_cases "$ST_DIR/s6.tsv" 2 2>&1)"; rc=$?
    st_assert S6 "rl 与 popcount 不自洽 ⇒ NOINFO ∧ dfail=rl-popcount" "$rc" "$RC_PASS" "$out" "tag=N-RL role=NEG verdict=NOINFO reason=decode-inconsistent|dfail=rl-popcount"
    out="$(mode_cases "$ST_DIR/s7.tsv" 2 2>&1)"; rc=$?
    st_assert S7 "chain 全在 libX11/libxcb ⇒ NOINFO reason=no-app-frame" "$rc" "$RC_PASS" "$out" "tag=N-CHAIN role=NEG verdict=NOINFO reason=no-app-frame"
    out="$(mode_cases "$ST_DIR/s8.tsv" 2 2>&1)"; rc=$?
    st_assert S8 "无触发物 ∧ 无 cut ⇒ NOINFO reason=no-trigger（不许读成反极成立）" "$rc" "$RC_PASS" "$out" "tag=N-TRIG role=NEG verdict=NOINFO reason=no-trigger"
    out="$(mode_cases "$ST_DIR/s9.tsv" 1 2>&1)"; rc=$?
    st_assert S9 "抽掉 POSCTL ⇒ FAIL reason=untriggerable" "$rc" "$RC_FAIL" "$out" "PROTO_ATTR_GATE=FAIL reason=untriggerable"
    out="$(mode_cases "$ST_DIR/s1.tsv" 99 2>&1)"; rc=$?
    st_assert S10 "--expect 不符 ⇒ FAIL rule=row-count-mismatch" "$rc" "$RC_FAIL" "$out" "rule=row-count-mismatch"
    : > "$ST_DIR/s11.tsv"
    out="$(mode_cases "$ST_DIR/s11.tsv" "" 2>&1)"; rc=$?
    st_assert S11 "空语料 ⇒ NOINFO（零检查绝不给 PASS）" "$rc" "$RC_NOINFO" "$out" "reason=cases-empty"
    out="$(mode_cases "$ST_DIR/s12.tsv" 2 2>&1)"; rc=$?
    st_assert S12 "翻转期望 ⇒ FAIL 并点名 tag（证期望真在驱动判词，非硬编码表）" "$rc" "$RC_FAIL" "$out" "❌ tag=N-NOPAIR want=ATTRIBUTED got=NOT_ATTRIBUTED"
    printf 'tag\trole\texpect\nX\tPOSCTL\tATTRIBUTED\n' > "$ST_DIR/s13.tsv"
    out="$(mode_cases "$ST_DIR/s13.tsv" "" 2>&1)"; rc=$?
    st_assert S13 "表头不认 ⇒ NOINFO reason=bad-header" "$rc" "$RC_NOINFO" "$out" "reason=bad-header"
    out="$(mode_cases "$ST_DIR/absent.tsv" "" 2>&1)"; rc=$?
    st_assert S14 "语料缺席 ⇒ NOINFO reason=cases-absent" "$rc" "$RC_NOINFO" "$out" "reason=cases-absent"
    say "PROTO_ATTR_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail noinfo_expect=$noinfo_n"
    if [ "$fail" -eq 0 ]; then
        say "PROTO_ATTR_SELFTEST=PASS total=$tot pass=$pass fail=$fail"
        say "PROTO_ATTR=ATTRIBUTED cases=$tot pass=$pass fail=$fail noinfo=$noinfo_n rc=$RC_PASS"
        return $RC_PASS
    fi
    say "PROTO_ATTR_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"
    say "PROTO_ATTR=NOT_ATTRIBUTED cases=$tot pass=$pass fail=$fail noinfo=$noinfo_n rc=$RC_FAIL"
    return $RC_FAIL
}

usage() {
    cat <<'TXT'
用法：
  proto-attribution-check.sh --cases <语料.tsv> [--expect N]     # 门禁走这条（确定性用例）
  proto-attribution-check.sh --legs <腿目录> […]                  # 真归档腿（会如实报 NOINFO）
  proto-attribution-check.sh --selftest                          # 自带 fixture，零 X／零 dotnet
  proto-attribution-check.sh [--repo DIR] [--screen WxH] [--base WxH] [--debug-tmp]

判据：吃 wire 台账（PROTO op0=12 逐字节解码 ＋ 调用链 ＋ socket 身份）＋ 服务器侧成对事件，
      三态 ATTRIBUTED／NOT_ATTRIBUTED／NOINFO；「符号级台账里没有 CALL」**永不算** NOT_ATTRIBUTED。
三态：0 = 门禁 PASS（ATTRIBUTED）｜1 = 门禁 FAIL（NOT_ATTRIBUTED）｜3 = 查不动（NOINFO，不算绿）
TXT
}

main() {
    local st=0 rcs=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --cases)    CASES="${2:-}"; shift 2 ;;
            --cases=*)  CASES="${1#*=}"; shift ;;
            --expect)   EXPECT="${2:-}"; shift 2 ;;
            --expect=*) EXPECT="${1#*=}"; shift ;;
            --legs)     shift; while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do LEG_DIRS+=("$1"); shift; done ;;
            --repo)     REPO="${2:-}"; shift 2 ;;
            --repo=*)   REPO="${1#*=}"; shift ;;
            --screen)   SCREEN="${2:-}"; shift 2 ;;
            --screen=*) SCREEN="${1#*=}"; shift ;;
            --base)     BASE="${2:-}"; shift 2 ;;
            --base=*)   BASE="${1#*=}"; shift ;;
            --selftest) st=1; shift ;;
            --debug-tmp) KEEP_TMP=1; shift ;;
            -h|--help)  usage; return $RC_PASS ;;
            *) say "用法：bash $SELF [--cases TSV] [--legs DIR…] [--selftest]"; return 2 ;;
        esac
    done
    if [ -n "$REPO" ] && [ ! -d "$REPO" ]; then
        say "PROTO_ATTR=NOINFO reason=repo-absent repo=$REPO cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO
    fi
    mkdir -p "$TMPBASE" 2>/dev/null || { say "PROTO_ATTR=NOINFO reason=tmpbase-unusable TMPBASE=$TMPBASE cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO; }
    WORK="$(mktemp -d "$TMPBASE/proto-attr.XXXXXX")" || { say "PROTO_ATTR=NOINFO reason=mktemp-failed cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO; }
    if [ "$KEEP_TMP" = 1 ]; then say "PROTO_ATTR_TMP=$WORK"; else trap 'rm -rf -- "${WORK:-}"' EXIT; fi
    if [ "$st" = 1 ]; then
        ST_DIR="$(mktemp -d "$TMPBASE/proto-attr-st.XXXXXX")" || { say "PROTO_ATTR=NOINFO reason=mktemp-failed-st cases=0 pass=0 fail=0 noinfo=0 rc=$RC_NOINFO"; return $RC_NOINFO; }
        selftest; rcs=$?
        rm -rf -- "$ST_DIR"
        return $rcs
    fi
    if [ "${#LEG_DIRS[@]}" -gt 0 ]; then
        mode_legs "${LEG_DIRS[@]}"; rcs=$?
        return $rcs
    fi
    if [ -z "$CASES" ] && [ -n "$REPO" ]; then CASES="$REPO/build/MilBridge/tools/proto-attribution-cases.tsv"; fi
    mode_cases "$CASES" "$EXPECT"
}

main "$@"
