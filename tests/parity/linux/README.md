# tests/parity/linux —— U1a 对照产物（我方渲染栈）

本目录是 **U1a 真机对照** 的输出目录，内容全部由
`tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityTests.cs` 生成，可以随时重新生成：

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/ -m:1 \
  --filter "FullyQualifiedName~ParityTests"
```

## 目录内容

| 路径 | 说明 |
|---|---|
| `actual/<scene>.png` | **我方**渲染栈对 `tests/parity/windows/scenes.json` 里 15 个场景的 256×256 重建结果 |
| `diff/<scene>.diff.png` | 差异图：**红 = 单通道 Δ>16**（超出 AA 容差，必须解释）、**黄 = 3..16**（边缘/取样差异）、**暗底 = 真机图压暗到 35%** |
| `parity-results.json` | 机器可读结果：每场景的差异像素数/占比/最大通道差/非边缘差异/分类，以及**逐探针**的"真机 vs 我方"RGBA |

## 输入（只读，不在这里）

- `../windows/scene*.png` —— 真机 Windows WPF（RenderTargetBitmap）渲染结果
- `../windows/scenes.json` —— 场景规格 + 约定（`conventions` 段是口径真源）
- `../windows/probe.json`、`../windows/verify_u1a_data.py` —— 版本留痕与采集侧自校验

## 怎么读差异图

1. **先看有没有红**。黄点是光栅器覆盖率差异（真机自己两格之间也会有 245/16384 个
   这种像素，最大通道差 44），红点才是需要解释的东西。
2. 红/黄点是否**贴着**真机图里的颜色边界？本套用例用"真机图 8 邻域内是否存在 >8 的
   通道跃变"判定"挨不挨着边界"，并把不挨着边界的差异单独计数为
   `differingInterior` —— 那个数才是"语义错"。
3. 当前状态：15 个场景里只有 scene06 剩 118 个非边缘像素（0 长度虚线圆点，
   `DashCap` 已知简化）与 scene14 的 3 个（画布最右列）。详见
   `docs/U1a-parity-report.md`。

## 真机数据完整性

```bash
python3 tests/parity/windows/verify_u1a_data.py    # 15/15 SHA256 + 110/110 探针
```
