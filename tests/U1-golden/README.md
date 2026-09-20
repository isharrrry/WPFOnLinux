# U1 命令流 golden binary 目录

这里放 Windows 机器抓取的真实 DUCE 命令流（`*.stream`）。
抓流与格式说明：`docs/U1-command-stream-golden-plan.md`。

- 本目录为空时：`Commands.Tests/GoldenBinaryReplayTests` 在发现期 Skip（无失败）。
- 放入流文件后：该用例自动转为实测（回放断言：FailedCommands==0、
  NotImpl ⊆ 7 条文档化 E_NOTIMPL、句柄在流内闭合）。
- 流文件只含命令字节，不含像素/隐私内容，可直接进仓库。

## 2026-09-10 说明：为何本目录暂时为空

Windows 真机已抓到一份**真实 DUCE 命令流**（352 条命令 / 12 种命令字），但它**缺 op5
（`MilResource_CreateOrAddRefOnChannel`）记录**——该句柄是 `ref DUCE.ResourceHandle` 出参，
而 `DUCE.ResourceHandle` 是 internal 类型，托管层 hook（Harmony transpiler）拿不到回填值。
缺 op5 → 资源表为空 → 回放时 352 条命令 100% 以 `E_HANDLE` 被拒（**不是**解码器缺陷被证实）。

因此该流**不作为** `GoldenBinaryReplayTests` 的输入（否则套件由 Skip 转 FAIL、且失败原因与解码器无关），
原件与说明保留在：

- `tests/parity/windows/streams/u1a-scenes-rtb.stream`（原件）
- `tests/U1-golden/PROVENANCE.md`（抓取方法、命令字统计、缺口）

**闭环条件**：完成「原生代理 DLL」路线（app-local 同名 `wpfgfx_cor3.dll` 转发 + 记录，原生侧
`ResourceHandle*` 是普通指针 → op5 可得），把补齐 op5 的流放回本目录，`GoldenBinaryReplayTests` 即自动转实测。
