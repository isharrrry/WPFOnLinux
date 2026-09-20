// X11 用例的可用性守卫。
//
// 【为什么用「发现期 Skip」而不是「运行期抛异常」】
//   最自然的写法是运行期发现没有 X server 就抛一个 skip 异常。但 xunit 的
//   `Xunit.Sdk.SkipException.ForSkip` 在它自己的 XML 文档里写死了：
//     "Note that this only works in v3 and later of xUnit.net, as it requires
//      runtime infrastructure changes."
//   本工程锁的是 xunit 2.9.2（与 Commands.Tests / Rendering.Tests 一致，不能单独升），
//   实测抛出去之后 v2 执行层不认那个 `$XunitDynamicSkip$` 前缀，用例被记成
//   **Failed** 而不是 Skipped——在无 X 的机器上 `dotnet test` 一片红，正是要避免的。
//
//   v2 唯一干净的跳过通道是 `FactAttribute.Skip`。它是在**发现期**读的，而特性
//   的构造函数恰好也在发现期执行，所以在构造函数里探测 X server 并据此设 Skip
//   就等价得到了"动态跳过"。这也顺带保证了：DISPLAY 不可用时用例压根不会被执行，
//   而不是执行到一半再放弃。
//
// 【判据是"真的能 XOpenDisplay"而不是"DISPLAY 非空"】
//   容器里 DISPLAY 常常被预设成 :0，但根本没有 X server 在听。只有 XOpenDisplay
//   返回非 0 才算数——这正是我们要拿 X11Display 自己去试的原因。

using System;
using System.Collections.Generic;
using Xunit;
using Xunit.Sdk;

namespace WpfGfx.Linux.Tests.Windowing
{
    /// <summary>纯探测：X server 到底能不能连上。不依赖 xunit，特性构造函数里可用。</summary>
    internal static class X11Probe
    {
        private static readonly Lazy<(bool Available, string Reason)> Probe =
            new Lazy<(bool, string)>(ProbeCore);

        public static bool Available => Probe.Value.Available;

        public static string Reason => Probe.Value.Reason;

        /// <summary>无 X server 时的跳过理由（给 Skip 字段用）。</summary>
        public static string SkipReason =>
            $"无 X server：{Reason}。要跑起来先执行 " +
            "tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start，再设 DISPLAY=:99。";

        private static (bool, string) ProbeCore()
        {
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            if (string.IsNullOrWhiteSpace(display))
                return (false, "环境变量 DISPLAY 未设置");

            try
            {
                using WpfGfx.Linux.Windowing.X11Display dpy =
                    WpfGfx.Linux.Windowing.X11Display.Open(null);
                return (true, $"DISPLAY={display}");
            }
            catch (Exception ex)
            {
                return (false, $"打开 DISPLAY={display} 失败：{ex.GetType().Name}: {ex.Message}");
            }
        }
    }

    internal static class X11Guard
    {
        /// <summary>
        /// 在 X11 用例开头调用。正常情况下用例在发现期就已经被 Skip 掉了，
        /// 这里是一道兜底：万一 Skip 没生效（比如直接反射调用方法），
        /// 抛异常总好过静默跑出个假结果。
        /// </summary>
        public static void Require()
        {
            if (!X11Probe.Available)
                throw new InvalidOperationException(X11Probe.SkipReason);
        }
    }

    /// <summary>
    /// 标记需要真实 X server 的用例。测试资源管理器里可按 Category=X11 过滤，
    /// CI 上用 <c>dotnet test --filter "Category!=X11"</c> 就能把窗口用例摘出去；
    /// 不摘也无所谓——无 X server 时它们在发现期就被标成跳过，不会红。
    /// </summary>
    /// <remarks>
    /// xunit v2 的 <see cref="FactAttribute"/> 没有 v3 的 <c>Traits</c> 集合属性，
    /// 自定义特性要带 trait 只能实现 <see cref="ITraitAttribute"/>——这是 v2 官方
    /// 的扩展点，由 <c>TraitDiscoverer</c> 负责枚举。
    /// </remarks>
    internal sealed class X11FactAttribute : FactAttribute, ITraitAttribute
    {
        public X11FactAttribute()
        {
            if (!X11Probe.Available) Skip = X11Probe.SkipReason;
        }

        public IReadOnlyList<KeyValuePair<string, string>> GetTraits() => Traits;

        private static readonly KeyValuePair<string, string>[] Traits =
            { new KeyValuePair<string, string>("Category", "X11") };
    }

    internal sealed class X11TheoryAttribute : TheoryAttribute, ITraitAttribute
    {
        public X11TheoryAttribute()
        {
            if (!X11Probe.Available) Skip = X11Probe.SkipReason;
        }

        public IReadOnlyList<KeyValuePair<string, string>> GetTraits() => Traits;

        private static readonly KeyValuePair<string, string>[] Traits =
            { new KeyValuePair<string, string>("Category", "X11") };
    }
}
