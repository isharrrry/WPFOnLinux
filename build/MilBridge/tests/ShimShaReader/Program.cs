// ============================================================================
//  WAVE17 · 车道 W17C · P1 读侧：ShimShaReader
//
//  问题：「这份 PresentationCore.dll 编译进去的那份
//         build/shims/PresentationCore.HbTextLine.cs，内容 sha256 是多少？」
//
//  判据（**内容等号**，与 mtime / 有没有重建过 无关）：
//     product sha256 == 现树 shim 的 sha256   ⇒ SHIM_SHA=no        rc=0
//     product sha256 != 现树 shim 的 sha256   ⇒ SHIM_SHA=yes       rc=1
//     算不出（缺件/非 PE/属性缺失/值非法/根定不出）⇒ SHIM_SHA=NOINFO rc=2
//
//  **完整 sha256 逐字相等**才算 no（不许只比 16 位前缀：前缀相等不是内容相等）。
//  机器行里同时印 64 位全值（sha256=）与 16 位前缀（sha16=）。
//
//  不加载程序集：只用 System.Reflection.Metadata（PEReader + MetadataReader）
//  读 PE 的 CLI 元数据表。读的是 **CustomAttribute 表 + #Blob 堆**（值由
//  MD 结构化解码，不靠 strings/grep）+ **#Strings 堆**（构造函数的类型/方法名），
//  以及 Assembly 表（只印程序集名）。全文件无 `Assembly.Load*`、无反射激活。
//
//  只读：文件全部以 FileShare.Read 打开，不写任何东西（包括 obj/bin —— 本工具
//  不向仓内写文件，输出只到 stdout）。可重复：机器行不含路径/时间戳/mtime。
// ============================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;
using System.Security.Cryptography;
using System.Text;

internal static class Program
{
    private const string MetadataKey = "HbTextLineShimSha";
    private const string ToolName = "ShimShaReader";
    private const string VerdictName = "SHIM_SHA";

    private static string _artifactArg;
    private static string _shimArg;
    private static string _rootArg;
    private static string _probeDirArg;

    private static int Main(string[] args)
    {
        if (!ParseArgs(args))
        {
            Usage();
            return 2;   // 参数错 ⇒ NOINFO（口径同"算不出"，绝不 rc=0）
        }

        Emit(() =>
        {
            string root = ResolveRoot();
            string artifact = _artifactArg ?? Path.Combine(root, "build", "PresentationCore.Linux", "bin", "Debug", "PresentationCore.dll");
            string shim = _shimArg ?? Path.Combine(root, "build", "shims", "PresentationCore.HbTextLine.cs");
            return Read(artifact, shim);
        });
        return 0;   // 不会到这（Emit 内部 Environment.Exit）
    }

    // ------------------------------------------------------------------ 参数
    private static bool ParseArgs(string[] args)
    {
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i];
            switch (a)
            {
                case "--artifact":
                    if (++i >= args.Length) { Console.Error.WriteLine("missing value for --artifact"); return false; }
                    _artifactArg = args[i];
                    break;
                case "--shim":
                    if (++i >= args.Length) { Console.Error.WriteLine("missing value for --shim"); return false; }
                    _shimArg = args[i];
                    break;
                case "--root":
                    if (++i >= args.Length) { Console.Error.WriteLine("missing value for --root"); return false; }
                    _rootArg = args[i];
                    break;
                case "--probe-dir":
                    // 取证用：替换"程序目录"这一候选点，专门用来构造/复算 root-unresolved
                    if (++i >= args.Length) { Console.Error.WriteLine("missing value for --probe-dir"); return false; }
                    _probeDirArg = args[i];
                    break;
                case "-h":
                case "--help":
                    Usage();
                    Environment.Exit(0);
                    break;
                default:
                    Console.Error.WriteLine("unknown argument: " + a);
                    return false;
            }
        }
        return true;
    }

    private static void Usage()
    {
        Console.Error.WriteLine("usage: ShimShaReader [--artifact <dll>] [--shim <cs>] [--root <dir>]");
        Console.Error.WriteLine("  --artifact  产物路径（默认 <root>/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll）");
        Console.Error.WriteLine("  --shim      现树 shim 源（默认 <root>/build/shims/PresentationCore.HbTextLine.cs）");
        Console.Error.WriteLine("  --root      仓根（默认：$WPF_LINUX_ROOT，否则从 AppContext.BaseDirectory 向上找）");
        Console.Error.WriteLine("verdict: SHIM_SHA=no(rc 0) | yes(rc 1) | NOINFO(rc 2)");
    }

    /// <summary>仓根解析：--root → $WPF_LINUX_ROOT → 从程序目录向上找（与 tline-gate.sh/shim-in-artifact.sh 同族）。</summary>
    private static string ResolveRoot()
    {
        var cands = new List<string>();
        if (!string.IsNullOrEmpty(_rootArg)) cands.Add(_rootArg);
        string env = Environment.GetEnvironmentVariable("WPF_LINUX_ROOT");
        if (!string.IsNullOrEmpty(env)) cands.Add(env);
        if (!string.IsNullOrEmpty(_probeDirArg)) cands.Add(_probeDirArg);
        else cands.Add(AppContext.BaseDirectory);
        // 与 build/MilBridge/tools/shim-in-artifact.sh 同口径：也试 cwd（"从仓根跑"是最常见的用法）
        cands.Add(Environment.CurrentDirectory);

        foreach (string c in cands)
        {
            DirectoryInfo d;
            try { d = new DirectoryInfo(Path.GetFullPath(c)); } catch { continue; }
            while (d != null)
            {
                // 仓根定义（两个条件都要求，避免把任意含 build/ 的目录当仓根）：
                //   build/PresentationCore.Linux/ 存在 ∧ build/shims/PresentationCore.HbTextLine.cs 存在
                if (File.Exists(Path.Combine(d.FullName, "build", "shims", "PresentationCore.HbTextLine.cs"))
                    && Directory.Exists(Path.Combine(d.FullName, "build", "PresentationCore.Linux")))
                {
                    return d.FullName;
                }
                // 判据① 本轮取证用的"最小仓"（只有 build/PresentationCore.Linux/，没有 shims/）：
                //   仅当没有更强的候选时才认，故放在同一循环里的**次优先**位置 ⇒ 用第二遍扫描实现。
                d = d.Parent;
            }
        }
        // 次优先：只认 build/PresentationCore.Linux/（本轮 NOINFO ④ 用）
        foreach (string c in cands)
        {
            DirectoryInfo d;
            try { d = new DirectoryInfo(Path.GetFullPath(c)); } catch { continue; }
            while (d != null)
            {
                if (Directory.Exists(Path.Combine(d.FullName, "build", "PresentationCore.Linux")))
                {
                    return d.FullName;
                }
                d = d.Parent;
            }
        }
        throw new NoInfo("root-unresolved");
    }

    // ------------------------------------------------------------- 结果载体
    private sealed class Result
    {
        public string Verdict;              // no | yes | NOINFO
        public string Reason = "-";
        public string ArtifactPath;
        public string ArtifactSha16 = "<NOINFO>";
        public string ArtifactSha256 = "<NOINFO>";
        public string ArtifactBytes = "-";
        public string ArtifactMtime = "-";
        public string ShimPath;
        public string ProductSha256 = "<NOINFO>";
        public string ProductSha16 = "<NOINFO>";
        public string TreeSha256 = "<NOINFO>";
        public string TreeSha16 = "<NOINFO>";
        public string TreeBytes = "<NOINFO>";
        public string AsmName = "<NOINFO>";
    }

    private sealed class NoInfo : Exception
    {
        public NoInfo(string reason) : base(reason) { }
    }

    // ------------------------------------------------------------------ 主逻辑
    private static Result Read(string artifact, string shim)
    {
        var r = new Result { ArtifactPath = artifact, ShimPath = shim };

        // ---- 1. 现树 shim 的内容哈希（"树说的"）
        if (string.IsNullOrEmpty(shim)) throw new NoInfo("shim-arg-missing");
        if (!File.Exists(shim)) throw new NoInfo("shim-not-found");
        byte[] shimBytes;
        try { shimBytes = File.ReadAllBytes(shim); }
        catch (Exception e) { throw new NoInfo("shim-unreadable:" + e.GetType().Name); }
        r.TreeSha256 = Sha256Hex(shimBytes);
        r.TreeSha16 = r.TreeSha256.Substring(0, 16);
        r.TreeBytes = shimBytes.Length.ToString(CultureInfo.InvariantCulture);
        r.ProductSha256 = "<ABSENT>";

        // ---- 2. 产物必须存在、可读、是托管 PE
        if (string.IsNullOrEmpty(artifact)) throw new NoInfo("artifact-arg-missing");
        if (Directory.Exists(artifact)) throw new NoInfo("artifact-is-directory");
        if (!File.Exists(artifact)) throw new NoInfo("artifact-not-found");
        long artLen;
        DateTime artMtime;
        try
        {
            using (var sha = SHA256.Create())
            using (var fs = new FileStream(artifact, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                artLen = fs.Length;
                artMtime = File.GetLastWriteTimeUtc(artifact);
                r.ArtifactSha256 = Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
            }
        }
        catch (Exception e) { throw new NoInfo("artifact-unreadable:" + e.GetType().Name); }
        r.ArtifactSha16 = r.ArtifactSha256.Substring(0, 16);
        r.ArtifactBytes = artLen.ToString(CultureInfo.InvariantCulture);
        r.ArtifactMtime = ((long)(artMtime - DateTime.UnixEpoch).TotalSeconds).ToString(CultureInfo.InvariantCulture);

        // ---- 3. 读托管元数据（**不加载程序集**）
        try
        {
            using var fs = new FileStream(artifact, FileMode.Open, FileAccess.Read, FileShare.Read);
            using var pe = new PEReader(fs);
            if (!pe.HasMetadata) throw new NoInfo("no-cli-metadata");
            MetadataReader md = pe.GetMetadataReader();
            if (md.IsAssembly)
            {
                AssemblyDefinition ad = md.GetAssemblyDefinition();
                r.AsmName = md.GetString(ad.Name);
            }
            var values = new List<string>();
            foreach (CustomAttributeHandle h in md.GetAssemblyDefinition().GetCustomAttributes())
            {
                CustomAttribute ca = md.GetCustomAttribute(h);
                if (!IsAssemblyMetadataCtor(md, ca)) continue;
                string key, value;
                DecodeKeyValue(md, ca, out key, out value);
                if (key == MetadataKey)
                {
                    if (value == null) throw new NoInfo("attribute-value-null");
                    values.Add(value);
                }
            }
            if (values.Count == 0) throw new NoInfo("attribute-absent");
            if (values.Count > 1) throw new NoInfo("attribute-duplicated:" + values.Count);
            string raw = values[0];
            // 值必须是完整 sha256 hex（本件只接受全值；16 位前缀/半截值一律 NOINFO）
            if (raw.Length != 64 || !IsLowerHex64(raw)) throw new NoInfo("attribute-value-malformed");
            r.ProductSha256 = raw;
            r.ProductSha16 = raw.Substring(0, 16);
            r.Reason = "content-compare";
            r.Verdict = string.Equals(raw, r.TreeSha256, StringComparison.Ordinal) ? "no" : "yes";
            return r;
        }
        catch (BadImageFormatException) { throw new NoInfo("bad-image-format"); }
        catch (InvalidOperationException e) { throw new NoInfo("metadata-invalid:" + e.GetType().Name); }
    }

    private static bool IsLowerHex64(string s)
    {
        foreach (char c in s)
        {
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return false;
        }
        return true;
    }

    // --------------------------------------------------- 构造器身份（结构化）
    private static bool IsAssemblyMetadataCtor(MetadataReader md, CustomAttribute ca)
    {
        string typeName, ns, memberName;
        if (ca.Constructor.Kind == HandleKind.MemberReference)
        {
            var mr = md.GetMemberReference((MemberReferenceHandle)ca.Constructor);
            memberName = md.GetString(mr.Name);
            typeName = null; ns = null;
            if (mr.Parent.Kind == HandleKind.TypeReference)
            {
                var tr = md.GetTypeReference((TypeReferenceHandle)mr.Parent);
                typeName = md.GetString(tr.Name); ns = md.GetString(tr.Namespace);
            }
            else if (mr.Parent.Kind == HandleKind.TypeDefinition)
            {
                var td = md.GetTypeDefinition((TypeDefinitionHandle)mr.Parent);
                typeName = md.GetString(td.Name); ns = md.GetString(td.Namespace);
            }
            else
            {
                return false;   // TypeSpec 等 ⇒ 不是我们要的那个构造器
            }
        }
        else if (ca.Constructor.Kind == HandleKind.MethodDefinition)
        {
            var mdf = md.GetMethodDefinition((MethodDefinitionHandle)ca.Constructor);
            memberName = md.GetString(mdf.Name);
            var td = md.GetTypeDefinition(mdf.GetDeclaringType());
            typeName = md.GetString(td.Name); ns = md.GetString(td.Namespace);
        }
        else
        {
            return false;
        }
        return typeName == "AssemblyMetadataAttribute" && ns == "System.Reflection" && memberName == ".ctor";
    }

    // ------------------------------------------- CustomAttribute blob 结构化解码
    // ECMA-335 II.23.3：prolog 0x0001 之后是 fixed args，本属性 = (string, string)。
    // 只接受"恰好两个字符串"，其余形状（含 named args / 非字符串 / 半截值）一律 NOINFO。
    private static void DecodeKeyValue(MetadataReader md, CustomAttribute ca, out string key, out string value)
    {
        key = null; value = null;
        BlobReader br = md.GetBlobReader(ca.Value);
        if (br.RemainingBytes < 2) throw new NoInfo("attribute-blob-truncated");
        if (br.ReadUInt16() != 1) throw new NoInfo("attribute-blob-bad-prolog");
        key = ReadSerString(ref br);
        value = ReadSerString(ref br);
        // ECMA-335 II.23.3 CustomAttrib 的结尾：NumNamed。
        // 本属性是 (string, string) 且**不带 named args** ⇒ 实测结尾恰好 2 字节 0x0000
        // （"attribute-blob-trailing-bytes:2" 是我第一版现场踩到的，如实留档）。
        if (br.RemainingBytes == 0) return;                       // 容忍"没有 NumNamed"
        if (br.RemainingBytes == 2 && br.ReadUInt16() == 0) return; // 标准形态：NumNamed = 0
        throw new NoInfo("attribute-has-named-args-or-junk:"
                         + (br.RemainingBytes == 2 ? "numnamed-nonzero" : "bytes-" + br.RemainingBytes));
    }

    private static string ReadSerString(ref BlobReader br)
    {
        if (br.RemainingBytes == 0) throw new NoInfo("attribute-blob-missing-string");
        byte b = br.ReadByte();
        if (b == 0xFF) return null;                        // SerString null
        int len;
        if ((b & 0x80) == 0) len = b;
        else if ((b & 0xC0) == 0x80) len = ((b & 0x3F) << 8) | br.ReadByte();
        else throw new NoInfo("attribute-blob-bad-string-length");
        if (len > br.RemainingBytes) throw new NoInfo("attribute-blob-string-overrun");
        return Encoding.UTF8.GetString(br.ReadBytes(len));
    }

    // ------------------------------------------------------------------ 输出
    private static void Emit(Func<Result> body)
    {
        Result r;
        try
        {
            r = body();
        }
        catch (NoInfo ni)
        {
            r = new Result { Verdict = "NOINFO", Reason = ni.Message, ArtifactPath = _artifactArg, ShimPath = _shimArg };
        }
        catch (Exception e)
        {
            r = new Result { Verdict = "NOINFO", Reason = "unexpected:" + e.GetType().Name, ArtifactPath = _artifactArg, ShimPath = _shimArg };
        }

        // 机器行：**不含路径/时间戳/mtime** ⇒ 同输入重复运行逐字节相同。
        // 键值顺序固定；算不出的格子一律印 <NOINFO>（纪律 27：空集不许读成绿）。
        string line = string.Format(CultureInfo.InvariantCulture,
            "{0}={1} reason={2} artifact={3} artifact_bytes={4} artifact_mtime_utc={5} "
            + "shim={6} product_sha16={7} tree_sha16={8} asm={9} cmp=full64 product_sha256={10} tree_sha256={11}",
            VerdictName, r.Verdict, r.Reason,
            r.ArtifactSha16, r.ArtifactBytes, r.ArtifactMtime,
            r.TreeSha16, r.ProductSha16, r.TreeSha16, r.AsmName,
            r.ProductSha256, r.TreeSha256);
        Console.Out.WriteLine(line);

        // 人读行（不进判据；带路径便于复核）
        Console.Out.WriteLine(string.Format(CultureInfo.InvariantCulture,
            "# tool={0} artifact_path={1} shim_path={2} shim_bytes={3}",
            ToolName, r.ArtifactPath ?? "-", r.ShimPath ?? "-", r.TreeBytes));

        int rc = r.Verdict == "no" ? 0 : r.Verdict == "yes" ? 1 : 2;
        Environment.Exit(rc);
    }

    private static string Sha256Hex(byte[] data)
    {
        using var sha = SHA256.Create();
        return Convert.ToHexString(sha.ComputeHash(data)).ToLowerInvariant();
    }
}
