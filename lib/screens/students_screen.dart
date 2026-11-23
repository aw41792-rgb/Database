import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Map<String, Object?>> students = [];
  bool loading = true;
  String query = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await SchoolDatabase.instance.getStudents(query: query);
    if (!mounted) return;
    setState(() {
      students = result;
      loading = false;
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'دا ځای ډکول اړین دي' : null;

  Future<void> _editStudent([Map<String, Object?>? old]) async {
    final formKey = GlobalKey<FormState>();
    const keys = [
      'basis_number','name','father_name','grandfather_name','birth_date',
      'admission_year','admission_age','admission_grade','admission_letter',
      'admission_date','grade','shift','student_type','province','district',
      'village','guardian','guardian_phone','status'
    ];
    const labels = [
      'اساس نمبر','د زده‌کوونکي نوم','د پلار نوم','د نیکه نوم','د زېږېدو نېټه',
      'د شاملېدو کال','د شاملېدو عمر','د شاملېدو ټولګی','د شاملېدو مکتوب شمېره',
      'د شاملېدو نېټه','اوسنی ټولګی','وخت','د ښوونځي ډول','ولایت','ولسوالۍ',
      'کلی','د ولي نوم','د ولي اړیکه','حالت'
    ];
    final controllers = <String, TextEditingController>{};
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final fallback = key == 'grade' ? '1' : key == 'shift' ? 'سهار' : key == 'status' ? 'فعال' : '';
      controllers[key] = TextEditingController(text: '${old?[key] ?? fallback}');
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(old == null ? 'د زده‌کوونکي بشپړ ثبت' : 'د زده‌کوونکي معلومات سمول'),
        content: SizedBox(
          width: 430,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < keys.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: TextFormField(
                        controller: controllers[keys[i]],
                        keyboardType: ['admission_age','admission_grade','grade'].contains(keys[i])
                            ? TextInputType.number : TextInputType.text,
                        decoration: InputDecoration(labelText: labels[i]),
                        validator: keys[i] == 'grade'
                            ? (value) {
                                final grade = int.tryParse(value?.trim() ?? '');
                                if (grade == null || grade < 1 || grade > 12) {
                                  return 'ټولګی باید له ۱ څخه تر ۱۲ پورې وي';
                                }
                                return null;
                              }
                            : ['basis_number','name','father_name','shift'].contains(keys[i])
                                ? _required : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('بندول')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
            },
            child: const Text('ثبتول'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final values = <String, Object?>{};
      for (final key in keys) {
        final value = controllers[key]!.text.trim();
        values[key] = value.isEmpty
            ? null
            : (['grade','admission_age','admission_grade'].contains(key)
                ? int.tryParse(value) : value);
      }
      try {
        if (old == null) {
          await SchoolDatabase.instance.addStudent(
            basisNumber: values['basis_number'] as String,
            name: values['name'] as String,
            fatherName: values['father_name'] as String,
            grade: values['grade'] as int,
            shift: values['shift'] as String,
            grandfatherName: values['grandfather_name'] as String?,
            birthDate: values['birth_date'] as String?,
            admissionYear: values['admission_year'] as String?,
            admissionAge: values['admission_age'] as int?,
            admissionGrade: values['admission_grade'] as int?,
            admissionLetter: values['admission_letter'] as String?,
            admissionDate: values['admission_date'] as String?,
            studentType: values['student_type'] as String?,
            province: values['province'] as String?,
            district: values['district'] as String?,
            village: values['village'] as String?,
            guardian: values['guardian'] as String?,
            guardianPhone: values['guardian_phone'] as String?,
            status: (values['status'] as String?) ?? 'فعال',
          );
        } else {
          await SchoolDatabase.instance.updateStudent(old['id'] as int, values);
        }
        await _load();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ثبت کې ستونزه؛ اساس نمبر تکراري کېدای شي. $error')),
          );
        }
      }
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _deleteStudent(Map<String, Object?> student) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذفول'),
        content: Text('ایا ${student['name']} حذف کړئ؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('نه')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('هو، حذف')),
        ],
      ),
    );
    if (yes == true) {
      await SchoolDatabase.instance.deleteStudent(student['id'] as int);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('د زده‌کوونکو بشپړ ثبت')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _editStudent(),
      icon: const Icon(Icons.add),
      label: const Text('نوی زده‌کوونکی'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'د نوم، پلار نوم یا اساس نمبر لټون',
            ),
            onChanged: (value) {
              query = value;
              _load();
            },
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? const Center(child: Text('زده‌کوونکی نشته'))
                  : ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${student['grade']}')),
                            title: Text('${student['name']}'),
                            subtitle: Text(
                              'اساس: ${student['basis_number']} • پلار: ${student['father_name']}\n'
                              '${student['village'] ?? ''} • ${student['shift']} • ${student['status']}',
                            ),
                            isThreeLine: true,
                            onTap: () => _editStudent(student),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editStudent(student);
                                } else {
                                  _deleteStudent(student);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('سمون')),
                                PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
  );
}