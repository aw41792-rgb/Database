import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SchoolDatabase {
  SchoolDatabase._();
  static final SchoolDatabase instance = SchoolDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      p.join(dbPath, 'shalak_school.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE students (id INTEGER PRIMARY KEY AUTOINCREMENT, basis_number TEXT NOT NULL UNIQUE, name TEXT NOT NULL, father_name TEXT NOT NULL, grade INTEGER NOT NULL, shift TEXT NOT NULL, created_at TEXT NOT NULL)');
        await db.execute('CREATE TABLE teachers (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, father_name TEXT, phone TEXT, subject TEXT)');
        await db.execute('CREATE TABLE attendance (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL, attendance_date TEXT NOT NULL, status TEXT NOT NULL)');
        await db.execute('CREATE TABLE exams (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, academic_year TEXT NOT NULL)');
        await db.execute('CREATE TABLE results (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL, exam_id INTEGER NOT NULL, subject TEXT NOT NULL, score REAL NOT NULL)');
        await db.execute('CREATE TABLE inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, item_name TEXT NOT NULL, quantity REAL NOT NULL DEFAULT 0, unit TEXT NOT NULL, note TEXT)');
        await db.execute('CREATE TABLE letters (id INTEGER PRIMARY KEY AUTOINCREMENT, letter_number TEXT, subject TEXT NOT NULL, letter_date TEXT NOT NULL, body TEXT NOT NULL)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await db.insert('settings', {'key': 'school_name', 'value': 'شلک منځنی ښوونځی'});
        await db.insert('settings', {'key': 'academic_year', 'value': '۱۴۰۵'});
      },
    );
    return _database!;
  }

  Future<int> addStudent({required String basisNumber, required String name, required String fatherName, required int grade, required String shift}) async {
    final db = await database;
    return db.insert('students', {'basis_number': basisNumber.trim(), 'name': name.trim(), 'father_name': fatherName.trim(), 'grade': grade, 'shift': shift, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, Object?>>> getStudents() async {
    final db = await database;
    return db.query('students', orderBy: 'grade ASC, name COLLATE NOCASE ASC');
  }

  Future<int> studentCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM students');
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
