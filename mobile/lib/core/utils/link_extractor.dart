class LinkExtractor {
  static final RegExp linkRegex = RegExp(
    r'https?:\/\/[^\s]+',
    caseSensitive: false,
  );

  static List<String> extractLinks(String text) {
    final matches = linkRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }
}
