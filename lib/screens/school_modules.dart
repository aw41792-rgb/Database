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
    final db = SchoolDatabase.instance;
    final result = await db.getStudents();
    final saved = await db.attendanceForDate(date);
    if (mounted) {
      setState(() {
        students = result;
        chosen
          ..clear()
          ..addAll(saved);
      });
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ورځنۍ حاضري')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(initialValue: date, decoration: const InputDecoration(labelText: 'نېټه (YYYY-MM-DD)'), onChanged: (v) { date = v; _load(); }),
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
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حاضري ثبت شوه')));
          },
          icon: const Icon(Icons.save), label: const Text('د ټولو حاضري ثبتول'),
        ),
      ),
    ]),
  );
}


class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override State<ResultsScreen> createState() => _ResultsScreenState();
}
class _ResultsScreenState extends State<ResultsScreen> {
  List<Map<String,Object?>> students=[], exams=[], results=[];
  int? studentId, examId;
  final subject=TextEditingController(), score=TextEditingController();
  @override void initState(){super.initState();_load();}
  @override void dispose(){subject.dispose();score.dispose();super.dispose();}
  Future<void> _load() async {
    final db=SchoolDatabase.instance;
    final s=await db.getStudents(), e=await db.rows('exams'), r=await db.rows('results');
    if(mounted)setState((){students=s;exams=e;results=r;});
  }
  Future<void> _save() async {
    if(studentId==null||examId==null||subject.text.trim().isEmpty||num.tryParse(score.text)==null)return;
    await SchoolDatabase.instance.insert('results',{'student_id':studentId,'exam_id':examId,'subject':subject.text.trim(),'score':num.parse(score.text)});
    subject.clear();score.clear();await _load();
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('نمره ثبت شوه')));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('د ازموینو پایلې او نمرې')),
    body:ListView(padding:const EdgeInsets.all(12),children:[
      if(students.isEmpty||exams.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('د نمرو له ثبت مخکې زده‌کوونکي او ازموینه ثبت کړئ.'))),
      if(students.isNotEmpty) DropdownButtonFormField<int>(initialValue:studentId,decoration:const InputDecoration(labelText:'زده‌کوونکی'),items:students.map((s)=>DropdownMenuItem(value:s['id'] as int,child:Text('${s['name']} — ${s['basis_number']}'))).toList(),onChanged:(v)=>setState(()=>studentId=v)),
      if(exams.isNotEmpty) DropdownButtonFormField<int>(initialValue:examId,decoration:const InputDecoration(labelText:'ازموینه'),items:exams.map((e)=>DropdownMenuItem(value:e['id'] as int,child:Text('${e['title']}'))).toList(),onChanged:(v)=>setState(()=>examId=v)),
      const SizedBox(height:8),TextField(controller:subject,decoration:const InputDecoration(labelText:'مضمون')),
      const SizedBox(height:8),TextField(controller:score,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ترلاسه شوې نمرې')),
      const SizedBox(height:8),FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('نمرې ثبتول')),
      const Divider(height:28),const Text('ثبت شوې پایلې',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      for(final r in results) ListTile(title:Text('مضمون: ${r['subject']}'),subtitle:Text('زده‌کوونکی ID: ${r['student_id']} • ازموینه ID: ${r['exam_id']} • نمرې: ${r['score']}')),
    ]),
  );
}

class InventoryMovesScreen extends StatefulWidget {
  const InventoryMovesScreen({super.key});
  @override State<InventoryMovesScreen> createState()=>_InventoryMovesScreenState();
}
class _InventoryMovesScreenState extends State<InventoryMovesScreen>{
  List<Map<String,Object?>> items=[],moves=[];int? itemId;String type='داخل';
  final quantity=TextEditingController(),date=TextEditingController(text:DateTime.now().toIso8601String().substring(0,10)),receiver=TextEditingController(),doc=TextEditingController(),note=TextEditingController();
  @override void initState(){super.initState();_load();}
  @override void dispose(){quantity.dispose();date.dispose();receiver.dispose();doc.dispose();note.dispose();super.dispose();}
  Future<void> _load()async{final d=SchoolDatabase.instance;final i=await d.rows('inventory',orderBy:'item_name ASC'),m=await d.rows('inventory_moves');if(mounted)setState((){items=i;moves=m;});}
  Future<void> _save()async{final q=double.tryParse(quantity.text);if(itemId==null||q==null||q<=0)return;try{await SchoolDatabase.instance.recordInventoryMove(itemId!,type,q,date.text,receiver:receiver.text,documentNo:doc.text,note:note.text);quantity.clear();await _load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('د جنس حرکت ثبت شو')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('د اجناسو ورود او مصرف')),body:ListView(padding:const EdgeInsets.all(12),children:[
    if(items.isEmpty)const Text('لومړی د اجناسو برخه کې جنس ثبت کړئ.'),
    DropdownButtonFormField<int>(initialValue:itemId,decoration:const InputDecoration(labelText:'جنس'),items:items.map((x)=>DropdownMenuItem(value:x['id'] as int,child:Text('${x['item_name']} — موجودي: ${x['quantity']} ${x['unit']}'))).toList(),onChanged:(v)=>setState(()=>itemId=v)),
    DropdownButtonFormField<String>(initialValue:type,decoration:const InputDecoration(labelText:'حرکت'),items:const ['داخل','مصرف'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v??'داخل')),
    TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'اندازه')),
    TextField(controller:date,decoration:const InputDecoration(labelText:'نېټه YYYY-MM-DD')),
    TextField(controller:receiver,decoration:const InputDecoration(labelText:'ترلاسه کوونکی / مصرفوونکی')),
    TextField(controller:doc,decoration:const InputDecoration(labelText:'د سند شمېره')),
    TextField(controller:note,decoration:const InputDecoration(labelText:'یادښت')),
    const SizedBox(height:8),FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('حرکت ثبتول')),
    const Divider(height:28),const Text('د ګدام اوسنی موجودي',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    for(final x in items)ListTile(title:Text('${x['item_name']}'),subtitle:Text('موجودي: ${x['quantity']} ${x['unit']}')),
    const Divider(),const Text('وروستي حرکتونه',style:TextStyle(fontWeight:FontWeight.bold)),
    for(final m in moves.take(20))ListTile(title:Text('${m['move_type']} — ${m['quantity']}'),subtitle:Text('جنس ID: ${m['item_id']} • ${m['move_date']} • ${m['receiver']??''}')),
  ]));
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

class StaffAttendanceScreen extends StatefulWidget {
  const StaffAttendanceScreen({super.key});
  @override State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}
class _StaffAttendanceScreenState extends State<StaffAttendanceScreen> {
  List<Map<String,Object?>> teachers=[];
  final Map<int,String> chosen={};
  String date=DateTime.now().toIso8601String().substring(0,10);
  bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final db=SchoolDatabase.instance;
    final t=await db.rows('teachers',orderBy:'name ASC');
    final saved=await db.staffAttendanceForDate(date);
    if (mounted) {
      setState(() {
        teachers = t;
        loading = false;
        chosen..clear()..addAll(saved);
      });
    }
  }
  Future<void> _save() async {
    for(final t in teachers){
      final id=t['id'] as int;
      await SchoolDatabase.instance.recordStaffAttendance(id,date,chosen[id]??'حاضر');
    }
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('د ښوونکو حاضري ثبت شوه')));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('د ښوونکو حاضري')),
    body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextFormField(
        initialValue:date,decoration:const InputDecoration(labelText:'نېټه (YYYY-MM-DD)'),
        onChanged:(v){date=v;},onFieldSubmitted:(_)=>_load())),
      Expanded(child:teachers.isEmpty?const Center(child:Text('لومړی ښوونکي ثبت کړئ')):ListView.builder(
        itemCount:teachers.length,itemBuilder:(ctx,i){
          final t=teachers[i],id=t['id'] as int;
          return ListTile(title:Text('${t['name']}'),
            subtitle:Text('${t['subject']??'مضمون نه دی ثبت'}'),
            trailing:DropdownButton<String>(
              value:chosen[id]??'حاضر',
              items:const ['حاضر','غیر حاضر','رخصت','مریض'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
              onChanged:(v)=>setState(()=>chosen[id]=v??'حاضر')));
        })),
      Padding(padding:const EdgeInsets.all(12),child:SizedBox(width:double.infinity,
        child:FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('د ښوونکو حاضري ثبتول'))))
    ]));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState()=>_SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen>{
  final school=TextEditingController(),year=TextEditingController();
  bool loading=true;
  @override void initState(){super.initState();_load();}
  @override void dispose(){school.dispose();year.dispose();super.dispose();}
  Future<void> _load()async{
    final s=await SchoolDatabase.instance.getSettings();
    school.text=s['school_name']??'شلک منځنی ښوونځی';
    year.text=s['academic_year']??'۱۴۰۵';
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _save()async{
    if(school.text.trim().isEmpty||year.text.trim().isEmpty)return;
    await SchoolDatabase.instance.saveSetting('school_name',school.text.trim());
    await SchoolDatabase.instance.saveSetting('academic_year',year.text.trim());
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تنظیمات خوندي شول')));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('د ښوونځي تنظیمات')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
      const Icon(Icons.tune_rounded,size:48,color:Color(0xFF16845B)),
      const SizedBox(height:12),
      TextField(controller:school,decoration:const InputDecoration(labelText:'د ښوونځي نوم')),
      const SizedBox(height:12),
      TextField(controller:year,decoration:const InputDecoration(labelText:'تعلیمي کال')),
      const SizedBox(height:16),
      FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('تنظیمات خوندي کول')),
      const SizedBox(height:20),
      const Card(child:Padding(padding:EdgeInsets.all(14),child:Text(
        'معلومات په همدې موبایل کې په محلي ډیټابیس کې ساتل کېږي. د اپلیکیشن له حذفولو مخکې د معلوماتو د بیک‌اپ جوړول اړین دي.',
        style:TextStyle(height:1.5)))),
    ]));
}
