// golden 用例的公共流程：渲染 → 落盘 → 比对 / 更新 → 失败时出 diff 图。
//
// 【为什么是静态工具类而不是测试基类】
//   MilVisual / TestScene 都是 internal（契约层故意不对外的），而 xUnit 要求测试类
//   必须 public。public 类的 protected 成员签名里不能出现 internal 类型（CS0051），
//   public 类也不能继承 internal 基类（CS0060）。所以把公共流程放进 internal 静态
//   类，测试类只在**方法体内**调用它——方法体不受可访问性约束。

using System;
using System.Collections.Generic;
using System.IO;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal delegate (TestScene Scene, MilVisual Root) SceneFactory();

    internal static class GoldenRunner
    {
        public static void Run(
            string name,
            SceneFactory build,
            ITestOutputHelper output,
            bool antialias = true,
            int width = RenderHarness.DefaultWidth,
            int height = RenderHarness.DefaultHeight)
        {
            (TestScene scene, MilVisual root) = build();
            using (scene)
            {
                RenderOutput result = RenderHarness.Render(root, scene.Provider, width, height, antialias);

                // 实测图**永远**落盘：即便通过也方便人眼复核，CI 还能当制品收走。
                string actualPath = RepoLayout.ActualPath(name);
                RenderHarness.SavePng(result.Bitmap, actualPath);

                // 渲染层最危险的失败是"静默少画"，把诊断计数打出来留痕。
                output.WriteLine(
                    $"[{name}] {result.Bitmap.Width}×{result.Bitmap.Height} AA={antialias} " +
                    $"指令={result.Diagnostics.InstructionCount} " +
                    $"未画出={Format(result.Diagnostics.NotDrawn)} " +
                    $"降级={Format(result.Diagnostics.Degraded)} " +
                    $"SaveCount {result.InitialSaveCount}→{result.FinalSaveCount}");

                // Push/Pop 必须配平，否则栈顶残留会污染后续帧。
                Assert.True(
                    result.IsStackBalanced,
                    $"画布栈未配平：渲染前 SaveCount={result.InitialSaveCount}，" +
                    $"渲染后={result.FinalSaveCount}。有 MilPush* 没被 MilPop 弹掉。");

                string goldenPath = RepoLayout.GoldenPath(name);

                if (GoldenOptions.UpdateEnabled)
                {
                    RenderHarness.SavePng(result.Bitmap, goldenPath);
                    output.WriteLine($"[{name}] {GoldenOptions.Describe()} → 已写入 {goldenPath}");
                    return;
                }

                if (!File.Exists(goldenPath))
                {
                    throw new FileNotFoundException(
                        $"基准图缺失：{goldenPath}{Environment.NewLine}" +
                        $"先跑一次 update-golden.sh（或 WPFGOLDEN_UPDATE=1 dotnet test）生成它，" +
                        $"并把 tests/golden/*.png 提交进仓库。", goldenPath);
                }

                using SKBitmap golden = RenderHarness.LoadPng(goldenPath);
                CompareResult comparison = ImageComparer.Compare(result.Bitmap, golden);

                if (!comparison.Passed)
                {
                    using SKBitmap diff = ImageComparer.CreateDiff(result.Bitmap, golden);
                    string diffPath = RepoLayout.DiffPath(name);
                    RenderHarness.SavePng(diff, diffPath);

                    throw new Xunit.Sdk.XunitException(
                        $"golden 比对失败：{name}{Environment.NewLine}" +
                        $"  {comparison.Message}{Environment.NewLine}" +
                        $"  实测图: {actualPath}{Environment.NewLine}" +
                        $"  基准图: {goldenPath}{Environment.NewLine}" +
                        $"  差异图: {diffPath}（红色为超出 Δ≤{ImageComparer.DefaultTolerance} 的像素）{Environment.NewLine}" +
                        $"  确认是有意变更后，用 --update-golden 更新基准图。");
                }

                output.WriteLine($"[{name}] 与基准一致（最大通道差 {comparison.MaxChannelDelta}）");
            }
        }

        private static string Format(IReadOnlyDictionary<MilDrawCommand, long> table)
        {
            if (table == null || table.Count == 0) return "无";

            var parts = new List<string>();
            foreach (KeyValuePair<MilDrawCommand, long> kv in table)
                parts.Add($"{kv.Key}×{kv.Value}");
            return string.Join(",", parts);
        }
    }
}
