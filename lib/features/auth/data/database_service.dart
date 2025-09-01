import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database service for managing SQLite database operations
///
/// This service handles:
/// - Database initialization and schema creation
/// - User table operations (CRUD)
/// - Database versioning and migrations
///
/// Usage:
/// ```dart
/// final dbService = DatabaseService.instance;
/// await dbService.init(); // Initialize database
/// ```
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// Gets the database instance, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('abaca_users.db');
    return _database!;
  }

  /// Initializes the SQLite database
  ///
  /// Creates the database file at the specified path and sets up the schema
  ///
  /// Parameters:
  /// - [filePath]: The name of the database file
  ///
  /// Returns: A [Database] instance
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Creates the database schema
  ///
  /// This method is called when the database is created for the first time.
  /// It creates the users table with the following schema:
  ///
  /// | Column    | Type    | Constraints           |
  /// |-----------|---------|----------------------|
  /// | id        | INTEGER | PRIMARY KEY AUTOINCREMENT |
  /// | firstName | TEXT    | NOT NULL             |
  /// | lastName  | TEXT    | NOT NULL             |
  /// | username  | TEXT    | NOT NULL UNIQUE      |
  /// | password  | TEXT    | NOT NULL             |
  /// | createdAt | INTEGER | NOT NULL             |
  ///
  /// Parameters:
  /// - [db]: The database instance
  /// - [version]: The database version
  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        firstName $textType,
        lastName $textType,
        username $textType UNIQUE,
        password $textType,
        createdAt $integerType
      )
    ''');
  }

  /// Handles database upgrades
  ///
  /// This method is called when the database version is upgraded.
  /// You can add migration logic here for future schema changes.
  ///
  /// Parameters:
  /// - [db]: The database instance
  /// - [oldVersion]: The current database version
  /// - [newVersion]: The target database version
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
    // }
  }

  /// Closes the database connection
  ///
  /// Call this method when you're done with the database to free up resources.
  /// The database will be automatically reopened if accessed again.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the entire database
  ///
  /// This method completely removes the database file from the device.
  /// Use with caution as this operation cannot be undone.
  ///
  /// Returns: true if the database was successfully deleted
  ///
  /// [isAdmin] should be true if the caller has administrative privileges.
  Future<bool> deleteDatabase({required bool isAdmin}) async {
    if (!isAdmin) {
      // You can throw an exception or return false if not authorized
      throw Exception('Unauthorized: Admin privileges required to delete database.');
    }
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'abaca_users.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      return true;
    } catch (e) {
      return false;
    }
  }
}
