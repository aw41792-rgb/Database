import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Map<String, Object?>> _students = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final rows = await SchoolDatabase.instance.getStudents();
    if (!mounted) return;
    setState(() { _students = rows; _loading = false; });
  }
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'دا ځای ډکول اړین دي' : null;

  Future<void> _addStudent() async {
    final formKey = GlobalKey<FormState>();
    final basis = TextEditingController(); final name = TextEditingController(); final father = TextEditingController();
    int grade = 1; String shift = 'سهار';
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('د نوي زده‌کوونکي ثبت'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: basis, decoration: const InputDecoration(labelText: 'اساس نمبر'), validator: _required),
        const SizedBox(height: 10), TextFormField(controller: name, decoration: const InputDecoration(labelText: 'د زده‌کوونکي نوم'), validator: _required),
        const SizedBox(height: 10), TextFormField(controller: father, decoration: const InputDecoration(labelText: 'د پلار نوم'), validator: _required),
        const SizedBox(height: 10), DropdownButtonFormField<int>(initialValue: grade, decoration: const InputDecoration(labelText: 'ټولګی'), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} ټولګی'))), onChanged: (v) => setDialogState(() => grade = v ?? 1)),
        const SizedBox(height: 10), DropdownButtonFormField<String>(initialValue: shift, decoration: const InputDecoration(labelText: 'وخت'), items: const ['سهار', 'ماسپښین', 'ماښام'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialogState(() => shift = v ?? 'سهار')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('بندول')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('ثبتول'))],
    )));
    if (saved == true) {
      try {
        await SchoolDatabase.instance.addStudent(basisNumber: basis.text, name: name.text, fatherName: father.text, grade: grade, shift: shift);
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('زده‌کوونکی ثبت شو.')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دا اساس نمبر مخکې ثبت شوی یا د ثبت ستونزه رامنځته شوې.')));
      }
    }
    basis.dispose(); name.dispose(); father.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('زده‌کوونکي')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _addStudent, icon: const Icon(Icons.add), label: const Text('نوی زده‌کوونکی')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _students.isEmpty ? const Center(child: Text('تر اوسه زده‌کوونکی نه دی ثبت شوی.')) : ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), itemCount: _students.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) { final student = _students[index]; return Card(child: ListTile(leading: CircleAvatar(child: Text('${student['grade']}')), title: Text('${student['name']}'), subtitle: Text('اساس نمبر: ${student['basis_number']} • پلار: ${student['father_name']}\nوخت: ${student['shift']}'), isThreeLine: true)); },
    ),
  );
}
