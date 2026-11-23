import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final controller = TextEditingController();
  List<Map<String,Object?>> results = [];
  bool loading = false;
  String query = '';
  int request = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    query = value;
    final current = ++request;
    if (value.trim().length < 2) {
      if (mounted) setState(() { results = []; loading = false; });
      return;
    }
    setState(() => loading = true);
    try {
      final found = await SchoolDatabase.instance.globalSearch(value);
      if (!mounted || current != request) return;
      setState(() { results = found; loading = false; });
    } catch (_) {
      if (!mounted || current != request) return;
      setState(() { results = []; loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('په لټون کې ستونزه رامنځته شوه')),
      );
    }
  }

  IconData _icon(String type) {
    switch(type) {
      case 'زده‌کوونکی': return Icons.school_rounded;
      case 'ښوونکی': return Icons.groups_rounded;
      case 'مکتوب': return Icons.description_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }

  Color _color(String type) {
    switch(type) {
      case 'زده‌کوونکی': return const Color(0xFF16845B);
      case 'ښوونکی': return const Color(0xFF1976A8);
      case 'مکتوب': return const Color(0xFF8A5AB5);
      default: return const Color(0xFFB07824);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('د ښوونځي عمومي لټون')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: 'نوم، اساس نمبر، مکتوب، جنس یا مضمون ولیکئ...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'پاکول',
              onPressed: () { controller.clear(); _search(''); },
              icon: const Icon(Icons.close_rounded),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      if (loading) const LinearProgressIndicator(minHeight: 2),
      Expanded(
        child: query.trim().length < 2
          ? const Center(child: Text('د لټون لپاره لږ تر لږه دوه توري ولیکئ'))
          : results.isEmpty && !loading
            ? const Center(child: Text('د دې لټون لپاره معلومات ونه موندل شول'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: results.length,
                separatorBuilder: (_,__) => const SizedBox(height: 7),
                itemBuilder: (context,index) {
                  final item=results[index];
                  final color=_color(item['type'] as String);
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Color(0xFFE5ECEF)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha:.12),
                        child: Icon(_icon(item['type'] as String),color:color),
                      ),
                      title: Text('${item['title']}',style:const TextStyle(fontWeight:FontWeight.w800)),
                      subtitle: Text('${item['type']} • ${item['subtitle']}'),
                    ),
                  );
                },
              ),
      ),
    ]),
  );
}
