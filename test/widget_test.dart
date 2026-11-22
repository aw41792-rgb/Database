import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shalak_school/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('د شلک ښوونځي اصلي پرده ښکاره کېږي', (tester) async {
    await tester.pumpWidget(const ShalakSchoolApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('شلک منځنی ښوونځی'), findsNWidgets(2));
    expect(find.text('زده‌کوونکي'), findsOneWidget);
  });
}
