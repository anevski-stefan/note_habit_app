import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final _databaseName = "TodoDatabase.db";
  static final _databaseVersion = 4;

  static final table = 'todos';
  static final columnId = 'id';
  static final columnTitle = 'title';
  static final columnIsDone = 'isDone';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), _databaseName);
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
        startDate TEXT,
        endDate TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE habit_completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER,
        date TEXT,
        completed INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE habits ADD COLUMN endDate TEXT');
    }
  }

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

  Future<List<Map<String, dynamic>>> getHabits() async {
    Database db = await instance.database;
    return await db.query('habits');
  }

  Future<int> insertHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('habits', row);
  }

  Future<int> updateHabit(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update('habits', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleHabitCompletion(int habitId, DateTime date) async {
    Database db = await instance.database;
    String dateString = date.toIso8601String().split('T')[0];

    List<Map<String, dynamic>> existing = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, dateString],
    );

    if (existing.isEmpty) {
      await db.insert('habit_completions', {
        'habit_id': habitId,
        'date': dateString,
        'completed': 1,
      });
    } else {
      int newStatus = existing.first['completed'] == 1 ? 0 : 1;
      await db.update(
        'habit_completions',
        {'completed': newStatus},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dateString],
      );
    }
  }

  Future<bool> isHabitCompletedOnDate(int habitId, DateTime date) async {
    Database db = await instance.database;
    String dateString = date.toIso8601String().split('T')[0];

    List<Map<String, dynamic>> result = await db.query(
      'habit_completions',
      where: 'habit_id = ? AND date = ? AND completed = 1',
      whereArgs: [habitId, dateString],
    );
    return result.isNotEmpty;
  }

  Future<int> getHabitCompletionCount(
      int habitId, DateTime startDate, DateTime? endDate) async {
    final db = await database;
    String query = '''
    SELECT COUNT(*) as count
    FROM habit_completions
    WHERE habit_id = ? AND date >= ? AND completed = 1
  ''';
    List<dynamic> args = [habitId, startDate.toIso8601String().split('T')[0]];

    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.toIso8601String().split('T')[0]);
    } else {
      query += ' AND date <= ?';
      args.add(DateTime.now().toIso8601String().split('T')[0]);
    }

    List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return result.first['count'] as int;
  }

  Future<void> markUncheckedDaysAsNotDone(
      {int? habitId, DateTime? upToDate}) async {
    final db = await database;
    final now = upToDate ?? DateTime.now();
    final dateString = now.toIso8601String().split('T')[0];

    String query = '''
    INSERT OR REPLACE INTO habit_completions (habit_id, date, completed)
    SELECT h.id, d.date, 0
    FROM habits h
    CROSS JOIN (
      SELECT date(?, '-' || (a.a + (10 * b.a) + (100 * c.a)) || ' days') AS date
      FROM (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
      CROSS JOIN (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b
      CROSS JOIN (SELECT 0 AS a UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS c
    ) d
    WHERE d.date >= h.startDate
      AND (h.endDate IS NULL OR d.date <= h.endDate)
      AND d.date < ?
  ''';

    List<dynamic> args = [dateString, dateString];

    if (habitId != null) {
      query += ' AND h.id = ?';
      args.add(habitId);
    }

    query += '''
    AND NOT EXISTS (
      SELECT 1
      FROM habit_completions hc
      WHERE hc.habit_id = h.id AND hc.date = d.date
    )
  ''';

    await db.execute(query, args);
  }
}
