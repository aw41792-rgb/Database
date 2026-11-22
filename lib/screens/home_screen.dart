import 'package:flutter/material.dart';
import '../data/school_database.dart';
import 'students_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _studentCount = 0;
  @override
  void initState() { super.initState(); _loadCount(); }
  Future<void> _loadCount() async {
    final count = await SchoolDatabase.instance.studentCount();
    if (mounted) setState(() => _studentCount = count);
  }
  Future<void> _openStudents() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentsScreen()));
    _loadCount();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شلک منځنی ښوونځی')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: const Color(0xFFE3F3EC), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('د ښوونځي د مدیریت سیستم', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), const Text('آف‌لاین اداره • د معلوماتو ځايي ساتنه'), const SizedBox(height: 16),
          Text('ثبت شوي زده‌کوونکي: $_studentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ]))),
        const SizedBox(height: 12),
        _ModuleTile(icon: Icons.school_outlined, title: 'زده‌کوونکي', subtitle: 'د زده‌کوونکو ثبت، کتنه او لټون', onTap: _openStudents),
        const _ModuleTile(icon: Icons.people_outline, title: 'ښوونکي', subtitle: 'د ښوونکو معلومات – راتلونکی پړاو'),
        const _ModuleTile(icon: Icons.fact_check_outlined, title: 'حاضري', subtitle: 'د زده‌کوونکو حاضري – راتلونکی پړاو'),
        const _ModuleTile(icon: Icons.assignment_outlined, title: 'ازموینې او پایلې', subtitle: 'د نمرو ثبت – راتلونکی پړاو'),
        const _ModuleTile(icon: Icons.inventory_2_outlined, title: 'اجناس او مصرف', subtitle: 'د ګدام ثبت – راتلونکی پړاو'),
        const _ModuleTile(icon: Icons.description_outlined, title: 'مکتوبونه او اسناد', subtitle: 'اداري اسناد – راتلونکی پړاو'),
        const _ModuleTile(icon: Icons.bar_chart_outlined, title: 'راپورونه', subtitle: 'چاپ او احصائیه – راتلونکی پړاو'),
      ]),
      bottomNavigationBar: const Padding(padding: EdgeInsets.all(12), child: Text('د شلک منځني ښوونځي اداره', textAlign: TextAlign.center)),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon; final String title; final String subtitle; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_left), onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دا برخه به په راتلونکي پړاو کې بشپړه شي.')))));
}
