# 波 `#57` 预登记（`TASK-0211`：关掉落地修法里的三处窄 `TOCTOU`／生命周期缺陷）

> 本件在**冻结之前**写死判据。世代：`#57`。步数：**31（不动）**。

## §1 本波改什么（只改三处；不许顺手改别的）

| 点 | 文件:函数 | 改法 |
|---|---|---|
| **A** | `src/WpfGfx.Linux.Native/src/win32_msg.c` `PostMessageW` | 「查表 → 判死 → 取 pt → 入队」收进**同一个临界区**：删 `:848`、`:882` 两次放锁，改为 `wpf_queue_push` **之后**放一次；两条早退支各自先放锁 |
| **B** | 同文件 `PostThreadMessageW` | 同形：删 `:896` 放锁，`if (!target)` 展开为**先放锁再报 1444**，放锁挪到 push 之后 |
| **fd** | `src/WpfGfx.Linux.Native/src/win32_core.c` `wpf_thread_destroy` | `close(wake_read/wake_write)` 改为**锁内先置 `-1` 再 close**（修前锁外且不置 `-1`） |

**导出符号 `547` 是硬线**；**零删守卫/断言**。

## §2 判据（先写；三点各自独立成对，严禁合并判一次）

1. **主判据（件级，可达性精确）** — `pushtooth.py`：到达 `call wpf_queue_push` 的**所有路径**的锁深度集合**不含 0** ⇒ `HELD`。修后 A/B 都 `HELD`、`rc=0`。
   （**不用**线性/地址序口径：该口径在**早退支**上必然假红 —— 合成已修件上 `lockspan.py` 对 B 打 `BROKEN` 而实为 `HELD`。）
2. **fd 点** — `fdsafe.py`：两个 `close` 各自 `lock_before=yes` 且 `minus1_store_before=yes` ⇒ `FDFIXED`。
3. **前提牙** — `premise.py`：`P1`（行为：同线程二次 `wpf_lock()` 返回）＋ `P2`（件级：push 恰好 1 个 unlock 且早于 `wake`）＋ `P3`（源级：`RECURSIVE` 与同一 `attr`）⇒ `PASS`。
   **前提破了修法会静默失效** ⇒ `HELD` 读数不代表窗口已关。
4. **两极性** — 只退 A ⇒ `aeb179a2d3d9ca44`（A `BROKEN`／B `HELD`）；只退 B ⇒ `d60f056672f7b4d5`（A `HELD`／B `BROKEN`）；只退 fd ⇒ `5d58b2c18791c369`（A/B `HELD`／fd `FDSTALE`）；全修后 ⇒ `d2b76a0a56a41be1`。
5. **九位位移** — 预期 `set(changed) = {win32shim, pf}`：`win32shim` `2067cb1c97728791→d2b76a0a56a41be1`（本波动 native）；`pf` 为 `D-G92` 环成员**机械位移**（**同尺寸 6,123,520**），成对记账、**不当漂移**。其余七位逐位不动。
6. **三态** — `PASS`/`FAIL`/`NOINFO`；`NOINFO` **既不算绿也不算红**。
7. **`NOINFO` 清单** — 三处的**可利用性／自然发生率**（`NOINFO`）；`QUEUE_INVARIANT`／WC07 触发件／样本应用（本件未跑）。

## §3 与既有登记的关系

本件 = **`D-G109` 的残余**，并入其 🔁🔁🔁 追加段（**不新缺陷号**）。
