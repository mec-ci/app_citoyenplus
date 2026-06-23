import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rendu HTML léger et sans dépendance externe.
///
/// Le contenu des actualités est rédigé via un éditeur riche (TipTap) côté
/// dashboard et stocké en HTML. L'application affichait ce HTML « en dur »
/// (balises visibles) car il était injecté dans un simple [Text]. Ce widget
/// interprète les balices générées par l'éditeur afin d'afficher un texte
/// correctement formaté.
///
/// Balises gérées : p, h1..h6, strong/b, em/i, u, s/strike/del, code, pre,
/// blockquote, ul/ol/li, hr, br, a, span, div. Les entités HTML usuelles sont
/// décodées (&amp;, &lt;, &nbsp;, &#39;, ...).
class SimpleHtmlView extends StatelessWidget {
  const SimpleHtmlView({
    super.key,
    required this.html,
    this.baseStyle,
  });

  final String html;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ??
        const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87);
    final blocks = _HtmlParser(base).parse(html);

    if (blocks.isEmpty) {
      return Text(htmlToPlainText(html), style: base);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

/// Convertit du HTML en texte brut lisible (sans balises), en préservant les
/// sauts de ligne des éléments de bloc. Utile pour les extraits (cartes) et le
/// partage.
String htmlToPlainText(String html) {
  if (html.isEmpty) return '';
  var text = html;
  // Les éléments de bloc et <br> deviennent des sauts de ligne.
  text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
  text = text.replaceAll(
    RegExp(r'</\s*(p|div|li|h[1-6]|blockquote|pre|tr)\s*>',
        caseSensitive: false),
    '\n',
  );
  // Retrait de toutes les balises restantes.
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = _decodeEntities(text);
  // Normalisation des espaces / sauts de ligne multiples.
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r' *\n *'), '\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}

String _decodeEntities(String input) {
  if (!input.contains('&')) return input;
  var out = input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#34;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&laquo;', '«')
      .replaceAll('&raquo;', '»')
      .replaceAll('&hellip;', '…')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&agrave;', 'à')
      .replaceAll('&ccedil;', 'ç')
      .replaceAll('&rsquo;', '’')
      .replaceAll('&lsquo;', '‘');
  // Entités numériques décimales (&#233;) et hexadécimales (&#xE9;).
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code != null ? String.fromCharCode(code) : m.group(0)!;
  });
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    return code != null ? String.fromCharCode(code) : m.group(0)!;
  });
  return out;
}

class _ListCtx {
  _ListCtx(this.ordered);
  final bool ordered;
  int counter = 0;
}

class _HtmlParser {
  _HtmlParser(this.base);

  final TextStyle base;

  final List<Widget> _blocks = [];
  final List<InlineSpan> _spans = [];
  final List<_ListCtx> _lists = [];

  // Marques inline actives.
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _strike = false;
  bool _code = false;
  String? _href;

  String _blockType = 'p';

  List<Widget> parse(String html) {
    if (html.trim().isEmpty) return _blocks;
    _tokenize(html);
    _flush();
    return _blocks;
  }

  void _tokenize(String html) {
    int i = 0;
    final len = html.length;
    while (i < len) {
      final lt = html.indexOf('<', i);
      if (lt < 0) {
        _addText(html.substring(i));
        break;
      }
      if (lt > i) {
        _addText(html.substring(i, lt));
      }
      final gt = html.indexOf('>', lt);
      if (gt < 0) {
        _addText(html.substring(lt));
        break;
      }
      _handleTag(html.substring(lt + 1, gt));
      i = gt + 1;
    }
  }

  void _addText(String raw) {
    if (raw.isEmpty) return;
    var text = _decodeEntities(raw).replaceAll(RegExp(r'\s+'), ' ');
    // On ignore le texte purement « blanc » entre deux blocs.
    if (text.trim().isEmpty && _spans.isEmpty) return;
    _spans.add(TextSpan(text: text, style: _currentStyle(), recognizer: _recognizer()));
  }

  TapGestureRecognizer? _recognizer() {
    final href = _href;
    if (href == null || href.isEmpty) return null;
    return TapGestureRecognizer()
      ..onTap = () {
        final uri = Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      };
  }

  TextStyle _currentStyle() {
    var s = base;
    if (_bold) s = s.copyWith(fontWeight: FontWeight.w700);
    if (_italic) s = s.copyWith(fontStyle: FontStyle.italic);
    final decorations = <TextDecoration>[];
    if (_underline || _href != null) decorations.add(TextDecoration.underline);
    if (_strike) decorations.add(TextDecoration.lineThrough);
    if (decorations.isNotEmpty) {
      s = s.copyWith(decoration: TextDecoration.combine(decorations));
    }
    if (_href != null) s = s.copyWith(color: const Color(0xFF1556B5));
    if (_code) {
      s = s.copyWith(
        fontFamily: 'monospace',
        backgroundColor: const Color(0xFFF0F0F0),
      );
    }
    return s;
  }

  void _handleTag(String tagContent) {
    var content = tagContent.trim();
    if (content.isEmpty || content.startsWith('!')) return; // commentaires / doctype

    final closing = content.startsWith('/');
    if (closing) content = content.substring(1).trim();

    // Nom de balise (avant un espace ou un '/').
    final match = RegExp(r'^[a-zA-Z0-9]+').firstMatch(content);
    if (match == null) return;
    final name = match.group(0)!.toLowerCase();

    switch (name) {
      case 'br':
        _spans.add(const TextSpan(text: '\n'));
        return;
      case 'hr':
        _flush();
        _blocks.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        ));
        return;
      case 'b':
      case 'strong':
        _bold = !closing;
        return;
      case 'i':
      case 'em':
        _italic = !closing;
        return;
      case 'u':
        _underline = !closing;
        return;
      case 's':
      case 'strike':
      case 'del':
        _strike = !closing;
        return;
      case 'code':
        _code = !closing;
        return;
      case 'a':
        if (closing) {
          _href = null;
        } else {
          _href = _extractHref(content);
        }
        return;
      case 'span':
        return; // pas de style spécifique
      case 'p':
      case 'div':
        _flush();
        _blockType = 'p';
        return;
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _flush();
        _blockType = closing ? 'p' : name;
        return;
      case 'blockquote':
        _flush();
        _blockType = closing ? 'p' : 'blockquote';
        return;
      case 'pre':
        _flush();
        _blockType = closing ? 'p' : 'pre';
        return;
      case 'ul':
      case 'ol':
        if (closing) {
          if (_lists.isNotEmpty) _lists.removeLast();
        } else {
          _lists.add(_ListCtx(name == 'ol'));
        }
        return;
      case 'li':
        if (closing) {
          _flush();
        } else {
          _flush();
          _blockType = 'li';
          if (_lists.isNotEmpty) _lists.last.counter++;
        }
        return;
      default:
        return;
    }
  }

  String? _extractHref(String content) {
    final m = RegExp(r'''href\s*=\s*["']([^"']*)["']''').firstMatch(content);
    return m?.group(1);
  }

  void _flush() {
    if (_spans.isEmpty) return;
    final spans = List<InlineSpan>.from(_spans);
    _spans.clear();

    final widget = _buildBlock(_blockType, spans);
    if (widget != null) _blocks.add(widget);
    _blockType = 'p';
  }

  Widget? _buildBlock(String type, List<InlineSpan> spans) {
    // Évite les blocs vides (uniquement des espaces).
    final hasContent = spans.any((s) =>
        s is! TextSpan || (s.text != null && s.text!.trim().isNotEmpty));
    if (!hasContent) return null;

    switch (type) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(type.substring(1));
        final scale = [1.7, 1.5, 1.3, 1.15, 1.05, 1.0][level - 1];
        final size = (base.fontSize ?? 15) * scale;
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: RichText(
            text: TextSpan(
              style: base.copyWith(
                  fontSize: size, fontWeight: FontWeight.w800, height: 1.3),
              children: spans,
            ),
          ),
        );
      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFFBBBBBB), width: 3),
            ),
          ),
          child: RichText(
            text: TextSpan(
              style: base.copyWith(
                  fontStyle: FontStyle.italic, color: Colors.black54),
              children: spans,
            ),
          ),
        );
      case 'pre':
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: RichText(
            text: TextSpan(
              style: base.copyWith(fontFamily: 'monospace', fontSize: 13),
              children: spans,
            ),
          ),
        );
      case 'li':
        final depth = (_lists.length - 1).clamp(0, 6);
        final ordered = _lists.isNotEmpty && _lists.last.ordered;
        final marker = ordered ? '${_lists.last.counter}.' : '•';
        return Padding(
          padding: EdgeInsets.only(left: 4.0 + depth * 16, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: ordered ? 22 : 16,
                child: Text(marker, style: base),
              ),
              Expanded(
                child: RichText(text: TextSpan(style: base, children: spans)),
              ),
            ],
          ),
        );
      default: // paragraphe
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(text: TextSpan(style: base, children: spans)),
        );
    }
  }
}
