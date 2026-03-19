import 'package:drift/drift.dart';

/// Locally cached team shares — tracks which entities are shared with which
/// teams and with what permissions.
class TeamSharesTable extends Table {
  TextColumn get id => text()(); // Share UUID
  TextColumn get entityType =>
      text()(); // project | note | skill | agent | workflow | doc
  TextColumn get entityId => text()();
  TextColumn get teamId => text()();
  BoolColumn get shareWithAll => boolean().withDefault(const Constant(true))();
  TextColumn get memberIds =>
      text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get permission => text().withDefault(const Constant('read'))();
  TextColumn get sharedBy => text()();
  DateTimeColumn get sharedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get contentHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
