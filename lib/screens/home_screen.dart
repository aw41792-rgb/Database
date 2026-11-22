import 'package:material_ui/material_ui.dart';
import '../data/school_database.dart';
import 'students_screen.dart';
import 'school_modules.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int students = 0, teachers = 0, exams = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final db = SchoolDatabase.instance;
      final values = await Future.wait<int>([
        db.studentCount(),
        db.count('teachers'),
        db.count('exams'),
      ]);
      if (!mounted) return;
      setState(() {
        students = values[0];
        teachers = values[1];
        exams = values[2];
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final date = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F8),
      appBar: AppBar(
        title: const Text('شلک منځنی ښوونځی', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: 'تازه کول', onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
          IconButton(tooltip: 'راپورونه', onPressed: () => _open(const ReportsScreen()), icon: const Icon(Icons.analytics_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _welcome(date),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Text('د ښوونځي لنډیز', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF173B35)))),
                if (loading) const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              childAspectRatio: 1.62,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _statCard('زده‌کوونکي', students, Icons.school_rounded, const Color(0xFF16845B), const Color(0xFFE3F4EC)),
                _statCard('ښوونکي', teachers, Icons.groups_rounded, const Color(0xFF1976A8), const Color(0xFFE4F2FA)),
                _statCard('ازموینې', exams, Icons.assignment_rounded, const Color(0xFF8A5AB5), const Color(0xFFF1EAF8)),
                _statCard('ټولګي', 12, Icons.meeting_room_rounded, const Color(0xFFB07824), const Color(0xFFFBF1DF)),
              ],
            ),
            const SizedBox(height: 22),
            const Text('د ښوونځي چارې', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF173B35))),
            const SizedBox(height: 10),
            _moduleCard(
              icon: Icons.school_rounded, title: 'زده‌کوونکي', subtitle: 'ثبت، لټون، د معلوماتو سمون او پېژندپاڼه',
              color: const Color(0xFF16845B), onTap: () => _open(const StudentsScreen()),
            ),
            _moduleCard(
              icon: Icons.groups_rounded, title: 'ښوونکي او کارکوونکي', subtitle: 'شخصي معلومات، مضمونونه او د دندې حالت',
              color: const Color(0xFF1976A8), onTap: () => _open(const SchoolModuleScreen(
                title: 'د ښوونکو اداره', table: 'teachers',
                fields: [
                  ModuleField('teacher_no','د ښوونکي شمېره'),
                  ModuleField('name','نوم',required:true),
                  ModuleField('father_name','د پلار نوم'),
                  ModuleField('grandfather_name','د نیکه نوم'),
                  ModuleField('phone','د اړیکې شمېره'),
                  ModuleField('subject','مضمون'),
                  ModuleField('qualification','زده‌کړې'),
                  ModuleField('address','استوګنځی'),
                  ModuleField('start_date','د دندې پیل'),
                  ModuleField('status','حالت'),
                ],
              )),
            ),
            _moduleCard(
              icon: Icons.fact_check_rounded, title: 'ورځنۍ حاضري', subtitle: 'حاضر، غیر حاضر، رخصت او ناروغ',
              color: const Color(0xFF008C95), onTap: () => _open(const AttendanceScreen()),
            ),
            _moduleCard(
              icon: Icons.assignment_rounded, title: 'ازموینې', subtitle: 'د ازموینو نوم، ډول، ټولګی او تعلیمي کال',
              color: const Color(0xFF8A5AB5), onTap: () => _open(const SchoolModuleScreen(
                title: 'ازموینې', table: 'exams',
                fields: [
                  ModuleField('title','د ازموینې نوم',required:true),
                  ModuleField('exam_type','د ازموینې ډول'),
                  ModuleField('grade','ټولګی',number:true),
                  ModuleField('academic_year','تعلیمي کال',required:true),
                  ModuleField('exam_date','نېټه'),
                  ModuleField('max_score','ټولې نمرې',number:true),
                ],
              )),
            ),
            _moduleCard(
              icon: Icons.grade_rounded, title: 'د نمرو ثبت او پایلې', subtitle: 'د زده‌کوونکو د مضمونونو نمرې',
              color: const Color(0xFFB07824), onTap: () => _open(const ResultsScreen()),
            ),
            _moduleCard(
              icon: Icons.inventory_2_rounded, title: 'اجناس او تجهیزات', subtitle: 'د توکو ثبت، موجودي او مشخصات',
              color: const Color(0xFF547B50), onTap: () => _open(const SchoolModuleScreen(
                title: 'د اجناسو ثبت', table: 'inventory',
                fields: [
                  ModuleField('item_name','د جنس نوم',required:true),
                  ModuleField('category','ډول'),
                  ModuleField('quantity','موجوده اندازه',number:true),
                  ModuleField('unit','واحد',required:true),
                  ModuleField('entry_date','د ورود نېټه'),
                  ModuleField('document_no','د سند شمېره'),
                  ModuleField('unit_price','د یوې دانې بیه',number:true),
                  ModuleField('note','یادښت'),
                ],
              )),
            ),
            _moduleCard(
              icon: Icons.swap_horiz_rounded, title: 'د اجناسو ورود او مصرف', subtitle: 'د داخل او مصرف ثبت او پاتې موجودي',
              color: const Color(0xFF397A91), onTap: () => _open(const InventoryMovesScreen()),
            ),
            _moduleCard(
              icon: Icons.description_rounded, title: 'مکتوبونه او اسناد', subtitle: 'وارده، صادره، عاجل، عادي او محرم',
              color: const Color(0xFF6D6A9C), onTap: () => _open(const SchoolModuleScreen(
                title: 'مکتوبونه او اسناد', table: 'letters',
                fields: [
                  ModuleField('letter_number','د مکتوب شمېره'),
                  ModuleField('direction','وارده / صادره'),
                  ModuleField('subject','موضوع',required:true),
                  ModuleField('letter_date','نېټه',required:true),
                  ModuleField('sender','لېږونکی'),
                  ModuleField('receiver','ترلاسه کوونکی'),
                  ModuleField('classification','عاجل / عادي / محرم'),
                  ModuleField('body','د مکتوب متن',required:true),
                  ModuleField('status','حالت'),
                ],
              )),
            ),
            _moduleCard(
              icon: Icons.bar_chart_rounded, title: 'راپورونه او احصائیه', subtitle: 'د ښوونځي شمېرې او د ټولګیو راپورونه',
              color: const Color(0xFF315E9B), onTap: () => _open(const ReportsScreen()),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1F4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7E5E9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt_rounded, color: Color(0xFF16845B), size: 27),
                  SizedBox(width: 11),
                  Expanded(child: Text('دا سیستم په همدې موبایل کې معلومات ساتي او د اساسي کارونو لپاره انټرنېټ ته اړتیا نه لري.', style: TextStyle(height: 1.5, color: Color(0xFF36545A)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcome(String date) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight, end: Alignment.bottomLeft,
        colors: [Color(0xFF126B50), Color(0xFF168A82), Color(0xFF237FA8)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: const Color(0xFF126B50).withOpacity(.20), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFFD9F5E8), size: 22),
          SizedBox(width: 8),
          Text('د ښوونځي هوښیار مدیریت', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 13),
        const Text('شلک منځنی ښوونځی', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('زده‌کړه • اداره • پرمختګ', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: .3)),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text('نن: $date', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    ),
  );

  Widget _statCard(String title, int value, IconData icon, Color color, Color pale) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE6EDEF))),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          Text('$value', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: color)),
        ]),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF42565A))),
      ]),
    ),
  );

  Widget _moduleCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 9),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFE6EDEF))),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 25)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF233D40))),
      subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.4))),
      trailing: const Icon(Icons.chevron_left_rounded, color: Color(0xFF789096)),
      onTap: onTap,
    ),
  );
}
