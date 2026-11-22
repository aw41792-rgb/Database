import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class ModuleField {
  const ModuleField(this.key, this.label, {this.required = false, this.number = false});
  final String key;
  final String label;
  final bool required;
  final bool number;
}

class SchoolModuleScreen extends StatefulWidget {
  const SchoolModuleScreen({super.key, required this.title, required this.table, required this.fields});
  final String title, table;
  final List<ModuleField> fields;
  @override State<SchoolModuleScreen> createState() => _SchoolModuleScreenState();
}

class _SchoolModuleScreenState extends State<SchoolModuleScreen> {
  List<Map<String, Object?>> data = [];
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final result = await SchoolDatabase.instance.rows(widget.table);
    if (mounted) setState(() { data = result; loading = false; });
  }
  Future<void> _edit([Map<String, Object?>? old]) async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{
      for (final f in widget.fields) f.key: TextEditingController(text: '${old?[f.key] ?? ''}')
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(old == null ? 'نوی ثبت' : 'معلومات سمول'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final f in widget.fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: controllers[f.key],
                        keyboardType: f.number ? TextInputType.number : TextInputType.text,
                        maxLines: f.key == 'body' ? 4 : 1,
                        decoration: InputDecoration(labelText: f.label),
                        validator: f.required ? (v) => v == null || v.trim().isEmpty ? 'دا ځای اړین دی' : null : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('بندول')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('ساتل')),
        ],
      ),
    );
    if (saved == true) {
      final values = <String, Object?>{};
      for (final f in widget.fields) {
        final value = controllers[f.key]!.text.trim();
        values[f.key] = value.isEmpty ? null : (f.number ? num.tryParse(value) : value);
      }
      try {
        if (old == null) {
          await SchoolDatabase.instance.insert(widget.table, values);
        } else {
          await SchoolDatabase.instance.update(widget.table, old['id'] as int, values);
        }
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ثبت کې ستونزه: $e')));
      }
    }
    for (final c in controllers.values) { c.dispose(); }
  }
  Future<void> _delete(Map<String, Object?> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذفول'),
        content: const Text('دا ریکارډ حذف شي؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('نه')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('هو')),
        ],
      ),
    );
    if (yes == true) { await SchoolDatabase.instance.remove(widget.table, row['id'] as int); await _load(); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('نوی ثبت')),
    body: loading ? const Center(child: CircularProgressIndicator()) : data.isEmpty
      ? const Center(child: Text('تر اوسه معلومات نه دي ثبت شوي'))
      : ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (ctx, i) {
            final row = data[i];
            final title = row['name'] ?? row['item_name'] ?? row['title'] ?? row['subject'] ?? row['letter_number'] ?? 'ریکارډ #${row['id']}';
            final subtitle = widget.fields.take(3).map((f) => '${f.label}: ${row[f.key] ?? '—'}').join(' • ');
            return Card(child: ListTile(
              title: Text('$title'), subtitle: Text(subtitle), isThreeLine: true,
              onTap: () => _edit(row),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _edit(row) : _delete(row),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('سمون')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ));
          },
        ),
  );
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override State<AttendanceScreen> createState() => _AttendanceScreenState();
}
class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, Object?>> students = [];
  final Map<int, String> chosen = {};
  String date = DateTime.now().toIso8601String().substring(0, 10);
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final result = await SchoolDatabase.instance.getStudents();
    if (mounted) setState(() => students = result);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ورځنۍ حاضري')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(initialValue: date, decoration: const InputDecoration(labelText: 'نېټه (YYYY-MM-DD)'), onChanged: (v) => date = v),
      ),
      Expanded(child: students.isEmpty
        ? const Center(child: Text('لومړی زده‌کوونکي ثبت کړئ'))
        : ListView.builder(
            itemCount: students.length,
            itemBuilder: (ctx, i) {
              final student = students[i];
              final id = student['id'] as int;
              return ListTile(
                title: Text('${student['name']}'),
                subtitle: Text('${student['basis_number']} • ${student['grade']} ټولګی'),
                trailing: DropdownButton<String>(
                  value: chosen[id] ?? 'حاضر',
                  items: const ['حاضر', 'غیر حاضر', 'رخصت', 'مریض'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setState(() { chosen[id] = v ?? 'حاضر'; }),
                ),
              );
            },
          ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: () async {
            for (final student in students) {
              final id = student['id'] as int;
              await SchoolDatabase.instance.recordAttendance(id, date, chosen[id] ?? 'حاضر');
            }
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حاضري ثبت شوه')));
          },
          icon: const Icon(Icons.save), label: const Text('د ټولو حاضري ثبتول'),
        ),
      ),
    ]),
  );
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}
class _ReportsScreenState extends State<ReportsScreen> {
  int students = 0, teachers = 0, exams = 0, letters = 0, inventory = 0;
  Map<String, int> grades = {}, attendance = {};
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final db = SchoolDatabase.instance;
    final s = await db.studentCount(), t = await db.count('teachers'), e = await db.count('exams');
    final l = await db.count('letters'), inv = await db.count('inventory');
    final g = await db.gradeCounts(), a = await db.attendanceSummary();
    if (mounted) setState(() { students=s; teachers=t; exams=e; letters=l; inventory=inv; grades=g; attendance=a; });
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('احصائیه او ګرافونه')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        _stat('زده‌کوونکي', students), _stat('ښوونکي', teachers), _stat('ازموینې', exams),
        _stat('مکتوبونه', letters), _stat('د اجناسو ډولونه', inventory),
      ]),
      const SizedBox(height: 20),
      const Text('د ټولګیو له مخې زده‌کوونکي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      for (int grade=1; grade<=12; grade++) _bar('$grade ټولګی', grades['$grade'] ?? 0, students),
      const SizedBox(height: 20),
      const Text('د حاضري ثبت شوې شمېرې', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      for (final status in ['حاضر','غیر حاضر','رخصت','مریض']) _bar(status, attendance[status] ?? 0, attendance.values.fold(0, (a,b)=>a+b)),
    ]),
  );
  Widget _stat(String label, int value) => SizedBox(width: 145, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Text('$value', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), Text(label)]))));
  Widget _bar(String label, int value, int total) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('$value')]),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ratio, minHeight: 12, backgroundColor: const Color(0xFFDDE8E5), color: const Color(0xFF16845B))),
      ]),
    );
  }
}