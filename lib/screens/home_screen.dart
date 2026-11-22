import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';
import 'students_screen.dart';
import 'school_modules.dart';

class HomeScreen extends StatefulWidget {const HomeScreen({super.key});@override State<HomeScreen> createState()=>_HomeScreenState();}
class _HomeScreenState extends State<HomeScreen>{
 int students=0,teachers=0;@override void initState(){super.initState();_refresh();}
 Future<void> _refresh()async{final d=SchoolDatabase.instance;final s=await d.studentCount();final t=await d.count('teachers');if(mounted)setState(()=>{students=s,teachers=t});}
 void _open(Widget page)async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>page));_refresh();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('شلک منځنی ښوونځی'),actions:[IconButton(onPressed:()=>_open(const ReportsScreen()),icon:const Icon(Icons.bar_chart))]),body:ListView(padding:const EdgeInsets.all(14),children:[
 Card(color:const Color(0xFFE3F3EC),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('د ښوونځي د مدیریت سیستم',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('آف‌لاین اداره • ځايي ډیټابېس • د شلک منځنی ښوونځی'),const SizedBox(height:14),Wrap(spacing:22,children:[Text('زده‌کوونکي: $students',style:const TextStyle(fontWeight:FontWeight.bold)),Text('ښوونکي: $teachers',style:const TextStyle(fontWeight:FontWeight.bold))]) ]))),
 const SizedBox(height:12),_tile(Icons.school,'زده‌کوونکي','بشپړ ثبت، سمون، لټون او حذف',()=>_open(const StudentsScreen())),
 _tile(Icons.people,'ښوونکي','شخصي معلومات، مضمون، اړیکه او حالت',()=>_open(const SchoolModuleScreen(title:'د ښوونکو اداره',table:'teachers',fields:[ModuleField('teacher_no','د ښوونکي شمېره'),ModuleField('name','نوم',required:true),ModuleField('father_name','د پلار نوم'),ModuleField('grandfather_name','د نیکه نوم'),ModuleField('phone','د اړیکې شمېره'),ModuleField('subject','مضمون'),ModuleField('qualification','زده‌کړې'),ModuleField('address','استوګنځی'),ModuleField('start_date','د دندې پیل'),ModuleField('status','حالت')]))),
 _tile(Icons.fact_check,'حاضري','ورځنۍ حاضري: حاضر، غیر حاضر، رخصت او مریض',()=>_open(const AttendanceScreen())),
 _tile(Icons.assignment,'ازموینې','د ازموینو نوم، ډول، ټولګی، کال او نېټه',()=>_open(const SchoolModuleScreen(title:'ازموینې',table:'exams',fields:[ModuleField('title','د ازموینې نوم',required:true),ModuleField('exam_type','ډول'),ModuleField('grade','ټولګی',number:true),ModuleField('academic_year','تعلیمي کال',required:true),ModuleField('exam_date','نېټه'),ModuleField('max_score','ټولې نمرې',number:true)]))),
 _tile(Icons.inventory,'اجناس او مصرف','د توکو موجودي، داخل او مصرفي ثبت',()=>_open(const SchoolModuleScreen(title:'د اجناسو ثبت',table:'inventory',fields:[ModuleField('item_name','د جنس نوم',required:true),ModuleField('category','ډول'),ModuleField('quantity','موجوده اندازه',number:true),ModuleField('unit','واحد',required:true),ModuleField('entry_date','د ورود نېټه'),ModuleField('document_no','د سند شمېره'),ModuleField('unit_price','د یوې دانې بیه',number:true),ModuleField('note','یادښت')]))),
 _tile(Icons.description,'مکتوبونه او اسناد','وارده، صادره، محرم او عادي مکتوبونه',()=>_open(const SchoolModuleScreen(title:'مکتوبونه او اسناد',table:'letters',fields:[ModuleField('letter_number','د مکتوب شمېره'),ModuleField('direction','وارده/صادره'),ModuleField('subject','موضوع',required:true),ModuleField('letter_date','نېټه',required:true),ModuleField('sender','لېږونکی'),ModuleField('receiver','ترلاسه کوونکی'),ModuleField('classification','عاجل/عادي/محرم'),ModuleField('body','د مکتوب متن',required:true),ModuleField('status','حالت')]))),
 _tile(Icons.analytics,'راپورونه او ګرافونه','د زده‌کوونکو، ټولګیو، حاضري او ادارې احصائیه',()=>_open(const ReportsScreen())),
 const SizedBox(height:18),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('یادونه: د زده‌کوونکو او ښوونکو معلومات په همدې موبایل کې ساتل کېږي. د موبایل د بدلون یا خرابېدو پر مهال د بیک‌اپ کاپي اړینه ده.'))),
 ]));
 Widget _tile(IconData icon,String title,String subtitle,VoidCallback action)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_left),onTap:action));
}