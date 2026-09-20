// X11 用例的可发现期跳过。
//
// 直接照搬 Windowing.Tests/X11Guard 的设计思路：xunit v2 没有运行期 skip 的官方
// 通道（v3 的 SkipException.ForSkip 需要运行期基础设施变化，本工程锁 v2.9.2 不升），
// 唯一干净的跳过通道是 FactAttribute.Skip 字段，它在发现期被读。所以我们在这里
// "打开 DISPLAY 试一下" —— 失败就把 Skip 填好，xunit 直接不执行这条用例。
//
// 【判据必须是"XOpenDisplay 能不能连上"，而不是"DISPLAY 非空"】
//   原来的 ProbeCore 只判断 DISPLAY 变量存在，于是 DISPLAY=:0 指向一个根本没在听
//   的地址时（容器里极常见），探针判定"有 X"，用例真跑起来后 X11Display.Open 抛
//   异常 —— 用例记成 **Failed** 而不是 Skipped。
//   实测复现：DISPLAY=:0 dotnet test HelloMil.Tests → X11_Capture… [FAIL]
//   修正后同一个命令是 Skipped。
//
// 【U10（2026-09-10）与 Windowing.Tests/X11Probe 统一】
//   此前这里用裸 XOpenDisplay P/Invoke 自测，与 Windowing.Tests 的探针（走
//   X11Display.Open，带 T15 的重试与失败分类）行为不一致。现已统一为同一实现：
//   经 InternalsVisibleTo（Interop/AssemblyInfo.cs）直接调用 X11Display.Open(null)，
//   删除本地 P/Invoke。两套测试对"X 是否可用"的判定从此同源。

using System;
using System.Collections.Generic;
using Xunit;
using Xunit.Sdk;

namespace WpfGfx.Linux.Tests.HelloMil
{
    /// <summary>纯探测：X server 到底能不能连上。</summary>
    internal static class HelloMilX11Probe
    {
        private static readonly Lazy<(bool Available, string Reason)> Probe =
            new Lazy<(bool, string)>(ProbeCore);

        public static bool Available => Probe.Value.Available;

        public static string Reason => Probe.Value.Reason;

        public static string SkipReason =>
            $"无 X server：{Reason}。要跑起来先起 Xvfb 并设 DISPLAY，例：Xvfb :99 -screen 0 1280x1024x24。";

        private static (bool, string) ProbeCore()
        {
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            if (string.IsNullOrWhiteSpace(display))
                return (false, "环境变量 DISPLAY 未设置");

            try
            {
                // 与 Windowing.Tests/X11Probe 同一探针实现：带 T15 重试与失败分类。
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

    /// <summary>X11 用例 trait 标记：无 X server 时在发现期 Skip。</summary>
    internal sealed class HelloMilX11FactAttribute : FactAttribute, ITraitAttribute
    {
        public HelloMilX11FactAttribute()
        {
            if (!HelloMilX11Probe.Available) Skip = HelloMilX11Probe.SkipReason;
        }

        public IReadOnlyList<KeyValuePair<string, string>> GetTraits() => Traits;

        private static readonly KeyValuePair<string, string>[] Traits =
            { new KeyValuePair<string, string>("Category", "X11") };
    }
}
