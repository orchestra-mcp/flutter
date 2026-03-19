import 'package:drift/drift.dart';

/// Per-entity sync metadata — tracks sync status, versions, and team
/// associations for every locally-known entity.
class EntitySyncMetadataTable extends Table {
  TextColumn get entityType =>
      text()(); // project | note | skill | agent | workflow | doc
  TextColumn get entityId => text()();
  TextColumn get status => text().withDefault(const Constant('never_synced'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get localVersion => integer().withDefault(const Constant(0))();
  IntColumn get remoteVersion => integer().nullable()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get lastSyncedBy => text().nullable()();
  TextColumn get sharedWithTeamIds =>
      text().withDefault(const Constant('[]'))(); // JSON array
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}
