// D1 / D2 —— UIAutomationTypes 的两处 Linux 缺口（T3 实测、主控派给本车道）。
//
// 【D1：`Win32ShimResolver` 没编进 UIAutomationTypes ⇒ DllNotFound】
//   真应用只要**给 ListBox 赋 ItemsSource**（不需要用户点选）就会：
//     ItemCollection.SetCollectionView → CollectionView.OnCollectionChanged
//     → ItemsControl.OnItemCollectionChanged2 → Selector.OnItemsChanged → SelectionChanger.End
//     → ListBox.OnSelectionChanged → AutomationPeer.ListenerExists → **AutomationPeer..cctor**
//     → **OSVersionHelper..cctor** → `[DllImport("PresentationNative_cor3.dll")]` → **DllNotFoundException**
//   符号在 shim 里是齐的（`libwpfwin32.so` 有 9 条 `IsWindows10*OrGreater`），
//   `PresentationNative_cor3.dll` 也早在 resolver 的 `MappedLibraries` 里 ⇒ **缺的只是 resolver 这一层**。
//
// 【本文件的判据为什么是"跑那个 cctor"而不是"文件里有没有 Include"】
//   主控抓过一次同类教训：**断言实现细节的字符串 = 实现的影子**（改一次实现红一次）。
//   所以这里直接**跑出事的那一步**：`RuntimeHelpers.RunClassConstructor(OSVersionHelper)`，
//   再调它那 9 条 `IsWindows10*OrGreater` 里的第一条 —— 这一步必须**不抛**
//   （修前抛 DllNotFoundException；修后能返回 bool，说明 resolver 真的把库映射上了）。
//   定位方式是**扫描程序集里带该 DllImport 的类型**，不是按记忆写死类型名（"读代码不读记忆"）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>D1/D2：UIAutomationTypes 在 Linux 上的两处缺口。</summary>
    [Trait("Category", "UIAutomation")]
    public sealed class UIAutomationLinuxTests
    {
        private readonly ITestOutputHelper _out;
        public UIAutomationLinuxTests(ITestOutputHelper output) => _out = output;

        /// <summary>UIAutomationTypes 的一个公开类型（用它拿到那个程序集，不按记忆猜程序集名）。</summary>
        private static readonly Assembly UiaTypesAssembly =
            typeof(System.Windows.Automation.AutomationIdentifier).Assembly;

        /// <summary>在给定程序集里找**声明了该 DllImport** 的类型（按需找，不写死类型名）。</summary>
        private static List<(Type Type, string Method)> TypesWithDllImport(Assembly asm, string libraryFragment)
        {
            var hits = new List<(Type, string)>();
            Type[] types;
            try { types = asm.GetTypes(); }
            catch (ReflectionTypeLoadException ex) { types = Array.FindAll(ex.Types, t => t != null); }

            foreach (Type t in types)
            {
                foreach (MethodInfo m in t.GetMethods(BindingFlags.Static | BindingFlags.Instance |
                                                      BindingFlags.Public | BindingFlags.NonPublic |
                                                      BindingFlags.DeclaredOnly))
                {
                    var dia = m.GetCustomAttribute<DllImportAttribute>();
                    if (dia == null) continue;
                    if (dia.Value != null && dia.Value.IndexOf(libraryFragment, StringComparison.OrdinalIgnoreCase) >= 0)
                        hits.Add((t, m.Name));
                }
            }
            return hits;
        }

        // ==================================================================
        //  D1：OSVersionHelper 的类型初始化（= 出事的那一步）必须不抛
        // ==================================================================

        [Fact]
        public void D1_UIAutomationTypes的OSVersionHelper静态构造不再DllNotFound()
        {
            var hits = TypesWithDllImport(UiaTypesAssembly, "PresentationNative_cor3");
            _out.WriteLine($"UIAutomationTypes 里声明 PresentationNative_cor3 DllImport 的成员：{hits.Count} 条");
            foreach ((Type t, string m) in hits)
                _out.WriteLine($"   {t.FullName}.{m}");

            Assert.True(hits.Count > 0,
                "UIAutomationTypes 里找不到 PresentationNative_cor3 的 DllImport —— 上游搬家了？" +
                "（本用例的判据依赖它，先确认再改断言）");

            // ① 触发类型初始化 —— **修前这一步就是 DllNotFoundException**。
            var distinct = new List<Type>();
            foreach ((Type t, _) in hits) if (!distinct.Contains(t)) distinct.Add(t);

            foreach (Type t in distinct)
            {
                Exception error = Record.Exception(() => RuntimeHelpers.RunClassConstructor(t.TypeHandle));
                _out.WriteLine($"RunClassConstructor({t.FullName}) ⇒ {(error == null ? "OK" : error.GetType().Name)}");
                Assert.True(error == null,
                    $"{t.FullName} 的静态构造失败：{error?.GetType().Name}: {error?.Message}\n" +
                    "⇒ Win32ShimResolver 没编进 UIAutomationTypes（D1）。修法：\n" +
                    "   src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py（无参即应用）" +
                    " + 重跑 port-lib.py UIAutomationTypes。");
            }

            // ② 真调一次那个 P/Invoke：能返回 bool 才说明**库真的被映射上了**（不只是 cctor 不抛）。
            int called = 0;
            foreach ((Type t, string name) in hits)
            {
                // 【不要用 `GetMethod(name, flags)`】同名重载会抛 AmbiguousMatchException
                //   （实测：本用例第一版就死在这里，看起来像"调用失败"，其实是取方法失败）。
                MethodInfo m = null;
                foreach (MethodInfo cand in t.GetMethods(BindingFlags.Static | BindingFlags.Public |
                                                         BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                {
                    if (cand.Name != name) continue;
                    if (cand.GetParameters().Length != 0) continue;
                    if (cand.ReturnType != typeof(bool)) continue;
                    m = cand;
                    break;
                }
                if (m == null) continue;

                object value = null;
                Exception error = Record.Exception(() => value = m.Invoke(null, null));
                _out.WriteLine($"调用 {t.Name}.{name}() ⇒ {(error == null ? value?.ToString() : error.GetType().Name)}");
                Assert.True(error == null,
                    $"{t.Name}.{name}() 调用失败：{error?.GetType().Name}: {error?.Message}");
                called++;
            }
            _out.WriteLine($"成功调用的零参 bool 型 P/Invoke：{called} 条");
            Assert.True(called > 0, "一条零参 bool 的 IsWindows*OrGreater 都没调到 —— 判据太弱，请核对");
        }

        /// <summary>记录异常（不在引用里引入 xunit 的 Record 扩展时用不了；这里自己写一个）。</summary>
        private static class Record
        {
            public static Exception Exception(Action body)
            {
                try { body(); return null; }
                catch (Exception ex) { return ex; }
            }
        }

        // ==================================================================
        //  D2：UiaGetReservedMixedAttributeValue 的封送异常必须消失
        // ==================================================================

        [Fact]
        public void D2_保留值API不再抛封送异常()
        {
            Type api = UiaTypesAssembly.GetType("MS.Internal.Automation.UiaCoreTypesApi", throwOnError: false);
            if (api == null)
            {
                _out.WriteLine("找不到 MS.Internal.Automation.UiaCoreTypesApi —— 上游搬家了？");
                return;   // 不假装跑过：类型不在就明说
            }

            foreach (string name in new[] { "UiaGetReservedNotSupportedValue", "UiaGetReservedMixedAttributeValue" })
            {
                MethodInfo m = api.GetMethod(name, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                if (m == null) { _out.WriteLine($"{name}：不存在，跳过"); continue; }

                object value = null;
                Exception error = Record.Exception(() => value = m.Invoke(null, null));
                _out.WriteLine($"{name}() ⇒ {(error == null ? (value?.ToString() ?? "<null>") : error.GetType().Name)}");
                _out.WriteLine($"   返回类型={m.ReturnType.Name} 值类型={(value == null ? "<null>" : value.GetType().FullName)}");

                Assert.True(error == null,
                    $"{name}() 仍然抛 {error?.GetType().Name}: {error?.Message}\n" +
                    "⇒ D2 未落地（IUnknown out-param 在 Linux 上不可封送）。修法见 " +
                    "src/WpfGfx.Linux.Native/tools/patch-uiautomationtypes-reservedvalue.py");
            }
        }

        // ==================================================================
        //  D3：Linux 上 UIA 标识符**落到最后那个 `else` 档**（不可达的运行时证词）
        //      ⇒ 同时证明 `SupportsWin7Identifiers()` 那一支**永不执行**（D-U1 的证据③④）
        //  【为什么断言"枚举成员相等"而不是 NotNull/范围】`Properties` 是**嵌套枚举**（首值 30000）
        //    ⇒ `Assert.NotNull(actual)` / `(int)actual >= 30000` 都是**恒真**的假牙（见 M7b 报告 §12.7）。
        //  【为什么 `GetField` 而不是 `GetProperty`】`LastSupportedProperty` 是**静态字段**，
        //    不是属性（`AutomationIdentifierConstants.cs:23`）——口径更正记在 M7b 报告 §12.8。
        // ==================================================================
        [Fact]
        public void D3_Linux上UIA标识符落到最后那个else档()
        {
            Type ovh = null;
            foreach (Type t in UiaTypesAssembly.GetTypes())      // 按名扫描，**不写死命名空间**（D1 同风格）
                if (t.Name == "OSVersionHelper") { ovh = t; break; }
            Assert.True(ovh != null, "UIAutomationTypes 里找不到 OSVersionHelper —— 上游搬家了？（本牙失效，别静默跳过）");

            PropertyInfo pVista = ovh.GetProperty("IsOsWindowsVistaOrGreater",
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            PropertyInfo pWin7 = ovh.GetProperty("IsOsWindows7OrGreater",
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            Assert.True(pVista != null && pWin7 != null, "OSVersionHelper 上找不到 IsOsWindows*OrGreater 属性");

            object vista = pVista.GetValue(null);
            object win7 = pWin7.GetValue(null);
            _out.WriteLine($"OSVersionHelper.IsOsWindowsVistaOrGreater={vista} ／ IsOsWindows7OrGreater={win7}");
            Assert.False((bool)vista, "Vista 谓词在 Linux 上必须为 false（为 true ⇒ shim 的 OS 谓词不再恒 0 ⇒ D-U1 前提变）");
            Assert.False((bool)win7, "7 谓词在 Linux 上必须为 false");

            Type aic = UiaTypesAssembly.GetType("MS.Internal.Automation.AutomationIdentifierConstants", throwOnError: false);
            Assert.True(aic != null, "找不到 MS.Internal.Automation.AutomationIdentifierConstants");

            // 读静态字段本身就会触发 cctor（= 真正跑那条 if/else 链）
            object actual = StaticField(aic, "LastSupportedProperty");
            object expected = Enum.Parse(Nested(aic, "Properties"), "TransformCanRotate");
            _out.WriteLine($"LastSupportedProperty={actual}（期望 TransformCanRotate={expected}）");
            Assert.Equal(expected, actual);

            // 加固项：KNOWN-DEFECTS 的 D-U1「已知边界」把这一档的**五个值**都登记了 ⇒ 一并钉住
            Assert.Equal(Enum.Parse(Nested(aic, "Events"), "Window_WindowClosed"),    StaticField(aic, "LastSupportedEvent"));
            Assert.Equal(Enum.Parse(Nested(aic, "Patterns"), "ScrollItem"),           StaticField(aic, "LastSupportedPattern"));
            Assert.Equal(Enum.Parse(Nested(aic, "TextAttributes"), "UnderlineStyle"), StaticField(aic, "LastSupportedTextAttribute"));
            Assert.Equal(Enum.Parse(Nested(aic, "ControlTypes"), "Separator"),        StaticField(aic, "LastSupportedControlType"));
        }

        /// <summary>取嵌套类型（找不到就**红**，不静默跳过）。</summary>
        private static Type Nested(Type t, string name)
        {
            Type n = t.GetNestedType(name, BindingFlags.Public | BindingFlags.NonPublic);
            Assert.True(n != null, $"{t.Name} 里找不到嵌套类型 {name}（上游搬家 ⇒ 本牙要改）");
            return n;
        }

        /// <summary>读静态字段（找不到就**红**，不静默跳过）。</summary>
        private static object StaticField(Type t, string name)
        {
            FieldInfo f = t.GetField(name, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            Assert.True(f != null, $"{t.Name}.{name} 不再是静态字段（上游改结构 ⇒ 本牙要改，别静默跳过）");
            return f.GetValue(null);
        }

        // ==================================================================
        //  D4：`UiaLookupId` 仍是**诚实的** `DllNotFoundException`
        //      ⇒ 钉住"只把 UIAutomationCore.dll 加进 MappedLibraries、却不落导出"这个**未来错误**
        // ==================================================================
        [Fact]
        public void D4_UiaLookupId仍是诚实的DllNotFound()
        {
            Type api = UiaTypesAssembly.GetType("MS.Internal.Automation.UiaCoreTypesApi", throwOnError: false);
            Assert.True(api != null, "找不到 MS.Internal.Automation.UiaCoreTypesApi");

            MethodInfo mi = api.GetMethod("UiaLookupId", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            // ⚠️ 这里**不学 D2 的"类型不在就 return"**：静默跳过 = 假绿。上游真搬走了 ⇒ 让本牙变红（信息性红），
            //    因为"这条 P/Invoke 还在不在"本身就是 D-U1 的前提。
            Assert.True(mi != null, "上游把 `UiaLookupId` 搬走/改名了 ⇒ D-U1 的前提变了，本牙必须重写（**不要**静默跳过）");

            object[] args = { Enum.ToObject(Nested(api, "AutomationIdType"), 0), Guid.Empty };  // `ref Guid`：装箱传入即可
            Exception err = Record.Exception(() => mi.Invoke(null, args));
            _out.WriteLine($"UiaLookupId(type, ref guid) ⇒ {(err == null ? "**没抛**" : err.GetType().Name)}");

            Assert.True(err != null,
                "`UiaLookupId` **能调通**了 ⇒ 说明有人落了导出（或加了映射）⇒ D-U1 的裁决必须重审（**信息性红**）");

            // 反射会把目标异常包在 TargetInvocationException 里 ⇒ 必须**拆一层**再判类型
            Exception inner = (err as TargetInvocationException)?.InnerException ?? err;
            _out.WriteLine($"   内层异常={inner.GetType().FullName}");
            Assert.IsType<DllNotFoundException>(inner);            // **精确类型**：子类也不算（这就是判据本身）
            Assert.IsNotType<EntryPointNotFoundException>(inner);  // 显式点出"禁止的降级"（只加映射不加导出 ⇒ 变这个）
        }
    }
}
