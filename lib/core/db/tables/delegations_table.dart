import 'package:drift/drift.dart';

class DelegationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get fromUserId => text()();
  TextColumn get toUserId => text()();
  TextColumn get task => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get featureId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
