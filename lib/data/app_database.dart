import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local cache of envelopes only.
///
/// Do not add a plaintext column. Full-disk encryption of this database is
/// the next step (SQLCipher or an equivalent). It is intentionally not
/// enabled yet.
class StoredEnvelopes extends Table {
  @override
  String get tableName => 'envelopes';

  TextColumn get id => text()();
  TextColumn get chatId => text()();
  TextColumn get sender => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get ciphertext => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [StoredEnvelopes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'secret_envelopes',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
            onResult: _ignoreWasmResult,
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}

void _ignoreWasmResult(WasmDatabaseResult result) {}
