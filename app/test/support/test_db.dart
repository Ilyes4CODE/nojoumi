import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:nojoumi/data/local/database.dart';
import 'package:sqlite3/open.dart';

/// Opens the real schema in memory, so the whole local data model is verifiable
/// on the developer's machine with no phone attached.
///
/// On Windows there is no `sqlite3.dll` next to the Dart VM, but the OS ships
/// `winsqlite3.dll` in System32 and it is a complete SQLite. Pointing the
/// `sqlite3` package at it is what lets `flutter test` exercise the database
/// rather than mock it — and a mocked database would prove nothing about
/// cascades, defaults, or the Article 6.2 primary key.
NojoumiDatabase openTestDatabase() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  final db = NojoumiDatabase.forTesting(NativeDatabase.memory());
  return db;
}

/// Creates the schema and seeds the singleton rows, mirroring what
/// `MigrationStrategy.beforeOpen` does on a real device.
Future<NojoumiDatabase> freshDatabase() async {
  final db = openTestDatabase();
  await db.customStatement('PRAGMA foreign_keys = ON');
  await db.seedForTesting();
  return db;
}
