// main.dart - GREEN THEME
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';
import 'page.dart';

void main() {
  runApp(const ArxivApp());
}

class ArxivApp extends StatelessWidget {
  const ArxivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cryptonite arXiv',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.green[700],
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
          primary: Colors.green[700]!,
          secondary: Colors.green[500]!,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[700],
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green[700],
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.green[50],
          selectedColor: Colors.green[100],
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> papers = [];
  bool loading = false;

  String field = 'all';
  String category = 'any';
  int maxResults = 20;

  final fields = {
    'all': 'All Fields',
    'ti': 'Title',
    'au': 'Author',
    'abs': 'Abstract',
  };

  final categories = {
    'any': 'All',
    'cs.AI': 'AI',
    'cs.CV': 'CV',
    'cs.LG': 'ML',
    'cs.CL': 'NLP',
    'cs.RO': 'Robotics',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 120,
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Cryptonite',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Search research papers',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => search(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFilterButton(
                        icon: Icons.tune,
                        label: fields[field]!,
                        onTap: showFieldPicker,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        icon: Icons.category,
                        label: categories[category]!,
                        onTap: showCategoryPicker,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        icon: Icons.filter_list,
                        label: '$maxResults results',
                        onTap: showMaxResultsPicker,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!loading && papers.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Search for research papers',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          if (!loading && papers.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => GoogleStylePaperCard(papers[i]),
                  childCount: papers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  void showFieldPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields.entries.map((e) {
            return RadioListTile<String>(
              title: Text(e.value),
              value: e.key,
              groupValue: field,
              onChanged: (v) {
                setState(() => field = v!);
                Navigator.pop(context);
                if (_controller.text.isNotEmpty) search();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void showCategoryPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.entries.map((e) {
            return RadioListTile<String>(
              title: Text(e.value),
              value: e.key,
              groupValue: category,
              onChanged: (v) {
                setState(() => category = v!);
                Navigator.pop(context);
                if (_controller.text.isNotEmpty) search();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void showMaxResultsPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Results'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$maxResults papers'),
              Slider(
                value: maxResults.toDouble(),
                min: 10,
                max: 50,
                divisions: 4,
                label: maxResults.toString(),
                onChanged: (v) => setDialogState(() => maxResults = v.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              if (_controller.text.isNotEmpty) search();
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  Future<void> search() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      loading = true;
      papers = [];
    });

    try {
      final query = _controller.text.trim();
      String searchQuery = 'all:${Uri.encodeComponent(query)}';
      
      if (category != 'any') {
        searchQuery += '+AND+cat:$category';
      }

      final url = 'http://export.arxiv.org/api/query?'
          'search_query=$searchQuery'
          '&max_results=200'
          '&sortBy=relevance'
          '&sortOrder=descending';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final entries = doc.findAllElements('entry').toList();

        final List<Map<String, dynamic>> results = [];
        final queryLower = query.toLowerCase();

        for (var entry in entries) {
          try {
            final id = _getText(entry, 'id').split('/abs/').last;
            final title = _getText(entry, 'title');
            final summary = _getText(entry, 'summary');
            final published = _getText(entry, 'published');

            final authorElements = entry.findAllElements('author').toList();
            final authors = authorElements
                .map((a) => _getText(a, 'name'))
                .where((n) => n.isNotEmpty)
                .toList();

            final titleLower = title.toLowerCase();
            int score = 0;
            if (titleLower == queryLower) score = 1000;
            else if (titleLower.contains(queryLower)) score = 500;
            else score = 100;

            results.add({
              'id': id,
              'title': title,
              'summary': summary,
              'authors': authors,
              'date': published.substring(0, 10),
              'pdf': 'https://arxiv.org/pdf/$id.pdf',
              'abstract': 'https://arxiv.org/abs/$id',
              'score': score,
            });
          } catch (e) {
            print('Parse error: $e');
          }
        }

        results.sort((a, b) => b['score'].compareTo(a['score']));
        final topResults = results.take(maxResults).toList();

        setState(() {
          papers = topResults;
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String _getText(xml.XmlElement element, String tag) {
    try {
      return element.findElements(tag).first.innerText.trim();
    } catch (e) {
      return '';
    }
  }
}

class GoogleStylePaperCard extends StatelessWidget {
  final Map<String, dynamic> paper;

  const GoogleStylePaperCard(this.paper, {super.key});

  @override
  Widget build(BuildContext context) {
    final authors = (paper['authors'] as List).cast<String>();
    final authorText = authors.take(3).join(', ') +
        (authors.length > 3 ? ' · ${authors.length - 3} more' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'arxiv.org › ${paper['id']}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Text(
                paper['date'],
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaperDetailsPage(paperId: paper['id']),
                ),
              );
            },
            child: Text(
              paper['title'],
              style: TextStyle(
                fontSize: 20,
                color: Colors.green[700],
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            authorText,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Text(
            paper['summary'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaperDetailsPage(paperId: paper['id']),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () => _launch(paper['pdf']),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
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
