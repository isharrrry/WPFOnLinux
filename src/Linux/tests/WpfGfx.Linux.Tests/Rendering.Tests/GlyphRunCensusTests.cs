// GlyphRunCensus（只读字形普查仪表）的自验用例（T2b）。
//
// 【为什么这条任务需要"验仪表"】主控这一轮的判据是"三个数 ⇒ 甲/乙归属"，
//   而**仪表本身说谎**是本工程反复踩到的一族（空壳断言、空帧下的"未画种类 0"、
//   管道尾巴的 `$?`、没编译的突变）。所以先证明：
//     ① 计数与分桶算得对（用**已知 id** 的合成 run 逐项核对）；
//     ② "全 .notdef" 的判定真的能区分 **拉丁 run** 与 **形如 CJK 的 run**——
//        这正是本任务要做的区分本身；
//     ③ 关掉时**一个数都不动**（不扰动被测对象）。
//
// 【合成 run 的 id 是编的，不代表真机】本用例只验"仪表会不会算错"，
//   真机的 id 要等部署件带普查重跑（见交付说明：渲染器 AOT 在桥里，需重建桥）。

using System;
using System.Collections.Generic;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class GlyphRunCensusTests
    {
        public GlyphRunCensusTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        [Fact]
        public void census_counts_and_distinguishes_notdef_from_real_ids()
        {
            GlyphRunCensus.ForceEnabled(true);
            try
            {
                using var scene = new TestScene();

                // run A：像拉丁 —— 11 个 id，非零，最大 91（照 M7b 实测的首个 run 形状）
                DUCE.ResourceHandle latin = GlyphRun(scene, new ushort[] { 58, 83, 73, 55, 72, 91, 87, 39, 12, 5, 3 });
                // run B：形如 CJK 但**全是 .notdef** ⇒ 应当被数进"全 notdef 的 run"
                DUCE.ResourceHandle cjkNotDef = GlyphRun(scene, new ushort[] { 0, 0, 0, 0, 0, 0, 0, 0 });
                // run C：非拉丁区的**真 id**（落在 CJK 码位区，说明面里有这些字形）
                DUCE.ResourceHandle cjkReal = GlyphRun(scene, new ushort[] { 0x4E00, 0x4E8C, 0x4E09, 0x56DB });

                DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
                var runs = new List<DUCE.ResourceHandle> { latin, cjkNotDef, cjkReal };

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    foreach (DUCE.ResourceHandle g in runs)
                        d.Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilDrawGlyphRun,
                            Geometry = new MilResourceHandle((uint)g),
                            Brush = new MilResourceHandle((uint)fill),
                        });
                });

                // GlyphRunRenderer 故意返回 true：本用例只验**计数**，不验绘制
                int drawn = 0;
                scene.Provider.GlyphRunRenderer = (_, _, _) => { drawn++; return true; };

                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

                (int runs2, int distinct, int allNotDef, int glyphs, int idZero, int maxId, int nonLatin,
                 int pidZero, int pidDistinct, ulong pidFirst) = GlyphRunCensus.LastFrame;
                Output.WriteLine($"  runs={runs2} distinct={distinct} allNotDef={allNotDef} glyphs={glyphs} " +
                                 $"id0={idZero} maxId=0x{maxId:X} nonLatin={nonLatin} 渲染器被调={drawn}");

                Assert.Equal(3, runs2);                 // 三个 run 都被数到
                Assert.Equal(3, distinct);              // 三个不同句柄
                Assert.Equal(1, allNotDef);             // **只有** B 是全 .notdef
                Assert.Equal(23, glyphs);               // 11 + 8 + 4
                Assert.Equal(8, idZero);                // B 的 8 个
                Assert.Equal(0x56DB, maxId);            // C 的最大 id
                Assert.Equal(4, nonLatin);              // C 的 4 个 id >= 0x1000
                Assert.Equal(3, drawn);                 // 渲染器照常被调 3 次（未被打断）

                // 面标识（PIDWriteFont）：本用例三个 run 都**没设** ⇒ 应为"全 0 ⇒ 无信息"。
                // ⚠ 这正是"静默默认值"那一族：0 既可能是真 0、也可能是字段没被填，
                //   所以仪表必须**单独报 0 的个数**，而不是只看非零就下结论。
                Output.WriteLine($"  面标识: pidZero={pidZero} 不同面数={pidDistinct} 最小pid=0x{pidFirst:x}");
                Assert.Equal(3, pidZero);               // 三个 run 都没带面标识
                Assert.Equal(1, pidDistinct);           // 只有一个取值(0) ⇒ 无信息（仪表如实标注）
            }
            finally { GlyphRunCensus.ForceEnabled(false); }
        }

        /// <summary>关掉时计数器必须纹丝不动 —— 这是"不扰动被测对象"的可判证据的一半。</summary>
        [Fact]
        public void census_is_inert_when_disabled()
        {
            GlyphRunCensus.ForceEnabled(false);
            try
            {
                using var scene = new TestScene();
                DUCE.ResourceHandle g = GlyphRun(scene, new ushort[] { 7, 8, 9 });
                DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawGlyphRun,
                    Geometry = new MilResourceHandle((uint)g),
                    Brush = new MilResourceHandle((uint)fill),
                }));
                scene.Provider.GlyphRunRenderer = (_, _, _) => true;

                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

                (int runs, int distinct, int allNotDef, int glyphs, int idZero, int maxId, int nonLatin,
                 int pidZero2, int pidDistinct2, ulong pidFirst2) = GlyphRunCensus.LastFrame;
                Output.WriteLine($"  关闭态：runs={runs} glyphs={glyphs} id0={idZero} maxId={maxId}");
                Assert.Equal(0, runs);
                Assert.Equal(0, glyphs);
                Assert.Equal(0, allNotDef);
                Assert.Equal(0, distinct);
            }
            finally { GlyphRunCensus.ForceEnabled(false); }
        }

        /// <summary>
        /// 环境变量通路（**部署件要用的就是这条**）。
        /// 在**新线程**上验：ThreadStatic 状态首次创建时读 `WPF_LINUX_GLYPH_CENSUS`，
        /// 所以新线程 = 干净的一次读取，不受本进程其它测试影响。
        /// ⚠ 本用例只验"开关读得对"；stderr 文本由 xUnit 捕获后不显示，
        ///   故"打印格式"不在这里验（部署跑时会进 runner 的日志）。
        /// </summary>
        [Fact]
        public void census_env_var_is_read_on_fresh_thread()
        {
            Assert.True(ProbeEnabledOnFreshThread("1"), "设 WPF_LINUX_GLYPH_CENSUS=1 后应为启用");
            Assert.True(ProbeEnabledOnFreshThread("yes"), "yes 也应算真");
            Assert.False(ProbeEnabledOnFreshThread(null), "未设时应为关闭（缺省零开销）");
            Assert.False(ProbeEnabledOnFreshThread("0"), "0 应为关闭");
            Environment.SetEnvironmentVariable("WPF_LINUX_GLYPH_CENSUS", null);   // 收尾：不留环境
        }

        private static bool ProbeEnabledOnFreshThread(string value)
        {
            bool result = false;
            var t = new System.Threading.Thread(() =>
            {
                Environment.SetEnvironmentVariable("WPF_LINUX_GLYPH_CENSUS", value);
                result = GlyphRunCensus.Enabled;
            });
            t.Start();
            t.Join();
            return result;
        }

        /// <summary>
        /// 原点 Y 必须被逐 run 记下（"多行摞印"的判据：同段落 N 行的 Y 是否全相同）。
        /// 本用例造两个 Y 不同的 run ⇒ 去重后应为 2；再各加一个与前者同 Y 的 ⇒ 仍应 2。
        /// </summary>
        [Fact]
        public void origin_y_is_recorded_per_run()
        {
            GlyphRunCensus.ForceEnabled(true);
            try
            {
                using var scene = new TestScene();
                // Y = 0 / 12 / 0 / 12  ⇒ 去重后 2 个不同 Y（模拟"两行"而不是"一行摞印"）
                double[] ys = { 0.0, 12.0, 0.0, 12.0 };
                var runs = new List<DUCE.ResourceHandle>();
                foreach (double y in ys)
                    runs.Add(scene.Add(new MilGlyphRun
                    {
                        GlyphIndices = new ushort[] { 5, 6, 7 },
                        Origin = new MilPoint2F { X = 3.5f, Y = (float)y },
                        ManagedBounds = new MilRect(0, 0, 10, 10),
                    }));

                DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    foreach (DUCE.ResourceHandle g in runs)
                        d.Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilDrawGlyphRun,
                            Geometry = new MilResourceHandle((uint)g),
                            Brush = new MilResourceHandle((uint)fill),
                        });
                });
                scene.Provider.GlyphRunRenderer = (_, _, _) => true;
                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

                IReadOnlyList<double> originYs = GlyphRunCensus.LastOriginYs;
                Output.WriteLine("  记录到的原点 Y = [" + string.Join(",", originYs) + "]");

                Assert.Equal(4, originYs.Count);
                Assert.Equal(0.0, originYs[0], 3);
                Assert.Equal(12.0, originYs[1], 3);
                var distinct = new List<double>(originYs);
                distinct.Sort();
                int nd = 0;
                for (int i = 0; i < distinct.Count; i++)
                    if (i == 0 || Math.Abs(distinct[i] - distinct[i - 1]) > 1e-6) nd++;
                Output.WriteLine($"  distinct_origin_y = {nd}");
                Assert.Equal(2, nd);
            }
            finally { GlyphRunCensus.ForceEnabled(false); }
        }

        /// <summary>
        /// 相关性判据：同 `originDIP.y` 的多个 run，其**设备 Y 去重数**是 1 还是 >1。
        /// 本用例造两个 **originDIP.y 完全相同**、但**画布 CTM 的 Ty 不同**的 run
        /// ⇒ 设备 Y 必须**不同** ⇒ 仪表必须把它判成"origin 只是行内相对量"那一支。
        /// 反过来，若把两 run 放在同一 CTM 下，设备 Y 必须相同（上游叠在同处那一支）。
        /// </summary>
        [Fact]
        public void correlation_distinguishes_same_origin_from_same_device_y()
        {
            GlyphRunCensus.ForceEnabled(true);
            try
            {
                // 同 originY、不同 Ty ⇒ 设备 Y 不同
                (int runs, int distinctDevY) = RenderTwoRunsWithOffset(0.0, 20.0);
                Output.WriteLine($"  不同 Ty: runs={runs} distinctDeviceY={distinctDevY}");
                Assert.Equal(2, runs);
                Assert.Equal(2, distinctDevY);        // ⇒ "origin 只是行内相对量"

                // 同 originY、同 Ty ⇒ 设备 Y 相同
                (runs, distinctDevY) = RenderTwoRunsWithOffset(0.0, 0.0);
                Output.WriteLine($"  相同 Ty: runs={runs} distinctDeviceY={distinctDevY}");
                Assert.Equal(2, runs);
                Assert.Equal(1, distinctDevY);        // ⇒ "上游就叠在同一处"
            }
            finally { GlyphRunCensus.ForceEnabled(false); }
        }

        /// <summary>
        /// 逐 run 明细行必须**如实**带出 devX/devY 与该 run 的 CTM（"行位置有没有带上"的直接判据）。
        /// 本用例两个 run 同 origin、CTM 的 Ty 差 20 ⇒ 明细行里 devY 必须差 20、CTM 的 f 也必须差 20。
        /// </summary>
        [Fact]
        public void detail_line_carries_device_y_and_ctm()
        {
            GlyphRunCensus.ForceEnabled(true);
            try
            {
                RenderTwoRunsWithOffset(0.0, 20.0);
                IReadOnlyList<string> lines = GlyphRunCensus.LastDetailLines;
                var detail = new List<string>();
                foreach (string l in lines) if (l.Contains("devY=")) detail.Add(l);
                foreach (string l in detail) Output.WriteLine("  " + l);
                Assert.Equal(2, detail.Count);

                Assert.Contains("originDIP=(0.000,11.139)", detail[0]);
                Assert.Contains("devY=11.139", detail[0]);
                Assert.Contains("devY=31.139", detail[1]);      // 同 origin、Ty 差 20 ⇒ devY 差 20
                Assert.Contains("CTM=[", detail[1]);
                Assert.Contains(",20.000]", detail[1]);          // CTM 的 f(Ty) 如实带出
                Assert.Contains(",0.000]", detail[0]);
            }
            finally { GlyphRunCensus.ForceEnabled(false); }
        }

        /// <summary>两个 originDIP.y 相同、CTM 的 Ty 分别加 tyA/tyB 的 run；返回(对数, 设备Y去重数)。</summary>
        private static (int, int) RenderTwoRunsWithOffset(double tyA, double tyB)
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle g = scene.Add(new MilGlyphRun
            {
                GlyphIndices = new ushort[] { 5, 6, 7 },
                Origin = new MilPoint2F { X = 0f, Y = 11.139f },
                ManagedBounds = new MilRect(0, 0, 10, 10),
            });
            DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushTransform,
                    Geometry = new MilResourceHandle((uint)scene.Translate(0f, (float)tyA)) });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilDrawGlyphRun,
                    Geometry = new MilResourceHandle((uint)g), Brush = new MilResourceHandle((uint)fill) });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushTransform,
                    Geometry = new MilResourceHandle((uint)scene.Translate(0f, (float)tyB)) });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilDrawGlyphRun,
                    Geometry = new MilResourceHandle((uint)g), Brush = new MilResourceHandle((uint)fill) });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
            });
            scene.Provider.GlyphRunRenderer = (_, _, _) => true;
            RenderHarness.Render(root, scene.Provider, 40, 60, antialias: true);

            IReadOnlyList<(double OriginY, double DeviceY)> pairs = GlyphRunCensus.LastYPairs;
            var dev = new List<double>();
            foreach ((double _, double dy) in pairs)
                if (!dev.Exists(v => Math.Abs(v - dy) <= 1e-6)) dev.Add(dy);
            return (pairs.Count, dev.Count);
        }

        private static DUCE.ResourceHandle GlyphRun(TestScene scene, ushort[] ids) =>
            scene.Add(new MilGlyphRun { GlyphIndices = ids, ManagedBounds = new MilRect(0, 0, 10, 10) });
    }
}
