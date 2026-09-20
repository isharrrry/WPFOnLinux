// “未画种类”台账尾部的自验（T2b）。
//
// 判据三条：
//   ① **空时必须返回空串** ⇒ 台账前缀 `未画种类 0` 逐字不变（T3 的判据②按字符串判它）；
//   ② 有未画时必须**出现类名+次数**，且形如 ` [A×n,B×m]`（前导空格、尾部 `]`）；
//   ③ 超过 8 类必须折叠成 `…+N`（台账行不能无限长）。
using System.Collections.Generic;
using System.Text;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Rendering;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class NotDrawnSummaryTests
    {
        public NotDrawnSummaryTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const string Prefix = "（skia 指令 12 条，未画种类 ";

        /// <summary>① 空 ⇒ 空串 ⇒ 既有前缀逐字不变（"加类名前后同一行"的自证）。</summary>
        [Fact]
        public void empty_summary_keeps_prefix_byte_identical()
        {
            var d = new RenderDiagnostics();
            string before = Prefix + d.NotDrawn.Count + "）";
            string after = Prefix + d.NotDrawn.Count + d.NotDrawnSummary() + "）";
            Output.WriteLine("  加类名之前: " + before);
            Output.WriteLine("  加类名之后: " + after);
            Assert.Equal(string.Empty, d.NotDrawnSummary());
            Assert.Equal(before, after);          // 逐字相同
        }

        /// <summary>② 有未画 ⇒ 类名+次数出现。</summary>
        [Fact]
        public void non_empty_summary_lists_kind_and_count()
        {
            var d = new RenderDiagnostics();
            d.RecordNotDrawn(MilDrawCommand.MilPushOpacityMask);
            d.RecordNotDrawn(MilDrawCommand.MilPushOpacityMask);
            d.RecordNotDrawn(MilDrawCommand.MilDrawVideo);

            string s = d.NotDrawnSummary();
            Output.WriteLine("  加类名之后: " + Prefix + d.NotDrawn.Count + s + "）");
            Assert.StartsWith(" [", s);
            Assert.EndsWith("]", s);
            Assert.Contains("MilPushOpacityMask×2", s);
            Assert.Contains("MilDrawVideo×1", s);
        }

        /// <summary>③ 超过 8 类折叠成 `…+N`。</summary>
        [Fact]
        public void summary_is_bounded()
        {
            var d = new RenderDiagnostics();
            var kinds = new List<MilDrawCommand>();
            foreach (MilDrawCommand c in System.Enum.GetValues<MilDrawCommand>())
                if (kinds.Count < RenderDiagnostics.MaxSummaryKinds + 2) kinds.Add(c);
            foreach (MilDrawCommand c in kinds) d.RecordNotDrawn(c);

            string s = d.NotDrawnSummary();
            Output.WriteLine($"  种类={kinds.Count} 摘要长度={s.Length}");
            Assert.Contains("…+2", s);            // 只列 8 类，剩 2 折叠
            Assert.True(s.Split('×').Length - 1 <= RenderDiagnostics.MaxSummaryKinds,
                "列出的类数不应超过上限");
        }
    }
}
