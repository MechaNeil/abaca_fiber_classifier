import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:bcrypt/bcrypt.dart';
import '../domain/entities/user.dart';

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
const int kDatabaseVersion = 5;

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
      version: kDatabaseVersion, // Use constant for version
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
        createdAt $integerType,
        role TEXT NOT NULL DEFAULT 'user'
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
        model TEXT NOT NULL DEFAULT 'mobilenetv3small_b2.tflite',
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

    // Create export functionality tables
    await _createExportTables(db);

    // Initialize default admin user
    await _initializeAdminUser(db);
  }

  /// Initializes the default admin user if not exists
  Future<void> _initializeAdminUser(Database db) async {
    // Check if admin user already exists
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (result.isEmpty) {
      // Create default admin user
      final hashedPassword = BCrypt.hashpw('admin29', BCrypt.gensalt());
      final adminUser = User(
        firstName: 'Admin',
        lastName: 'User',
        username: 'admin',
        password: hashedPassword,
        createdAt: DateTime.now(),
        role: UserRole.admin,
      );

      await db.insert('users', adminUser.toMap());
    }
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
          model TEXT NOT NULL DEFAULT 'mobilenetv3small_b2.tflite',
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

    if (oldVersion < 3) {
      // Add role column in version 3
      await db.execute('''
        ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user'
      ''');

      // Initialize admin user after adding role column
      await _initializeAdminUser(db);
    }

    if (oldVersion < 4) {
      // Add model column in version 4
      await db.execute('''
        ALTER TABLE classification_history ADD COLUMN model TEXT NOT NULL DEFAULT 'mobilenetv3small_b2.tflite'
      ''');
    }

    if (oldVersion < 5) {
      // Add export functionality tables in version 5
      await _createExportTables(db);
    }

    if (oldVersion < 5) {
      // Add export functionality tables in version 5
      await _createExportTables(db);
    }
  }

  /// Creates export-related tables for activity logging and model performance tracking
  Future<void> _createExportTables(Database db) async {
    // Create user activity logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        username TEXT,
        activityType TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create model performance metrics table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS model_performance_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        modelName TEXT NOT NULL,
        modelPath TEXT NOT NULL,
        recordedAt INTEGER NOT NULL,
        totalClassifications INTEGER NOT NULL,
        successfulClassifications INTEGER NOT NULL,
        averageConfidence REAL NOT NULL,
        highestConfidence REAL NOT NULL,
        lowestConfidence REAL NOT NULL,
        gradeDistribution TEXT NOT NULL,
        averageConfidencePerGrade TEXT NOT NULL,
        processingTimeMs REAL NOT NULL,
        deviceInfo TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON user_activity_logs(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_activity_user ON user_activity_logs(userId)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_activity_type ON user_activity_logs(activityType)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_metrics_model ON model_performance_metrics(modelPath)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_metrics_recorded ON model_performance_metrics(recordedAt DESC)
    ''');
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

  /// Resets the database by deleting and recreating it
  ///
  /// ⚠️ WARNING: This will delete ALL data in the database!
  /// This method should only be used for development/testing purposes.
  ///
  /// Usage:
  /// ```dart
  /// await DatabaseService.instance.resetDatabase();
  /// ```
  Future<void> resetDatabase() async {
    await close();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'abaca_users.db');

    // Delete the database file
    await deleteDatabase(path);

    // Reinitialize the database
    _database = await _initDB('abaca_users.db');
  }

  // The deleteDatabase method has been removed for security reasons.
}
