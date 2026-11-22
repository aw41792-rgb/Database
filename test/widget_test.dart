import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shalak_school/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('د شلک ښوونځي اصلي پرده ښکاره کېږي', (tester) async {
    await tester.pumpWidget(const ShalakSchoolApp());
    await tester.pumpAndSettle();
    expect(find.text('شلک منځنی ښوونځی'), findsOneWidget);
    expect(find.text('زده‌کوونکي'), findsOneWidget);
  });
}
