# 原始命令流（逐字节，未经任何位置调整）

| 文件 | 抓法 | 内容 | 状态 |
|---|---|---|---|
| `u1b-scenes-rtb-raw.stream` | **原生代理 DLL**（路线①，Linux 侧 zig 交叉编译） | ch1 主通道：op1×417 / op2×380 / op3×417 / op4×45 / **op5×641** / op6×641，17 种命令字（含 `RenderData 0x18`、`PathGeometry 0x7d`） | ✅ 解码 417/417 通过 |
| `u1b-channel0-raw.stream` | 同上 | ch0：3 命令（partition/channel 设置） | 旁证 |
| `u1b-channel2-raw.stream` | 同上 | ch2：窗口目标通道，39 命令 | 旁证（对拍余 16 条跨通道句柄） |
| `u1b-channel3-raw.stream` | 同上 | ch3：5 命令 | 旁证 |
| `u1a-scenes-rtb-managedhook-partial.stream` | 托管层 Harmony hook（已被原生代理取代） | op1×352 / op3×352 / op4×45，12 种命令字，**无 op5** | ⚠️ 历史产物：缺句柄回填记录，回放必失败；保留仅为对比"托管 hook 会漏命令" |

回放在用的版本（op6 位置对齐）在 `tests/U1-golden/u1b-scenes-rtb-reldefer.stream`，
差异与证据见 `tests/U1-golden/PROVENANCE.md`。
