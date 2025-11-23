// page.dart - WITH CATEGORY MAPPING
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';

class PaperDetailsPage extends StatefulWidget {
  final String paperId;

  const PaperDetailsPage({
    super.key,
    required this.paperId,
  });

  @override
  State<PaperDetailsPage> createState() => _PaperDetailsPageState();
}

class _PaperDetailsPageState extends State<PaperDetailsPage> {
  Map<String, dynamic>? paper;
  bool loading = true;
  String? error;

  // Category mapping
  final Map<String, String> categoryNames = {
    'cs.AI': 'Artificial Intelligence',
    'cs.CL': 'Computation and Language (NLP)',
    'cs.CV': 'Computer Vision',
    'cs.LG': 'Machine Learning',
    'cs.RO': 'Robotics',
    'cs.NE': 'Neural and Evolutionary Computing',
    'cs.CR': 'Cryptography and Security',
    'cs.DS': 'Data Structures and Algorithms',
    'cs.DB': 'Databases',
    'cs.IR': 'Information Retrieval',
    'cs.IT': 'Information Theory',
    'cs.DC': 'Distributed, Parallel, and Cluster Computing',
    'cs.GT': 'Computer Science and Game Theory',
    'cs.HC': 'Human-Computer Interaction',
    'cs.SE': 'Software Engineering',
    'stat.ML': 'Machine Learning (Statistics)',
    'math.OC': 'Optimization and Control',
    'eess.AS': 'Audio and Speech Processing',
    'eess.IV': 'Image and Video Processing',
    'eess.SP': 'Signal Processing',
  };

  String _getCategoryName(String code) {
    return categoryNames[code] ?? code;
  }

  @override
  void initState() {
    super.initState();
    fetchPaperDetails();
  }

  Future<void> fetchPaperDetails() async {
    try {
      final url = 'http://export.arxiv.org/api/query?id_list=${widget.paperId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final doc = xml.XmlDocument.parse(response.body);
        final entry = doc.findAllElements('entry').first;

        final id = _getText(entry, 'id').split('/abs/').last;
        final title = _getText(entry, 'title');
        final summary = _getText(entry, 'summary');
        final published = _getText(entry, 'published');
        final updated = _getText(entry, 'updated');
        final comment = _getText(entry, 'comment');
        final journalRef = _getText(entry, 'journal_ref');
        final doi = _getText(entry, 'doi');
        final primaryCategory = entry
            .findElements('primary_category')
            .firstOrNull
            ?.getAttribute('term') ?? '';

        final categories = entry
            .findAllElements('category')
            .map((c) => c.getAttribute('term') ?? '')
            .where((c) => c.isNotEmpty)
            .toList();

        final authorElements = entry.findAllElements('author').toList();
        final authors = authorElements
            .map((a) => _getText(a, 'name'))
            .where((n) => n.isNotEmpty)
            .toList();

        final links = entry.findAllElements('link').toList();
        String pdfUrl = 'https://arxiv.org/pdf/$id.pdf';
        for (var link in links) {
          if (link.getAttribute('title') == 'pdf') {
            pdfUrl = link.getAttribute('href') ?? pdfUrl;
          }
        }

        setState(() {
          paper = {
            'id': id,
            'title': title,
            'summary': summary,
            'authors': authors,
            'published': published.substring(0, 10),
            'updated': updated.substring(0, 10),
            'comment': comment,
            'journal_ref': journalRef,
            'doi': doi,
            'primary_category': primaryCategory,
            'categories': categories,
            'pdf': pdfUrl,
            'abstract': 'https://arxiv.org/abs/$id',
          };
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _getText(xml.XmlElement element, String tag) {
    try {
      return element.findElements(tag).first.innerText.trim();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || paper == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error loading paper: $error'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green[700]),
        title: Text(
          'Paper Details',
          style: TextStyle(color: Colors.green[700]),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  paper!['title'],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),

                // Authors
                _buildSection(
                  'Authors',
                  (paper!['authors'] as List).cast<String>().join(', '),
                ),

                // Published/Updated
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Published',
                        paper!['published'],
                        Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Updated',
                        paper!['updated'],
                        Icons.update,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Primary Category with readable name
                _buildSection(
                  'Primary Category',
                  _getCategoryName(paper!['primary_category']),
                ),

                // All Categories with readable names
                if ((paper!['categories'] as List).length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'All Categories',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (paper!['categories'] as List)
                            .cast<String>()
                            .map((cat) => Chip(
                                  label: Text(
                                    _getCategoryName(cat),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  backgroundColor: Colors.green[50],
                                ))
                            .toList(),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Abstract
                const Text(
                  'Abstract',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    paper!['summary'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Comments
                if (paper!['comment'].isNotEmpty)
                  _buildSection('Comments', paper!['comment']),

                // Journal Reference
                if (paper!['journal_ref'].isNotEmpty)
                  _buildSection('Journal Reference', paper!['journal_ref']),

                // DOI
                if (paper!['doi'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOI',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launch('https://doi.org/${paper!['doi']}'),
                        child: Text(
                          paper!['doi'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Action Buttons
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launch(paper!['pdf']),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white,),
                        label: const Text('View PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launch(paper!['abstract']),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View on arXiv'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[700]!),
                        ),
                      ),
                    ),
                  ],
                ),

                // arXiv ID
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'arXiv:${paper!['id']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
