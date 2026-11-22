import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';

class SchoolModuleScreen extends StatefulWidget {
 const SchoolModuleScreen({super.key,required this.title,required this.table,required this.fields});
 final String title,table; final List<ModuleField> fields;
 @override State<SchoolModuleScreen> createState()=>_SchoolModuleScreenState();
}
class ModuleField {const ModuleField(this.key,this.label,{this.required=false,this.number=false});final String key,label;final bool required,number;}
class _SchoolModuleScreenState extends State<SchoolModuleScreen>{
 List<Map<String,Object?>> rows=[]; bool loading=true;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{final r=await SchoolDatabase.instance.rows(widget.table);if(mounted)setState(()=>{rows=r,loading=false});}
 Future<void> _form([Map<String,Object?>? old])async{
  final key=GlobalKey<FormState>();final c={for(final f in widget.fields)f.key:TextEditingController(text:'${old?[f.key]??''}')};
  final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(old==null?'نوی ثبت':'معلومات سمول'),content:SizedBox(width:420,child:Form(key:key,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[for(final f in widget.fields)Padding(padding:const EdgeInsets.only(bottom:9),child:TextFormField(controller:c[f.key],keyboardType:f.number?TextInputType.number:TextInputType.text,maxLines:f.key=='body'?4:1,decoration:InputDecoration(labelText:f.label),validator:f.required?(v)=>v==null||v.trim().isEmpty?'دا ځای اړین دی':null:null))]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('بندول')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('ثبتول'))]));
  if(ok==true){final v=<String,Object?>{};for(final f in widget.fields){final s=c[f.key]!.text.trim();v[f.key]=s.isEmpty?null:(f.number?num.tryParse(s):s);}try{if(old==null){await SchoolDatabase.instance.insert(widget.table,v);}else{await SchoolDatabase.instance.update(widget.table,old['id'] as int,v);}await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ثبت کې ستونزه: $e')));}}
  for(final x in c.values){x.dispose();}
 }
 Future<void> _remove(Map<String,Object?> row)async{final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('حذفول'),content:const Text('دا ریکارډ حذف شي؟'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('نه')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('هو'))]));if(yes==true){await SchoolDatabase.instance.remove(widget.table,row['id'] as int);_load();}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.title)),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_form(),icon:const Icon(Icons.add),label:const Text('نوی ثبت')),body:loading?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('تر اوسه معلومات نه دي ثبت شوي')):ListView.builder(padding:const EdgeInsets.all(10),itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];final title=r['name']??r['item_name']??r['title']??r['subject']??r['letter_number']??'ریکارډ #${r['id']}';final subtitle=widget.fields.take(3).map((f)=>'${f.label}: ${r[f.key]??'—'}').join(' • ');return Card(child:ListTile(title:Text('$title'),subtitle:Text(subtitle),isThreeLine:true,onTap:()=>_form(r),trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?_form(r):_remove(r),itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('سمون')),PopupMenuItem(value:'delete',child:Text('حذف'))])));}));
}

class AttendanceScreen extends StatefulWidget{const AttendanceScreen({super.key});@override State<AttendanceScreen> createState()=>_AttendanceScreenState();}
class _AttendanceScreenState extends State<AttendanceScreen>{
 List<Map<String,Object?>> students=[];String date=DateTime.now().toIso8601String().substring(0,10);final Map<int,String> chosen={};
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{students=await SchoolDatabase.instance.getStudents();if(mounted)setState((){});}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ورځنۍ حاضري')),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:TextFormField(initialValue:date,decoration:const InputDecoration(labelText:'نېټه (YYYY-MM-DD)'),onChanged:(v)=>date=v)),Expanded(child:ListView.builder(itemCount:students.length,itemBuilder:(c,i){final s=students[i];final id=s['id'] as int;return ListTile(title:Text('${s['name']}'),subtitle:Text('${s['basis_number']} • ${s['grade']} ټولګی'),trailing:DropdownButton<String>(value:chosen[id]??'حاضر',items:const ['حاضر','غیر حاضر','رخصت','مریض'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>chosen[id]=v??'حاضر'));})),Padding(padding:const EdgeInsets.all(12),child:FilledButton.icon(onPressed:()async{for(final s in students){final id=s['id'] as int;await SchoolDatabase.instance.recordAttendance(id,date,chosen[id]??'حاضر');}if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حاضري ثبت شوه')));},icon:const Icon(Icons.save),label:const Text('د ټولو حاضري ثبتول')))]));
}

class ReportsScreen extends StatefulWidget{const ReportsScreen({super.key});@override State<ReportsScreen> createState()=>_ReportsScreenState();}
class _ReportsScreenState extends State<ReportsScreen>{
 int students=0,teachers=0,exams=0,letters=0,items=0;Map<String,int> grades={};Map<String,int> attendance={};
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{final d=SchoolDatabase.instance;final s=await d.studentCount();final t=await d.count('teachers');final e=await d.count('exams');final l=await d.count('letters');final i=await d.count('inventory');final g=await d.gradeCounts();final a=await d.attendanceSummary();if(mounted)setState(()=>{students=s,teachers=t,exams=e,letters=l,items=i,grades=g,attendance=a});}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('احصائیه او ګرافونه')),body:ListView(padding:const EdgeInsets.all(16),children:[Wrap(spacing:8,runSpacing:8,children:[_stat('زده‌کوونکي',students),_stat('ښوونکي',teachers),_stat('ازموینې',exams),_stat('مکتوبونه',letters),_stat('د اجناسو ډولونه',items)]),const SizedBox(height:20),const Text('د ټولګیو له مخې زده‌کوونکي',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),for(int n=1;n<=12;n++)_bar('$n ټولګی',grades['$n']??0,students),const SizedBox(height:20),const Text('د حاضري ثبت شوې شمېرې',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),for(final k in ['حاضر','غیر حاضر','رخصت','مریض'])_bar(k,attendance[k]??0,attendance.values.fold(0,(a,b)=>a+b))]));
 Widget _stat(String title,int n)=>SizedBox(width:145,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[Text('$n',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),Text(title)]))));
 Widget _bar(String label,int value,int total){final ratio=total==0?0.0:value/total;return Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(label),Text('$value')]),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:ratio,minHeight:12,backgroundColor:const Color(0xFFDDE8E5),color:const Color(0xFF16845B)))]));}
}
