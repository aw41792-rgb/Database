import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SchoolDatabase {
  SchoolDatabase._();
  static final SchoolDatabase instance = SchoolDatabase._();
  Database? _database;
  Future<Database>? _databaseOpening;
  static bool _desktopFactoryReady = false;

  static const _countableTables = {
    'students','teachers','exams','results','attendance','inventory',
    'inventory_moves','letters','settings','staff_attendance','leaves',
    'student_transfers','finance','holidays','notifications'
  };

  Future<void> _prepareDatabaseFactory() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    if (_desktopFactoryReady) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _desktopFactoryReady = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _databaseOpening ??= _openDatabase();
    try {
      return await _databaseOpening!;
    } catch (_) {
      _databaseOpening = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    await _prepareDatabaseFactory();
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'shalak_school.db'),
      version: 3,
      onCreate: (db, version) async => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _upgradeToV2(db);
        if (oldVersion < 3) await _createExtraTables(db);
      },
    );
    return _database!;
  }

  Future<void> _upgradeToV2(Database db) async {
    final alterations = <String>[
      "ALTER TABLE students ADD COLUMN grandfather_name TEXT",
      "ALTER TABLE students ADD COLUMN birth_date TEXT",
      "ALTER TABLE students ADD COLUMN admission_year TEXT",
      "ALTER TABLE students ADD COLUMN admission_age INTEGER",
      "ALTER TABLE students ADD COLUMN admission_grade INTEGER",
      "ALTER TABLE students ADD COLUMN admission_letter TEXT",
      "ALTER TABLE students ADD COLUMN admission_date TEXT",
      "ALTER TABLE students ADD COLUMN student_type TEXT",
      "ALTER TABLE students ADD COLUMN province TEXT",
      "ALTER TABLE students ADD COLUMN district TEXT",
      "ALTER TABLE students ADD COLUMN village TEXT",
      "ALTER TABLE students ADD COLUMN guardian TEXT",
      "ALTER TABLE students ADD COLUMN guardian_phone TEXT",
      "ALTER TABLE students ADD COLUMN status TEXT DEFAULT 'فعال'",
      "ALTER TABLE teachers ADD COLUMN teacher_no TEXT",
      "ALTER TABLE teachers ADD COLUMN grandfather_name TEXT",
      "ALTER TABLE teachers ADD COLUMN qualification TEXT",
      "ALTER TABLE teachers ADD COLUMN address TEXT",
      "ALTER TABLE teachers ADD COLUMN start_date TEXT",
      "ALTER TABLE teachers ADD COLUMN status TEXT DEFAULT 'فعال'",
      "ALTER TABLE exams ADD COLUMN exam_type TEXT",
      "ALTER TABLE exams ADD COLUMN grade INTEGER",
      "ALTER TABLE exams ADD COLUMN exam_date TEXT",
      "ALTER TABLE exams ADD COLUMN max_score REAL DEFAULT 100",
      "ALTER TABLE inventory ADD COLUMN category TEXT",
      "ALTER TABLE inventory ADD COLUMN entry_date TEXT",
      "ALTER TABLE inventory ADD COLUMN document_no TEXT",
      "ALTER TABLE inventory ADD COLUMN unit_price REAL DEFAULT 0",
      "ALTER TABLE letters ADD COLUMN direction TEXT",
      "ALTER TABLE letters ADD COLUMN sender TEXT",
      "ALTER TABLE letters ADD COLUMN receiver TEXT",
      "ALTER TABLE letters ADD COLUMN classification TEXT",
      "ALTER TABLE letters ADD COLUMN status TEXT",
    ];
    for (final sql in alterations) {
      try { await db.execute(sql); } catch (_) { /* column already exists */ }
    }
    await _createExtraTables(db);
  }

  Future<void> _createSchema(Database db) async {
    await db.execute("""CREATE TABLE students(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      basis_number TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      father_name TEXT NOT NULL,
      grandfather_name TEXT,
      birth_date TEXT,
      admission_year TEXT,
      admission_age INTEGER,
      admission_grade INTEGER,
      admission_letter TEXT,
      admission_date TEXT,
      grade INTEGER NOT NULL,
      shift TEXT NOT NULL,
      student_type TEXT,
      province TEXT,
      district TEXT,
      village TEXT,
      guardian TEXT,
      guardian_phone TEXT,
      status TEXT NOT NULL DEFAULT 'فعال',
      created_at TEXT NOT NULL
    )""");
    await db.execute("""CREATE TABLE teachers(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      teacher_no TEXT UNIQUE,
      name TEXT NOT NULL,
      father_name TEXT,
      grandfather_name TEXT,
      phone TEXT,
      subject TEXT,
      qualification TEXT,
      address TEXT,
      start_date TEXT,
      status TEXT DEFAULT 'فعال'
    )""");
    await _createExtraTables(db);
    await db.insert('settings', {'key':'school_name','value':'شلک منځنی ښوونځی'});
    await db.insert('settings', {'key':'academic_year','value':'۱۴۰۵'});
  }

  Future<void> _createExtraTables(Database db) async {
    final statements = <String>[
      """CREATE TABLE IF NOT EXISTS attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL, status TEXT NOT NULL, note TEXT,
        UNIQUE(student_id,attendance_date))""",
      """CREATE TABLE IF NOT EXISTS exams(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        exam_type TEXT, grade INTEGER, academic_year TEXT NOT NULL,
        exam_date TEXT, max_score REAL DEFAULT 100)""",
      """CREATE TABLE IF NOT EXISTS results(
        id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL,
        exam_id INTEGER NOT NULL, subject TEXT NOT NULL, score REAL NOT NULL,
        note TEXT, UNIQUE(student_id,exam_id,subject))""",
      """CREATE TABLE IF NOT EXISTS inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT, item_name TEXT NOT NULL,
        category TEXT, quantity REAL NOT NULL DEFAULT 0, unit TEXT NOT NULL,
        entry_date TEXT, document_no TEXT, unit_price REAL DEFAULT 0, note TEXT)""",
      """CREATE TABLE IF NOT EXISTS inventory_moves(
        id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER NOT NULL,
        move_type TEXT NOT NULL, quantity REAL NOT NULL, move_date TEXT NOT NULL,
        receiver TEXT, document_no TEXT, note TEXT)""",
      """CREATE TABLE IF NOT EXISTS letters(
        id INTEGER PRIMARY KEY AUTOINCREMENT, letter_number TEXT,
        direction TEXT, subject TEXT NOT NULL, letter_date TEXT NOT NULL,
        sender TEXT, receiver TEXT, classification TEXT, body TEXT NOT NULL, status TEXT)""",
      "CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)",
      """CREATE TABLE IF NOT EXISTS staff_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT, teacher_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL, status TEXT NOT NULL, note TEXT,
        UNIQUE(teacher_id,attendance_date))""",
      """CREATE TABLE IF NOT EXISTS leaves(
        id INTEGER PRIMARY KEY AUTOINCREMENT, person_type TEXT NOT NULL,
        person_id INTEGER, person_name TEXT NOT NULL, leave_type TEXT,
        start_date TEXT NOT NULL, end_date TEXT NOT NULL, reason TEXT,
        decision TEXT DEFAULT 'تر څېړنې لاندې', order_number TEXT)""",
      """CREATE TABLE IF NOT EXISTS student_transfers(
        id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL,
        transfer_date TEXT NOT NULL, destination TEXT NOT NULL,
        letter_number TEXT, reason TEXT, note TEXT)""",
      """CREATE TABLE IF NOT EXISTS finance(
        id INTEGER PRIMARY KEY AUTOINCREMENT, transaction_type TEXT NOT NULL,
        amount REAL NOT NULL, transaction_date TEXT NOT NULL,
        category TEXT, source_or_recipient TEXT, document_number TEXT, note TEXT)""",
      """CREATE TABLE IF NOT EXISTS holidays(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        start_date TEXT NOT NULL, end_date TEXT NOT NULL, holiday_type TEXT, note TEXT)""",
      """CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        body TEXT, created_at TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0)""",
      "CREATE INDEX IF NOT EXISTS idx_students_grade ON students(grade,status)",
      "CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date)",
      "CREATE INDEX IF NOT EXISTS idx_results_student ON results(student_id,exam_id)",
      "CREATE INDEX IF NOT EXISTS idx_inventory_moves_item ON inventory_moves(item_id,move_date)",
    ];
    for (final sql in statements) { await db.execute(sql); }
  }

  Future<int> addStudent({
    required String basisNumber, required String name,
    required String fatherName, required int grade, required String shift,
    String? grandfatherName, String? birthDate, String? admissionYear,
    int? admissionAge, int? admissionGrade, String? admissionLetter,
    String? admissionDate, String? studentType, String? province,
    String? district, String? village, String? guardian,
    String? guardianPhone, String status='فعال',
  }) async {
    return (await database).insert('students', {
      'basis_number':basisNumber.trim(),'name':name.trim(),
      'father_name':fatherName.trim(),'grandfather_name':grandfatherName,
      'birth_date':birthDate,'admission_year':admissionYear,
      'admission_age':admissionAge,'admission_grade':admissionGrade,
      'admission_letter':admissionLetter,'admission_date':admissionDate,
      'grade':grade,'shift':shift,'student_type':studentType,
      'province':province,'district':district,'village':village,
      'guardian':guardian,'guardian_phone':guardianPhone,
      'status':status,'created_at':DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateStudent(int id, Map<String,Object?> values) async =>
      (await database).update('students', values, where:'id=?', whereArgs:[id]);
  Future<int> deleteStudent(int id) async =>
      (await database).delete('students', where:'id=?', whereArgs:[id]);

  Future<List<Map<String,Object?>>> getStudents({String query='', int? grade}) async {
    final db=await database;
    final q=query.trim();
    final where=<String>[], args=<Object?>[];
    if(q.isNotEmpty) {
      where.add('(name LIKE ? OR father_name LIKE ? OR basis_number LIKE ?)');
      args.addAll(['%$q%','%$q%','%$q%']);
    }
    if(grade!=null) { where.add('grade=?'); args.add(grade); }
    return db.query('students',where:where.isEmpty?null:where.join(' AND '),
      whereArgs:args.isEmpty?null:args,orderBy:'grade ASC,name COLLATE NOCASE ASC');
  }

  Future<int> studentCount() async {
    final r=await (await database).rawQuery('SELECT COUNT(*) total FROM students');
    return Sqflite.firstIntValue(r)??0;
  }
  Future<int> count(String table) async {
    if(!_countableTables.contains(table)) throw ArgumentError('ناسم جدول');
    final r=await (await database).rawQuery('SELECT COUNT(*) total FROM "$table"');
    return Sqflite.firstIntValue(r)??0;
  }
  Future<List<Map<String,Object?>>> rows(String table,{String orderBy='id DESC'}) async {
    if(!_countableTables.contains(table)) throw ArgumentError('ناسم جدول');
    return (await database).query(table,orderBy:orderBy);
  }
  Future<int> insert(String table,Map<String,Object?> values) async {
    if(!_countableTables.contains(table)) throw ArgumentError('ناسم جدول');
    return (await database).insert(table,values);
  }
  Future<int> update(String table,int id,Map<String,Object?> values) async {
    if(!_countableTables.contains(table)) throw ArgumentError('ناسم جدول');
    return (await database).update(table,values,where:'id=?',whereArgs:[id]);
  }
  Future<int> remove(String table,int id) async {
    if(!_countableTables.contains(table)) throw ArgumentError('ناسم جدول');
    return (await database).delete(table,where:'id=?',whereArgs:[id]);
  }

  Future<Map<String,int>> gradeCounts() async {
    final r=await (await database).rawQuery(
      "SELECT grade,COUNT(*) total FROM students WHERE status='فعال' GROUP BY grade");
    return {for(final x in r) '${x['grade']}':(x['total'] as int)};
  }
  Future<Map<String,int>> attendanceSummary({String? date}) async {
    final r=await (await database).rawQuery(
      'SELECT status,COUNT(*) total FROM attendance ${date==null?'':'WHERE attendance_date=? '}GROUP BY status',
      date==null?null:[date]);
    return {for(final x in r) '${x['status']}':(x['total'] as int)};
  }
  Future<Map<int,String>> attendanceForDate(String date) async {
    final r=await (await database).query('attendance',
      columns:['student_id','status'],where:'attendance_date=?',whereArgs:[date]);
    return {for(final x in r) x['student_id'] as int:x['status'] as String};
  }
  Future<void> recordAttendance(int studentId,String date,String status) async =>
      (await database).insert('attendance',{
        'student_id':studentId,'attendance_date':date,'status':status,
      },conflictAlgorithm:ConflictAlgorithm.replace);

  Future<void> saveResult({required int studentId, required int examId, required String subject, required double score}) async {
    final db = await database;
    final exam = await db.query('exams', columns: ['max_score'], where: 'id=?', whereArgs: [examId], limit: 1);
    if (exam.isEmpty) throw Exception('ازموینه ونه موندل شوه');
    final maxScore = (exam.first['max_score'] as num?)?.toDouble() ?? 100;
    if (score < 0 || score > maxScore) {
      throw ArgumentError('نمرې باید له صفر څخه تر $maxScore پورې وي');
    }
    final student = await db.query('students', columns: ['id'], where: 'id=?', whereArgs: [studentId], limit: 1);
    if (student.isEmpty) throw Exception('زده‌کوونکی ونه موندل شو');
    if (subject.trim().isEmpty) throw ArgumentError('د مضمون نوم اړین دی');
    await db.insert('results', {
      'student_id': studentId,
      'exam_id': examId,
      'subject': subject.trim(),
      'score': score,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String,double>> financeSummary() async {
    final rows = await (await database).rawQuery(
      "SELECT transaction_type, COALESCE(SUM(amount),0) AS total FROM finance GROUP BY transaction_type");
    double income = 0, expense = 0;
    for (final row in rows) {
      final amount = (row['total'] as num).toDouble();
      final type = '${row['transaction_type']}';
      if (type == 'عواید' || type == 'عاید' || type == 'داخل') income += amount;
      if (type == 'لګښت' || type == 'مصرف' || type == 'خارج') expense += amount;
    }
    return {'عواید': income, 'لګښت': expense, 'پاتې': income - expense};
  }

  Future<Map<String,int>> attendanceTotals() async {
    final rows = await (await database).rawQuery(
      "SELECT status, COUNT(*) AS total FROM attendance GROUP BY status");
    return {for (final row in rows) '${row['status']}': (row['total'] as num).toInt()};
  }

  Future<Map<int,String>> staffAttendanceForDate(String date) async {
    final r=await (await database).query('staff_attendance',
      columns:['teacher_id','status'],where:'attendance_date=?',whereArgs:[date]);
    return {for(final x in r) x['teacher_id'] as int:x['status'] as String};
  }
  Future<void> recordStaffAttendance(int teacherId,String date,String status) async =>
      (await database).insert('staff_attendance',{
        'teacher_id':teacherId,'attendance_date':date,'status':status,
      },conflictAlgorithm:ConflictAlgorithm.replace);

  Future<void> recordInventoryMove(int itemId,String type,double quantity,String date,
      {String? receiver,String? documentNo,String? note}) async {
    if(quantity<=0) throw ArgumentError('اندازه باید له صفر څخه زیاته وي');
    final db=await database;
    await db.transaction((txn) async {
      final found=await txn.query('inventory',where:'id=?',whereArgs:[itemId],limit:1);
      if(found.isEmpty) throw Exception('توکی ونه موندل شو');
      final current=(found.first['quantity'] as num).toDouble();
      final next=type=='داخل'?current+quantity:current-quantity;
      if(next<0) throw Exception('په ګدام کې کافي اندازه نشته');
      await txn.update('inventory',{'quantity':next},where:'id=?',whereArgs:[itemId]);
      await txn.insert('inventory_moves',{
        'item_id':itemId,'move_type':type,'quantity':quantity,'move_date':date,
        'receiver':receiver,'document_no':documentNo,'note':note,
      });
    });
  }

  Future<List<Map<String,Object?>>> globalSearch(String query) async {
    final q=query.trim();
    if(q.length<2) return [];
    final db=await database;
    final pattern='%$q%';
    final results=<Map<String,Object?>>[];
    final students=await db.rawQuery(
      "SELECT id,basis_number,name,father_name,grade,village FROM students "
      "WHERE name LIKE ? OR father_name LIKE ? OR grandfather_name LIKE ? OR basis_number LIKE ? OR guardian LIKE ? OR guardian_phone LIKE ? "
      "ORDER BY name LIMIT 30",
      [pattern,pattern,pattern,pattern,pattern,pattern]);
    for(final r in students) {
      results.add({'type':'زده‌کوونکی','title':'${r['name']}','subtitle':'اساس نمبر: ${r['basis_number']} • پلار: ${r['father_name']} • ټولګی: ${r['grade']}','id':r['id']});
    }
    final teachers=await db.rawQuery(
      "SELECT id,teacher_no,name,father_name,subject FROM teachers "
      "WHERE name LIKE ? OR father_name LIKE ? OR teacher_no LIKE ? OR subject LIKE ? OR phone LIKE ? "
      "ORDER BY name LIMIT 20",
      [pattern,pattern,pattern,pattern,pattern]);
    for(final r in teachers) {
      results.add({'type':'ښوونکی','title':'${r['name']}','subtitle':'شمېره: ${r['teacher_no']??'—'} • مضمون: ${r['subject']??'—'}','id':r['id']});
    }
    final letters=await db.rawQuery(
      "SELECT id,letter_number,subject,letter_date FROM letters "
      "WHERE letter_number LIKE ? OR subject LIKE ? OR body LIKE ? OR sender LIKE ? OR receiver LIKE ? "
      "ORDER BY letter_date DESC LIMIT 20",
      [pattern,pattern,pattern,pattern,pattern]);
    for(final r in letters) {
      results.add({'type':'مکتوب','title':'${r['subject']}','subtitle':'شمېره: ${r['letter_number']??'—'} • نېټه: ${r['letter_date']}','id':r['id']});
    }
    final items=await db.rawQuery(
      "SELECT id,item_name,category,quantity,unit FROM inventory "
      "WHERE item_name LIKE ? OR category LIKE ? OR unit LIKE ? "
      "ORDER BY item_name LIMIT 20",
      [pattern,pattern,pattern]);
    for(final r in items) {
      results.add({'type':'جنس','title':'${r['item_name']}','subtitle':'ډول: ${r['category']??'—'} • موجودي: ${r['quantity']} ${r['unit']}','id':r['id']});
    }
    return results;
  }

  Future<Map<String,String>> getSettings() async {
    final rows=await (await database).query('settings');
    return {for(final r in rows) r['key'] as String:r['value'] as String};
  }
  Future<void> saveSetting(String key,String value) async =>
      (await database).insert('settings',{'key':key,'value':value},
        conflictAlgorithm:ConflictAlgorithm.replace);
}
