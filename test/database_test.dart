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

}
