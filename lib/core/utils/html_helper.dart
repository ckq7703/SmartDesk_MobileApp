import 'package:html_unescape/html_unescape.dart';

class HtmlHelper {
  static final _htmlUnescape = HtmlUnescape();

  static String stripHtml(String htmlText) {
    if (htmlText.isEmpty) return htmlText;

    try {
      // 1. Decode HTML entities
      String decodedText = _htmlUnescape.convert(htmlText);

      // 2. Remove HTML tags
      decodedText = decodedText.replaceAll(RegExp(r'<[^>]*>'), '');

      // 3. Clean up whitespace and special characters
      decodedText = decodedText
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('&nbsp;', ' ')
          .trim();

      return decodedText;
    } catch (e) {
      // Fallback: basic cleanup
      return htmlText
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
    }
  }

  static String getPreview(String text, {int maxLength = 120}) {
    final cleaned = stripHtml(text);
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength)}...';
  }
}
