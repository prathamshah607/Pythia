import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';
import 'page.dart';
import 'news.dart';

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
      home: const HomeWithTabs(),
    );
  }
}

class HomeWithTabs extends StatefulWidget {
  const HomeWithTabs({super.key});
  @override
  State<HomeWithTabs> createState() => _HomeWithTabsState();
}

class _HomeWithTabsState extends State<HomeWithTabs> {
  final TextEditingController _searchController =
      TextEditingController(text: '');
  String query = '';
  int searchNonce = 0;
  int currentIndex = 0;

  void _submitSearch() {
    setState(() {
      query = _searchController.text.trim();
      searchNonce++;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // List of the pages to make switching easy
    final pages = [
      HomePage(query: query, searchNonce: searchNonce),
      GoogleAINewsPage(query: query, searchNonce: searchNonce),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Row(
  children: [
    Image.network(
      'https://cryptonitemit.in/assets/logos/cryptonite-outline.png',
      height: 32,
      width: 48,
      color: Colors.green[900],     // adjust if you want it more/less wide
      fit: BoxFit.contain,
    ),
    const SizedBox(width: 18),
    Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search AI or research papers',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: (_) => _submitSearch(),
        ),
      ),
    ),
  ],
),

      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => setState(() => currentIndex = idx),
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'arXiv',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Updates',
          ),
        ],
      ),
    );
  }
}

// ---------------- ARXIV PAGE ------------------

class HomePage extends StatefulWidget {
  final String query;
  final int searchNonce;
  const HomePage({super.key, required this.query, required this.searchNonce});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  int lastSearchNonce = -1;

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.searchNonce != widget.searchNonce) {
      if (widget.query.isNotEmpty) search();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) search();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters Row (ONLY this remains as subheader)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
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
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : papers.isEmpty
                  ? const Center(
                      child: Text('Search for research papers',
                          style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 160, vertical: 20),
                      itemCount: papers.length,
                      itemBuilder: (context, i) =>
                          GoogleStylePaperCard(papers[i]),
                    ),
        ),
      ],
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
                if (widget.query.isNotEmpty) search();
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
                if (widget.query.isNotEmpty) search();
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
              if (widget.query.isNotEmpty) search();
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  Future<void> search() async {
    setState(() {
      loading = true;
      papers = [];
    });

    final q = widget.query.trim();
    if (q.isEmpty) {
      setState(() => loading = false);
      return;
    }

    try {
      String searchQuery =
          '${field == "all" ? "all" : field}:${Uri.encodeComponent(q)}';

      if (category != 'any') {
        searchQuery += '+AND+cat:$category';
      }

      final url = 'http://export.arxiv.org/api/query?'
          'search_query=$searchQuery'
          '&max_results=$maxResults'
          '&sortBy=relevance'
          '&sortOrder=descending';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final entries = doc.findAllElements('entry').toList();

        final List<Map<String, dynamic>> results = [];
        for (var entry in entries) {
          try {
            final id = _getText(entry, 'id').split('/abs/').last;
            final title = _getText(entry, 'title');
            final summary = _getText(entry, 'summary');
            final published = _getText(entry, 'published');
            final authorsRaw = entry.findAllElements('author');
            final authors = authorsRaw
                .map((a) => _getText(a, 'name'))
                .where((n) => n.isNotEmpty)
                .toList();

            results.add({
              'id': id,
              'title': title,
              'summary': summary,
              'authors': authors,
              'date': published.substring(0, 10),
              'pdf': 'https://arxiv.org/pdf/$id.pdf',
              'abstract': 'https://arxiv.org/abs/$id',
            });
          } catch (_) {}
        }
        setState(() {
          papers = results;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  String _getText(xml.XmlElement element, String tag) {
    try {
      return element.findElements(tag).first.innerText.trim();
    } catch (_) {
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
              Text('arxiv.org › ${paper['id']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(width: 12),
              Text(paper['date'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PaperDetailsPage(paperId: paper['id']))),
            child: Text(
              paper['title'],
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.green[700],
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(height: 6),
          Text(authorText,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 10),
          Text(paper['summary'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[800], height: 1.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PaperDetailsPage(paperId: paper['id']))),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              TextButton.icon(
                onPressed: () => _launch(paper['pdf']),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
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
