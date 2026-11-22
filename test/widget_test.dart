import 'package:flutter_test/flutter_test.dart';
import 'package:shalak_school/main.dart';

void main() {
  testWidgets('د شلک ښوونځي اصلي پرده ښکاره کېږي', (tester) async {
    await tester.pumpWidget(const ShalakSchoolApp());
    expect(find.text('شلک منځنی ښوونځی'), findsOneWidget);
    expect(find.text('زده‌کوونکي'), findsOneWidget);
  });
}
