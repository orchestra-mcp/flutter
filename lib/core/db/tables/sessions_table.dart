import 'package:drift/drift.dart';

class SessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountId => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
