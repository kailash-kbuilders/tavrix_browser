/// A search provider. `%s` in [searchTemplate] is replaced by the query.
class SearchEngine {
  const SearchEngine({
    required this.id,
    required this.name,
    required this.searchTemplate,
    this.suggestTemplate,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String searchTemplate;
  final String? suggestTemplate;
  final bool isCustom;

  String urlFor(String query) =>
      searchTemplate.replaceAll('%s', Uri.encodeComponent(query));

  String? suggestUrlFor(String query) =>
      suggestTemplate?.replaceAll('%s', Uri.encodeComponent(query));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'searchTemplate': searchTemplate,
        'suggestTemplate': suggestTemplate,
        'isCustom': isCustom,
      };

  factory SearchEngine.fromJson(Map<String, dynamic> json) => SearchEngine(
        id: json['id'] as String? ?? 'custom',
        name: json['name'] as String? ?? 'Custom',
        searchTemplate: json['searchTemplate'] as String? ?? 'https://www.google.com/search?q=%s',
        suggestTemplate: json['suggestTemplate'] as String?,
        isCustom: json['isCustom'] as bool? ?? true,
      );

  static const List<SearchEngine> defaults = [
    SearchEngine(
      id: 'google',
      name: 'Google',
      searchTemplate: 'https://www.google.com/search?q=%s',
      suggestTemplate: 'https://suggestqueries.google.com/complete/search?client=firefox&q=%s',
    ),
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      searchTemplate: 'https://www.bing.com/search?q=%s',
      suggestTemplate: 'https://api.bing.com/osjson.aspx?query=%s',
    ),
    SearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      searchTemplate: 'https://duckduckgo.com/?q=%s',
      suggestTemplate: 'https://duckduckgo.com/ac/?q=%s&type=list',
    ),
    SearchEngine(
      id: 'yahoo',
      name: 'Yahoo',
      searchTemplate: 'https://search.yahoo.com/search?p=%s',
    ),
    SearchEngine(
      id: 'brave',
      name: 'Brave Search',
      searchTemplate: 'https://search.brave.com/search?q=%s',
    ),
    SearchEngine(
      id: 'ecosia',
      name: 'Ecosia',
      searchTemplate: 'https://www.ecosia.org/search?q=%s',
    ),
  ];
}
