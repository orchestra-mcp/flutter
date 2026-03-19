import 'package:drift/drift.dart';

/// Version history for shared entities — records who changed what and when,
/// enabling version browsing and rollback in the UI.
class SyncVersionHistoryTable extends Table {
  TextColumn get id => text()(); // Version entry UUID
  TextColumn get entityType => text()(); // project | note | skill | agent | workflow | doc
  TextColumn get entityId => text()();
  IntColumn get version => integer()();
  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  TextColumn get changeSummary => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get contentHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
