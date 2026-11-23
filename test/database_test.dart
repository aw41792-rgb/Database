import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shalak_school/data/school_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('د ازموینې نمرې باید له ټاکل شوي حد څخه پورته نه وي', () async {
    final db = SchoolDatabase.instance;
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final studentId = await db.addStudent(
      basisNumber: 'TEST-$stamp',
      name: 'ازمایښتي زده‌کوونکی',
      fatherName: 'ازمایښتي پلار',
      grade: 1,
      shift: 'سهار',
    );
    final examId = await db.insert('exams', {
      'title': 'ازمایښتي ازموینه $stamp',
      'academic_year': '۱۴۰۵',
      'max_score': 50,
    });

    await expectLater(
      db.saveResult(
        studentId: studentId,
        examId: examId,
        subject: 'ریاضي',
        score: 51,
      ),
      throwsArgumentError,
    );

    await db.saveResult(
      studentId: studentId,
      examId: examId,
      subject: 'ریاضي',
      score: 45,
    );
    final results = await db.rows('results');
    expect(results.any((r) =>
      r['student_id'] == studentId &&
      r['exam_id'] == examId &&
      r['score'] == 45
    ), isTrue);
  });

  test('مالي لنډیز باید عواید، لګښت او پاتې پیسې سمې جمع کړي', () async {
    final db = SchoolDatabase.instance;
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    await db.insert('finance', {
      'transaction_type': 'عواید',
      'amount': 1000,
      'transaction_date': '۱۴۰۵/۰۱/۰۱',
      'category': 'ازموینه',
      'source_or_recipient': 'ازمایښتي',
      'document_number': 'IN-$stamp',
    });
    await db.insert('finance', {
      'transaction_type': 'لګښت',
      'amount': 250,
      'transaction_date': '۱۴۰۵/۰۱/۰۲',
      'category': 'قرطاسیه',
      'source_or_recipient': 'ازمایښتي',
      'document_number': 'OUT-$stamp',
    });
    final summary = await db.financeSummary();
    expect(summary['عواید'], greaterThanOrEqualTo(1000));
    expect(summary['لګښت'], greaterThanOrEqualTo(250));
    expect(summary['پاتې'], greaterThanOrEqualTo(750));
  });
  test('حاضري باید ټاکلی او معتبر حالت ولري', () async {
    final db = SchoolDatabase.instance;
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final studentId = await db.addStudent(
      basisNumber: 'ATT-$stamp',
      name: 'د حاضري ازمایښتي زده‌کوونکی',
      fatherName: 'ازمایښتي',
      grade: 1,
      shift: 'سهار',
    );
    await expectLater(
      db.recordAttendance(studentId, '۱۴۰۵/۰۱/۰۱', 'نامعلوم'),
      throwsArgumentError,
    );
    await expectLater(
      db.recordAttendance(studentId, '', 'حاضر'),
      throwsArgumentError,
    );
    await db.recordAttendance(studentId, '۱۴۰۵/۰۱/۰۱', 'غیر حاضر');
    final records = await db.rows('attendance');
    expect(records.any((r) =>
      r['student_id'] == studentId && r['status'] == 'غیر حاضر'
    ), isTrue);
  });

  test('د ښوونکي حاضري باید ناسم حالت ونه مني', () async {
    final db = SchoolDatabase.instance;
    final teacherId = await db.insert('teachers', {
      'name': 'د حاضري ازمایښتي ښوونکی',
      'teacher_no': 'T-${DateTime.now().microsecondsSinceEpoch}',
    });
    await expectLater(
      db.recordStaffAttendance(teacherId, '۱۴۰۵/۰۱/۰۱', 'ناسم'),
      throwsArgumentError,
    );
    await db.recordStaffAttendance(teacherId, '۱۴۰۵/۰۱/۰۱', 'حاضر');
    final records = await db.rows('staff_attendance');
    expect(records.any((r) =>
      r['teacher_id'] == teacherId && r['status'] == 'حاضر'
    ), isTrue);
  });


  test('زده‌کوونکی باید له ۱ تر ۱۲ ټولګي او اړینو معلوماتو سره ثبت شي', () async {
    final db = SchoolDatabase.instance;
    await expectLater(
      db.addStudent(
        basisNumber: 'BAD-GRADE-${DateTime.now().microsecondsSinceEpoch}',
        name: 'ناسم ټولګی',
        fatherName: 'ازمایښتي',
        grade: 13,
        shift: 'سهار',
      ),
      throwsArgumentError,
    );
    await expectLater(
      db.addStudent(
        basisNumber: '',
        name: 'بې اساس نمبر',
        fatherName: 'ازمایښتي',
        grade: 1,
        shift: 'سهار',
      ),
      throwsArgumentError,
    );
  });

  test('د ګدام حرکت باید یوازې داخل یا مصرف او مثبته اندازه ولري', () async {
    final db = SchoolDatabase.instance;
    final itemId = await db.insert('inventory', {
      'item_name': 'ازمایښتي کاغذ',
      'quantity': 10,
      'unit': 'بسته',
    });
    await expectLater(
      db.recordInventoryMove(itemId, 'نامعلوم', 1, '۱۴۰۵/۰۱/۰۱'),
      throwsArgumentError,
    );
    await expectLater(
      db.recordInventoryMove(itemId, 'مصرف', 0, '۱۴۰۵/۰۱/۰۱'),
      throwsArgumentError,
    );
    await db.recordInventoryMove(itemId, 'مصرف', 3, '۱۴۰۵/۰۱/۰۱');
    final items = await db.rows('inventory', orderBy: 'id DESC');
    expect(items.first['quantity'], 7);
  });

  test('ثبت شوي زده‌کوونکي باید د تاریخچې په شتون کې حذف نه شي', () async {
    final db = SchoolDatabase.instance;
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final studentId = await db.addStudent(
      basisNumber: 'SAFE-DELETE-$stamp',
      name: 'د حذف ساتنې ازموینه',
      fatherName: 'ازمایښتي',
      grade: 1,
      shift: 'سهار',
    );
    await db.recordAttendance(studentId, '۱۴۰۵/۰۱/۰۳', 'حاضر');
    await expectLater(db.remove('students', studentId), throwsA(anything));
    final students = await db.getStudents(query: 'SAFE-DELETE-$stamp');
    expect(students.any((s) => s['id'] == studentId), isTrue);
  });

}
