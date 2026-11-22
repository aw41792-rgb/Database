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

  Future<void> _prepareDatabaseFactory() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    if (_desktopFactoryReady) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _desktopFactoryReady = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _databaseOpening ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    await _prepareDatabaseFactory();
    final root = await getDatabasesPath();
    _database = await openDatabase(p.join(root,'shalak_school.db'),version:2,
      onCreate:(db,v) async => _createSchema(db),
      onUpgrade:(db,oldV,newV) async {
        if(oldV<2) {
          for(final sql in [
            "ALTER TABLE students ADD COLUMN grandfather_name TEXT","ALTER TABLE students ADD COLUMN birth_date TEXT",
            "ALTER TABLE students ADD COLUMN admission_year TEXT","ALTER TABLE students ADD COLUMN admission_age INTEGER",
            "ALTER TABLE students ADD COLUMN admission_grade INTEGER","ALTER TABLE students ADD COLUMN admission_letter TEXT",
            "ALTER TABLE students ADD COLUMN admission_date TEXT","ALTER TABLE students ADD COLUMN student_type TEXT",
            "ALTER TABLE students ADD COLUMN province TEXT","ALTER TABLE students ADD COLUMN district TEXT",
            "ALTER TABLE students ADD COLUMN village TEXT","ALTER TABLE students ADD COLUMN guardian TEXT",
            "ALTER TABLE students ADD COLUMN guardian_phone TEXT","ALTER TABLE students ADD COLUMN status TEXT DEFAULT 'فعال'"
          ]) { try { await db.execute(sql); } catch (_) {} }
          for (final sql in [
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
            "ALTER TABLE letters ADD COLUMN status TEXT"
          ]) { try { await db.execute(sql); } catch (_) {} }
          await _createExtraTables(db);
        }
      });
    return _database!;
  }
  Future<void> _createSchema(Database db) async {
    await db.execute("""CREATE TABLE students(id INTEGER PRIMARY KEY AUTOINCREMENT,basis_number TEXT NOT NULL UNIQUE,name TEXT NOT NULL,father_name TEXT NOT NULL,grandfather_name TEXT,birth_date TEXT,admission_year TEXT,admission_age INTEGER,admission_grade INTEGER,admission_letter TEXT,admission_date TEXT,grade INTEGER NOT NULL,shift TEXT NOT NULL,student_type TEXT,province TEXT,district TEXT,village TEXT,guardian TEXT,guardian_phone TEXT,status TEXT NOT NULL DEFAULT 'فعال',created_at TEXT NOT NULL)""");
    await db.execute("CREATE TABLE teachers(id INTEGER PRIMARY KEY AUTOINCREMENT,teacher_no TEXT UNIQUE,name TEXT NOT NULL,father_name TEXT,grandfather_name TEXT,phone TEXT,subject TEXT,qualification TEXT,address TEXT,start_date TEXT,status TEXT DEFAULT 'فعال')");
    await _createExtraTables(db);
    await db.insert('settings',{'key':'school_name','value':'شلک منځنی ښوونځی'});
    await db.insert('settings',{'key':'academic_year','value':'۱۴۰۵'});
  }
  Future<void> _createExtraTables(Database db) async {
    await db.execute("CREATE TABLE IF NOT EXISTS attendance(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL,attendance_date TEXT NOT NULL,status TEXT NOT NULL,note TEXT,UNIQUE(student_id,attendance_date))");
    await db.execute("CREATE TABLE IF NOT EXISTS exams(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,exam_type TEXT,grade INTEGER,academic_year TEXT NOT NULL,exam_date TEXT,max_score REAL DEFAULT 100)");
    await db.execute("CREATE TABLE IF NOT EXISTS results(id INTEGER PRIMARY KEY AUTOINCREMENT,student_id INTEGER NOT NULL,exam_id INTEGER NOT NULL,subject TEXT NOT NULL,score REAL NOT NULL,note TEXT,UNIQUE(student_id,exam_id,subject))");
    await db.execute("CREATE TABLE IF NOT EXISTS inventory(id INTEGER PRIMARY KEY AUTOINCREMENT,item_name TEXT NOT NULL,category TEXT,quantity REAL NOT NULL DEFAULT 0,unit TEXT NOT NULL,entry_date TEXT,document_no TEXT,unit_price REAL DEFAULT 0,note TEXT)");
    await db.execute("CREATE TABLE IF NOT EXISTS inventory_moves(id INTEGER PRIMARY KEY AUTOINCREMENT,item_id INTEGER NOT NULL,move_type TEXT NOT NULL,quantity REAL NOT NULL,move_date TEXT NOT NULL,receiver TEXT,document_no TEXT,note TEXT)");
    await db.execute("CREATE TABLE IF NOT EXISTS letters(id INTEGER PRIMARY KEY AUTOINCREMENT,letter_number TEXT,direction TEXT,subject TEXT NOT NULL,letter_date TEXT NOT NULL,sender TEXT,receiver TEXT,classification TEXT,body TEXT NOT NULL,status TEXT)");
    await db.execute("CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY,value TEXT NOT NULL)");
  }
  Future<int> addStudent({required String basisNumber,required String name,required String fatherName,required int grade,required String shift,String? grandfatherName,String? birthDate,String? admissionYear,int? admissionAge,int? admissionGrade,String? admissionLetter,String? admissionDate,String? studentType,String? province,String? district,String? village,String? guardian,String? guardianPhone,String status='فعال'}) async {
    return (await database).insert('students',{'basis_number':basisNumber.trim(),'name':name.trim(),'father_name':fatherName.trim(),'grandfather_name':grandfatherName,'birth_date':birthDate,'admission_year':admissionYear,'admission_age':admissionAge,'admission_grade':admissionGrade,'admission_letter':admissionLetter,'admission_date':admissionDate,'grade':grade,'shift':shift,'student_type':studentType,'province':province,'district':district,'village':village,'guardian':guardian,'guardian_phone':guardianPhone,'status':status,'created_at':DateTime.now().toIso8601String()});
  }
  Future<int> updateStudent(int id,Map<String,Object?> values) async => (await database).update('students',values,where:'id=?',whereArgs:[id]);
  Future<int> deleteStudent(int id) async => (await database).delete('students',where:'id=?',whereArgs:[id]);
  Future<List<Map<String,Object?>>> getStudents({String query=''}) async {
    final db=await database;
    if(query.trim().isEmpty) return db.query('students',orderBy:'grade ASC,name COLLATE NOCASE ASC');
    return db.query('students',where:'name LIKE ? OR father_name LIKE ? OR basis_number LIKE ?',whereArgs:['%$query%','%$query%','%$query%'],orderBy:'grade ASC');
  }
  Future<int> studentCount() async {final r=await (await database).rawQuery('SELECT COUNT(*) total FROM students');return Sqflite.firstIntValue(r)??0;}
  Future<int> count(String table) async {final r=await (await database).rawQuery('SELECT COUNT(*) total FROM $table');return Sqflite.firstIntValue(r)??0;}
  Future<List<Map<String,Object?>>> rows(String table,{String orderBy='id DESC'}) async => (await database).query(table,orderBy:orderBy);
  Future<int> insert(String table,Map<String,Object?> values) async => (await database).insert(table,values,conflictAlgorithm:ConflictAlgorithm.replace);
  Future<int> update(String table,int id,Map<String,Object?> values) async => (await database).update(table,values,where:'id=?',whereArgs:[id]);
  Future<int> remove(String table,int id) async => (await database).delete(table,where:'id=?',whereArgs:[id]);
  Future<Map<String,int>> gradeCounts() async {final r=await (await database).rawQuery('SELECT grade,COUNT(*) total FROM students WHERE status="فعال" GROUP BY grade');return {for(final x in r) '${x['grade']}':(x['total'] as int)};}
  Future<Map<String,int>> attendanceSummary() async {final r=await (await database).rawQuery('SELECT status,COUNT(*) total FROM attendance GROUP BY status');return {for(final x in r) '${x['status']}':(x['total'] as int)};}
  Future<void> recordAttendance(int studentId,String date,String status) async => (await database).insert('attendance',{'student_id':studentId,'attendance_date':date,'status':status},conflictAlgorithm:ConflictAlgorithm.replace);
  Future<void> recordInventoryMove(int itemId,String type,double quantity,String date,{String? receiver,String? documentNo,String? note}) async {
    final db=await database;
    await db.transaction((txn) async {
      final found=await txn.query('inventory',where:'id=?',whereArgs:[itemId],limit:1);
      if(found.isEmpty) throw Exception('توکی ونه موندل شو');
      final current=(found.first['quantity'] as num).toDouble();
      final next=type=='داخل'?current+quantity:current-quantity;
      if(next<0) throw Exception('په ګدام کې کافي اندازه نشته');
      await txn.update('inventory',{'quantity':next},where:'id=?',whereArgs:[itemId]);
      await txn.insert('inventory_moves',{'item_id':itemId,'move_type':type,'quantity':quantity,'move_date':date,'receiver':receiver,'document_no':documentNo,'note':note});
    });
  }
}