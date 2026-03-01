// lib/core/database/migrations.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Migrations {
  static const int dbVersion = 6; // ← bumped from 5 to 6

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_name TEXT NOT NULL DEFAULT 'My Dairy Farm',
        rate_per_liter REAL NOT NULL DEFAULT 100.0,
        owner_name TEXT,
        phone TEXT,
        address TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        allocated_liters REAL NOT NULL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        is_payer INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        sale_date TEXT NOT NULL,
        allocated_liters REAL NOT NULL DEFAULT 0.0,
        taken_allocated INTEGER NOT NULL DEFAULT 0,
        extra_liters REAL NOT NULL DEFAULT 0.0,
        extra_amount REAL NOT NULL DEFAULT 0.0,
        rate_per_liter REAL NOT NULL DEFAULT 100.0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
        UNIQUE(client_id, sale_date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_number TEXT NOT NULL UNIQUE,
        name TEXT,
        breed TEXT,
        date_of_birth TEXT,
        gender TEXT NOT NULL DEFAULT 'Female',
        mother_id INTEGER,
        father_tag TEXT,
        purchase_date TEXT,
        purchase_price REAL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1,
        in_production INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS production (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        production_date TEXT NOT NULL,
        morning REAL NOT NULL DEFAULT 0.0,
        afternoon REAL NOT NULL DEFAULT 0.0,
        evening REAL NOT NULL DEFAULT 0.0,
        total REAL GENERATED ALWAYS AS (morning + afternoon + evening) STORED,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE,
        UNIQUE(animal_id, production_date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        vaccine_name TEXT NOT NULL,
        vaccination_date TEXT NOT NULL,
        next_due_date TEXT,
        given_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_date TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL DEFAULT 0.0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_date TEXT NOT NULL,
        cash_amount REAL NOT NULL DEFAULT 0.0,
        rate_per_liter REAL NOT NULL DEFAULT 100.0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0.0,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payments_client_month
      ON payments (client_id, year, month)
    ''');

    // v6 — credit_entries (included here so fresh installs are fully up-to-date)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT    NOT NULL,
        phone       TEXT,
        entry_type  TEXT    NOT NULL,
        amount      REAL    NOT NULL DEFAULT 0,
        liters      REAL             DEFAULT 0,
        description TEXT,
        entry_date  TEXT    NOT NULL,
        created_at  TEXT    NOT NULL
      )
    ''');

    // Apply structural migrations so fresh-install schema matches upgrades
    await _applyV2Migration(db);
    await _applyV3Migration(db);
    await _applyV4Migration(db);
    // v5 columns already present above in CREATE TABLE statements
    // v6 table already created above

    // Insert default settings
    await db.insert('settings', {
      'farm_name': 'My Dairy Farm',
      'rate_per_liter': 100.0,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert 8 default animals
    final now = DateTime.now().toIso8601String();
    for (int i = 1; i <= 8; i++) {
      await db.insert('animals', {
        'tag_number': 'COW-$i',
        'name': 'Animal $i',
        'breed': 'Holstein',
        'gender': 'Female',
        'is_active': 1,
        'in_production': 1,
        'created_at': now,
      });
    }
  }

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _applyV2Migration(db);
    if (oldVersion < 3) await _applyV3Migration(db);
    if (oldVersion < 4) await _applyV4Migration(db);
    if (oldVersion < 5) await _applyV5Migration(db);
    if (oldVersion < 6) await _applyV6Migration(db); // ← fixes the crash
  }

  // ── v1 → v2 ───────────────────────────────────────────────────────────────
  static Future<void> _applyV2Migration(Database db) async {
    final vaccCols  = await db.rawQuery('PRAGMA table_info(vaccinations)');
    final hasIsDone = vaccCols.any((c) => c['name'] == 'is_done');
    if (!hasIsDone) {
      await db.execute(
        'ALTER TABLE vaccinations ADD COLUMN is_done INTEGER NOT NULL DEFAULT 0',
      );
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animal_events (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id     INTEGER NOT NULL,
        event_type    TEXT    NOT NULL DEFAULT 'other',
        event_date    TEXT    NOT NULL,
        title         TEXT    NOT NULL,
        description   TEXT,
        result        TEXT,
        notes         TEXT,
        created_at    TEXT    NOT NULL,
        FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_animal_events_animal_id
      ON animal_events (animal_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_animal_events_date
      ON animal_events (event_date DESC)
    ''');
  }

  // ── v2 → v3 ───────────────────────────────────────────────────────────────
  static Future<void> _applyV3Migration(Database db) async {
    final animalCols      = await db.rawQuery('PRAGMA table_info(animals)');
    final hasInProduction = animalCols.any((c) => c['name'] == 'in_production');

    if (!hasInProduction) {
      await db.execute(
        'ALTER TABLE animals ADD COLUMN in_production INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute(
        'UPDATE animals SET in_production = 0 WHERE mother_id IS NOT NULL',
      );
    }
  }

  // ── v3 → v4 ───────────────────────────────────────────────────────────────
  static Future<void> _applyV4Migration(Database db) async {
    final clientCols   = await db.rawQuery('PRAGMA table_info(clients)');
    final hasSortOrder = clientCols.any((c) => c['name'] == 'sort_order');

    if (!hasSortOrder) {
      await db.execute(
        'ALTER TABLE clients ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('UPDATE clients SET sort_order = id');
    }
  }

  // ── v4 → v5 ───────────────────────────────────────────────────────────────
  static Future<void> _applyV5Migration(Database db) async {
    final clientCols = await db.rawQuery('PRAGMA table_info(clients)');
    final hasIsPayer = clientCols.any((c) => c['name'] == 'is_payer');
    if (!hasIsPayer) {
      await db.execute(
        'ALTER TABLE clients ADD COLUMN is_payer INTEGER NOT NULL DEFAULT 1',
      );
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0.0,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_payments_client_month
      ON payments (client_id, year, month)
    ''');
  }

  // ── v5 → v6 ───────────────────────────────────────────────────────────────
  // Adds the credit_entries table for the credit/debit ledger feature.
  // THIS is what was missing — existing DBs at v5 never got this table.
  static Future<void> _applyV6Migration(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_entries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT    NOT NULL,
        phone       TEXT,
        entry_type  TEXT    NOT NULL,
        amount      REAL    NOT NULL DEFAULT 0,
        liters      REAL             DEFAULT 0,
        description TEXT,
        entry_date  TEXT    NOT NULL,
        created_at  TEXT    NOT NULL
      )
    ''');
  }
}