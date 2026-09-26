# 波 `#77` · 预登记片段 —— `TASK-0744-FU`「**装置须随行打印 socket 身份**」

- 车道 **W184A**（预备车道：只读侦察 ＋ 判据先写 ＋ 交付"释放即落"的包）
- 判据先写时刻：**2026-09-26 16:34:10**（`criteria.md` 落盘；**早于**本波任何装置／真腿读数）
- 权威树 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓**）
- 世代（现读）`BASELINE-FROZEN gen=#75 sha16=3b9e463e70220e11`；`$R` 现读 `run_step=47`／`DECL 47 gen=#76`／`--expect 205`

## §1 为什么本波**必须有**（前一波自己留下的后续项）

`TASK-0744` 的牙 `PROTO-ATTR` 要判「那条几何请求是谁写的」⇒ 输出 `ATTRIBUTED`。
`#77`（车道 W180A）把牙与语料做成了包，但它在**真腿上 `ATTRIBUTED` 结构性不可达**，并**拒绝做假绿**：

> 现场（`W180A-report.md` §三处如实划界 ①）：`0744` 真腿 `ATTRIBUTED` **结构性不可达**
> （装置不印 socket 身份）⇒ `NOINFO reason=sock-id-absent`，**拒绝做成假绿**；
> 后续 ＝ **装置随行打印 socket 身份**。

本波就是把这条后续**做成可落地的包**。**判据一格都没放宽**：`sock_id` 这一格的门槛一字不动，
只是**输入从缺变成有**（`criteria.md` §1／§2）。

## §2 两极化（**先写期望；读数见 `polarity.md`**）

| 极 | 操作 | 期望 | 判否条件 |
|---|---|---|---|
| **正 E1** | 异树（**真拷贝**）`landing.sh --apply --repo <沙箱> --allow-foreign` | 五件落地 ∧ `run_step 47→48` ∧ `DECL 48 #77` ∧ `names_n=48` ∧ `coverage==expect`；**源树零写入** | 任一收口断言不过，或源树出现写入 ⇒ 落地器作废 |
| **反 E2** | `--repo <符号链接>`（解析后指向权威树）；或裸权威树 | **响亮拒跑**（`rc=4` 点名）∧ **写入件数 0** | 通过 ⇒ 逃逸闸失效 ⇒ 作废 |
| **正 P1** | 真腿上用**新装置**（`sock=` 随行）跑一拍，`--legs` 判 | 该腿 `sock_id=present`（真 socket 序号）∧ 成对事件在场 ⇒ `ATTRIBUTED` | ≥3 腿跑满仍无 `sock_id=present` ⇒ 装置改法作废 |
| **反 P2** | **畸形身份行**（`sock=-`）／**旧装置行**（无 `sock=` 字段） | 前者 `NOINFO reason=sock-id-malformed` ∧ 计数只增；后者 `NOINFO reason=sock-id-absent`（旧行为逐字不变） | 任一产出 `ATTRIBUTED` ⇒ 牙假绿 ⇒ 作废 |
| **兼容 C1** | 归档 16 列语料（**无**第 17 列） | 判词与 `#77` 现件**逐数相同**（`att=3 fail=2 noinfo=13 mismatch=0 posctl_att=2`） | 有差异 ⇒ 改动伤既有读牙 |
| **兼容 C2** | 旧正则 `head=[0-9a-f ]+` 对新装置行 | 取出的字节数**仍 = 24**（贪婪止于 `sock=` 的 `s`） | ≠24 ⇒ 新字段破坏既有解码 |

## §3 分母口径与判据类型（`D-G94`）

- 分母只算「**真发出过请求**」的腿；`op0=-` 且无 `cut` ⇒ `NOINFO reason=no-trigger`，**不入分母**。
- 本牙判「某条请求由谁写出的证据是否齐」是**确定性**读数（逐字节），**不吃大样本**；
  本波**不做**任何"率"推断（不报红率、不报提升率）。

## §4 落地形状（**本波不落地**；包交主控）

- 新件 5：`build/MilBridge/tools/devices/xwrap-sockid.{c,so}`、`devices/dev-selftest.c`、
  `build/MilBridge/tools/proto-attribution-check.sh`、`build/MilBridge/tools/proto-attribution-cases.tsv`
- 接线 2：`verify-all.sh` 加一步 `PROTO-ATTR`（三处声明同趟：`STEPS-DECL`／`STEP-NAMES`／口径句）；
  `build/close-wave.sh` 的 `fp_inputs()` 白名单 **+3 行** ⇒ `[FP-MANIFEST-TEETH] --expect` 同趟 +3
- **步数 47 → 48**；`inputs_fp` **必移**（`close-wave.sh` 自含于覆盖面 ＝ 设计使然）
- **零产品改动** ⇒ 九位逐位不动（装置是 `LD_PRELOAD` 仪器，**不是**产品件）

## §5 未取到／不许外推（**先写**）

- 本波**不构建** `libwpfwin32.so`／`pc`／`pf`／`hbtextline`；九位不动 ⇒ 不需要 `dotnet` 构建。
- 真腿读数**只**在一台私有显示位（`:23x`）＋ `xfwm4` ＋ 既有 `W-OLD` 应用上取；
  **不外推**到别的窗口管理器（本机只有 `xfwm4`）。
- 「WM 已死」这一点**不在本波射程**（属 `TASK-0109`）；本波只把「身份格」做成可判。
