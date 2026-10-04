using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using static U1Parity.J;

namespace U1Parity
{
    /// <summary>
    /// U1a: render the scene set offscreen with RenderTargetBitmap and emit PNG + scenes.json + probe.json.
    /// Nothing here creates a Window / HwndTarget, so it must run in a non-interactive (session 0) context.
    /// </summary>
    public static class Program
    {
        private static string OutDir;
        private static readonly List<string> Log = new List<string>();

        private static void Say(string s)
        {
            Log.Add(s);
            Console.WriteLine(s);
            Console.Out.Flush();
        }

        [STAThread]
        public static int Main(string[] args)
        {
            OutDir = args.Length > 0 ? args[0] : @"C:\u1-parity\out";
            var probe = O();
            probe["format"] = "wpf-linux-u1a-probe/1";
            probe["collectedAtUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);
            probe["outDir"] = OutDir;

            try
            {
                Directory.CreateDirectory(OutDir);
                probe["renderTargetBitmapUsable"] = null;

                var host = O();
                host["machineName"] = Environment.MachineName;
                host["userName"] = Environment.UserName;
                host["osVersion"] = Environment.OSVersion.VersionString;
                host["osDescription"] = System.Runtime.InteropServices.RuntimeInformation.OSDescription;
                host["osArchitecture"] = System.Runtime.InteropServices.RuntimeInformation.OSArchitecture.ToString();
                host["processArchitecture"] = System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture.ToString();
                host["clrVersion"] = Environment.Version.ToString();
                host["is64BitProcess"] = Environment.Is64BitProcess;
                host["processorCount"] = (double)Environment.ProcessorCount;
                host["sessionId"] = Process.GetCurrentProcess().SessionId.ToString(CultureInfo.InvariantCulture);
                host["sessionName"] = Environment.GetEnvironmentVariable("SESSIONNAME") ?? "";
                host["userInteractive"] = Environment.UserInteractive;
                probe["host"] = host;

                // ---- runtime / native DLL version record ----
                var rt = O();
                rt["frameworkDescription"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription;
                string wdDir = Path.Combine(AppContext.BaseDirectory);
                rt["appBaseDirectory"] = wdDir;
                rt["presentationCorePath"] = typeof(RenderTargetBitmap).Assembly.Location;
                rt["presentationCoreVersion"] = typeof(RenderTargetBitmap).Assembly.GetName().Version.ToString();
                rt["windowsBaseVersion"] = typeof(System.Windows.DependencyObject).Assembly.GetName().Version.ToString();
                rt["dotnetInfo"] = RunCapture("dotnet", "--info");
                probe["runtime"] = rt;

                var natives = new List<object>();
                foreach (string cand in FindNativeCandidates())
                {
                    var fi = new FileInfo(cand);
                    if (!fi.Exists) continue;
                    var d = O();
                    d["path"] = fi.FullName;
                    d["sizeBytes"] = (double)fi.Length;
                    d["lastWriteTimeUtc"] = fi.LastWriteTimeUtc.ToString("o", CultureInfo.InvariantCulture);
                    d["fileVersion"] = FileVersionOf(fi.FullName);
                    d["sha256"] = Sha256OfFile(fi.FullName);
                    natives.Add(d);
                }
                probe["nativeDlls"] = natives;

                // ---- render path self-description ----
                var rp = O();
                rp["pixelFormat"] = "Pbgra32";
                rp["width"] = (double)Scenes.W;
                rp["height"] = (double)Scenes.H;
                rp["dpi"] = 96.0;
                rp["visual"] = "DrawingVisual + DrawingContext (no Window, no HwndTarget, no Dispatcher.Run)";
                rp["pngSourceFormat"] = "Bgra32 (FormatConvertedBitmap from Pbgra32, straight alpha)";
                probe["renderPath"] = rp;

                // ---- render ----
                var sceneList = Scenes.Build();
                foreach (var rawScene in sceneList)
                {
                    var scene = (Dictionary<string, object>)rawScene;
                    // freeze the exact composite matrix of every transform op into the JSON
                    AnnotateComposites((List<object>)scene["ops"]);
                }

                var scenesJson = O();
                scenesJson["format"] = "wpf-linux-u1a-scenes/1";
                scenesJson["producedBy"] = "U1Parity (net10.0-windows, UseWPF, RenderTargetBitmap offscreen)";
                scenesJson["conventions"] = Scenes.Conventions();
                var sceneArray = new List<object>();
                var pngIndex = new List<object>();

                var sw = Stopwatch.StartNew();
                int totalExpectChecked = 0, totalExpectFailed = 0;
                foreach (var rawScene in sceneList)
                {
                    var scene = (Dictionary<string, object>)rawScene;
                    string id = (string)scene["id"];
                    string pngPath = Path.Combine(OutDir, (string)scene["png"]);

                    var dv = new DrawingVisual();
                    using (DrawingContext dc = dv.RenderOpen())
                    {
                        R.DrawOps(dc, (List<object>)scene["ops"]);
                    }

                    var rtb = new RenderTargetBitmap(Scenes.W, Scenes.H, 96, 96, PixelFormats.Pbgra32);
                    rtb.Render(dv);

                    var conv = new FormatConvertedBitmap(rtb, PixelFormats.Bgra32, null, 0);
                    int stride = Scenes.W * 4;
                    byte[] px = new byte[stride * Scenes.H];
                    conv.CopyPixels(px, stride, 0);

                    var enc = new PngBitmapEncoder();
                    enc.Frames.Add(BitmapFrame.Create(conv));
                    using (var fs = File.Create(pngPath)) enc.Save(fs);

                    // decode what actually landed on disk and re-check every probe against it
                    byte[] roundTrip;
                    using (var fs = File.OpenRead(pngPath))
                    {
                        var dec = new PngBitmapDecoder(fs, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
                        var bc = new FormatConvertedBitmap(dec.Frames[0], PixelFormats.Bgra32, null, 0);
                        roundTrip = new byte[stride * Scenes.H];
                        bc.CopyPixels(roundTrip, stride, 0);
                    }

                    int mismatch = 0;
                    int expectChecked = 0, expectFailed = 0;
                    foreach (Dictionary<string, object> p in (List<object>)scene["probes"])
                    {
                        int x = (int)J.N(p["x"]);
                        int y = (int)J.N(p["y"]);
                        int i = y * stride + x * 4;
                        int b = px[i], g = px[i + 1], r = px[i + 2], a = px[i + 3];
                        p["rgba"] = L((double)r, (double)g, (double)b, (double)a);
                        p["hex"] = "#" + a.ToString("X2") + r.ToString("X2") + g.ToString("X2") + b.ToString("X2");
                        if (roundTrip[i] != b || roundTrip[i + 1] != g || roundTrip[i + 2] != r || roundTrip[i + 3] != a)
                        {
                            mismatch++;
                            p["pngRoundTripMismatch"] = true;
                        }
                        if (J.Has(p, "expect"))
                        {
                            expectChecked++;
                            string ex = (string)p["expect"];
                            uint ev = uint.Parse(ex.Substring(1), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
                            int ea = (int)(ev >> 24), er = (int)((ev >> 16) & 0xFF), eg = (int)((ev >> 8) & 0xFF), eb = (int)(ev & 0xFF);
                            int d = Math.Max(Math.Max(Math.Abs(ea - a), Math.Abs(er - r)), Math.Max(Math.Abs(eg - g), Math.Abs(eb - b)));
                            double tol = J.Has(p, "expectTolerance") ? J.D(p, "expectTolerance") : 2.0;
                            p["expectMaxChannelDelta"] = (double)d;
                            p["expectOk"] = d <= tol;
                            if (d > tol)
                            {
                                expectFailed++;
                                Say(string.Format(CultureInfo.InvariantCulture,
                                    "  !! {0} probe ({1},{2}) measured {3} but predicted {4} (max delta {5} > tol {6})",
                                    id, x, y, p["hex"], ex, d, tol));
                            }
                        }
                    }

                    var stats = O();
                    var seen = new HashSet<int>();
                    int nonWhite = 0;
                    long sum = 0;
                    for (int i = 0; i < px.Length; i += 4)
                    {
                        int v = (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
                        seen.Add(v);
                        if (!(px[i] == 255 && px[i + 1] == 255 && px[i + 2] == 255)) nonWhite++;
                        sum += px[i] + px[i + 1] + px[i + 2];
                    }
                    stats["distinctRgbColors"] = (double)seen.Count;
                    stats["nonWhitePixels"] = (double)nonWhite;
                    stats["meanChannelValue"] = Math.Round((double)sum / (Scenes.W * Scenes.H * 3), 4);
                    stats["probePngRoundTripMismatches"] = (double)mismatch;
                    stats["expectChecked"] = (double)expectChecked;
                    stats["expectFailed"] = (double)expectFailed;
                    totalExpectChecked += expectChecked;
                    totalExpectFailed += expectFailed;
                    scene["stats"] = stats;
                    scene["probeCount"] = (double)((List<object>)scene["probes"]).Count;

                    var fi = new FileInfo(pngPath);
                    var entry = O();
                    entry["id"] = id;
                    entry["file"] = fi.Name;
                    entry["sizeBytes"] = (double)fi.Length;
                    entry["sha256"] = Sha256OfFile(pngPath);
                    entry["probeCount"] = (double)((List<object>)scene["probes"]).Count;
                    entry["nonWhitePixels"] = (double)nonWhite;
                    entry["distinctRgbColors"] = (double)seen.Count;
                    pngIndex.Add(entry);

                    sceneArray.Add(scene);
                    Say(string.Format(CultureInfo.InvariantCulture,
                        "{0}: {1} bytes, {2} probes, nonWhite={3}, colors={4}, probes-on-disk-mismatch={5}",
                        id, fi.Length, entry["probeCount"], nonWhite, seen.Count, mismatch));
                }
                sw.Stop();

                scenesJson["scenes"] = sceneArray;
                scenesJson["sceneCount"] = (double)sceneArray.Count;
                File.WriteAllText(Path.Combine(OutDir, "scenes.json"), Serialize(scenesJson), new UTF8Encoding(false));

                probe["renderTargetBitmapUsable"] = true;
                probe["sceneCount"] = (double)sceneArray.Count;
                probe["totalProbes"] = (double)SumProbes(sceneArray);
                probe["predictionsChecked"] = (double)totalExpectChecked;
                probe["predictionsFailed"] = (double)totalExpectFailed;
                probe["pngs"] = pngIndex;
                probe["elapsedSeconds"] = Math.Round(sw.Elapsed.TotalSeconds, 3);
                probe["log"] = ToObjList(Log);
            }
            catch (Exception ex)
            {
                probe["renderTargetBitmapUsable"] = false;
                probe["fatal"] = ex.GetType().FullName + ": " + ex.Message;
                probe["fatalStackTrace"] = ex.StackTrace ?? "";
                Say("FATAL " + ex);
                try { File.WriteAllText(Path.Combine(OutDir, "probe.json"), Serialize(probe), new UTF8Encoding(false)); } catch { }
                return 2;
            }

            File.WriteAllText(Path.Combine(OutDir, "probe.json"), Serialize(probe), new UTF8Encoding(false));
            Say("WROTE " + Path.Combine(OutDir, "scenes.json"));
            Say("WROTE " + Path.Combine(OutDir, "probe.json"));
            return 0;
        }

        private static List<object> ToObjList(List<string> src)
        {
            var r = new List<object>();
            foreach (var s in src) r.Add(s);
            return r;
        }

        private static double SumProbes(List<object> scenes)
        {
            double n = 0;
            foreach (var s in scenes) n += J.N(((Dictionary<string, object>)s)["probeCount"]);
            return n;
        }

        private static void AnnotateComposites(List<object> ops)
        {
            foreach (object raw in ops)
            {
                var op = (Dictionary<string, object>)raw;
                string kind = J.S(op, "op");
                if (kind == "transform")
                {
                    Matrix m = R.MatrixOf(op);
                    op["composite"] = L(m.M11, m.M12, m.M21, m.M22, m.OffsetX, m.OffsetY);
                    AnnotateComposites((List<object>)op["children"]);
                }
                else if (kind == "opacity" || kind == "clip")
                {
                    AnnotateComposites((List<object>)op["children"]);
                }
            }
        }

        private static IEnumerable<string> FindNativeCandidates()
        {
            var list = new List<string>();
            string baseDir = AppContext.BaseDirectory;
            list.Add(Path.Combine(baseDir, "wpfgfx_cor3.dll"));
            string pfd = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            string runtimeDir = System.Runtime.InteropServices.RuntimeEnvironment.GetRuntimeDirectory();
            list.Add(Path.Combine(runtimeDir, "wpfgfx_cor3.dll"));
            list.Add(Path.Combine(runtimeDir, "PresentationNative_cor3.dll"));
            list.Add(Path.Combine(runtimeDir, "D3DCompiler_47_cor3.dll"));
            // any other installed WindowsDesktop.App version, for the record
            string root = Path.Combine(pfd, "dotnet", "shared", "Microsoft.WindowsDesktop.App");
            if (Directory.Exists(root))
            {
                foreach (string d in Directory.GetDirectories(root))
                {
                    string c = Path.Combine(d, "wpfgfx_cor3.dll");
                    if (File.Exists(c) && !list.Contains(c)) list.Add(c);
                }
            }
            return list;
        }

        private static string FileVersionOf(string path)
        {
            try
            {
                var vi = FileVersionInfo.GetVersionInfo(path);
                return (vi.FileVersion ?? "") + " | product=" + (vi.ProductVersion ?? "");
            }
            catch (Exception e) { return "ERR " + e.Message; }
        }

        private static string Sha256OfFile(string path)
        {
            using (var sha = SHA256.Create())
            using (var fs = File.OpenRead(path))
            {
                var h = sha.ComputeHash(fs);
                var sb = new StringBuilder(h.Length * 2);
                foreach (byte b in h) sb.Append(b.ToString("x2", CultureInfo.InvariantCulture));
                return sb.ToString();
            }
        }

        private static string RunCapture(string exe, string arguments)
        {
            try
            {
                var psi = new ProcessStartInfo(exe, arguments)
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    StandardOutputEncoding = Encoding.UTF8,
                    StandardErrorEncoding = Encoding.UTF8,
                };
                psi.EnvironmentVariables["DOTNET_CLI_UI_LANGUAGE"] = "en";
                psi.EnvironmentVariables["DOTNET_NOLOGO"] = "1";
                psi.EnvironmentVariables["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1";
                using (var p = Process.Start(psi))
                {
                    string o = p.StandardOutput.ReadToEnd();
                    string e = p.StandardError.ReadToEnd();
                    p.WaitForExit(60000);
                    return o + (e.Length > 0 ? "\n[stderr]\n" + e : "");
                }
            }
            catch (Exception ex)
            {
                return "ERR " + ex.GetType().Name + ": " + ex.Message;
            }
        }
    }
}
