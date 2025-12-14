import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        categoryId TEXT NOT NULL DEFAULT 'other',
        reminderTime TEXT,
        photoPath TEXT,
        photoPaths TEXT,
        completedAt TEXT,
        completedBy TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migração para versão 2 - adiciona dueDate
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT');
    }

    // Migração para versão 3 - adiciona categoryId
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN categoryId TEXT');
    }

    // Migração para versão 4 - adiciona reminderTime
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tasks ADD COLUMN reminderTime TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPath TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN completedBy TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE tasks ADD COLUMN locationName TEXT');
    }
    // Migração para versão 6 - adiciona photoPaths para múltiplas fotos
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE tasks ADD COLUMN photoPaths TEXT');
      // Migra dados existentes de photoPath para photoPaths
      final tasks = await db.query('tasks');
      for (final task in tasks) {
        if (task['photoPath'] != null && task['photoPath'] != '') {
          final photoPath = task['photoPath'] as String;
          final photoPaths = '["$photoPath"]';
          await db.update(
            'tasks',
            {'photoPaths': photoPaths},
            where: 'id = ?',
            whereArgs: [task['id']],
          );
        }
      }
    }
  }

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll({String? categoryId}) async {
    final db = await database;
    // Ordena por data de criação
    const orderBy = 'createdAt DESC';

    if (categoryId != null) {
      final result = await db.query(
        'tasks',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        orderBy: orderBy,
      );
      return result.map((map) => Task.fromMap(map)).toList();
    }

    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Limpa todas as tarefas do banco de dados
  /// Use com cuidado - deleta todos os dados!
  Future<void> deleteAllTasks() async {
    final db = await database;
    await db.delete('tasks');
  }

  /// Reseta completamente o banco de dados
  /// Use apenas em caso de problemas de migração
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    // Fecha o banco de dados atual
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete o arquivo do banco de dados
    await deleteDatabase(path);

    // Recria o banco de dados
    await database;
  }
}
