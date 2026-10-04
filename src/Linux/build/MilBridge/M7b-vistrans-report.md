# M7b · **MIL 视觉变换命令**取证（RTL 位移最后一段）：桥侧只读诊断

> **本轮只写源码 + 本报告**：未发桥、未重建 PC、未跑应用、未同步任何副本。
> **编译检查**：私有输出目录 `-o /tmp/vistrans-build/out` ⇒ **`已成功生成 / 0 个警告 / 0 个错误`**，
> 产物 `/tmp/vistrans-build/out/WpfGfx.Linux.dll`（349,696 B）；**仓库内 `src/WpfGfx.Linux/{obj,bin}` 的
> mtime 未变**（仍为 2026-09-10 14:58:08）⇒ 这次检查没有动仓库产物。
> ⚠️ **我改了 `src/WpfGfx.Linux/**` ⇒ 桥（AOT）需由主控重发**，我这边不发。

---

## 1. 插点（`file:line`）

| 位置 | 内容 |
|---|---|
| `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:157` | `case MilCmdVisualSetOffset`（`:148`）内、**赋值之后**插一行 `MilVisualTransformDiag.NoteOffset(ch, s.Handle, s.OffsetX, s.OffsetY);` |
| `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:169` | `case MilCmdVisualSetTransform`（`:158`）内、**赋值之后**插一行 `MilVisualTransformDiag.NoteTransform(ch, ts.Handle, ts.HTransform);`（顺带把原来的 `ReadFixed(...).HTransform` 提成局部 `ts`，便于同时拿到 `ts.Handle`） |
| **新文件** `src/WpfGfx.Linux/Commands/MilVisualTransformDiag.cs`（sha16 `019b7e070b65be41`） | 诊断本体：开关 `:42`、上限 `:43-44`、`NoteOffset` `:71`、`NoteTransform` `:83`、**解析前原始字段** `:106`、`Content` 代理线索 `:128`、有界发射 `:146`、**触顶通知** `:174` |

> 说明：插点不在任务里列的 `{Interop,Rendering}/**`，而在 **`Commands/MilCommandDispatcher.cs`** ——
> 那是你点名的 `MilCommandDispatcher` 处理这两个命令的确切位置（`0x1b` / `0x1c`）。

**只读性**：诊断只读资源表 + 调 `TransformResolver.Resolve`（**投影期用的同一个解析器**，纯函数式）；
两个调用点都在原赋值**之后**，不参与任何赋值 ⇒ 关掉开关即逐字回到原行为。

## 2. 开关 / 有界 / 过滤口径

- **开关**：`WPF_LINUX_VISTRANS_TRACE=1`（未设/空白/`0` ⇒ **一行不打**；与 `KEY_DIAG`/`MSGFLOW` 同族）。
- **有界**：关注类 **≤200 行**；非关注类**只采样前 40 条**；**第一次被丢弃时打一行触顶汇总**
  （含累计 `SetTransform`/`SetOffset` 条数）⇒ **不静默截断**（L12）。
- **过滤口径（如实登记）**：命令层**判不了"这是不是一个文本视觉"**（`Content` 只到 `MilRenderDataResource`
  这一层，看不进 RenderData 里有没有 GlyphRun）⇒ 我**没有**按"文本视觉"过滤，改成：
  **关注类 = `SetOffset` 带负偏移（镜像/右对齐的签名）或 `SetTransform` 的解析矩阵非单位（含镜像/平移/缩放）**
  ⇒ 必打；其余（Identity、非负 offset）⇒ 采样。
  另外**每行都附 `content=<Content 资源类型名>`** 作为"是不是文本"的代理线索。

**输出形态（三种行）**：
```
[VISTRANS] #7 SetOffset visual=0x… offset=(X=-23.6102, Y=0.0000) 负偏移=是 content=MilRenderDataResource
[VISTRANS] #8 SetTransform visual=0x… hTransform=0x… resKind=MilMatrixTransform 原始字段=Matrix[M11=-1.0000 M12=0.0000 M21=0.0000 M22=1.0000 DX=86.2559 DY=0.0000] 解析矩阵=[M11=-1.0000 M12=0.0000 M21=0.0000 M22=1.0000 DX=86.2559 DY=0.0000] 镜像=是 非单位=是 content=MilRenderDataResource
[VISTRANS] 触顶：关注类已达上限（已打 200 行；采样 40/40）⇒ 之后不再打印。累计 SetTransform=… SetOffset=…
```

## 3. 判据（**互斥，三选一**，写死）

| 观测 | 裁决 | 修复归属 |
|---|---|---|
| 该视觉**从来没有 `SetTransform` 行**（只有 `SetOffset`） | **PC 没把镜像交给 MIL** | **PC/PF 侧**：`Visual.cs` 的 `VisualTransform` → MIL 的那一步（给我坐标，我接或你派人） |
| 有 `SetTransform` 行且矩阵是 **`M11=−1`**（或 `DX≈86.26` 之类）**而最终 `world.m11=+1`** | **桥丢了它** | **我的车道**：`Resources/VisualProjection.cs` 的 `TransformResolver.Resolve`（`:91-130`）与投影组装点（`:33-40`）；预期读数见 §5 |
| 有 `SetTransform` 行但矩阵**本来就不是镜像**（Identity / 纯平移 / 只有 `OffsetX=65.2559`） | 往**PC 侧那个矩阵的来源**查 | 我会把 `resKind` + `原始字段` 一并给你（本诊断已内置） |

## 4. 一跑就用的命令（T3 的应用槽；我只给命令，不跑）

```bash
WFP_RUN_DIR=/tmp/vistrans-run \
  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 90 --only=text-rtl \
  --app-env=WPF_LINUX_VISTRANS_TRACE=1
# 读法（四行 grep）
L=/tmp/vistrans-run/probe-triage-text-rtl.log
grep -a "\[VISTRANS\]" "$L" | head -40                     # 全貌
grep -a "SetTransform" "$L" | grep -c "镜像=是"            # 有没有"矩阵本来是镜像"的 SetTransform
grep -a "SetTransform" "$L" | grep -o "resKind=[^ ]*" | sort | uniq -c   # 变换资源到底是哪一类
grep -a "SetOffset"   "$L" | grep -c "负偏移=是"           # 负平移有没有（RTL 的另一个签名）
```
**与 PF 探针读数对照**（宿主契约侧，已由 T1c 量出）：`M1' M11=−1 M22=1 OffsetX=65.255859375`、
元素框 `t0=86.2559 → t1=21.0000` —— 若 MIL 层看到的是 `SetOffset(X=−23.6102)` **且没有** `M11=−1` 的
`SetTransform`，那就是**判据①**的现场形态。

## 5. 修好后应看到的读数（验收）

| 量 | 期望 |
|---|---|
| RTL run 的 CTM | ≈ LTR 的 `dx≈+21.875`；或在镜像口径下 `m11=−1.0417`（**现在两侧都是 `+1.0417`**） |
| 墨迹包络 | 落回 `[22, 88]` 附近（现在实测 `[−24.6, 43.4]`） |
| 判据 1 | `\|Δright\| ≤ 2`、`\|Δw\| ≤ 3`、墨迹比 ∈ `[0.9, 1.1]` |

**若判据②成立**（桥丢了镜像），我预期要改的两处与预期读数：
1. `Resources/VisualProjection.cs:91-130` 的 `TransformResolver.Resolve`：确认它不是"只认
   `TYPE_MATRIXTRANSFORM` 的那一支"而漏掉别的包装（例如 `TransformGroup` 里嵌套的镜像）——
   **本诊断的 `resKind`/`原始字段` 会直接指出丢在哪一层**；
2. 投影组装点 `VisualProjection.cs:33-40`（`Concat(parentWorld, v.Transform, Translate(v.Offset))`）：
   确认 `v.Transform` **确实参与了合成**、且与 `v.Offset` 的**顺序**与 WPF 语义一致
   （镜像应当作用于"已含 offset 的局部坐标系"）——预期读数：RTL 的 `CTM.m11` 变负、`Δright/Δw` 进判据。

## 6. 遗留与风险（登记）
- 本诊断**只看命令侧**：它不能证明"命令没来"是 PC 的 bug 还是**PC 认为不需要发**（例如宿主自己把镜像
  烘进 `RenderSize`/offset 了）⇒ 判据①成立时我会同时给你 PF 侧的对照（`M11=−1`、`ApplyMirrorTransform` 已为 True）。
- 命令层的 `Content` 线索只能到 `MilRenderDataResource`；若将来想在命令层做"文本视觉"过滤，
  需要**更细的内容类型**（登记为可选工作）。
