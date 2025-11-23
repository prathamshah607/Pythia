import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as htmlparses;

class GoogleAINewsPage extends StatefulWidget {
  final String query;
  final int searchNonce;
  const GoogleAINewsPage({
    super.key,
    required this.query,
    required this.searchNonce,
  });

  @override
  State<GoogleAINewsPage> createState() => _GoogleAINewsPageState();
}

class _GoogleAINewsPageState extends State<GoogleAINewsPage> {
  List<Map<String, dynamic>> articles = [];
  bool loading = false;

  // Filter chips: only these 3
  final List<Map<String, String>> sortOptions = [
    {'label': 'Best Match', 'value': 'relevance'},
    {'label': 'Last 7 days', 'value': '7d'},
    {'label': 'Last 24h', 'value': '1d'},
  ];
  String sortOption = "relevance";

  @override
  void didUpdateWidget(covariant GoogleAINewsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.searchNonce != widget.searchNonce) {
      if (widget.query.isNotEmpty) fetchFeed();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) fetchFeed();
  }

  Widget _buildSortChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(
        children: [
          for (final opt in sortOptions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                label: Row(
                  children: [
                    if (opt['value'] == sortOption)
                      const Icon(Icons.filter_alt,
                          size: 16, color: Colors.green)
                    else
                      const SizedBox(width: 16), // keep label aligned
                    const SizedBox(width: 2),
                    Text(opt['label']!, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                selected: sortOption == opt['value'],
                selectedColor: Colors.green[100],
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: sortOption == opt['value']
                        ? Colors.green[400]!
                        : Colors.grey[300]!,
                  ),
                ),
                onSelected: (val) {
                  if (sortOption != opt['value']) {
                    setState(() => sortOption = opt['value']!);
                    if (widget.query.isNotEmpty) fetchFeed();
                  }
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSortChips(),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : articles.isEmpty
                  ? const Center(
                      child: Text(
                        'Search for AI news articles',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 160, vertical: 20),
                      itemCount: articles.length,
                      itemBuilder: (context, i) =>
                          GoogleNewsArticleCard(article: articles[i]),
                    ),
        ),
      ],
    );
  }

  Future<void> fetchFeed() async {
    setState(() {
      loading = true;
      articles = [];
    });
    final userQuery = widget.query.trim();
    final query = userQuery.isEmpty ? 'AI' : '$userQuery AI';

    String sortSuffix = "";
    if (sortOption == "1d") sortSuffix = "+when:1d";
    if (sortOption == "7d") sortSuffix = "+when:7d";

    final url =
        'https://news.google.com/rss/search?q=${Uri.encodeComponent(query + sortSuffix)}&hl=en-IN&gl=IN&ceid=IN:en';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final items = doc.findAllElements('item').toList();
        final List<Map<String, dynamic>> fetched = [];
        for (var item in items) {
          try {
            String fullTitle = item.findElements('title').first.innerText;
            // Split title and source (author)
            String title = fullTitle;
            String author = "";
            int sepIdx = fullTitle.lastIndexOf(" - ");
            if (sepIdx > 0) {
              title = fullTitle.substring(0, sepIdx).trim();
              author = fullTitle.substring(sepIdx + 3).trim();
            }
            final link = item.findElements('link').first.innerText;
            final pubDate = item.findElements('pubDate').first.innerText;
            final rawDesc = item.findElements('description').first.innerText;
            final description = htmlparses.parse(rawDesc).body?.text ?? '';
            fetched.add({
              'title': title,
              'author': author,
              'link': link,
              'pubDate': pubDate,
              'description': description,
            });
          } catch (_) {}
        }

        setState(() {
          articles = fetched;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }
}

// --- News Article Card ---
class GoogleNewsArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  const GoogleNewsArticleCard({required this.article, super.key});
  @override
  Widget build(BuildContext context) {
    // Show the author/source line if present
    final hasAuthor = (article['author'] as String?).toString().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAuthor)
            Row(
              children: [
                Icon(Icons.language, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  article['author'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  article['pubDate'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          if (!hasAuthor)
            Text(
              article['pubDate'],
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _launch(article['link']),
            child: Text(
              article['title'],
              style: TextStyle(
                fontSize: 20,
                color: Colors.green[700],
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            article['description'],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _launch(article['link']),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Read More'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
