// B2/B3/B4 oracle · TextSource / TextRun / TextRunProperties / TextParagraphProperties 实现
//
// 这是 TextFormatter 公开 API 要求的四件套。刻意做得**最小**：
// 整段文本作为一个 TextCharacters run 交给 WPF，断行/断字由 WPF 自己决定
// （这正是我们要测的东西——不能被我们自己的切分策略污染）。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace WpfOracleLayout
{
    internal sealed class OracleTextSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;

        public OracleTextSource(string text, TextRunProperties props)
        {
            _text = text;
            _props = props;
        }

        public override TextRun GetTextRun(int textSourceCharacterIndex)
        {
            if (textSourceCharacterIndex < 0) throw new ArgumentOutOfRangeException(nameof(textSourceCharacterIndex));
            if (textSourceCharacterIndex >= _text.Length)
                return new TextEndOfParagraph(1);
            return new TextCharacters(_text, textSourceCharacterIndex,
                                      _text.Length - textSourceCharacterIndex, _props);
        }

        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int textSourceCharacterIndex)
            => textSourceCharacterIndex;

        /// <summary>本 oracle 不需要"前一段文本"（那是给 number substitution / 复杂脚本用的），返回空跨度。</summary>
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int textSourceCharacterIndexLimit)
        {
            var ccr = new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange());
            return new TextSpan<CultureSpecificCharacterBufferRange>(0, ccr);
        }
    }

    /// <summary>
    /// 带 TextModifier 的源：用来实测"TextLineBreak 什么时候非 null"。
    ///
    /// WPF 源码 TextMetrics.cs:299-308 写明：只有 `_lastRun.TextModifierScope != null`
    /// 且末 run 不是 TextEndOfParagraph 时才会 new 出 TextLineBreak，否则返回 null。
    /// 这段就是造出那个条件的公开手段（TextModifier 是公开抽象类）。
    /// </summary>
    internal sealed class OracleModifier : TextModifier
    {
        private readonly int _length;
        private readonly TextRunProperties _props;

        public OracleModifier(int length, TextRunProperties props) { _length = length; _props = props; }

        public override int Length => _length;
        public override TextRunProperties Properties => _props;
        public override TextRunProperties ModifyProperties(TextRunProperties properties) => properties;
        public override bool HasDirectionalEmbedding => false;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
    }

    internal sealed class OracleTextSourceWithModifier : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        private readonly int _modStart;
        private readonly int _modEnd;

        public OracleTextSourceWithModifier(string text, TextRunProperties props, int modStart, int modEnd)
        {
            _text = text; _props = props; _modStart = modStart; _modEnd = modEnd;
        }

        public override TextRun GetTextRun(int textSourceCharacterIndex)
        {
            if (textSourceCharacterIndex >= _text.Length) return new TextEndOfParagraph(1);
            if (textSourceCharacterIndex < _modStart)
                return new TextCharacters(_text, textSourceCharacterIndex,
                                          _modStart - textSourceCharacterIndex, _props);
            if (textSourceCharacterIndex < _modEnd)
                return new OracleModifier(_modEnd - textSourceCharacterIndex, _props);
            return new TextCharacters(_text, textSourceCharacterIndex,
                                      _text.Length - textSourceCharacterIndex, _props);
        }

        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;

        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int textSourceCharacterIndexLimit)
        {
            var ccr = new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange());
            return new TextSpan<CultureSpecificCharacterBufferRange>(0, ccr);
        }
    }

    internal sealed class OracleRunProperties : TextRunProperties
    {
        private readonly Typeface _typeface;
        private readonly double _emSize;
        private readonly CultureInfo _culture;

        public OracleRunProperties(Typeface typeface, double emSize, CultureInfo culture, double pixelsPerDip)
        {
            _typeface = typeface;
            _emSize = emSize;
            _culture = culture;
            PixelsPerDip = pixelsPerDip;   // 基类的可写属性（非 virtual），直接赋值
        }

        public override Typeface Typeface => _typeface;
        public override double FontRenderingEmSize => _emSize;
        public override double FontHintingEmSize => _emSize;
        public override Brush ForegroundBrush => Brushes.Black;
        public override Brush BackgroundBrush => null;
        public override CultureInfo CultureInfo => _culture;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
        public override BaselineAlignment BaselineAlignment => BaselineAlignment.Baseline;
        public override NumberSubstitution NumberSubstitution => null;
        public override TextRunTypographyProperties TypographyProperties => null;
    }

    internal sealed class OracleParagraphProperties : TextParagraphProperties
    {
        private readonly TextRunProperties _defaults;
        private readonly FlowDirection _flow;
        private readonly TextAlignment _align;
        private readonly TextWrapping _wrap;
        private readonly double _lineHeight;
        private readonly bool _firstLine;
        private readonly double _indent;
        private readonly double _paraIndent;
        private readonly bool _alwaysCollapsible;

        public OracleParagraphProperties(
            TextRunProperties defaults, FlowDirection flow, TextAlignment align, TextWrapping wrap,
            double lineHeight, bool firstLine, double indent, double paraIndent, bool alwaysCollapsible)
        {
            _defaults = defaults;
            _flow = flow;
            _align = align;
            _wrap = wrap;
            _lineHeight = lineHeight;
            _firstLine = firstLine;
            _indent = indent;
            _paraIndent = paraIndent;
            _alwaysCollapsible = alwaysCollapsible;
        }

        public override TextRunProperties DefaultTextRunProperties => _defaults;
        public override FlowDirection FlowDirection => _flow;
        public override TextAlignment TextAlignment => _align;
        public override TextWrapping TextWrapping => _wrap;
        public override double LineHeight => _lineHeight;      // 0 = 不指定（WPF 用字体自然行高）
        public override bool FirstLineInParagraph => _firstLine;
        public override double Indent => _indent;
        public override double ParagraphIndent => _paraIndent;
        public override bool AlwaysCollapsible => _alwaysCollapsible;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
        public override double DefaultIncrementalTab => 0;
    }
}
