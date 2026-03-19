import 'package:drift/drift.dart';

class NotificationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get data => text().withDefault(const Constant('{}'))(); // JSON
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
