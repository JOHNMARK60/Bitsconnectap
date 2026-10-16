import 'package:flutter/material.dart';

class AnnouncementContent extends StatelessWidget {
  const AnnouncementContent({
    required this.html,
    required this.fallbackText,
    this.baseStyle,
    super.key,
  });

  final String html;
  final String fallbackText;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final style =
        baseStyle ??
        const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.45);
    final blocks = _parseAnnouncementBlocks(html, fallbackText);

    if (blocks.isEmpty) {
      return Text(fallbackText, style: style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < blocks.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == blocks.length - 1 ? 0 : 10,
            ),
            child: _AnnouncementBlockView(block: blocks[index], style: style),
          ),
      ],
    );
  }
}

String announcementHtmlFromMap(Map<String, dynamic> item) {
  return _firstNonEmpty([
    item['message_html'],
    item['content_html'],
    item['html'],
    item['message'],
    item['content'],
  ]);
}

String announcementTextFromMap(Map<String, dynamic> item) {
  return _firstNonEmpty([
    item['message'],
    item['content'],
    _plainText(announcementHtmlFromMap(item)),
  ]);
}

class _AnnouncementBlockView extends StatelessWidget {
  const _AnnouncementBlockView({required this.block, required this.style});

  final _AnnouncementBlock block;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final child = Text.rich(
      TextSpan(children: _inlineSpans(block.html, style)),
      textAlign: block.align,
      style: style,
    );

    if (!block.isListItem) {
      return Padding(
        padding: EdgeInsets.only(left: block.indent),
        child: child,
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: block.indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              block.number == null ? '\u2022' : '${block.number}.',
              textAlign: TextAlign.right,
              style: style.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AnnouncementBlock {
  const _AnnouncementBlock({
    required this.html,
    required this.align,
    required this.indent,
    this.number,
    this.bullet = false,
  });

  final String html;
  final TextAlign align;
  final double indent;
  final int? number;
  final bool bullet;

  bool get isListItem => bullet || number != null;
}

List<_AnnouncementBlock> _parseAnnouncementBlocks(
  String html,
  String fallback,
) {
  final cleaned = _removeUnsafe(html).replaceAll('\r\n', '\n');
  final blockPattern = RegExp(
    r'<(p|div|li)\b([^>]*)>(.*?)</\1>|<br\s*/?>',
    caseSensitive: false,
    dotAll: true,
  );
  final blocks = <_AnnouncementBlock>[];
  var lastListKey = '';
  var number = 0;

  for (final match in blockPattern.allMatches(cleaned)) {
    final tag = match.group(1)?.toLowerCase();
    if (tag == null) continue;

    final inner = match.group(3) ?? '';
    if (_plainText(inner).isEmpty) continue;

    final attrs = match.group(2) ?? '';
    final listContext = tag == 'li'
        ? _listContextAt(cleaned, match.start)
        : null;
    if (listContext?.key != lastListKey) {
      number = 0;
      lastListKey = listContext?.key ?? '';
    }
    if (listContext?.ordered == true) number++;

    blocks.add(
      _AnnouncementBlock(
        html: inner,
        align: _textAlign(attrs),
        indent: _indent(attrs) + (tag == 'li' ? 4 : 0),
        number: listContext?.ordered == true ? number : null,
        bullet: listContext != null && !listContext.ordered,
      ),
    );
  }

  if (blocks.isNotEmpty) return blocks;

  return _plainText(cleaned).isNotEmpty || fallback.trim().isNotEmpty
      ? [
          _AnnouncementBlock(
            html: cleaned.trim().isNotEmpty ? cleaned : fallback,
            align: TextAlign.left,
            indent: 0,
          ),
        ]
      : const [];
}

List<TextSpan> _inlineSpans(String html, TextStyle baseStyle) {
  final cleaned = _removeUnsafe(
    html,
  ).replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  final tagPattern = RegExp(
    r'<(/?)(strong|b|em|i|u)\b[^>]*>',
    caseSensitive: false,
  );
  final spans = <TextSpan>[];
  var position = 0;
  var boldDepth = 0;
  var italicDepth = 0;
  var underlineDepth = 0;

  void addText(String value) {
    final decoded = _decodeHtml(value);
    if (decoded.isEmpty) return;
    spans.add(
      TextSpan(
        text: decoded,
        style: baseStyle.copyWith(
          fontWeight: boldDepth > 0 ? FontWeight.w800 : FontWeight.w400,
          fontStyle: italicDepth > 0 ? FontStyle.italic : FontStyle.normal,
          decoration: underlineDepth > 0 ? TextDecoration.underline : null,
        ),
      ),
    );
  }

  for (final match in tagPattern.allMatches(cleaned)) {
    addText(_stripTags(cleaned.substring(position, match.start)));
    final closing = match.group(1) == '/';
    final tag = match.group(2)?.toLowerCase();
    final delta = closing ? -1 : 1;
    if (tag == 'strong' || tag == 'b') {
      boldDepth = (boldDepth + delta).clamp(0, 99).toInt();
    } else if (tag == 'em' || tag == 'i') {
      italicDepth = (italicDepth + delta).clamp(0, 99).toInt();
    } else if (tag == 'u') {
      underlineDepth = (underlineDepth + delta).clamp(0, 99).toInt();
    }
    position = match.end;
  }

  addText(_stripTags(cleaned.substring(position)));
  return spans.isEmpty ? [TextSpan(text: _plainText(cleaned))] : spans;
}

_ListContext? _listContextAt(String html, int index) {
  final before = html.substring(0, index).toLowerCase();
  final lastOl = before.lastIndexOf('<ol');
  final lastUl = before.lastIndexOf('<ul');
  final lastCloseOl = before.lastIndexOf('</ol');
  final lastCloseUl = before.lastIndexOf('</ul');

  if (lastOl > lastCloseOl && lastOl > lastUl) {
    return _ListContext(ordered: true, key: 'ol-$lastOl');
  }
  if (lastUl > lastCloseUl) {
    return _ListContext(ordered: false, key: 'ul-$lastUl');
  }

  return const _ListContext(ordered: false, key: 'loose-list');
}

class _ListContext {
  const _ListContext({required this.ordered, required this.key});

  final bool ordered;
  final String key;
}

TextAlign _textAlign(String attrs) {
  final match = RegExp(
    r'text-align\s*:\s*(left|center|right|justify)',
    caseSensitive: false,
  ).firstMatch(attrs);
  return switch (match?.group(1)?.toLowerCase()) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => TextAlign.left,
  };
}

double _indent(String attrs) {
  final match = RegExp(
    r'(?:margin-left|padding-left)\s*:\s*(\d{1,3}(?:\.\d{1,2})?)(px|em|rem)',
    caseSensitive: false,
  ).firstMatch(attrs);
  if (match == null) return 0;
  final value = double.tryParse(match.group(1) ?? '') ?? 0;
  final unit = match.group(2)?.toLowerCase();
  final pixels = unit == 'em' || unit == 'rem' ? value * 16 : value;
  return pixels.clamp(0, 72).toDouble();
}

String _removeUnsafe(String value) {
  return value
      .replaceAll(
        RegExp(
          r'<(script|style)\b[^>]*>.*?</\1>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      )
      .replaceAll(
        RegExp(r'''\s+on\w+\s*=\s*(["']).*?\1''', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), '');
}

String _plainText(String html) {
  final spaced = _removeUnsafe(html).replaceAll(
    RegExp(r'<\/?(p|div|li|ul|ol|br)\b[^>]*>', caseSensitive: false),
    ' ',
  );
  return _decodeHtml(_stripTags(spaced)).replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _stripTags(String value) {
  return value.replaceAll(RegExp(r'<[^>]+>'), '');
}

String _decodeHtml(String value) {
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        final codePoint = int.tryParse(match.group(1) ?? '');
        return codePoint == null
            ? match.group(0)!
            : String.fromCharCode(codePoint);
      });
}

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
