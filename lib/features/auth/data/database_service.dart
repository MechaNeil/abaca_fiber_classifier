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
      version: 2, // Increment version for new table
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Creates the database schema
  ///
  /// This method is called when the database is created for the first time.
  /// It creates the users table and classification_history table with the following schema:
  ///
  /// Users Table:
  /// | Column    | Type    | Constraints           |
  /// |-----------|---------|----------------------|
  /// | id        | INTEGER | PRIMARY KEY AUTOINCREMENT |
  /// | firstName | TEXT    | NOT NULL             |
  /// | lastName  | TEXT    | NOT NULL             |
  /// | username  | TEXT    | NOT NULL UNIQUE      |
  /// | password  | TEXT    | NOT NULL             |
  /// | createdAt | INTEGER | NOT NULL             |
  ///
  /// Classification History Table:
  /// | Column         | Type    | Constraints           |
  /// |----------------|---------|----------------------|
  /// | id             | INTEGER | PRIMARY KEY AUTOINCREMENT |
  /// | imagePath      | TEXT    | NOT NULL             |
  /// | predictedLabel | TEXT    | NOT NULL             |
  /// | confidence     | REAL    | NOT NULL             |
  /// | probabilities  | TEXT    | NOT NULL             |
  /// | timestamp      | INTEGER | NOT NULL             |
  /// | userId         | INTEGER | NULL (foreign key)   |
  ///
  /// Parameters:
  /// - [db]: The database instance
  /// - [version]: The database version
  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Create users table
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

    // Create classification history table
    await db.execute('''
      CREATE TABLE classification_history (
        id $idType,
        imagePath $textType,
        predictedLabel $textType,
        confidence $realType,
        probabilities $textType,
        timestamp $integerType,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create index for better performance on timestamp queries
    await db.execute('''
      CREATE INDEX idx_history_timestamp ON classification_history(timestamp DESC)
    ''');

    // Create index for user-specific queries
    await db.execute('''
      CREATE INDEX idx_history_user ON classification_history(userId)
    ''');

    // Create index for grade-specific queries
    await db.execute('''
      CREATE INDEX idx_history_label ON classification_history(predictedLabel)
    ''');
  }

  /// Handles database upgrades
  ///
  /// This method is called when the database version is upgraded.
  /// It handles migration logic for schema changes.
  ///
  /// Parameters:
  /// - [db]: The database instance
  /// - [oldVersion]: The current database version
  /// - [newVersion]: The target database version
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add classification_history table in version 2
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';
      const realType = 'REAL NOT NULL';

      await db.execute('''
        CREATE TABLE classification_history (
          id $idType,
          imagePath $textType,
          predictedLabel $textType,
          confidence $realType,
          probabilities $textType,
          timestamp $integerType,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');

      // Create indexes for better performance
      await db.execute('''
        CREATE INDEX idx_history_timestamp ON classification_history(timestamp DESC)
      ''');

      await db.execute('''
        CREATE INDEX idx_history_user ON classification_history(userId)
      ''');

      await db.execute('''
        CREATE INDEX idx_history_label ON classification_history(predictedLabel)
      ''');
    }
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

  // The deleteDatabase method has been removed for security reasons.
}
