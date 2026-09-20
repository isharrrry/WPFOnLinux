using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using System.Reflection.Emit;
using HarmonyLib;

namespace U1Recorder
{
    /// <summary>
    /// U1b route 2: managed interception of System.Windows.Media.Composition.Channel with Lib.Harmony.
    /// Records the DUCE byte stream in the WPFST\001 format of docs/U1-command-stream-golden-plan.md 2.3.
    /// </summary>
    public static class Program
    {
        internal static string OutDir;
        internal static readonly object Gate = new object();
        internal static readonly List<string> Recent = new List<string>();

        internal static void Note(string rec)
        {
            lock (Gate)
            {
                Recent.Add(rec);
                if (Recent.Count > 40) Recent.RemoveAt(0);
            }
        }
        internal static readonly StringBuilder Report = new StringBuilder();
        private static readonly Dictionary<object, ChannelLog> Chans =
            new Dictionary<object, ChannelLog>(ReferenceComparer.Instance);

        internal sealed class ChannelLog
        {
            public int Index;
            public BinaryWriter W;
            public string Path;
            public int Commands;
            public readonly Dictionary<byte, int> Ops = new Dictionary<byte, int>();
        }

        private sealed class ReferenceComparer : IEqualityComparer<object>
        {
            public static readonly ReferenceComparer Instance = new ReferenceComparer();
            public new bool Equals(object a, object b) { return ReferenceEquals(a, b); }
            public int GetHashCode(object o) { return RuntimeHelpers.GetHashCode(o); }
        }

        internal static ChannelLog LogFor(object chan)
        {
            ChannelLog cl;
            if (!Chans.TryGetValue(chan, out cl))
            {
                cl = new ChannelLog { Index = Chans.Count };
                Chans[chan] = cl;
                cl.Path = System.IO.Path.Combine(OutDir, "wpf-duce-ch" + cl.Index + ".stream");
                var fs = File.Create(cl.Path);
                cl.W = new BinaryWriter(fs);
                cl.W.Write(new byte[] { 0x57, 0x50, 0x46, 0x53, 0x54, 0x01 });
                Report.AppendLine("channel #" + cl.Index + " -> " + cl.Path);
            }
            return cl;
        }

        internal static void Emit(object chan, byte op, byte[] payload)
        {
          lock (Gate)
          {
            var cl = LogFor(chan);
            int n = payload == null ? 0 : payload.Length;
            cl.W.Write(op);
            cl.W.Write((uint)n);
            if (n > 0) cl.W.Write(payload);
            cl.W.Flush();
            cl.Commands++;
            int c;
            cl.Ops.TryGetValue(op, out c);
            cl.Ops[op] = c + 1;
            Note("ch" + cl.Index + " op" + op + " cb" + n + " " + (n >= 4 ? BitConverter.ToString(payload, 0, 4) : ""));
          }
        }

        internal static void EmitRaw(object chan, byte op, params uint[] words)
        {
          lock (Gate)
          {
            var cl = LogFor(chan);
            cl.W.Write(op);
            cl.W.Write((uint)(words.Length * 4));
            foreach (uint w in words) cl.W.Write(w);
            cl.W.Flush();
            cl.Commands++;
            int c;
            cl.Ops.TryGetValue(op, out c);
            cl.Ops[op] = c + 1;
          }
        }

        internal static void Flush()
        {
            try { lock (Gate) File.WriteAllText(System.IO.Path.Combine(OutDir, "recorder-report.txt"), Report.ToString()); } catch { }
        }

        public static string Sig(MethodInfo mi)
        {
            var sb = new StringBuilder();
            sb.Append(mi.ReturnType.Name).Append(' ').Append(mi.Name).Append('(');
            var ps = mi.GetParameters();
            for (int i = 0; i < ps.Length; i++)
            {
                if (i > 0) sb.Append(", ");
                var p = ps[i];
                sb.Append(p.ParameterType.Name);
                if (p.ParameterType.IsByRef) sb.Append('&');
                if (p.IsOut) sb.Append(" out");
                sb.Append(' ').Append(p.Name);
            }
            sb.Append(')');
            return sb.ToString();
        }

        [STAThread]
        public static int Main(string[] args)
        {
            OutDir = args.Length > 0 ? args[0] : @"C:\u1-parity\out";
            Directory.CreateDirectory(OutDir);
            int rc = 0;

            // --- U1 route 1 bootstrap: make PresentationCore load the app-local forwarding proxy.
            // WPF resolves its native libraries by full path from the runtime directory, so a plain
            // app-local copy is ignored; a DllImportResolver redirects the import instead.
            string proxyPath = null;
            foreach (string a in args) if (a.StartsWith("proxy=")) proxyPath = a.Substring(6);
            if (proxyPath != null)
            {
                Report.AppendLine("--- proxy bootstrap: " + proxyPath);
                try
                {
                    NativeLibrary.SetDllImportResolver(typeof(Visual).Assembly, (name, asm, paths) =>
                    {
                        if (string.Equals(name, "wpfgfx_cor3.dll", StringComparison.OrdinalIgnoreCase))
                            return NativeLibrary.Load(proxyPath);
                        return IntPtr.Zero;
                    });
                    Report.AppendLine("  SetDllImportResolver: OK");
                }
                catch (Exception ex)
                {
                    Report.AppendLine("  SetDllImportResolver FAILED: " + ex.GetType().Name + ": " + ex.Message);
                    try
                    {
                        IntPtr h = NativeLibrary.Load(proxyPath);
                        Report.AppendLine("  preload via NativeLibrary.Load OK, handle=" + h);
                    }
                    catch (Exception e2)
                    {
                        Report.AppendLine("  preload FAILED: " + e2.GetType().Name + ": " + e2.Message);
                    }
                }
                Flush();
            }
            try
            {
                Report.AppendLine("=== U1b route 2: Harmony over System.Windows.Media.Composition.Channel ===");
                Report.AppendLine("Harmony version: " + typeof(Harmony).Assembly.GetName().Version);
                Report.AppendLine("PresentationCore: " + typeof(Visual).Assembly.Location);
                Report.AppendLine("PresentationCore version: " + typeof(Visual).Assembly.GetName().Version);

                var pcAsm = typeof(Visual).Assembly;
                Report.AppendLine("--- PresentationCore types mentioning Channel / Duce / DUCE ---");
                try
                {
                    foreach (var t in pcAsm.GetTypes())
                    {
                        string fn = t.FullName ?? t.Name;
                        if (fn.IndexOf("Channel", StringComparison.OrdinalIgnoreCase) >= 0 ||
                            fn.IndexOf("Duce", StringComparison.OrdinalIgnoreCase) >= 0)
                            Report.AppendLine("  " + (t.IsPublic ? "public  " : "internal") + " " + fn);
                    }
                }
                catch (Exception ex) { Report.AppendLine("  type dump failed: " + ex.Message); }

                Type chanType = pcAsm.GetType("System.Windows.Media.Composition.Channel", false);
                if (chanType == null) chanType = pcAsm.GetType("System.Windows.Media.Composition.DUCE.Channel", false);
                if (chanType == null)
                {
                    foreach (var t in pcAsm.GetTypes())
                        if (t.Name == "Channel") { chanType = t; break; }
                }
                Report.AppendLine("Channel type: " + (chanType == null ? "NOT FOUND" : chanType.AssemblyQualifiedName));
                if (chanType == null)
                {
                    File.WriteAllText(Path.Combine(OutDir, "recorder-report.txt"), Report.ToString());
                    Console.WriteLine("Channel type not found");
                    return 3;
                }

                Report.AppendLine("--- declared instance methods ---");
                foreach (var mi in chanType.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                    Report.AppendLine("  " + Sig(mi));

                var harmony = new Harmony("u1.duce.recorder");
                var prefix = new HarmonyMethod(typeof(Patches).GetMethod("RecordPrefix", BindingFlags.Static | BindingFlags.Public));
                var postfix = new HarmonyMethod(typeof(Patches).GetMethod("RecordPostfix", BindingFlags.Static | BindingFlags.Public));
                var commitPost = new HarmonyMethod(typeof(Patches).GetMethod("CommitPostfix", BindingFlags.Static | BindingFlags.Public));
                var transpiler = new HarmonyMethod(typeof(Patches).GetMethod("RecordTranspiler", BindingFlags.Static | BindingFlags.Public));
                var handleTranspiler = new HarmonyMethod(typeof(Patches).GetMethod("CreateHandleTranspiler", BindingFlags.Static | BindingFlags.Public));

                bool skipSend = false;
                string onlyList = null;
                bool noPatch = false;
                foreach (string a in args)
                {
                    if (a == "nosend") skipSend = true;
                    if (a == "nopatch") noPatch = true;
                    if (a.StartsWith("only:")) onlyList = a.Substring(5);
                }
                var only = new List<string>();
                if (onlyList != null) foreach (string x in onlyList.Split(',')) if (x.Length > 0) only.Add(x);
                if (noPatch) { Report.AppendLine("nopatch: no Harmony patch applied"); }
                else Report.AppendLine("only=" + (onlyList ?? "<all>"));
                Report.AppendLine("--- patching ---");
                string[] want = { "BeginCommand", "AppendCommandData", "EndCommand", "SendCommand", "Commit", "Close", "CreateOrAddRefOnChannel", "ReleaseOnChannel" };
                foreach (string name in want)
                {
                    foreach (var target in chanType.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                    {
                        if (target.Name != name) continue;
                        if (name == "SendCommand" && skipSend) { Report.AppendLine("  SKIPPED (nosend) " + Sig(target)); continue; }
                        if (noPatch) continue;
                        if (only.Count > 0 && !only.Contains(name)) continue;
                        try
                        {
                            HarmonyMethod pre = null, post = null, trans = null;
                            if (name == "Commit" || name == "Close") { post = commitPost; }
                            else if (name == "CreateOrAddRefOnChannel") { post = postfix; }
                            else if (name == "ReleaseOnChannel") { post = postfix; }
                            else
                            {
                                // No prefix here: Harmony materialises __args for pointer parameters with an
                                // invalid cast (ChkCastAny) and fatally crashes the CLR. The recording call is
                                // injected into the body by the transpiler instead, where the real byte* is on
                                // the evaluation stack.
                                trans = transpiler;
                            }
                            harmony.Patch(target, pre, post, trans);
                            Report.AppendLine("  PATCHED " + Sig(target));
                        }
                        catch (Exception ex)
                        {
                            rc = 4;
                            Report.AppendLine("  PATCH FAILED " + Sig(target) + " :: " + ex.GetType().Name + ": " + ex.Message);
                        }
                    }
                }
                Flush();

                // ---------------- workload ----------------
                AppDomain.CurrentDomain.UnhandledException += (se, ea) =>
                {
                    try { File.WriteAllText(Path.Combine(OutDir, "crash.txt"), ea.ExceptionObject.ToString()); } catch { }
                };
                Report.AppendLine("--- workload 1: offscreen RenderTargetBitmap over the U1a scene set ---");
                Flush();
                int sceneCount = 0;
                try
                {
                    var scenes = U1Parity.Scenes.Build();
                    int sceneIdx = 0;
                    foreach (var raw in scenes)
                    {
                      try
                      {
                        sceneIdx++;
                        var sc = (Dictionary<string, object>)raw;
                        Report.AppendLine("  scene " + sceneIdx + " " + sc["id"] + " begin");
                        Flush();
                        var dv = new DrawingVisual();
                        using (DrawingContext dc = dv.RenderOpen())
                        {
                            U1Parity.R.DrawOps(dc, (List<object>)sc["ops"]);
                        }
                        var rtb = new RenderTargetBitmap(256, 256, 96, 96, PixelFormats.Pbgra32);
                        rtb.Render(dv);
                        var conv = new FormatConvertedBitmap(rtb, PixelFormats.Bgra32, null, 0);
                        var px = new byte[256 * 4 * 256];
                        conv.CopyPixels(px, 256 * 4, 0);
                        sceneCount++;
                        Report.AppendLine("  scene " + sceneIdx + " done (commands so far " + Chans.Count + " channels)");
                        Flush();
                      }
                      catch (Exception ex)
                      {
                        Report.AppendLine("  scene " + sceneIdx + " FAILED: " + ex.GetType().Name + ": " + ex.Message);
                        Flush();
                      }
                    }
                    Report.AppendLine("rendered scenes: " + sceneCount);
                }
                catch (Exception ex)
                {
                    Report.AppendLine("workload 1 FAILED: " + ex.GetType().Name + ": " + ex.Message);
                }

                Report.AppendLine("--- workload 2: windowed render (session 0 experiment) ---");
                bool wantWindow = false;
                foreach (string a in args) if (a == "window") wantWindow = true;
                if (!wantWindow)
                {
                    Report.AppendLine("  skipped (pass the argument 'window' to enable)");
                }
                else try
                {
                    var t = new Thread(WindowWorkload);
                    t.IsBackground = true;
                    t.SetApartmentState(ApartmentState.STA);
                    t.Start();
                    if (!t.Join(TimeSpan.FromSeconds(12))) Report.AppendLine("window workload TIMED OUT after 12s (left as a background thread)");
                    else Report.AppendLine("window workload finished");
                }
                catch (Exception ex)
                {
                    Report.AppendLine("workload 2 FAILED: " + ex.GetType().Name + ": " + ex.Message);
                }

                Report.AppendLine("--- last recorded commands before exit ---");
                lock (Gate) foreach (string r in Recent) Report.AppendLine("    " + r);
                Report.AppendLine("--- stream summary ---");
                Report.AppendLine("  hook invocations / null pointer occurrences:");
                foreach (var kv in Patches.HookCalls) Report.AppendLine("    " + kv.Key + " x" + kv.Value);
                foreach (var kv in Patches.NullPtr) Report.AppendLine("    NULLPTR " + kv.Key + " x" + kv.Value);
                foreach (var kv in Chans)
                {
                    var cl = kv.Value;
                    Report.AppendLine("  " + cl.Path + " : " + cl.Commands + " records");
                    foreach (var op in cl.Ops)
                        Report.AppendLine("      op" + op.Key + " x" + op.Value);
                    cl.W.Flush();
                }
                if (Chans.Count == 0) Report.AppendLine("  NO CHANNEL TRAFFIC CAPTURED");
            }
            catch (Exception ex)
            {
                rc = 5;
                Report.AppendLine("FATAL " + ex);
            }
            finally
            {
                foreach (var kv in Chans) { try { kv.Value.W.Flush(); kv.Value.W.Dispose(); } catch { } }
                File.WriteAllText(Path.Combine(OutDir, "recorder-report.txt"), Report.ToString());
                Console.WriteLine(Report.ToString());
            }
            // a shown Window in session 0 can hang WPF teardown; the work is already on disk
            Environment.Exit(rc);
            return rc;
        }

        private static void WindowWorkload()
        {
            try
            {
                var win = new Window();
                win.Width = 320;
                win.Height = 240;
                win.Title = "U1 DUCE probe";
                var sp = new System.Windows.Controls.StackPanel();
                sp.Children.Add(new System.Windows.Shapes.Rectangle
                {
                    Width = 120,
                    Height = 60,
                    Fill = new LinearGradientBrush(Colors.Red, Colors.Blue, 45),
                    Margin = new Thickness(8)
                });
                sp.Children.Add(new System.Windows.Shapes.Ellipse
                {
                    Width = 90,
                    Height = 50,
                    Fill = Brushes.SeaGreen,
                    Stroke = Brushes.Black,
                    StrokeThickness = 4,
                    Margin = new Thickness(8)
                });
                win.Content = sp;
                win.Show();
                Report.AppendLine("  window shown, handle=" + new System.Windows.Interop.WindowInteropHelper(win).Handle);
                var t = new DispatcherTimer(TimeSpan.FromSeconds(2), DispatcherPriority.Background, (s, e) =>
                {
                    try { win.Close(); } catch (Exception ex) { Report.AppendLine("  close: " + ex.Message); }
                    Dispatcher.CurrentDispatcher.InvokeShutdown();
                }, Dispatcher.CurrentDispatcher);
                t.Start();
                Dispatcher.Run();
                Report.AppendLine("  dispatcher exited");
            }
            catch (Exception ex)
            {
                Report.AppendLine("  window FAILED: " + ex.GetType().Name + ": " + ex.Message);
            }
        }
    }

    /// <summary>Harmony hooks. Every hook is failure-isolated: it must never break the render.</summary>
    public static class Patches
    {
        [ThreadStatic] private static bool _inHook;
        internal static readonly Dictionary<string, int> HookCalls = new Dictionary<string, int>();
        internal static readonly Dictionary<string, int> NullPtr = new Dictionary<string, int>();

        internal static int DiagLeft = 4;

        internal static string Describe(object o)
        {
            if (o == null) return "NULL";
            string tn = o.GetType().FullName;
            if (o is Pointer) { unsafe { return "Pointer(" + tn + ")->" + (*(uint*)Pointer.Unbox(o)); } }
            return tn;
        }

        internal static void Bump(Dictionary<string, int> d, string k)
        {
            try
            {
                lock (Program.Gate)
                {
                    int c;
                    d.TryGetValue(k, out c);
                    d[k] = c + 1;
                }
            }
            catch { }
        }

        /// <summary>
        /// Injects the recording call at the top of the method body, where the raw byte* is still a
        /// real argument. Harmony's __args array carries null for pointer parameters, so a prefix
        /// cannot observe the command bytes.
        /// </summary>
        /// <summary>
        /// CreateOrAddRefOnChannel backfills its ref handle, so the recording call is injected before
        /// every ret, where arg1 (ResourceHandle&) already points at the Windows-assigned handle.
        /// </summary>
        public static IEnumerable<CodeInstruction> CreateHandleTranspiler(
            IEnumerable<CodeInstruction> instructions, MethodBase __originalMethod)
        {
            var list = new List<CodeInstruction>(instructions);
            var target = typeof(Patches).GetMethod("RecordCreateOrAddRef", BindingFlags.Static | BindingFlags.Public);
            var outp = new List<CodeInstruction>();
            int injected = 0;
            foreach (var ins in list)
            {
                if (ins.opcode == OpCodes.Ret)
                {
                    outp.Add(new CodeInstruction(OpCodes.Ldarg_0));
                    outp.Add(new CodeInstruction(OpCodes.Ldarg_1));
                    outp.Add(new CodeInstruction(OpCodes.Ldarg_2));
                    outp.Add(new CodeInstruction(OpCodes.Call, target));
                    injected++;
                }
                outp.Add(ins);
            }
            Program.Report.AppendLine("  transpiled " + __originalMethod.Name + " at " + injected + " ret site(s)");
            return outp;
        }

        // ResourceHandle is a 4-byte explicitly-laid-out struct, so a byref to it is passed as a
        // managed pointer and can be read back through a same-size shim.
        [StructLayout(LayoutKind.Explicit, Size = 4)]
        public struct HandleShim { [FieldOffset(0)] public uint Value; }

        public static void RecordCreateOrAddRef(object self, ref HandleShim handle, int type)
        {
            try
            {
                Program.EmitRaw(self, 5, unchecked((uint)type), handle.Value);
            }
            catch { }
        }

        public static IEnumerable<CodeInstruction> RecordTranspiler(
            IEnumerable<CodeInstruction> instructions, MethodBase __originalMethod)
        {
            var list = new List<CodeInstruction>(instructions);
            string name = __originalMethod.Name;
            var ps = __originalMethod.GetParameters();
            int n = ps.Length;

            string targetName;
            int argCount;   // how many of arg1..arg3 to pass in addition to `this`
            if (name == "BeginCommand") { targetName = "RecordBegin"; argCount = 3; }
            else if (name == "AppendCommandData") { targetName = "RecordAppend"; argCount = 2; }
            else if (name == "SendCommand") { targetName = "RecordSend"; argCount = 2; }
            else if (name == "EndCommand") { targetName = "RecordEnd"; argCount = 0; }
            else return list;

            if (n < argCount) { Program.Report.AppendLine("  transpiler: " + name + " has only " + n + " params"); return list; }

            MethodInfo target = typeof(Patches).GetMethod(targetName, BindingFlags.Static | BindingFlags.Public);
            var injected = new List<CodeInstruction>();
            injected.Add(new CodeInstruction(OpCodes.Ldarg_0));
            if (argCount >= 1) injected.Add(new CodeInstruction(OpCodes.Ldarg_1));
            if (argCount >= 2) injected.Add(new CodeInstruction(OpCodes.Ldarg_2));
            if (argCount >= 3) injected.Add(new CodeInstruction(OpCodes.Ldarg_3));
            injected.Add(new CodeInstruction(OpCodes.Call, target));
            list.InsertRange(0, injected);
            Program.Report.AppendLine("  transpiled " + name + " (params=" + n + ")");
            return list;
        }

        public static unsafe void RecordBegin(object self, byte* data, int cbSize, int cbExtra)
        {
            try
            {
                Bump(HookCalls, "BeginCommand");
                if (data == (byte*)0) { Bump(NullPtr, "BeginCommand"); return; }
                Copy(self, 1, data, cbSize, (uint)(cbExtra < 0 ? 0 : cbExtra));
            }
            catch { }
        }

        public static unsafe void RecordAppend(object self, byte* data, int cbSize)
        {
            try
            {
                Bump(HookCalls, "AppendCommandData");
                if (data == (byte*)0) { Bump(NullPtr, "AppendCommandData"); return; }
                Copy(self, 2, data, cbSize);
            }
            catch { }
        }

        public static unsafe void RecordSend(object self, byte* data, int cbSize)
        {
            try
            {
                Bump(HookCalls, "SendCommand");
                if (data == (byte*)0) { Bump(NullPtr, "SendCommand"); return; }
                // out-of-band: one complete command, normalized to BeginCommand + EndCommand
                Copy(self, 1, data, cbSize);
                Program.Emit(self, 3, null);
            }
            catch { }
        }

        public static void RecordEnd(object self)
        {
            try
            {
                Bump(HookCalls, "EndCommand");
                Program.Emit(self, 3, null);
            }
            catch { }
        }

        private static unsafe void Copy(object chan, byte op, byte* data, int cbSize)
        {
            Copy(chan, op, data, cbSize, 0u);
        }

        /// <summary>
        /// op1 records carry cbExtra(u32) followed by the command bytes, which is exactly what
        /// GoldenBinaryReplayTests.ReplayFile feeds to MilChannel.BeginCommand(data, cbExtra).
        /// </summary>
        private static unsafe void Copy(object chan, byte op, byte* data, int cbSize, uint cbExtra)
        {
            try
            {
                if (op == 1)
                {
                    var buf = new byte[4 + (cbSize > 0 ? cbSize : 0)];
                    BitConverter.GetBytes(cbExtra).CopyTo(buf, 0);
                    if (cbSize > 0) Marshal.Copy((IntPtr)data, buf, 4, cbSize);
                    Program.Emit(chan, 1, buf);
                    return;
                }
                if (cbSize <= 0) { Program.Emit(chan, op, new byte[0]); return; }
                var b2 = new byte[cbSize];
                Marshal.Copy((IntPtr)data, b2, 0, cbSize);
                Program.Emit(chan, op, b2);
            }
            catch (Exception ex)
            {
                Program.Report.AppendLine("  hook record error: " + ex.GetType().Name + ": " + ex.Message);
            }
        }

        public static void RecordPrefix(object __instance, object[] __args, MethodBase __originalMethod)
        {
            // diagnostic only: Harmony hands pointer parameters to __args as null, which is exactly why
            // the byte capture lives in the transpiler instead
            if (_inHook) return;
            _inHook = true;
            try
            {
                string name = __originalMethod.Name;
                Bump(HookCalls, "prefix:" + name);
                if (__args != null && __args.Length > 0 && __args[0] == null) Bump(NullPtr, "prefix:" + name + "[0]");
            }
            catch { }
            finally { _inHook = false; }
        }

        public static void RecordPostfix(object __instance, object[] __args, MethodBase __originalMethod)
        {
            if (_inHook) return;
            _inHook = true;
            try
            {
                string name = __originalMethod.Name;
                if (name == "CreateOrAddRefOnChannel")
                {
                    object res = __args != null && __args.Length > 0 ? __args[0] : null;
                    object box = __args != null && __args.Length > 1 ? __args[1] : null;
                    object t = __args != null && __args.Length > 2 ? __args[2] : null;
                    uint h = ReadHandleField(res);
                    if (h == 0) h = ReadHandleField(box);
                    if (h == 0 && box is Pointer)
                    {
                        // Harmony hands byref parameters over as a boxed managed pointer, so the
                        // pointee can be read *after* the call and holds the backfilled handle.
                        unsafe { h = *(uint*)Pointer.Unbox(box); }
                    }
                    if (DiagLeft > 0)
                    {
                        DiagLeft--;
                        Program.Report.AppendLine("  DIAG args.len=" + (__args == null ? -1 : __args.Length)
                            + " a0=" + Describe(res) + " a1=" + Describe(box) + " a2=" + Describe(t) + " handle=" + h);
                        Program.Flush();
                    }
                    Program.EmitRaw(__instance, 5, ToU32(t), h);
                }
                else if (name == "ReleaseOnChannel")
                {
                    object h = __args != null && __args.Length > 0 ? __args[0] : null;
                    Program.EmitRaw(__instance, 6, ReadHandleField(h));
                }
            }
            catch (Exception ex)
            {
                Program.Report.AppendLine("  hook(Postfix " + __originalMethod.Name + ") error: " + ex.GetType().Name + ": " + ex.Message);
            }
            finally { _inHook = false; }
        }

        public static void CommitPostfix(object __instance)
        {
            try { Program.Emit(__instance, 4, null); }
            catch (Exception ex) { Program.Report.AppendLine("  hook(Commit) error: " + ex.Message); }
        }

        private static unsafe void EmitBytes(object chan, byte op, object[] args, int ptrIdx, int sizeIdx)
        {
            if (args == null || args.Length <= sizeIdx) return;
            object ptrObj = args[ptrIdx];
            if (ptrObj == null) return;
            byte* p = (byte*)Pointer.Unbox(ptrObj);
            if (p == (byte*)0) return;
            int cb = Convert.ToInt32(args[sizeIdx], CultureInfo.InvariantCulture);
            if (cb <= 0) { Program.Emit(chan, op, new byte[0]); return; }
            var buf = new byte[cb];
            Marshal.Copy((IntPtr)p, buf, 0, cb);
            Program.Emit(chan, op, buf);
        }

        private static uint ToU32(object value)
        {
            if (value == null) return 0;
            if (value is Enum) return Convert.ToUInt32(value, CultureInfo.InvariantCulture);
            if (value.GetType().IsPrimitive) return Convert.ToUInt32(value, CultureInfo.InvariantCulture);
            return ReadHandleField(value);
        }

        /// <summary>
        /// Reads the 32-bit DUCE handle out of a ResourceHandle struct or out of the resource object
        /// that owns one (walking one level of indirection such as MatrixTransform._duceResource).
        /// </summary>
        private static uint ReadHandleField(object value)
        {
            return ReadHandleField(value, 2, new HashSet<object>());
        }

        private static uint ReadHandleField(object value, int depth, HashSet<object> seen)
        {
            if (value == null || depth < 0) return 0;
            if (!value.GetType().IsValueType && !seen.Add(value)) return 0;
            try
            {
                Type t = value.GetType();
                var nested = new List<object>();
                for (Type cur = t; cur != null && cur != typeof(object); cur = cur.BaseType)
                {
                    foreach (var f in cur.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                    {
                        object v;
                        try { v = f.GetValue(value); } catch { continue; }
                        if (v == null) continue;
                        if (f.Name == "_handle" || f.Name == "handle" || f.Name == "_hResource")
                        {
                            if (v is Enum || v.GetType().IsPrimitive)
                                return Convert.ToUInt32(v, CultureInfo.InvariantCulture);
                        }
                        if (depth > 0 && !f.FieldType.IsPrimitive && !f.FieldType.IsEnum)
                            nested.Add(v);
                    }
                }
                foreach (object sub in nested)
                {
                    uint r = ReadHandleField(sub, depth - 1, seen);
                    if (r != 0) return r;
                }
            }
            catch { }
            return 0;
        }
    }
}
