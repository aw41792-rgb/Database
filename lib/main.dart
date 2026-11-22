import 'package:material_ui/material_ui.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShalakSchoolApp());
}

class ShalakSchoolApp extends StatelessWidget {
  const ShalakSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF16845B);
    return MaterialApp(
      title: 'شلک منځنی ښوونځی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF4F8FA),
        appBarTheme: const AppBarTheme(centerTitle: true, backgroundColor: seed, foregroundColor: Colors.white),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
    );
  }
}
