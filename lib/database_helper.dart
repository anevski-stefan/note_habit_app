import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "TodoDatabase.db";
  static final _databaseVersion = 3;

  static final table = 'todos';
  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnIsDone = 'isDone';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $table (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL,
      $columnIsDone INTEGER NOT NULL
    )
  ''');
    await db.execute('''
    CREATE TABLE habits(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      frequency TEXT,
      selectedDays TEXT,
      startDate TEXT
    )
  ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE habits ADD COLUMN selectedDays TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE habits ADD COLUMN startDate TEXT');
    }
  }

  // Helper methods for todos

  Future<int> insertTodo(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllTodos() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> updateTodo(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteTodo(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Helper methods for habits

  Future<List<Map<String, dynamic>>> getHabits() async {
    Database db = await instance.database;
    return await db.query('habits');
  }

  Future<int> insertHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('habits', row);
  }
}
