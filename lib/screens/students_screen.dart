import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override State<StudentsScreen> createState()=>_StudentsScreenState();
}
class _StudentsScreenState extends State<StudentsScreen>{
  List<Map<String,Object?>> data=[]; bool loading=true; String query='';
  final search=TextEditingController();
  @override void initState(){super.initState();_load();}
  @override void dispose(){search.dispose();super.dispose();}
  Future<void> _load() async {final r=await SchoolDatabase.instance.getStudents(query:query);if(mounted)setState(()=>{data=r,loading=false});}
  Future<void> _edit([Map<String,Object?>? old]) async {
    final f=GlobalKey<FormState>();
    final keys=['basis_number','name','father_name','grandfather_name','birth_date','admission_year','admission_age','admission_grade','admission_letter','admission_date','grade','shift','student_type','province','district','village','guardian','guardian_phone','status'];
    final labels=['اساس نمبر','نوم','د پلار نوم','د نیکه نوم','د زېږېدو نېټه','د شاملېدو کال','د شاملېدو عمر','د شاملېدو ټولګی','د شاملېدو مکتوب شمېره','د شاملېدو نېټه','اوسنی ټولګی','وخت','د ښوونځي ډول','ولایت','ولسوالۍ','کلی','ولي نوم','د ولي اړیکه','حالت'];
    final c={for(int i=0;i<keys.length;i++) keys[i]:TextEditingController(text:'${old?[keys[i]]??(keys[i]=='grade'?'1':keys[i]=='shift'?'سهار':keys[i]=='status'?'فعال':'')}')};
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(old==null?'د زده‌کوونکي بشپړ ثبت':'د زده‌کوونکي معلومات سمول'),content:SizedBox(width:420,child:Form(key:f,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[for(int i=0;i<keys.length;i++) Padding(padding:const EdgeInsets.only(bottom:9),child:TextFormField(controller:c[keys[i]],keyboardType:['admission_age','admission_grade','grade'].contains(keys[i])?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:labels[i]),validator:['basis_number','name','father_name','grade','shift'].contains(keys[i])?(v)=>v==null||v.trim().isEmpty?'دا ځای اړین دی':null:null)))]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('بندول')),FilledButton(onPressed:(){if(f.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('ساتل'))]));
    if(ok==true){
      final values=<String,Object?>{};
      for(final k in keys){final v=c[k]!.text.trim();values[k]=v.isEmpty?null:(['grade','admission_age','admission_grade'].contains(k)?int.tryParse(v):v);}
      try{if(old==null){await SchoolDatabase.instance.addStudent(basisNumber:values['basis_number'] as String,name:values['name'] as String,fatherName:values['father_name'] as String,grade:values['grade'] as int,shift:values['shift'] as String,grandfatherName:values['grandfather_name'] as String?,birthDate:values['birth_date'] as String?,admissionYear:values['admission_year'] as String?,admissionAge:values['admission_age'] as int?,admissionGrade:values['admission_grade'] as int?,admissionLetter:values['admission_letter'] as String?,admissionDate:values['admission_date'] as String?,studentType:values['student_type'] as String?,province:values['province'] as String?,district:values['district'] as String?,village:values['village'] as String?,guardian:values['guardian'] as String?,guardianPhone:values['guardian_phone'] as String?,status:values['status'] as String???'فعال');}else{await SchoolDatabase.instance.updateStudent(old['id'] as int,values);} await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت نه شو؛ اساس نمبر تکراري کېدای شي. $e')));}
    }
    for(final x in c.values){x.dispose();}
  }
  Future<void> _delete(Map<String,Object?> row) async {final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('حذفول'),content:Text('ایا ${row['name']} حذف کړئ؟'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('نه')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('هو، حذف'))]));if(yes==true){await SchoolDatabase.instance.deleteStudent(row['id'] as int);_load();}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('د زده‌کوونکو بشپړ ثبت')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('نوی زده‌کوونکی')),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:TextField(controller:search,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'د نوم، پلار نوم یا اساس نمبر لټون'),onChanged:(v){query=v;_load();})),Expanded(child:loading?const Center(child:CircularProgressIndicator()):data.isEmpty?const Center(child:Text('زده‌کوونکی نشته')):ListView.builder(itemCount:data.length,itemBuilder:(c,i){final s=data[i];return Card(child:ListTile(leading:CircleAvatar(child:Text('${s['grade']}')),title:Text('${s['name']}'),subtitle:Text('اساس: ${s['basis_number']} • پلار: ${s['father_name']}\n${s['village']??''} • ${s['shift']} • ${s['status']}'),isThreeLine:true,onTap:()=>_edit(s),trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?_edit(s):_delete(s),itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('سمون')),PopupMenuItem(value:'delete',child:Text('حذف'))])));} ))]));
}